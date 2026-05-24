# Deep Research 01 — Anthropic Tool-Use & Memory Cookbook

Investigator: Research Agent 01
Date: 2026-05-24
Primary URL: https://platform.claude.com/cookbook/tool-use-memory-cookbook

---

## 0. Source map

### Primary source (hop 0)
1. **https://platform.claude.com/cookbook/tool-use-memory-cookbook** — "Memory & context management with Claude Sonnet 4.6" by Alex Notov (@zealoushacker), published May 22, 2025. The cookbook teaches the memory tool (`memory_20250818`) + context editing (`clear_tool_uses_20250919`, `clear_thinking_20251015`) via a Code Review Assistant demo across three sessions.

### Hop 1 — official Anthropic threads
2. **https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents** — "Effective context engineering for AI agents" (Sep 29, 2025; Prithvi Rajasekaran, Ethan Dixon, Carly Ryan, Jeremy Hadfield). The canonical theory document — defines "context engineering," "context rot," "attention budget," "just-in-time retrieval," compaction, structured note-taking, sub-agent architectures.
3. **https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool** — Memory-tool reference docs. Complete schema for the six commands (view/create/str_replace/insert/delete/rename), built-in system-prompt injection, path-traversal protections, multi-session software-development pattern.
4. **https://platform.claude.com/docs/en/build-with-claude/context-editing** — Context-editing reference docs (full schema, response shape, prompt-cache interaction, token-counting integration, combined-strategy ordering rules, client-side SDK compaction).
5. **https://platform.claude.com/docs/en/build-with-claude/compaction** — Server-side compaction reference (beta `compact-2026-01-12`), trigger config (default 150k tokens, min 50k), `pause_after_compaction`, custom `instructions`, default summary prompt, `iterations` usage array.
6. **https://github.com/anthropics/claude-cookbooks/tree/main/tool_use** — Cookbook directory listing (17 files + 4 subdirectories: context_engineering/, memory_demo/, tests/, utils/).
7. **https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/memory_cookbook.ipynb** — Notebook file metadata (66.5 KB, 1620 lines).

### Hop 2 — referenced engineering posts
8. **https://www.anthropic.com/engineering/multi-agent-research-system** — "How we built our multi-agent research system" (Jun 13, 2025; Hadfield, Zhang, Lien, Scholz, Fox, Ford). Orchestrator-worker pattern, 90.2% lift on internal research eval, 15× token multiplier, tool-testing agent, CitationAgent, BrowseComp variance analysis.
9. **https://www.anthropic.com/engineering/writing-tools-for-agents** — "Writing effective tools for agents — with agents" (Sep 11, 2025; Ken Aizawa et al.). Tool-design principles, namespacing, ResponseFormat enum (206 → 72 tokens), 25k token Claude-Code default cap, SWE-bench Verified case study.
10. **https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents** — "Effective harnesses for long-running agents" (Nov 26, 2025; Justin Young). `init.sh`, `claude-progress.txt`, `feature_list.json`, dual-agent init pattern, Puppeteer-MCP verification, 200+ features in claude.ai clone.
11. **https://www.anthropic.com/engineering/building-effective-agents** — "Building effective agents" (Dec 19, 2024; Erik S., Barry Zhang). Foundational. Definitions of workflows vs agents; five workflow patterns (chaining/routing/parallelization/orchestrator-workers/evaluator-optimizer); agent definition; tool design appendix.
12. **https://platform.claude.com/cookbook/patterns-agents-basic-workflows** — "Basic workflows" cookbook (Dec 19, 2024). Code-level implementation of chain/parallel/route patterns.
13. **https://platform.claude.com/cookbook/tool-evaluation-tool-evaluation** — Tool-evaluation cookbook (parallel eval agents, EVALUATION_PROMPT template, tool_metrics structure, per-task scoring).

