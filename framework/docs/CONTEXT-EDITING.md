# Context Editing — M17 Anthropic API Integration

> Phase 12.11. Pairs `framework/hooks/observation-mask.sh` (R13-002 bash
> extractive masking, ~50% reduction) with the Anthropic server-side
> Context Editing API (~84% reduction on heavy-tool agentic workflows).
> The two paths are mutually exclusive — NOT additive.

---

## 1. What this is

The Anthropic Context Editing API is a server-side strategy that selectively
clears stale content from the conversation history **before** the prompt
reaches Claude. It runs at the API layer, transparently to the client
application. When wired correctly, the client maintains its full local
conversation; the server applies the configured `edits` array on every
`messages.create()` call.

APEX's prior approach (R13-002, F-302, delivered in `observation-mask.sh`)
performs the same idea **client-side** in bash: scan the transcript, replace
older tool-result bodies with a single-line stub, atomic rewrite. This still
works on every platform that has bash + jq, and is the safety net when the
adapter cannot route through the API.

M17 adds the API path **without removing the bash path**. The two paths
coexist; `observation-mask.sh` chooses one per invocation.

---

## 2. Decision matrix (the only two gates)

The hook consults exactly two flags. There is no force-override switch by
design — adding a "force API" would make the failure-mode tests
unfalsifiable.

| `settings.json` `context_editing.enabled` | Adapter capability `apex_context_editing_supported` | Path taken |
| ----------------------------------------- | --------------------------------------------------- | ---------- |
| `false` (default)                         | any                                                 | **bash** (R13-002) |
| `true`                                    | absent / `false`                                    | **bash** (R13-002) |
| `true`                                    | `true`, ping ok or no ping configured               | **API**    |
| `true`                                    | `true`, but API ping fails                          | **bash** (fail-safe) |

In every "API fails" cell the hook emits a `MAJOR` severity event
(`m17-api-fallback` dedup key) so the failure is observable in
`/apex:status` without breaking the masking guarantee.

---

## 3. Stacking is NOT additive

The reductions claimed by the two paths are alternatives, not stages.

- R13-002 bash masking: ~50% reduction on a 100-turn transcript (JetBrains
  study, R2-C034).
- M17 API path (`clear_tool_uses_20250919`): ~84% reduction on the same
  workload (Anthropic Sep 2025 release notes, R2-C099/C156).

`50% + 84%` does NOT equal `134%` of anything. Whichever path runs is the
**only** reduction applied for that invocation. The bash path will not run
when the API path succeeds (it exits immediately after `_m17_mark_state_path
"api"`). The API path does not run when bash runs (the bash block is reached
only by fall-through).

If the user reads "M17 saves 84% on top of F-202's 50%" anywhere in the
APEX surface, that is a documentation bug — please file it.

---

## 4. Protocol — the API request

When the active adapter exposes the capability and the opt-in flag is set,
the adapter is expected to inject the following into every Claude API call:

```
POST https://api.anthropic.com/v1/messages

Headers:
  x-api-key: $ANTHROPIC_API_KEY
  anthropic-version: 2023-06-01
  anthropic-beta: context-management-2025-06-27
  content-type: application/json

Body (relevant subset):
{
  "model": "<model>",
  "max_tokens": <int>,
  "messages": [ ... full client history ... ],
  "tools":    [ ... ],
  "context_management": {
    "edits": [
      { "type": "clear_tool_uses_20250919" }
    ]
  }
}
```

`observation-mask.sh` does **not** issue this request directly — Claude Code
(and any future SDK-based adapter) owns the `messages.create()` invocation
that talks to api.anthropic.com. The hook's job is twofold:

1. **Dispatch**: pick the path (API vs bash) based on the two gates.
2. **Observability**: stamp `STATE.context.mask_path = "api" | "bash"` and
   `STATE.context.last_mask_at` so the rest of APEX (rotation-decide,
   `/apex:status`, telemetry) can see which path ran.

### Advanced options the adapter may forward

The `clear_tool_uses_20250919` strategy supports trigger/keep/exclude tuning:

```jsonc
{
  "type": "clear_tool_uses_20250919",
  "trigger":        { "type": "input_tokens", "value": 30000 },
  "keep":           { "type": "tool_uses",    "value": 3 },
  "clear_at_least": { "type": "input_tokens", "value": 5000 },
  "exclude_tools":  ["web_search"]
}
```

APEX does not yet expose these knobs in `settings.json` — the adapter is
free to choose defaults that match the host's UX. Future work may surface
`context_editing.trigger`/`keep` in `settings.json` if user demand exists.

---

## 5. Optional connectivity ping

The hook supports an optional environment variable, `APEX_CONTEXT_EDITING_API_URL`,
which when set triggers a `curl` ping with a hard 5s connect / 10s overall
timeout. The ping is **not** intended to call api.anthropic.com directly
(that would require an API key in the hook, which violates the executor
contract). Its purpose is testing: a fake responder URL lets
`test-context-editing.sh` simulate API success/failure without hitting the
real Anthropic endpoint.

In production this variable is unset, no ping happens, and the capability
flag is trusted as the adapter's self-report.

---

## 6. Failure modes & severity

| Failure                                                       | Path     | Severity | Recovery |
| ------------------------------------------------------------- | -------- | -------- | -------- |
| `context_editing.enabled = false` (default)                   | bash     | none     | n/a — by design |
| capability flag absent or false                               | bash     | none     | n/a — by design |
| Capability `true`, ping endpoint times out                    | bash     | `MAJOR`  | event-log `observation.mask.api_fallback`; user reviews `/apex:status` |
| Capability `true`, ping returns non-2xx                       | bash     | `MAJOR`  | as above |
| Capability `true`, ping returns 2xx but empty body            | bash     | `MAJOR`  | as above |
| API surface changed (`anthropic-beta` value or strategy name) | bash     | `MAJOR`  | as above; remediation is to update the adapter, not this hook |
| `curl` absent on the host                                     | bash     | `MAJOR`  | as above; bash fallback is cross-platform |
| Anthropic API returns 200 but did not actually clear anything | (silent) | n/a      | **Unobservable from this hook** — the adapter owns the API call. See §7. |

### §7 — unfalsifiable-cost-claim risk

A subtle silent-failure path: the Anthropic API returns 200, the adapter
believes context was cleared, but the masked payload still contained
observation tokens (e.g., the SDK forgot to attach the beta header). In
this case `mask_path="api"` is recorded but the actual token reduction is
zero. The hook cannot detect this from outside the SDK.

Mitigation: the adapter SHOULD log the `usage.input_tokens` delta after
each cleared call; APEX's telemetry (M16) tracks token-cost drift across
sessions. If the M17 opt-in is on and token cost does not drop versus a
control session with the opt-in off, the unfalsifiable case is firing —
file a bug with the adapter, not with this hook.

---

## 8. Cross-platform note

- **API path**: HTTP-only. Works wherever the SDK works (Anthropic ships
  Python, TypeScript, Go, Ruby, Java, C#, PHP — see §9).
- **Bash path**: requires `bash` + `jq`. Tested on Linux, macOS, and
  Windows Git Bash. The cross-platform fallback contract is preserved
  verbatim from R13-002.

A platform with neither SDK nor bash is out of scope for both APEX and
M17. Cursor adapter currently falls back to bash because the cursor
runtime does not expose the capability flag (see
`framework/adapters/cursor/adapter.json`).

---

## 9. Anthropic SDK version pinning

Confirmed (as of fetch on 2026-05-18) at
`https://docs.claude.com/en/docs/build-with-claude/context-editing`:

- Beta header: `anthropic-beta: context-management-2025-06-27`
- Strategy:    `clear_tool_uses_20250919`  (tool result clearing)
- Strategy:    `clear_thinking_20251015`   (thinking block clearing)
- SDK methods: `client.beta.messages.create(...)` (NOT
  `client.messages.create` — the beta plane is separate)

SDK availability matrix from the docs:

| SDK         | Beta channel                | Notes |
| ----------- | --------------------------- | ----- |
| Python      | `client.beta.messages`      | pass `betas=["context-management-2025-06-27"]` |
| TypeScript  | `anthropic.beta.messages`   | pass `betas: [...]`, `context_management: { edits: [...] }` |
| Go          | `client.Beta.Messages.New`  | uses `BetaContextManagementConfigParam` |
| Ruby        | `client.beta.messages`      | symbol/Hash form, same shape |
| Java        | `client.beta().messages()`  | uses `BetaContextManagementConfig.builder()` |
| C#          | `client.Beta.Messages`      | uses `BetaContextManagementConfig` |
| PHP         | `$client->beta->messages`   | `contextManagement: [...]` named arg |

**Claude Code SDK pinning**: the public Claude Code releases (the canonical
APEX adapter) bundle the official `@anthropic-ai/sdk` for TypeScript. The
capability flag is expected to be exposed when the bundled SDK is at or
above the version that ships `BetaMessagesAPI.create()` with
`context_management` support. APEX does not gate on a specific SDK semver
because the adapter contract is "either you expose the capability or you
don't"; what matters in the hook is the capability flag, not the SDK
version directly.

If you are wiring a custom adapter and want to expose M17, your
`adapter.json` should include:

```json
{
  "capabilities": {
    "apex_context_editing_supported": true
  }
}
```

And your adapter's `messages.create()` wrapper must inject the beta header
and `context_management.edits[]` on every call. If you cannot do that —
because your runtime does not forward custom betas, for example — leave
the capability flag at `false` and APEX will use the bash fallback.

---

## 10. When does M17 supersede F-202?

The short answer: when both gates pass and the API ping (if configured)
succeeds. The matrix in §2 is the authoritative answer. The bash path
remains the safety net for every other cell, and the MAJOR-severity
fallback event ensures unexpected superseding-failures are visible.

The longer answer involves the user's intent. Most users on Claude Code
running multi-hundred-turn agentic workflows will see meaningful cost
savings from flipping `context_editing.enabled = true`. Users on Cursor,
or users with adapter configurations that disable the capability flag,
should stay on the bash path — there is no second-class reduction there;
the ~50% headline is what they get.

---

## 11. Where to look if something breaks

- Hook source: `framework/hooks/observation-mask.sh`
- Settings:    `framework/settings.json` (`context_editing.enabled`)
- Adapter:     `framework/adapters/<adapter>/adapter.json`
  (`capabilities.apex_context_editing_supported`)
- Tests:       `framework/tests/test-context-editing.sh`
- State:       `.apex/STATE.json` → `context.mask_path`, `context.last_mask_at`
- Event log:   `.apex/event-log.jsonl` → `observation.mask.fired`,
               `observation.mask.api_fallback`
- Anthropic docs: `https://docs.claude.com/en/docs/build-with-claude/context-editing`

If the API fallback fires repeatedly, the most likely causes (in order):

1. Beta header drift — Anthropic shipped a new `context-management-...`
   header and the adapter still sends the old one. Update the adapter.
2. Strategy name drift — `clear_tool_uses_20250919` was renamed. Update.
3. ZDR / org-policy block — the API key's org disabled the beta. Move to
   a key whose org has the beta enabled, or flip the opt-in off.
4. Adapter bug — the capability flag is true but the SDK call does not
   attach the context_management config. File a bug with the adapter.