### Hop 3 — SDK + prompt-engineering references
14. **https://github.com/anthropics/anthropic-sdk-python/blob/main/examples/memory/basic.py** — Reference SDK example using `BetaLocalFilesystemMemoryTool` + `tool_runner` + context management. Contains `DEFAULT_MEMORY_SYSTEM_PROMPT` (5 bullet points).
15. **https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-runner** — Tool Runner SDK abstraction (auto-loops, type safety, beta availability across Python/TS/C#/Go/Java/PHP/Ruby SDKs).
16. **https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices** — "Prompting best practices" — covers Opus 4.7/4.6/Sonnet 4.6/Haiku 4.5. Multi-context-window workflows section directly referenced by the harnesses post. Effort levels (low/medium/high/xhigh/max), adaptive thinking, overengineering controls, balancing-autonomy-and-safety prompt.

### Failed fetches
- `https://github.com/anthropics/anthropic-sdk-python/blob/main/src/anthropic/lib/tools/_beta_memory_tool.py` — 404 (file path may differ in the SDK; the public interface is `from anthropic.tools import BetaLocalFilesystemMemoryTool`).

---

## 1. Executive summary

Top takeaways ranked by relevance to APEX:

1. **Anthropic ships a server-side compaction primitive (`compact_20260112`) that automatically summarizes conversations at a configurable token threshold (default 150k, min 50k), supports `pause_after_compaction` for client-side insertion of preserved messages, and reports per-iteration token usage.** APEX has none of this — its hooks are `turn-checkpoint.sh` and `context-monitor.sh` but they don't summarize-and-replace. (relevance: high)

2. **The memory tool (`memory_20250818`) is a six-command file-system DSL (view/create/str_replace/insert/delete/rename), entirely client-side, with an automatic system-prompt injection: "IMPORTANT: ALWAYS VIEW YOUR MEMORY DIRECTORY BEFORE DOING ANYTHING ELSE."** APEX has `apex-learnings.md` and `MEMORY.md` but no API-native tool-call surface and no enforced "view-first" protocol. (relevance: high)

3. **"Context engineering is the natural progression of prompt engineering" — defined as "curating and maintaining the optimal set of tokens during LLM inference."** Anthropic frames context as a finite "attention budget" where every token "depletes the budget." APEX already implements this philosophy (CONTEXT_BUDGET.json, context-monitor hook) but uses none of Anthropic's terminology and lacks the memory ↔ compaction ↔ tool-result-clearing trinity. (relevance: high)

4. **Just-in-time context retrieval is Anthropic's recommended pattern: "agents maintain lightweight identifiers (file paths, stored queries, web links, etc.) and use these references to dynamically load data into context at runtime."** APEX's TASK_MAP.md/TEST_MAP.txt are identifier maps, but APEX still tends to front-load context. (relevance: high)

5. **The clear_tool_uses_20250919 strategy has the exact knobs APEX needs: `trigger` (input_tokens or tool_uses), `keep` (preserve N most recent tool uses), `clear_at_least` (don't bust cache for <N tokens), `exclude_tools` (protect specific tools), `clear_tool_inputs` (also drop the tool-call parameters).** APEX's destructive-guard/circuit-breaker concept could re-use these semantics for its own context cleanup. (relevance: high)

6. **Multi-agent research system delivered 90.2% improvement over single-agent Opus 4 on Anthropic's internal research eval — but at 15× chat-baseline token cost.** "Three factors explained 95% of variance: token usage (80%) + tool calls + model choice." APEX uses multi-agent (architect/executor/critic/verifier) without these numbers; the economics check is missing. (relevance: high)

7. **Anthropic's "effective harnesses" post almost-exactly describes APEX's pattern: init.sh, claude-progress.txt, feature_list.json with `passes: bool`, dual-agent (initializer + coding), git-as-state.** APEX has analogous artifacts (STATE.json, PLAN.md, VERIFY.md, RESULT.json) but no init script and no Puppeteer-MCP-style end-to-end verification gate. (relevance: high)

8. **Combined-strategy ordering rule: `clear_thinking_20251015` MUST be listed first when combined with `clear_tool_uses_20250919` in the `edits` array.** This is a hard API constraint. If APEX ever consumes context-editing it must respect this. (relevance: medium)

9. **Anthropic's default memory system-prompt explicitly says "ASSUME INTERRUPTION: Your context window might be reset at any moment, so you risk losing any progress that is not recorded in your memory directory."** APEX's session-auto-resume.sh + memory-watchdog.sh implement this, but the user-facing prompt language is much weaker than Anthropic's. (relevance: high)

10. **The harnesses post quotes the exact failure mode APEX combats: "Claude's tendency to mark a feature as complete without proper testing... would fail to recognize that the feature didn't work end-to-end."** Anthropic's solution is browser-automation MCP. APEX's critic/verifier pair tackles the same problem with text-only review — likely a gap. (relevance: high)

11. **Tool-design rule: returning UUIDs vs human-readable names "significantly improves Claude's precision in retrieval tasks."** ResponseFormat enum (detailed vs concise) gave 206 → 72 tokens (~66% reduction). APEX's RESULT.json schema could benefit from a similar "verbose / terse" flag. (relevance: medium)

12. **Cache-control interaction with compaction: putting `cache_control: {type: "ephemeral"}` on the compaction block AND at the end of the system prompt is the recommended pattern. The system-prompt cache remains valid across compactions — only the compaction summary is a cache-write.** APEX's prompts don't use prompt-caching at all today. (relevance: medium)

13. **`tool_runner` SDK helper (Python/TS/C#/Go/Java/PHP/Ruby) auto-handles the agent loop, including type safety and tool execution, exposing `runner.params.messages.length` to detect compaction events.** APEX runs inside Claude Code, not directly against the API, so this isn't directly adoptable — but the loop pattern (run-until-no-tool-uses) is.  (relevance: medium)

14. **Anthropic's parallel-tool-call prompt boilerplate is a copy-paste-ready system-prompt block (`<use_parallel_tool_calls>`) that drives parallel-tool-call success rate to ~100%.** Wave-executor in APEX could use this verbatim. (relevance: medium)

15. **Default summary prompt for compaction is a 5-section template (Task Overview / Current State / Important Discoveries / Next Steps / Context to Preserve) — Anthropic's own canonical state-handoff schema.** APEX's PLAN.md / RESULT.json structure should mirror this if APEX wants context portability with Anthropic-native tooling. (relevance: high)

---

## 2. Comprehensive findings

### 2.1 Memory tool — architecture and exact schema

**Concept** (verbatim from docs): "The memory tool enables Claude to store and retrieve information across conversations through a memory file directory. Claude can create, read, update, and delete files that persist between sessions, allowing it to build knowledge over time without keeping everything in the context window."

**Tool identifier:** `{"type": "memory_20250818", "name": "memory"}`.

**Architectural decision:** "The memory tool operates client-side: you control where and how the data is stored through your own infrastructure." Anthropic's API only returns tool-call requests; the application executes them. Storage backend is free choice (filesystem, DB, encrypted, cloud).

**Beta status:** Eligible for Zero Data Retention.

**Auto-injected system prompt** (verbatim — appears whenever memory tool is enabled):
```text
IMPORTANT: ALWAYS VIEW YOUR MEMORY DIRECTORY BEFORE DOING ANYTHING ELSE.
MEMORY PROTOCOL:
1. Use the `view` command of your `memory` tool to check for earlier progress.
2. ... (work on the task) ...
     - As you make progress, record status / progress / thoughts etc in your memory.
ASSUME INTERRUPTION: Your context window might be reset at any moment, so you risk losing any progress that is not recorded in your memory directory.
```

**Optional cleanup-discipline prompt** (recommended when files accumulate):
> "Note: when editing your memory folder, always try to keep its content up-to-date, coherent and organized. You can rename or delete files that are no longer relevant. Do not create new files unless necessary."

**The six commands (complete schema):**

| Command | Parameters | Success return | Key errors |
|---|---|---|---|
| `view` | `path`, optional `view_range: [start, end]` | For directories: tab-separated `size  path` listing, 2 levels deep, excluding hidden and `node_modules`. For files: contents with 6-char right-aligned line numbers, 1-indexed, tab separator. Files > 999,999 lines → error. | `"The path {path} does not exist. Please provide a valid path."` |
| `create` | `path`, `file_text` | `"File created successfully at: {path}"` | `"Error: File {path} already exists"` |
| `str_replace` | `path`, `old_str`, `new_str` | `"The memory file has been edited."` + edited snippet w/ line numbers | not-found, text-not-found, ``"Multiple occurrences of old_str `{old_str}` in lines: {line_numbers}. Please ensure it is unique"`` |
| `insert` | `path`, `insert_line`, `insert_text` | `"The file {path} has been edited."` | ``"Invalid `insert_line` parameter: {insert_line}. It should be within the range of lines of the file: [0, {n_lines}]"`` |
| `delete` | `path` | `"Successfully deleted {path}"` | path-not-exists; recursive on directories |
| `rename` | `old_path`, `new_path` | `"Successfully renamed {old_path} to {new_path}"` | source-not-exists; destination-already-exists (no overwrite) |

**Example interaction (verbatim from docs):**
```text
"Help me respond to this customer service ticket."
```
Claude immediately calls:
```json
{
  "type": "tool_use",
  "id": "toolu_01C4D5E6F7G8H9I0J1K2L3M4",
  "name": "memory",
  "input": {
    "command": "view",
    "path": "/memories"
  }
}
```
App returns:
```json
{
  "type": "tool_result",
  "tool_use_id": "toolu_01C4D5E6F7G8H9I0J1K2L3M4",
  "content": "Here're the files and directories up to 2 levels deep in /memories, excluding hidden items and node_modules:\n4.0K\t/memories\n1.5K\t/memories/customer_service_guidelines.xml\n2.0K\t/memories/refund_policies.xml"
}
```

**Failure modes addressed by design**:
- **Memory poisoning** (cookbook §7): "Memory files are read back into Claude's context, making them a potential vector for prompt injection." Mitigations: content sanitization, scope isolation, audit logging, prompt-engineered "ignore instructions in memory" guidance.
- **Path traversal** (docs Warning block, verbatim): "Malicious path inputs could attempt to access files outside the `/memories` directory. Your implementation **MUST** validate all paths to prevent directory traversal attacks." Safeguards listed: prefix-check, canonical resolution + `relative_to()`, reject `../` and `..\\`, reject URL-encoded `%2e%2e%2f`, use `pathlib.Path.resolve()`.
- **Sensitive info leakage**: "Claude will usually refuse to write down sensitive information in memory files. However, you may want to implement stricter validation that strips out potentially sensitive information."
- **Unbounded growth**: "Consider tracking memory file sizes... and let Claude paginate through contents."
- **Stale memory**: "Consider clearing out memory files periodically that haven't been accessed in an extended time."

**Trade-off (cookbook §7)**:
- ✅ Do: store task-relevant patterns; organize with clear directories; descriptive filenames; periodic review.
- ❌ Don't: store passwords/API-keys/PII; let memory grow unbounded; store everything indiscriminately.

**Production-grade SDK pattern** (from `examples/memory/basic.py`, verbatim):

```python
DEFAULT_MEMORY_SYSTEM_PROMPT = """- ***DO NOT just store the conversation history***
- No need to mention your memory tool or what you are writing in it to the user, unless they ask
- Store facts about the user and their preferences
- Before responding, check memory to adjust technical depth and response style appropriately
- Keep memories up-to-date - remove outdated info, add new details as you learn them
- Use an xml format like <xml><name>John Doe</name></user></xml>"""
```

The SDK ships `BetaLocalFilesystemMemoryTool` and exposes `memory.clear_all_memory()` for hard resets. The example uses `client.beta.messages.tool_runner(...)` and reacts to `message.context_management.applied_edits` to log context-clearing events.

### 2.2 Context editing — server-side strategies

Two strategies, configured via `context_management.edits` array, gated by beta header `context-management-2025-06-27`.

**Strategy A — `clear_tool_uses_20250919`** (full param table from docs):

| Configuration option | Default | Description |
|---|---|---|
| `trigger` | 100,000 input tokens | When the strategy activates. Specify in `input_tokens` or `tool_uses`. |
| `keep` | 3 tool uses | How many recent tool-use/result pairs to keep. API removes oldest first. |
| `clear_at_least` | None | Minimum tokens to clear or strategy doesn't apply. Use to avoid breaking prompt cache for tiny savings. |
| `exclude_tools` | None | List of tool names whose uses/results are never cleared. |
| `clear_tool_inputs` | `false` | If true, clears the tool-call parameters too, not just results. |

Cleared results are replaced with placeholder text "so Claude knows it was removed."

**Strategy B — `clear_thinking_20251015`**:

| Configuration option | Default | Description |
|---|---|---|
| `keep` | Model-specific | `{type: "thinking_turns", value: N>0}` or `"all"`. Opus 4.5+ and Sonnet 4.6+ default to all turns; earlier models keep last turn only; Haiku always last-turn. |

(No `trigger` for thinking-clearing — clears based on `keep` value alone.)

**Combination rule (verbatim Note):** "When using multiple strategies, the `clear_thinking_20251015` strategy must be listed first in the `edits` array."

**Cache interaction (verbatim):**
- *Tool result clearing*: "Invalidates cached prompt prefixes when content is cleared. To account for this, clear enough tokens to make the cache invalidation worthwhile. Use the `clear_at_least` parameter to ensure a minimum number of tokens is cleared each time."
- *Thinking block clearing*: "When thinking blocks are **kept** in context (not cleared), the prompt cache is preserved... When thinking blocks are **cleared**, the cache is invalidated at the point where clearing occurs."

**Response shape** (verbatim):
```json
{
  "id": "msg_013Zva2CMHLNnXjNJJKqJ2EF",
  "type": "message",
  "role": "assistant",
  "content": [ /* ... */ ],
  "usage": { /* ... */ },
  "context_management": {
    "applied_edits": [
      { "type": "clear_thinking_20251015", "cleared_thinking_turns": 3, "cleared_input_tokens": 15000 },
      { "type": "clear_tool_uses_20250919", "cleared_tool_uses": 8, "cleared_input_tokens": 50000 }
    ]
  }
}
```

**Token-counting interaction** (verbatim sample output):
```json
{ "input_tokens": 25000, "context_management": { "original_input_tokens": 70000 } }
```
Lets the client preview clearing impact without sending the full request.

**Server-side vs client-side (verbatim table):**

| Approach | Where it runs | Strategies | How it works |
|---|---|---|---|
| Server-side | API | `clear_tool_uses_20250919`, `clear_thinking_20251015` | Applied before the prompt reaches Claude. Clears specific content from conversation history. Each strategy can be configured independently. |
| Client-side | SDK | Compaction | Available in Python, TS, Ruby SDKs when using `tool_runner`. Generates a summary and replaces full conversation history. |

**Pairing with memory tool (verbatim):** "When your conversation context approaches the configured clearing threshold, Claude receives an automatic warning to preserve important information. This enables Claude to save tool results or context to its memory files before they're cleared from the conversation history."

### 2.3 Server-side compaction (`compact_20260112`)

**Beta header:** `compact-2026-01-12`. **Supported models:** Claude Mythos Preview, Opus 4.7, Opus 4.6, Sonnet 4.6.

**Mechanism (verbatim):** "Server-side compaction is the recommended strategy for managing context in long-running conversations and agentic workflows. It handles context management automatically with minimal integration work." Flow:
1. API detects input tokens exceed trigger.
2. API generates a summary.
3. A `compaction` block is inserted at start of assistant response.
4. On subsequent requests, API "automatically drops all message blocks prior to the `compaction` block, continuing from the summary."

**Params:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `type` | string | Required | `"compact_20260112"` |
| `trigger` | object | 150,000 tokens | Must be ≥ 50,000 |
| `pause_after_compaction` | bool | `false` | If true, returns with `stop_reason: "compaction"` so client can inject preserved messages before continuing |
| `instructions` | string | `null` | Custom summarization prompt — **completely replaces** default |

**Default summary prompt (verbatim):**
```text
You have written a partial transcript for the initial task above. Please write a summary of the transcript. The purpose of this summary is to provide continuity so you can continue to make progress towards solving the task in a future context, where the raw history above may not be accessible and will be replaced with this summary. Write down anything that would be helpful, including the state, next steps, learnings etc. You must wrap your summary in a <summary></summary> block.
```

**Client-side compaction (SDK alternative) default prompt — 5-section template (verbatim):**
```text
You have been working on the task described above but have not yet completed it. Write a continuation summary that will allow you (or another instance of yourself) to resume work efficiently in a future context window where the conversation history will be replaced with this summary. Your summary should be structured, concise, and actionable. Include:

1. Task Overview
The user's core request and success criteria
Any clarifications or constraints they specified

2. Current State
What has been completed so far
Files created, modified, or analyzed (with paths if relevant)
Key outputs or artifacts produced

3. Important Discoveries
Technical constraints or requirements uncovered
Decisions made and their rationale
Errors encountered and how they were resolved
What approaches were tried that didn't work (and why)

4. Next Steps
Specific actions needed to complete the task
Any blockers or open questions to resolve
Priority order if multiple steps remain

5. Context to Preserve
User preferences or style requirements
Domain-specific details that aren't obvious
Any promises made to the user

Be concise but complete—err on the side of including information that would prevent duplicate work or repeated mistakes. Write in a way that enables immediate resumption of the task.

Wrap your summary in <summary></summary> tags.
```

**Token accounting (critical):** "Top-level `input_tokens` and `output_tokens` do **NOT** include compaction iteration usage. They reflect the sum of all non-compaction iterations. **To calculate total tokens consumed and billed, sum across all entries in the `usage.iterations` array.**"

Sample `usage` shape (verbatim):
```json
{
  "usage": {
    "input_tokens": 23000,
    "output_tokens": 1000,
    "iterations": [
      { "type": "compaction", "input_tokens": 180000, "output_tokens": 3500 },
      { "type": "message",    "input_tokens": 23000,  "output_tokens": 1000 }
    ]
  }
}
```

**Limitations / failure modes (verbatim):**
1. "Same model for summarization: The model specified in your request is used for summarization. No option to use a different (cheaper) model."
2. "Compaction might fail when tools are defined: When your request includes `tools`, the model occasionally calls a tool during internal summarization instead of writing a summary. Response contains `compaction` block with `content: null`." Mitigation: explicit `instructions` like `"Do not call any tools while writing this summary; respond with text only."`

**Streaming behavior:** A `content_block_start` event with `content_block.type == "compaction"`, then a single `content_block_delta` with the complete summary (no intermediate streaming of summary content), then `content_block_stop`.

**Multiple compactions are possible in one conversation:** "The last compaction block reflects the final state, replacing content prior to it."

**Server tools trigger checked per-iteration:** "Compaction may occur multiple times within a single request depending on trigger threshold and output generated."

**Cache-control pattern (verbatim):**
```json
{
  "role": "assistant",
  "content": [
    { "type": "compaction", "content": "[summary text]", "cache_control": { "type": "ephemeral" } },
    { "type": "text", "text": "Based on our conversation..." }
  ]
}
```
"Add a `cache_control` breakpoint at the end of your system prompt. This keeps the system prompt cached separately from conversation, so when compaction occurs: System prompt cache remains valid and is read from cache; Only compaction summary needs to be written as new cache entry."

**Total-budget enforcement pattern (verbatim Python):**
```python
TRIGGER_THRESHOLD = 100_000
TOTAL_TOKEN_BUDGET = 3_000_000
n_compactions = 0
# ...
if response.stop_reason == "compaction":
    n_compactions += 1
    messages.append({"role": "assistant", "content": response.content})
    if n_compactions * TRIGGER_THRESHOLD >= TOTAL_TOKEN_BUDGET:
        messages.append({
            "role": "user",
            "content": "Please wrap up your current work and summarize the final state.",
        })
```

### 2.4 Context engineering theory (the engineering blog)

**Definition (verbatim):** "Context engineering [is] the set of strategies for curating and maintaining the optimal set of tokens (information) during LLM inference, including all the other information that may land there outside of the prompts." Distinct from prompt engineering: "Prompt engineering is the discrete task of writing a prompt, context engineering is iterative and the curation phase happens each time we decide what to pass to the model."

**Context rot (verbatim):** "as the number of tokens in the context window increases, the model's ability to accurately recall information from that context decreases."

**Attention budget metaphor (verbatim):** LLMs have "limited 'attention budget' comparable to human working memory—every new token introduced depletes this budget by some amount."

**Architectural cause (verbatim):**
> "LLMs are based on the transformer architecture, which enables every token to attend to every other token across the entire context. This results in n² pairwise relationships for n tokens."

Plus distribution effects: "Models develop their attention patterns from training data distributions where shorter sequences are typically more common than longer ones." And position-encoding interpolation introduces "some degradation in token position understanding."

**System prompt "right altitude" (two failure modes verbatim):**
1. Over-specific: "Hardcoding complex, brittle logic in their prompts to elicit exact agentic behavior. This approach creates fragility and increases maintenance complexity over time."
2. Under-specific: "Vague, high-level guidance that fails to give the LLM concrete signals for desired outputs or falsely assumes shared context."

Recommended: "Specific enough to guide behavior effectively, yet flexible enough to provide the model with strong heuristics."

Organize with "distinct sections (like `<background_information>`, `<instructions>`, `## Tool guidance`, `## Output description`, etc) and using techniques like XML tagging or Markdown headers."

**Tool design (verbatim):**
> "Tools should be self-contained, robust to error, and extremely clear with respect to their intended use. One of the most common failure modes we see is bloated tool sets that cover too much functionality or lead to ambiguous decision points about which tool to use. If a human engineer can't definitively say which tool should be used in a given situation, an AI agent can't be expected to do better."

**Few-shot anti-pattern (verbatim):**
> "Teams will often stuff a laundry list of edge cases into a prompt in an attempt to articulate every possible rule the LLM should follow for a particular task. We do not recommend this." Instead: "Curate a set of diverse, canonical examples that effectively portray the expected behavior of the agent. For an LLM, examples are the 'pictures' worth a thousand words."

**Just-in-time retrieval (verbatim):**
> "Rather than pre-processing all relevant data up front, agents built with the 'just in time' approach maintain lightweight identifiers (file paths, stored queries, web links, etc.) and use these references to dynamically load data into context at runtime using tools."

Claude Code example: "The model can write targeted queries, store results, and leverage Bash commands like head and tail to analyze large volumes of data without ever loading the full data objects into context."

Signal value of metadata (verbatim): "To an agent operating in a file system, the presence of a file named `test_utils.py` in a `tests` folder implies a different purpose than a file with the same name located in `src/core_logic/` Folder hierarchies, naming conventions, and timestamps all provide important signals."

Trade-off acknowledged: "Runtime exploration is slower than retrieving pre-computed data... Without proper guidance, an agent can waste context by misusing tools, chasing dead-ends, or failing to identify key information."

Claude Code hybrid pattern (verbatim): "Claude Code is an agent that employs this hybrid model: CLAUDE.md files are naively dropped into context up front, while primitives like glob and grep allow it to navigate its environment and retrieve files just-in-time."

**Three long-horizon techniques (verbatim summary):**

1. **Compaction** — "taking a conversation nearing the context window limit, summarizing its contents, and reinitiating a new context window with the summary." Claude Code's implementation: "We implement this by passing the message history to the model to summarize and compress the most critical details. The model preserves architectural decisions, unresolved bugs, and implementation details while discarding redundant tool outputs or messages. The agent can then continue with this compressed context plus the five most recently accessed files."

   Optimization (verbatim): "Start by maximizing recall to ensure your compaction prompt captures every relevant piece of information from the trace, then iterate to improve precision by eliminating superfluous content."

2. **Structured note-taking (agentic memory)** — "the agent regularly writes notes persisted to memory outside of the context window. These notes get pulled back into the context window at later times. This strategy provides persistent memory with minimal overhead. Like Claude Code creating a to-do list, or your custom agent maintaining a NOTES.md file."

   Pokémon case study (verbatim): "Claude playing Pokémon demonstrates how memory transforms agent capabilities in non-coding domains. The agent maintains precise tallies across thousands of game steps—tracking objectives like 'for the last 1,234 steps I've been training my Pokémon in Route 1, Pikachu has gained 8 levels toward the target of 10.' Without any prompting about memory structure, it develops maps of explored regions, remembers which key achievements it has unlocked, and maintains strategic notes of combat strategies."

3. **Sub-agent architectures** — "Rather than one agent attempting to maintain state across an entire project, specialized sub-agents can handle focused tasks with clean context windows. The main agent coordinates with a high-level plan while subagents perform deep technical work." Token economics: "Each subagent might explore extensively, using tens of thousands of tokens or more, but returns only a condensed, distilled summary of its work (often 1,000-2,000 tokens)."

**Overarching principle (verbatim):** "Find the smallest set of high-signal tokens that maximize the likelihood of your desired outcome."

### 2.5 Multi-agent research system — the numbers

| Metric | Value (verbatim) |
|---|---|
| Performance lift | "outperformed single-agent Claude Opus 4 by 90.2% on our internal research eval" (Opus 4 lead + Sonnet 4 subagents) |
| BrowseComp variance | "Three factors explained 95% of the performance variance" |
| Token usage variance | "Token usage by itself explains 80% of the variance" |
| Agent vs chat token use | "agents typically use about 4× more tokens than chat interactions" |
| Multi-agent vs chat | "multi-agent systems use about 15× more tokens than chats" |
| Model upgrade vs token doubling | "upgrading to Claude Sonnet 4 is a larger performance gain than doubling the token budget on Claude Sonnet 3.7" |
| Tool-description improvement | "40% decrease in task completion time for future agents" after tool-testing agent rewrote descriptions |
| Parallel tool calling | "cut research time by up to 90% for complex queries" |

**Effort scaling embedded in prompts (verbatim):**
- Simple fact-finding: "just 1 agent with 3-10 tool calls"
- Direct comparisons: "2-4 subagents with 10-15 calls each"
- Complex research: "more than 10 subagents with clearly divided responsibilities"

**Eight prompt-engineering principles (verbatim names):** Think like your agents; Teach the orchestrator how to delegate; Scale effort to query complexity; Tool design and selection are critical; Let agents improve themselves; Start wide, then narrow down; Guide the thinking process; Parallel tool calling.

**Critical failure modes addressed:**
- Vague subagent tasks → "agents duplicate work, leave gaps, or fail to find necessary information." Example: "agents exploring '2021 automotive chip crisis' while others duplicated '2025 supply chains' investigation."
- Overly long queries → "agents default to overly long, specific queries that return few results." Counter: "short, broad queries, evaluate what's available, then progressively narrow focus."
- SEO bias → "agents consistently chose SEO-optimized content farms over authoritative but less highly-ranked sources like academic PDFs or personal blogs."

**Memory pattern (verbatim):** "Lead agent saves its plan to Memory to persist the context... if the context window exceeds 200,000 tokens it will be truncated and it is important to retain the plan." "After context resets, the agent reads its own notes."

**Subagent output handling (verbatim Appendix):** "Direct subagent outputs can bypass the main coordinator for certain types of results. Agents call tools to store their work in external systems, then pass lightweight references back to the coordinator. This prevents information loss during multi-stage processing and reduces token overhead from copying large outputs through conversation history." Works for "structured outputs like code, reports, or data visualizations."

**When multi-agent is NOT suitable (verbatim):** "Domains that require all agents to share the same context"; "tasks with many dependencies between agents"; "most coding tasks (fewer truly parallelizable tasks than research)."

**Engineering challenges (verbatim):**
- "Agents make dynamic decisions and are non-deterministic between runs, even with identical prompts."
- "Full production tracing let us diagnose why agents failed and fix issues systematically. Monitor agent decision patterns and interaction structures—all without monitoring the contents of individual conversations, to maintain user privacy."
- "Rainbow deployments to avoid disrupting running agents... gradually shifting traffic from old to new versions while keeping both running simultaneously."
- "Letting the agent know when a tool is failing and letting it adapt works surprisingly well."

### 2.6 Writing tools for agents — design principles

**Choosing the right tools (verbatim):** "More tools don't always lead to better outcomes." Consolidation examples:
- `schedule_event` instead of `list_users` + `list_events` + `create_event`
- `search_logs` instead of `read_logs`
- `get_customer_context` instead of `get_customer_by_id` + `list_transactions` + `list_notes`

**Namespacing (verbatim):** "Namespacing (grouping related tools under common prefixes) can help delineate boundaries." Examples: service-level (`asana_search`, `jira_search`); resource-level (`asana_projects_search`, `asana_users_search`). "Selecting between prefix- and suffix-based namespacing [has] non-trivial effects on tool-use evaluations. Effects vary by LLM."

**Field naming (verbatim):** "Merely resolving arbitrary alphanumeric UUIDs to more semantically meaningful and interpretable language... significantly improves Claude's precision in retrieval tasks." Use `name` not `uuid`, `image_url` not `256px_image_url`, `file_type` not `mime_type`.

**ResponseFormat enum pattern (verbatim schema):**
```
enum ResponseFormat {
   DETAILED = "detailed",
   CONCISE = "concise"
}
```
With measured outcome: "Detailed response = 206 tokens; Concise response = 72 tokens (approximately 1/3 token usage)."

**Token efficiency (verbatim):** "Claude Code default: We restrict tool responses to 25,000 tokens by default." Steer to many small searches over one giant search.

**Error response design (verbatim):** "Prompt-engineer your error responses to clearly communicate specific and actionable improvements, rather than opaque error codes or tracebacks."

**Tool description engineering (verbatim):** "Think of how you would describe your tool to a new hire on your team. Consider the context that you might implicitly bring—specialized query formats, definitions of niche terminology, relationships between underlying resources—and make it explicit." Quantitative: "Claude Sonnet 3.5 achieved state-of-the-art performance on the SWE-bench Verified evaluation after we made precise refinements to tool descriptions, dramatically reducing error rates."

**Tool-eval methodology (verbatim):** Tasks should require "multiple tool calls (potentially dozens)." Track top-level accuracy, total runtime, total tool calls, total token consumption, tool errors, and tool calling patterns. Analysis trick: "Concatenate the transcripts from your evaluation agents and paste them into Claude Code. Claude is an expert at analyzing transcripts and refactoring lots of tools all at once."

Key insight (verbatim): "What agents omit in their feedback... can often be more important than what they include."

### 2.7 Effective harnesses for long-running agents

**The problem (verbatim):** "Imagine a software project staffed by engineers working in shifts, where each new engineer arrives with no memory of what happened on the previous shift."

**Two failure modes addressed:**
1. Over-ambition: "agents attempt to one-shot entire applications, leaving half-implemented features"
2. Premature completion: "later agents declare projects finished prematurely"

**Dual-agent pattern:** Initializer (first session only — sets up env) + Coding Agent (subsequent sessions).

**`feature_list.json` row schema (verbatim):**
```json
{
    "category": "functional",
    "description": "New chat button creates a fresh conversation",
    "steps": [
      "Navigate to main interface",
      "Click the 'New Chat' button",
      "Verify a new conversation is created",
      "Check that chat area shows welcome state",
      "Verify conversation appears in sidebar"
    ],
    "passes": false
}
```
Discipline (verbatim): "we prompt coding agents to edit this file only by changing the status of a passes field."

**Coding-agent bootstrap protocol (verbatim):**
> "1. Run pwd to see the directory you're working in. You'll only be able to edit files in this directory.
> 2. Read the git logs and progress files to get up to speed on what was recently worked on.
> 3. Read the features list file and choose the highest-priority feature that's not yet done to work on."

**Verification gap addressed (verbatim):** "Claude's tendency to mark a feature as complete without proper testing. Absent explicit prompting, Claude tended to make code changes, and even do testing with unit tests or curl commands against a development server, but would fail recognize that the feature didn't work end-to-end." Solution: Puppeteer MCP for browser-based end-to-end checks.

**Test-preservation discipline (verbatim, "strongly-worded"):**
> "It is unacceptable to remove or edit tests because this could lead to missing or buggy functionality."

**Scale:** "200 features" in the claude.ai clone example.

**Limitation acknowledged:** "compaction isn't sufficient. Out of the box, even a frontier coding model like Opus 4.5 running on the Claude Agent SDK in a loop across multiple context windows will fall short of building a production-quality web app if it's only given a high-level prompt."

### 2.8 Building effective agents — the canonical patterns

**Definitions (verbatim):**
- Workflows: "systems where LLMs and tools are orchestrated through predefined code paths."
- Agents: "systems where LLMs dynamically direct their own processes and tool usage, maintaining control over how they accomplish tasks."

**Five workflow patterns (verbatim names + when-to-use):**

1. **Prompt chaining** — "ideal for situations where the task can be easily and cleanly decomposed into fixed subtasks." E.g., write outlines → validate → fill in content.

2. **Routing** — "works well for complex tasks where there are distinct categories that are better handled separately." E.g., direct simple questions to Haiku, complex ones to Sonnet.

3. **Parallelization** — two variants: sectioning (split work) and voting (re-run for diversity). "Effective when the divided subtasks can be parallelized for speed, or when multiple perspectives or attempts are needed." E.g., guardrails (one model screens while another responds); code-vulnerability voting.

4. **Orchestrator-workers** — "well-suited for complex tasks where you can't predict the subtasks needed." Distinction from parallelization: subtasks aren't pre-defined.

5. **Evaluator-optimizer** — "particularly effective when we have clear evaluation criteria, and when iterative refinement provides measurable value." Two signs of fit: (a) LLM responses improve with feedback, (b) the LLM can provide such feedback.

**Agent pattern (verbatim):** "for open-ended problems where it's difficult or impossible to predict the required number of steps, and where you can't hardcode a fixed path." Requires: "Clear success criteria; Feedback loops; Meaningful human oversight; Trust in decision-making." Risks: "higher costs, and the potential for compounding errors."

**Tool-design (Appendix 2) verbatim quotes:**
- "Give the model enough tokens to 'think' before it writes itself into a corner"
- "Keep the format close to what the model has seen naturally occurring in text"
- "Poka-yoke your tools" to make mistakes harder
- Real example: "In SWE-bench implementation, we found that the model would make mistakes with tools using relative filepaths after the agent had moved out of the root directory. To fix this, we changed the tool to always require absolute filepaths."

### 2.9 Prompt engineering — multi-context window workflows (verbatim section)

The Claude-4 best-practices guide contains a "Multi-context window workflows" subsection (under "Agentic systems") that is the prompt-engineering analogue of the harnesses post. Verbatim numbered list:

> "For tasks spanning multiple context windows:
> 1. **Use a different prompt for the very first context window:** Use the first context window to set up a framework (write tests, create setup scripts), then use future context windows to iterate on a todo-list.
> 2. **Have the model write tests in a structured format:** Ask Claude to create tests before starting work and keep track of them in a structured format (e.g., `tests.json`). This leads to better long-term ability to iterate. Remind Claude of the importance of tests: 'It is unacceptable to remove or edit tests because this could lead to missing or buggy functionality.'
> 3. **Set up quality of life tools:** Encourage Claude to create setup scripts (e.g., `init.sh`) to gracefully start servers, run test suites, and linters. This prevents repeated work when continuing from a fresh context window.
> 4. **Starting fresh vs compacting:** When a context window is cleared, consider starting with a brand new context window rather than using compaction. Claude's latest models are extremely effective at discovering state from the local filesystem. In some cases, you may want to take advantage of this over compaction. Be prescriptive about how it should start:
>    - 'Call pwd; you can only read and write files in this directory.'
>    - 'Review progress.txt, tests.json, and the git logs.'
>    - 'Manually run through a fundamental integration test before moving on to implementing new features.'
> 5. **Provide verification tools:** As the length of autonomous tasks grows, Claude needs to verify correctness without continuous human feedback. Tools like Playwright MCP server or computer use capabilities for testing UIs are helpful.
> 6. **Encourage complete usage of context:** Prompt Claude to efficiently complete components before moving on."

**Sample prompt (verbatim):**
```text
This is a very long task, so it may be beneficial to plan out your work clearly. It's encouraged to spend your entire output context working on the task - just make sure you don't run out of context with significant uncommitted work. Continue working systematically until you have completed this task.
```

**Context-awareness section (verbatim — extremely relevant to APEX):**
> "Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining."

**Balancing autonomy and safety prompt (verbatim — directly mirrors APEX's destructive-guard):**
```text
Consider the reversibility and potential impact of your actions. You are encouraged to take local, reversible actions like editing files or running tests, but for actions that are hard to reverse, affect shared systems, or could be destructive, ask the user before proceeding.

Examples of actions that warrant confirmation:
- Destructive operations: deleting files or branches, dropping database tables, rm -rf
- Hard to reverse operations: git push --force, git reset --hard, amending published commits
- Operations visible to others: pushing code, commenting on PRs/issues, sending messages, modifying shared infrastructure

When encountering obstacles, do not use destructive actions as a shortcut. For example, don't bypass safety checks (e.g. --no-verify) or discard unfamiliar files that may be in-progress work.
```

**Overengineering control (verbatim — APEX-relevant):**
```text
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused:

- Scope: Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.

- Documentation: Don't add docstrings, comments, or type annotations to code you didn't change. Only add comments where the logic isn't self-evident.

- Defensive coding: Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs).

- Abstractions: Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task.
```

**Hallucination-suppression prompt (verbatim):**
```text
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

**Test-anti-hardcoding prompt (verbatim — directly relevant to APEX critic):**
```text
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them. The solution should be robust, maintainable, and extendable.
```

**Parallel tool-call prompt (verbatim — drop-in for APEX wave-executor):**
```text
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

### 2.10 Tool-runner SDK — auto-loop primitive

Available beta in Python, TypeScript, C#, Go, Java, PHP, Ruby SDKs. Handles "the agentic loop, error wrapping, and type safety automatically." Use manual loop only "When you need human-in-the-loop approval, custom logging, or conditional execution."

Memory + context-management + tool_runner integrated example (verbatim, from `examples/memory/basic.py`):
```python
runner = client.beta.messages.tool_runner(
    betas=["context-management-2025-06-27"],
    model="claude-sonnet-4-20250514",
    max_tokens=2048,
    system=DEFAULT_MEMORY_SYSTEM_PROMPT,
    messages=messages,
    tools=[memory],  # BetaLocalFilesystemMemoryTool
    context_management=DEFAULT_CONTEXT_MANAGEMENT,
)

for message in runner:
    # ... process content blocks ...
    if message.context_management:
        for edit in message.context_management.applied_edits:
            print(f"\n🧹 [Context Management: {edit.type} applied]")
    # ...
    tool_response = runner.generate_tool_call_response()  # auto-execute memory ops
    if tool_response and tool_response["content"]:
        messages.append({"role": "user", "content": tool_response["content"]})
```

### 2.11 Tool evaluation cookbook

Reference framework that parallel-evaluates agent runs over a single eval file. `EVALUATION_PROMPT` (verbatim above in Sources) demands `<summary>`, `<feedback>`, `<response>` XML tags. Tracks per-tool `count` and `durations`. Pass/fail is exact-string-match.

Notable failure mode caught: "Task 1 (Compound Interest): Expected `11614.72` but got `$11,614.72` (formatting mismatch) ❌." Aggregate: 7/8 (87.5%) on a small calculator eval, average 22.73s/task, 7.75 tool calls/task.

---

## 3. Cross-reference / synthesis

How does this body of work cohere?

**A unified "context budget" worldview.** The cookbook is the *teaching example* of three primitives that all sit on the same conceptual frame from the engineering blog:
- Memory tool = note-taking
- clear_tool_uses_20250919 = surgical lossless eviction
- compact_20260112 = lossy resync via server-side summary

The harnesses post then layers a filesystem-based meta-architecture on top: git + progress.txt + feature_list.json + init.sh. The multi-context-window section of the prompt-engineering guide makes that layer prompt-discoverable.

**Memory is positioned as the durable substrate; everything else is volatile.** The compaction default prompt and the SDK compaction prompt agree on a 5-section template (Task / State / Discoveries / Next Steps / Context). Memory file structure should follow it. APEX's STATE.json already encodes most of this but is not formatted as a Claude-readable summary.

**The "Pokémon agent" story is the punchline.** It demonstrates that memory > compaction for non-coding domains: "After context resets, the agent reads its own notes and continues multi-hour training sequences." This is exactly what APEX's session-auto-resume.sh is supposed to do, but APEX uses RESUME-PROMPT.md not a memory tool.

**Verification as the unsolved problem.** Both the multi-agent post ("source-quality heuristics") and the harnesses post ("Puppeteer MCP") concede that current agents cannot reliably self-verify without external mechanisms. APEX's critic/verifier pair attempts this in text-only. This is corroborated by the prompt-engineering guide's investigate-before-answering snippet — the field's consensus is "trust nothing the model claims about code it hasn't physically read."

**Where Anthropic's view extends APEX's:** APEX's "ecosystem 10-question gate" is uniquely APEX. None of Anthropic's docs prescribe a pre-change consultation step at that level of rigor — they prescribe planning + verification, not architectural ecosystem-impact analysis.

**Where Anthropic's view contradicts APEX's:** Anthropic actively discourages "stuff[ing] a laundry list of edge cases into a prompt." APEX agents (architect, critic) tend to be long and prescriptive. Anthropic's stance: "smarter models require less prescriptive engineering."

**Where Anthropic specializes APEX-relevant ground:** The exact knobs APEX needs (clear_at_least to protect cache, exclude_tools to protect important tools, pause_after_compaction to splice in preserved data, clear_tool_inputs to also drop tool params) are all there in the API surface.

---

## 4. APEX implications

### 4.1 Adopt a memory-tool-shaped artifact

**Does APEX do this?** Partially. `apex-learnings.md` and `MEMORY.md` are persistent learning stores, but they are read by *Claude Code's own context loader*, not via a tool the agent can call mid-conversation. The agent cannot incrementally view/create/str_replace these files on its own initiative the way the memory tool affords.

**Adopt?** Yes — at minimum, copy the protocol prompt: "ALWAYS VIEW YOUR MEMORY DIRECTORY BEFORE DOING ANYTHING ELSE."

**Smallest viable change:** Add a memory-view step at the top of `/apex:next` Step A (already implied) and at the top of every agent system prompt. Refactor `apex-learnings.md` to follow the 5-section compaction-style schema (Task Overview / Current State / Important Discoveries / Next Steps / Context to Preserve). Borrow Anthropic's "DO NOT just store the conversation history" warning verbatim.

**Risk:** Doubling up — Claude Code already auto-loads CLAUDE.md and MEMORY.md. Adding a `view`-first protocol on top may overlap. Mitigation: a single dispatcher prompt in `/apex:resume`.

### 4.2 Adopt the 5-section state-handoff template

**Does APEX do this?** STATE.json has phase/task/decisions but does not have the 5-section narrative. RESUME-PROMPT.md does, but informally.

**Adopt?** Yes, with high confidence. This is Anthropic's own canonical handoff format and will be future-compatible if APEX ever switches to server-side compaction.

**Smallest viable change:** Update `STATE.json` schema (or add a `STATE_NARRATIVE.md` sibling) with five fixed sections: Task Overview, Current State, Important Discoveries, Next Steps, Context to Preserve. Update `turn-checkpoint.sh` and `session-auto-resume.sh` to write/read these sections.

**Risk:** Schema drift if existing tooling assumes the old shape. Mitigation: additive, not replacement.

### 4.3 Re-use the destructive-guard prompt verbatim

**Does APEX do this?** Yes — APEX has destructive-guard.sh. But APEX's prompts to the model around destruction are weaker than Anthropic's published verbatim "Examples of actions that warrant confirmation" block.

**Adopt?** Yes. Paste Anthropic's balancing-autonomy-and-safety block into the architect/executor system prompts directly.

**Smallest viable change:** Insert the verbatim block into agent prompts that touch files (executor, wave-executor, remediation-planner). One block per agent.

**Risk:** Negligible — same intent as APEX's own anti-destructive-action stance.

### 4.4 Use parallel-tool-call boilerplate in wave-executor

**Does APEX do this?** APEX uses wave-based parallelization, but each wave is a sequence of single agent runs. Tool-call-level parallelism within one agent run is not enforced.

**Adopt?** Yes — embed the `<use_parallel_tool_calls>` block at the top of wave-executor.md.

**Smallest viable change:** One paragraph added to wave-executor.

**Risk:** Anthropic claims ~100% success; APEX may see edge cases when waves have hidden dependencies. The block already handles this ("if some tool calls depend on previous calls... do NOT call these tools in parallel").

### 4.5 Add an end-to-end verification gate analogous to Puppeteer-MCP

**Does APEX do this?** Critic + Verifier review evidence. But Anthropic explicitly calls out that text-only verification misses end-to-end behavior. Without browser/IDE/runtime introspection, APEX shares this gap.

**Adopt?** Yes, scope-permitting. For non-UI projects, the gate is "run the actual command and show me the output"; for UI projects, this is a Playwright/Puppeteer call.

**Smallest viable change:** Add a new agent `runtime-verifier` invoked after `verifier` for UI-bearing phases (gated by `ui_phase: true` in PLAN_META.json). Tool: Playwright MCP. For non-UI, reuse the executor's bash output and require a `runtime_evidence` field in RESULT.json.

**Risk:** Major capability expansion. Defer to Campaign C if scope warrants.

### 4.6 Adopt `clear_at_least` and `exclude_tools` semantics in context-monitor.sh

**Does APEX do this?** context-monitor.sh exists but its policy is opaque to me from filenames alone. The two specific knobs from `clear_tool_uses_20250919` map directly to APEX needs:
- `clear_at_least` → don't trigger an expensive cleanup unless it saves enough to be worth it
- `exclude_tools` → don't evict outputs from critical APEX agents (critic, verifier, framework-auditor)

**Adopt?** Yes, conceptually. APEX cannot use the Anthropic feature directly (it lives in Claude Code, not raw API), but the *logic* of these knobs should appear in context-monitor.sh and circuit-breaker.sh.

**Smallest viable change:** Add `MINIMUM_TOKENS_TO_CLEAR` and `PROTECTED_AGENT_OUTPUTS` config keys to CONTEXT_BUDGET.json. Make circuit-breaker.sh honor them.

**Risk:** Need to verify Claude Code's compaction is overridable from a hook.

### 4.7 Adopt tool-design discipline for APEX's internal "tools" (agents, hooks)

**Does APEX do this?** Partially. APEX has clear agent names (architect/executor/critic) but ~30 agents and ~50 commands is exactly the proliferation Anthropic warns against ("More tools don't always lead to better outcomes" / "bloated tool sets that cover too much functionality").

**Adopt?** Yes — audit the agent + command surface against Anthropic's principles. Especially: namespacing (APEX uses `apex:` prefix — good), description quality (worth a re-read), and consolidation (e.g., is `/apex:next` doing too much? Is there overlap between `/apex:plan-phase` and `/apex:ui-phase`?).

**Smallest viable change:** A `framework-auditor` round dedicated to tool/command consolidation, using Anthropic's eval framework (concatenate transcripts → analyze patterns → propose merges).

**Risk:** Disruptive. Phase appropriately.

### 4.8 Update STATE.json schema with `applied_edits`-shaped logs

**Does APEX do this?** STATE.json tracks decisions, but does not track context-management events (when memory was checkpointed, when context was compacted, what was preserved/dropped).

**Adopt?** Yes. Borrow `applied_edits` shape verbatim. Useful for forensics and walkthrough.

**Smallest viable change:** Add a `context_events: []` array to STATE.json. Each entry mirrors `{type, cleared_*, original_input_tokens, after_input_tokens, timestamp}`.

**Risk:** None — purely additive instrumentation.

### 4.9 Replace verbose agent prompts with "right altitude" prompts

**Does APEX do this?** APEX prompts are long. Anthropic's "right altitude" guidance: specific but not over-fitted.

**Adopt?** Yes, gradually. Start with critic and executor — these have the most "anti-rationalization armor."

**Smallest viable change:** Run `/apex:health-check` Poison Pill validation against shortened prompts. Keep whichever version measurably wins.

**Risk:** Regression in critic discipline if shortened poorly. Mitigated by Poison Pill protocol.

### 4.10 Use the canonical workflow vocabulary

**Does APEX do this?** Inconsistently. APEX uses terms like "wave," "phase," "round," "campaign." Anthropic uses "prompt chaining," "routing," "parallelization," "orchestrator-workers," "evaluator-optimizer."

**Adopt?** Map APEX terms onto Anthropic's canonical names internally. Wave = parallelization; Round (self-heal) = evaluator-optimizer; Architect→Executor→Critic = orchestrator-workers + evaluator-optimizer.

**Smallest viable change:** Glossary in apex-spec.md cross-referencing terms. Helps onboard external users and future-proofs the framework.

**Risk:** None.

### 4.11 Adopt `pause_after_compaction` style splicing in session-auto-resume

**Does APEX do this?** No. session-auto-resume.sh loads RESUME-PROMPT.md but doesn't have a "pause-and-splice" semantic.

**Adopt?** Conceptually: when session resumes, allow the user (or a hook) to inject "preserved messages" (recent decisions, recent commits, urgent flags) before the model resumes. This is `pause_after_compaction` behavior.

**Smallest viable change:** Augment RESUME-PROMPT.md generation with a "preserved-messages" section pulled from the last 3 commits and last 5 STATE.json entries.

**Risk:** Possible info-overload. Tune by trial.

### 4.12 Track per-task token budgets the way Anthropic tracks per-subagent

**Does APEX do this?** CONTEXT_BUDGET.json tracks overall context. It does not differentiate by agent.

**Adopt?** Track tokens-per-agent-invocation. Compare to Anthropic's effort-scaling rules: simple = 3-10 tool calls, comparison = 10-15, complex = 10+ subagents. Use these as default budgets for the executor, critic, and orchestrator respectively.

**Smallest viable change:** Add per-agent token budgets to PLAN_META.json. Surface in `/apex:status`.

**Risk:** Over-engineering. Skip if not actionable.

---

## 5. Open questions

1. **Will Claude Code expose the underlying server-side compaction primitive to hook authors?** As of May 2026, the harnesses post says Claude Code's compaction is internal and not configurable from APEX's hook layer. If it later exposes `pause_after_compaction`-style hooks, APEX should be ready.

2. **What is the right memory-store backend for APEX?** Filesystem is the obvious default, but Anthropic notes encrypted-storage and database backends are valid via `BetaAbstractMemoryTool` subclassing. APEX's workflows already produce filesystem state; co-locating memory with `.apex/` is straightforward but raises sync questions with git.

3. **How should APEX handle memory-poisoning at the framework level?** Anthropic only mentions client-side mitigation. APEX has a multi-agent flow where a poisoned memory could cascade. A framework-level rule like "agents must declare which memory files they read in RESULT.json" would help auditing.

4. **Is there a quantitative APEX-on-APEX eval?** Anthropic measured 90.2% lift on internal research eval, 40% tool-description improvement, 90% parallel-tool speedup. APEX has no comparable numbers. Health-check runs validate prompts but don't measure outcomes against a baseline.

5. **Should APEX adopt the auto-injected memory protocol prompt verbatim?** It's punchy and battle-tested by Anthropic. Adopting it may improve resume-from-interrupt behavior, but it also makes APEX's behavior more sensitive to memory-tool semantics that may evolve.

6. **What's the right interaction between APEX's ecosystem-10q gate and Anthropic's just-in-time pattern?** The 10q gate is upfront; JIT retrieval is lazy. Can the 10q gate be implemented as lazy retrieval — only consult ecosystem when a tool call hits a sensitive area?

7. **Does Claude Code respect `exclude_tools` for its own context management?** Unclear from public docs. If yes, APEX could mark critic/verifier/auditor outputs as protected. If no, APEX needs its own equivalent.

8. **For multi-context workflows, is the Anthropic-recommended "start fresh > compact" advice (verbatim §2.9 item 4) compatible with APEX's resume-prompt model?** Anthropic says fresh + filesystem-discovery often beats compaction. APEX assumes compaction-style resume. The right answer may be hybrid.

9. **How does Anthropic's "tool description" rewrite (40% time reduction) generalize to agents?** APEX has ~30 agent prompts that play the role of tool descriptions. Running a tool-testing-agent style sweep over them might yield similar gains.

10. **Should the architect/executor/critic boundary be re-drawn as orchestrator/worker/evaluator-optimizer?** This is a cosmetic change but might unlock community contributions if APEX uses canonical names.

---

## 6. Raw citation appendix

### URLs fetched

| Hop | URL | What was found |
|---|---|---|
| 0 | https://platform.claude.com/cookbook/tool-use-memory-cookbook | Primary cookbook — memory tool + context editing tutorial, Code Review Assistant demo, 3-session pattern. |
| 1 | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | Theoretical foundation — context engineering, context rot, attention budget, three long-horizon techniques. |
| 1 | https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool | Memory tool reference. Schema, examples, security, multi-session software dev pattern. |
| 1 | https://platform.claude.com/docs/en/build-with-claude/context-editing | Context editing reference. Full schema for both strategies, cache interaction, token counting. |
| 1 | https://platform.claude.com/docs/en/build-with-claude/compaction | Server-side compaction reference. Beta `compact-2026-01-12`, params, default prompt, limitations. |
| 1 | https://github.com/anthropics/claude-cookbooks/tree/main/tool_use | Directory listing — 17 files + 4 subdirs. |
| 1 | https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/memory_cookbook.ipynb | Notebook metadata — 66.5 KB, 1620 lines. |
| 2 | https://www.anthropic.com/engineering/multi-agent-research-system | Multi-agent system, 90.2% lift, 15× token multiplier, BrowseComp variance analysis. |
| 2 | https://www.anthropic.com/engineering/writing-tools-for-agents | Tool design principles, ResponseFormat enum, SWE-bench Verified case, 25k token cap. |
| 2 | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents | init.sh, claude-progress.txt, feature_list.json with passes:bool, dual-agent pattern. |
| 2 | https://www.anthropic.com/engineering/building-effective-agents | Canonical five workflow patterns + agent definition. |
| 2 | https://platform.claude.com/cookbook/patterns-agents-basic-workflows | Code implementations of chain/parallel/route. |
| 2 | https://platform.claude.com/cookbook/tool-evaluation-tool-evaluation | EVALUATION_PROMPT, per-tool metrics, parallel eval pattern. |
| 3 | https://github.com/anthropics/anthropic-sdk-python/blob/main/examples/memory/basic.py | SDK reference — `BetaLocalFilesystemMemoryTool`, `tool_runner`, `DEFAULT_MEMORY_SYSTEM_PROMPT`. |
| 3 | https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-runner | tool_runner auto-loop SDK abstraction (7 SDKs supported). |
| 3 | https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices | Multi-context workflows section, effort levels, parallel-tool prompt, balancing autonomy, overengineering controls. |
| failed | https://github.com/anthropics/anthropic-sdk-python/blob/main/src/anthropic/lib/tools/_beta_memory_tool.py | 404 — file path may have moved. |

### Key verbatim quotes (cross-indexed to §)

- §1 #2 / §2.1: "IMPORTANT: ALWAYS VIEW YOUR MEMORY DIRECTORY BEFORE DOING ANYTHING ELSE. MEMORY PROTOCOL: ... ASSUME INTERRUPTION: Your context window might be reset at any moment, so you risk losing any progress that is not recorded in your memory directory."
- §1 #3 / §2.4: "Context engineering [is] the set of strategies for curating and maintaining the optimal set of tokens (information) during LLM inference."
- §1 #4 / §2.4: "Agents built with the 'just in time' approach maintain lightweight identifiers (file paths, stored queries, web links, etc.) and use these references to dynamically load data into context at runtime."
- §1 #5 / §2.2: clear_tool_uses_20250919 supports `trigger`, `keep`, `clear_at_least`, `exclude_tools`, `clear_tool_inputs`.
- §1 #6 / §2.5: "outperformed single-agent Claude Opus 4 by 90.2% on our internal research eval"; "multi-agent systems use about 15× more tokens than chats."
- §1 #7 / §2.7: feature_list.json schema verbatim; "It is unacceptable to remove or edit tests..."
- §1 #8 / §2.2: "When using multiple strategies, the `clear_thinking_20251015` strategy must be listed first in the `edits` array."
- §1 #10 / §2.7: "Claude's tendency to mark a feature as complete without proper testing... would fail to recognize that the feature didn't work end-to-end."
- §1 #11 / §2.6: ResponseFormat enum, "Detailed response = 206 tokens; Concise response = 72 tokens (approximately 1/3 token usage)."
- §1 #12 / §2.3: cache_control + compaction pattern.
- §1 #13 / §2.10: tool_runner SDK pattern.
- §1 #14 / §2.9: `<use_parallel_tool_calls>` verbatim block.
- §1 #15 / §2.3: Compaction default 5-section template verbatim.
- §2.4: "n² pairwise relationships for n tokens"; "context rot"; "attention budget"; "every new token introduced depletes this budget by some amount."
- §2.4 Pokémon: "for the last 1,234 steps I've been training my Pokémon in Route 1, Pikachu has gained 8 levels toward the target of 10."
- §2.5: "Three factors explained 95% of the performance variance"; "Token usage by itself explains 80% of the variance"; "agents typically use about 4× more tokens than chat interactions"; "40% decrease in task completion time" (tool description rewrite); "cut research time by up to 90% for complex queries" (parallel tool calling).
- §2.6: "Claude Code default: We restrict tool responses to 25,000 tokens by default"; "Merely resolving arbitrary alphanumeric UUIDs to more semantically meaningful and interpretable language... significantly improves Claude's precision in retrieval tasks."
- §2.7: "Imagine a software project staffed by engineers working in shifts, where each new engineer arrives with no memory of what happened on the previous shift"; "200 features" in claude.ai clone; "compaction isn't sufficient."
- §2.8: "Workflows: systems where LLMs and tools are orchestrated through predefined code paths. Agents: systems where LLMs dynamically direct their own processes and tool usage."
- §2.9: multi-context numbered list verbatim, parallel-tool-call block verbatim, destructive-action block verbatim, overengineering block verbatim, investigate-before-answering block verbatim, test-anti-hardcoding block verbatim.

### Models referenced across all sources

`claude-opus-4-7` (current generally-available top model, "particular strengths in long-horizon agentic work, knowledge work, vision, and memory tasks"), `claude-opus-4-6`, `claude-opus-4-5`, `claude-opus-4-1`, `claude-opus-4`, `claude-sonnet-4-6`, `claude-sonnet-4-5-20250929`, `claude-sonnet-4-20250514`, `claude-sonnet-4`, `claude-sonnet-3-7`, `claude-haiku-4-5`, `claude-mythos-preview`.

### Beta headers referenced

- `context-management-2025-06-27` (context editing + memory tool integration)
- `compact-2026-01-12` (server-side compaction)
- `memory_20250818` (memory tool type — used in `tools` array, not a beta header)
- `clear_tool_uses_20250919`, `clear_thinking_20251015`, `compact_20260112` (edit-strategy types within `context_management.edits[]`)

### Failed/incomplete leads (transparency)

- The SDK source for `BetaLocalFilesystemMemoryTool` was not retrievable at the path I tried; the public interface lives at `from anthropic.tools import BetaLocalFilesystemMemoryTool`. The wire-level behavior (the six commands, their error strings, line-number format) is fully documented in §2.1 from the docs page.
- Compaction iteration usage details across server-tool boundaries are documented (each iteration counted separately) but the public-facing client may show stale `cache_read_input_tokens` numbers; this is called out by Anthropic.
- Cookbook subdirectories (`memory_demo/`, `context_engineering/`, `tests/`, `utils/`) likely contain additional fixture code; those were not fetched in depth — relevant only to a *re-implementer*, not to APEX-pattern adoption.
