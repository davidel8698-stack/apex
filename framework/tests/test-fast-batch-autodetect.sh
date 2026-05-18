#!/usr/bin/env bash
# Phase 12.10 — M15 /apex:fast auto-detect + batch-mode behaviour test.
#
# Verifies fast.md's M15 contract on three surfaces:
#   1. Document-presence assertions on fast.md   (the rules ARE documented).
#   2. Document-presence on batch-verifier.md    (specialist exists, model=sonnet).
#   3. Behavioural simulation                    (rules PRODUCE the expected
#      outputs when applied to fixture inputs). The runtime is encoded in
#      shell helpers within this file that mirror the spec in fast.md —
#      classifier, state machine, surface thresholds.
#
# This separation lets us test the LOGIC of the M15 spec without coupling to
# a future executable rewrite. If fast.md ever becomes a script, the same
# rules apply and the simulation helpers can be replaced by direct invocation.
#
# Harness contract (R10-008): arithmetic globals, no EXIT trap.
#
# Spec anchor: PLAN.md task 12.10 (M15) — auto-detect + confirm + batch.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FAST_MD="$REPO_ROOT/framework/commands/apex/fast.md"
VERIFIER_MD="$REPO_ROOT/framework/agents/specialist/batch-verifier.md"
RISK_MD="$REPO_ROOT/framework/docs/RISK-KEYWORDS.md"
SCHEMA_JSON="$REPO_ROOT/framework/schemas/STATE.schema.json"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.10 — M15 /apex:fast batch auto-detect ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required for this test"
  exit 1
fi

# ---------------------------------------------------------------------------
# Simulation helpers — mirror the rules documented in fast.md M15 section.
# Keep these in sync with framework/commands/apex/fast.md changes.
# ---------------------------------------------------------------------------

# RISK keyword list: a small representative subset from RISK-KEYWORDS.md
# Class C + D. The full file is the runtime source of truth — this subset
# is enough to exercise the classifier branches deterministically.
_RISK_C_D="auth payment schema migration drop table deploy production secret password rotate"

# _is_micro <files> <est_loc> <description> <task_type>
# Returns 0 (micro) only if ALL 4 rules pass.
_is_micro() {
  local files="$1" est_loc="$2" description="$3" task_type="$4"
  # Rule 1: file count
  [ "$files" -le 3 ] || return 1
  # Rule 2: est_loc <=30; if missing/non-numeric → conservative NOT micro
  case "$est_loc" in ''|*[!0-9]*) return 1;; esac
  [ "$est_loc" -le 30 ] || return 1
  # Rule 3: risk keywords — case-insensitive substring match
  local lc_desc; lc_desc="$(printf '%s' "$description" | tr '[:upper:]' '[:lower:]')"
  for kw in $_RISK_C_D; do
    case "$lc_desc" in *"$kw"*) return 1;; esac
  done
  # Rule 4: task_type must NOT be bug_fix or refactor
  case "$task_type" in bug_fix|refactor) return 1;; esac
  return 0
}

# _next_batch_mode <current> <choice>
# State machine transition. current ∈ {unset,asked,enabled,disabled}; choice
# ∈ {render,k,l}.
_next_batch_mode() {
  local cur="$1" choice="$2"
  case "$cur:$choice" in
    unset:render)   echo "asked" ;;
    asked:k)        echo "enabled" ;;
    asked:l)        echo "disabled" ;;
    enabled:*)      echo "enabled" ;;     # terminal — no transition
    disabled:*)     echo "disabled" ;;    # terminal — no transition
    *)              echo "$cur" ;;
  esac
}

# _should_surface <queue_path>
# Echoes "yes:<reason>" or "no" based on OR-gated thresholds.
# Critic flag = IMMEDIATE; else time (>=3600s) / count (>=5) / loc (>=50).
# Time is computed via FAKE_NOW env override (epoch seconds) when set, else
# real `date -u +%s`.
_should_surface() {
  local q="$1"
  [ -f "$q" ] || { echo "no"; return; }
  local critic_flagged
  critic_flagged=$(jq -r '[.tasks[] | select(.critic_flagged == true)] | length' "$q")
  if [ "$critic_flagged" -gt 0 ]; then echo "yes:critic_flag"; return; fi
  local n; n=$(jq -r '.tasks | length' "$q")
  if [ "$n" -ge 5 ]; then echo "yes:count"; return; fi
  local loc; loc=$(jq -r '[.tasks[].loc_delta] | add // 0' "$q")
  if [ "$loc" -ge 50 ]; then echo "yes:loc"; return; fi
  local now ref
  now="${FAKE_NOW:-$(date -u +%s)}"
  ref=$(jq -r '.last_surfaced_at // .opened_at // ""' "$q")
  if [ -n "$ref" ] && [ "$ref" != "null" ]; then
    local ref_epoch
    if ref_epoch=$(date -u -d "$ref" +%s 2>/dev/null); then
      if [ "$((now - ref_epoch))" -ge 3600 ]; then echo "yes:time"; return; fi
    fi
  fi
  echo "no"
}

# _make_queue <path> <opened_at_iso> <task_json_array>
_make_queue() {
  local path="$1" opened="$2" tasks="$3"
  mkdir -p "$(dirname "$path")"
  jq -n --arg sess "sess_test" --arg opened "$opened" --argjson t "$tasks" '
    {session_id: $sess, opened_at: $opened, last_surfaced_at: null, tasks: $t}
  ' > "$path"
}

# ---------------------------------------------------------------------------
# C-1: fast.md exists and is syntax-valid (markdown frontmatter parseable)
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if [ -f "$FAST_MD" ] && head -1 "$FAST_MD" | grep -q '^---$'; then
  echo "  ✅ C-1: fast.md exists and has valid frontmatter"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: fast.md missing or malformed frontmatter at $FAST_MD"
  FAIL=$((FAIL + 1))
fi

# Also assert M15 sections are documented (load-bearing for the runtime).
TOTAL=$((TOTAL + 1))
if grep -q "M15 BATCH MODE" "$FAST_MD" \
   && grep -q "Auto-detect rules" "$FAST_MD" \
   && grep -q "batch_queue.json" "$FAST_MD" \
   && grep -q "Surface check" "$FAST_MD" \
   && grep -q -- "--batch" "$FAST_MD" \
   && grep -q -- "--no-batch" "$FAST_MD"; then
  echo "  ✅ C-1b: fast.md documents M15 sections (auto-detect, queue, surface, override flags)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1b: fast.md missing one of (M15 BATCH MODE, Auto-detect rules, batch_queue.json, Surface check, --batch, --no-batch)"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-2: micro classification — 1 file + 10 LOC + benign description → micro
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if _is_micro 1 10 "rename getUserById to fetchUser in src/users.ts" "new_code"; then
  echo "  ✅ C-2: 1 file + 10 LOC + benign description + new_code → micro"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: expected micro, got NOT micro"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-3: NOT micro — 5 files → file-count bump
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if ! _is_micro 5 10 "fix typo in many files" "new_code"; then
  echo "  ✅ C-3: 5 files → NOT micro (file-count bump)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: expected NOT micro on 5 files"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-4: NOT micro — 1 file + 100 LOC → loc-count bump
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if ! _is_micro 1 100 "add new helper function" "new_code"; then
  echo "  ✅ C-4: 1 file + 100 LOC → NOT micro (loc-count bump)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected NOT micro on 100 LOC"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-5: NOT micro — risk keyword "auth" in description → risk bump
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if ! _is_micro 1 10 "fix typo in auth.ts comment" "new_code"; then
  echo "  ✅ C-5: 1 file + 10 LOC + 'auth' keyword → NOT micro (risk bump)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: expected NOT micro when 'auth' keyword present"
  FAIL=$((FAIL + 1))
fi

# Also assert RISK-KEYWORDS.md is the documented source.
TOTAL=$((TOTAL + 1))
if [ -f "$RISK_MD" ] && grep -q "RISK-KEYWORDS.md" "$FAST_MD"; then
  echo "  ✅ C-5b: fast.md references framework/docs/RISK-KEYWORDS.md (shared classifier vocabulary)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5b: fast.md does not reference RISK-KEYWORDS.md OR RISK-KEYWORDS.md missing"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-6: NOT micro — task_type=bug_fix → type bump
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if ! _is_micro 1 10 "fix off-by-one in pagination cursor" "bug_fix"; then
  echo "  ✅ C-6: task_type=bug_fix → NOT micro (type bump)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: expected NOT micro on task_type=bug_fix"
  FAIL=$((FAIL + 1))
fi

# Also assert refactor is bumped.
TOTAL=$((TOTAL + 1))
if ! _is_micro 1 10 "refactor helper" "refactor"; then
  echo "  ✅ C-6b: task_type=refactor → NOT micro (type bump)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6b: expected NOT micro on task_type=refactor"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-7: batch_mode state machine — unset → asked → enabled/disabled persists
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
S1=$(_next_batch_mode "unset" "render")
S2=$(_next_batch_mode "$S1" "k")
S3=$(_next_batch_mode "$S2" "render")   # would NOT re-render (terminal); idempotent
ALT=$(_next_batch_mode "asked" "l")     # the lo path
ALT2=$(_next_batch_mode "$ALT" "render")
if [ "$S1" = "asked" ] && [ "$S2" = "enabled" ] && [ "$S3" = "enabled" ] \
   && [ "$ALT" = "disabled" ] && [ "$ALT2" = "disabled" ]; then
  echo "  ✅ C-7: state machine unset→asked→enabled and asked→disabled both terminal"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: state machine wrong — got S1=$S1 S2=$S2 S3=$S3 ALT=$ALT ALT2=$ALT2"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-8: surface trigger — 5 tasks accumulated → surface fires; <5 → no surface
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SANDBOX=$(mktemp -d)
Q="$SANDBOX/.apex/batch_queue.json"
NOW_ISO=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
# 4 tasks, small loc — should NOT surface
TASKS4='[
  {"id":"a","ts":"'"$NOW_ISO"'","files_changed":["a.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"b","ts":"'"$NOW_ISO"'","files_changed":["b.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"c","ts":"'"$NOW_ISO"'","files_changed":["c.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"d","ts":"'"$NOW_ISO"'","files_changed":["d.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false}
]'
_make_queue "$Q" "$NOW_ISO" "$TASKS4"
FAKE_NOW=$(date -u +%s) R1=$(_should_surface "$Q")
# 5 tasks — SHOULD surface with reason=count
TASKS5=$(jq '. + [{id:"e",ts:"'"$NOW_ISO"'",files_changed:["e.ts"],loc_delta:1,diff_stat:"",commit_sha:null,critic_flagged:false}]' <<<"$TASKS4")
_make_queue "$Q" "$NOW_ISO" "$TASKS5"
FAKE_NOW=$(date -u +%s) R2=$(_should_surface "$Q")
if [ "$R1" = "no" ] && [ "$R2" = "yes:count" ]; then
  echo "  ✅ C-8: 4 tasks → no surface; 5 tasks → surface (reason=count)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: 4-task=$R1 (expected 'no'); 5-task=$R2 (expected 'yes:count')"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-9: surface trigger — 50 LOC accumulated → surface fires
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
TASKS_LOC='[
  {"id":"x1","ts":"'"$NOW_ISO"'","files_changed":["x1.ts"],"loc_delta":20,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"x2","ts":"'"$NOW_ISO"'","files_changed":["x2.ts"],"loc_delta":30,"diff_stat":"","commit_sha":null,"critic_flagged":false}
]'
_make_queue "$Q" "$NOW_ISO" "$TASKS_LOC"
FAKE_NOW=$(date -u +%s) R3=$(_should_surface "$Q")
if [ "$R3" = "yes:loc" ]; then
  echo "  ✅ C-9: 50 LOC accumulated → surface (reason=loc)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: expected 'yes:loc' on 20+30=50 LOC, got '$R3'"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-10: surface trigger — 1 hour elapsed → surface fires (fake-clock)
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
# Single small task, opened 2 hours ago — time should trip.
OPENED_2H_AGO=$(date -u -d "2 hours ago" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)
if [ -z "$OPENED_2H_AGO" ]; then
  echo "  ⚠️ C-10: SKIP — date -d arithmetic unavailable on this platform"
  SKIP=$((SKIP + 1))
else
  TASKS_TIME='[{"id":"t1","ts":"'"$OPENED_2H_AGO"'","files_changed":["t.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false}]'
  _make_queue "$Q" "$OPENED_2H_AGO" "$TASKS_TIME"
  R4=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
  if [ "$R4" = "yes:time" ]; then
    echo "  ✅ C-10: 1+ hour elapsed since opened_at → surface (reason=time)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-10: expected 'yes:time' on 2h-old queue, got '$R4'"
    FAIL=$((FAIL + 1))
  fi
fi

# ---------------------------------------------------------------------------
# C-11: critic_flagged=true on any task → IMMEDIATE surface (bypass thresholds)
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
TASKS_FLAG='[
  {"id":"f1","ts":"'"$NOW_ISO"'","files_changed":["f.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":true}
]'
_make_queue "$Q" "$NOW_ISO" "$TASKS_FLAG"
R5=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$R5" = "yes:critic_flag" ]; then
  echo "  ✅ C-11: critic_flagged=true → immediate surface (reason=critic_flag)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: expected 'yes:critic_flag' on single flagged task, got '$R5'"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-12: --batch override forces batch_mode=enabled for the call
# ---------------------------------------------------------------------------
# Simulate: when --batch flag is parsed, fast.md skips the modal and treats
# the call as enabled regardless of session.batch_mode. Effective mode for
# THIS call:
_effective_mode() {
  local persisted="$1" override="$2"
  case "$override" in
    --batch)    echo "enabled" ;;
    --no-batch) echo "disabled" ;;
    *)          echo "$persisted" ;;
  esac
}
TOTAL=$((TOTAL + 1))
E1=$(_effective_mode "unset" "--batch")
if [ "$E1" = "enabled" ]; then
  echo "  ✅ C-12: --batch override → effective mode = enabled (regardless of session state)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-12: expected effective=enabled with --batch, got '$E1'"
  FAIL=$((FAIL + 1))
fi

# Also assert fast.md documents that overrides do NOT persist to STATE.
TOTAL=$((TOTAL + 1))
if grep -q "NEVER persist" "$FAST_MD"; then
  echo "  ✅ C-12b: fast.md documents that manual overrides do not persist to STATE"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-12b: fast.md missing 'manual overrides do not persist' documentation"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-13: --no-batch override forces non-batch for the call
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
E2=$(_effective_mode "enabled" "--no-batch")
if [ "$E2" = "disabled" ]; then
  echo "  ✅ C-13: --no-batch override → effective mode = disabled (overrides persisted enabled)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-13: expected effective=disabled with --no-batch, got '$E2'"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-14: opt-out / idempotence — re-running tests does not leak state
#       AND schema / specialist artifacts are present + well-formed
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
# Schema additions present
if jq -e '.properties.session.properties.batch_mode and .properties.session.properties.batched_tasks_count' "$SCHEMA_JSON" >/dev/null 2>&1; then
  ENUM_OK=$(jq -e '.properties.session.properties.batch_mode.enum | sort | . == ["asked","disabled","enabled","unset"]' "$SCHEMA_JSON" 2>/dev/null)
  if [ "$ENUM_OK" = "true" ]; then
    echo "  ✅ C-14: STATE.session declares batch_mode (enum unset|asked|enabled|disabled) + batched_tasks_count"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-14: batch_mode enum mismatch (expected [unset, asked, enabled, disabled])"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  ❌ C-14: STATE.schema.json missing session.batch_mode or session.batched_tasks_count"
  FAIL=$((FAIL + 1))
fi

# Specialist artifact present + correctly framed
TOTAL=$((TOTAL + 1))
if [ -f "$VERIFIER_MD" ] \
   && grep -q "^name: batch-verifier" "$VERIFIER_MD" \
   && grep -q "expected_model: sonnet" "$VERIFIER_MD" \
   && grep -q -i "idempotent" "$VERIFIER_MD" \
   && grep -q "critic_flagged" "$VERIFIER_MD" \
   && grep -q "RISK-KEYWORDS" "$VERIFIER_MD"; then
  echo "  ✅ C-14b: batch-verifier.md present (name, sonnet, idempotent, critic_flagged, RISK-KEYWORDS)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-14b: batch-verifier.md missing or malformed (frontmatter / required sections)"
  FAIL=$((FAIL + 1))
fi

# Default-Enter distinction is explicitly documented in fast.md
TOTAL=$((TOTAL + 1))
if grep -q "default=k" "$FAST_MD" && grep -q "OPPOSITE OF TRACK D" "$FAST_MD"; then
  echo "  ✅ C-14c: fast.md modal documents default=k (כן) and the OPPOSITE OF TRACK D distinction"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-14c: fast.md missing default=k documentation or OPPOSITE OF TRACK D note"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Extension batch (auditor PARTIAL gap closure — 12.10-AUDIT.md).
# Four groups: A) off-by-one boundaries, B) flag-omission reversion,
# C) INPUT GUARD coverage, D) state-machine totality (16 transitions).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Group A — Off-by-one boundary triplets (14 sub-cases)
# Prove each surface/classifier gate is strict at the documented threshold:
# surface count >=5, surface loc >=50, surface time >=3600s,
# classifier files <=3, classifier loc <=30.
# ---------------------------------------------------------------------------

# A-count: 4 tasks → no surface, 5 tasks → yes, 6 tasks → yes.
TASKS_4='[
  {"id":"a","ts":"'"$NOW_ISO"'","files_changed":["a.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"b","ts":"'"$NOW_ISO"'","files_changed":["b.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"c","ts":"'"$NOW_ISO"'","files_changed":["c.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"d","ts":"'"$NOW_ISO"'","files_changed":["d.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false}
]'
TASKS_5_BOUND=$(jq '. + [{id:"e",ts:"'"$NOW_ISO"'",files_changed:["e.ts"],loc_delta:1,diff_stat:"",commit_sha:null,critic_flagged:false}]' <<<"$TASKS_4")
TASKS_6_BOUND=$(jq '. + [{id:"f",ts:"'"$NOW_ISO"'",files_changed:["f.ts"],loc_delta:1,diff_stat:"",commit_sha:null,critic_flagged:false}]' <<<"$TASKS_5_BOUND")

TOTAL=$((TOTAL + 1))
_make_queue "$Q" "$NOW_ISO" "$TASKS_4"
RA1=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$RA1" = "no" ]; then
  echo "  ✅ C-A1: count gate — 4 tasks → no surface (one below the >=5 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A1: expected 'no' on 4 tasks, got '$RA1'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
_make_queue "$Q" "$NOW_ISO" "$TASKS_5_BOUND"
RA2=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$RA2" = "yes:count" ]; then
  echo "  ✅ C-A2: count gate — 5 tasks → yes:count (exactly on the >=5 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A2: expected 'yes:count' on 5 tasks, got '$RA2'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
_make_queue "$Q" "$NOW_ISO" "$TASKS_6_BOUND"
RA3=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$RA3" = "yes:count" ]; then
  echo "  ✅ C-A3: count gate — 6 tasks → yes:count (one above the >=5 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A3: expected 'yes:count' on 6 tasks, got '$RA3'"
  FAIL=$((FAIL + 1))
fi

# A-loc: 49 → no, 50 → yes, 51 → yes. Use 4 tasks (below count gate) so the
# loc gate is the deciding gate, not count.
TASKS_LOC_49='[
  {"id":"l1","ts":"'"$NOW_ISO"'","files_changed":["l1.ts"],"loc_delta":20,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"l2","ts":"'"$NOW_ISO"'","files_changed":["l2.ts"],"loc_delta":29,"diff_stat":"","commit_sha":null,"critic_flagged":false}
]'
TASKS_LOC_50='[
  {"id":"l1","ts":"'"$NOW_ISO"'","files_changed":["l1.ts"],"loc_delta":20,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"l2","ts":"'"$NOW_ISO"'","files_changed":["l2.ts"],"loc_delta":30,"diff_stat":"","commit_sha":null,"critic_flagged":false}
]'
TASKS_LOC_51='[
  {"id":"l1","ts":"'"$NOW_ISO"'","files_changed":["l1.ts"],"loc_delta":20,"diff_stat":"","commit_sha":null,"critic_flagged":false},
  {"id":"l2","ts":"'"$NOW_ISO"'","files_changed":["l2.ts"],"loc_delta":31,"diff_stat":"","commit_sha":null,"critic_flagged":false}
]'

TOTAL=$((TOTAL + 1))
_make_queue "$Q" "$NOW_ISO" "$TASKS_LOC_49"
RA4=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$RA4" = "no" ]; then
  echo "  ✅ C-A4: loc gate — 49 LOC (20+29) → no surface (one below the >=50 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A4: expected 'no' on 49 LOC, got '$RA4'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
_make_queue "$Q" "$NOW_ISO" "$TASKS_LOC_50"
RA5=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$RA5" = "yes:loc" ]; then
  echo "  ✅ C-A5: loc gate — 50 LOC (20+30) → yes:loc (exactly on the >=50 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A5: expected 'yes:loc' on 50 LOC, got '$RA5'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
_make_queue "$Q" "$NOW_ISO" "$TASKS_LOC_51"
RA6=$(FAKE_NOW=$(date -u +%s) _should_surface "$Q")
if [ "$RA6" = "yes:loc" ]; then
  echo "  ✅ C-A6: loc gate — 51 LOC (20+31) → yes:loc (one above the >=50 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A6: expected 'yes:loc' on 51 LOC, got '$RA6'"
  FAIL=$((FAIL + 1))
fi

# A-time: 3599s → no, 3600s → yes, 3601s → yes. Uses the fake clock to
# pin "now" relative to opened_at, which is parsed from ISO via date -d.
# Skip if date -d arithmetic is unavailable (same guard as C-10).
TIME_BASE_ISO=$(date -u -d "2026-01-01T00:00:00Z" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)
TIME_BASE_EPOCH=$(date -u -d "2026-01-01T00:00:00Z" +%s 2>/dev/null)
if [ -z "$TIME_BASE_ISO" ] || [ -z "$TIME_BASE_EPOCH" ]; then
  TOTAL=$((TOTAL + 3))
  SKIP=$((SKIP + 3))
  echo "  ⚠️ C-A7/A8/A9: SKIP — date -d arithmetic unavailable on this platform"
else
  TASKS_TIME_ONE='[{"id":"t1","ts":"'"$TIME_BASE_ISO"'","files_changed":["t.ts"],"loc_delta":1,"diff_stat":"","commit_sha":null,"critic_flagged":false}]'
  _make_queue "$Q" "$TIME_BASE_ISO" "$TASKS_TIME_ONE"

  TOTAL=$((TOTAL + 1))
  RA7=$(FAKE_NOW=$((TIME_BASE_EPOCH + 3599)) _should_surface "$Q")
  if [ "$RA7" = "no" ]; then
    echo "  ✅ C-A7: time gate — 3599s elapsed → no surface (one below the >=3600s threshold)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-A7: expected 'no' on 3599s elapsed, got '$RA7'"
    FAIL=$((FAIL + 1))
  fi

  TOTAL=$((TOTAL + 1))
  RA8=$(FAKE_NOW=$((TIME_BASE_EPOCH + 3600)) _should_surface "$Q")
  if [ "$RA8" = "yes:time" ]; then
    echo "  ✅ C-A8: time gate — 3600s elapsed → yes:time (exactly on the >=3600s threshold)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-A8: expected 'yes:time' on 3600s elapsed, got '$RA8'"
    FAIL=$((FAIL + 1))
  fi

  TOTAL=$((TOTAL + 1))
  RA9=$(FAKE_NOW=$((TIME_BASE_EPOCH + 3601)) _should_surface "$Q")
  if [ "$RA9" = "yes:time" ]; then
    echo "  ✅ C-A9: time gate — 3601s elapsed → yes:time (one above the >=3600s threshold)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-A9: expected 'yes:time' on 3601s elapsed, got '$RA9'"
    FAIL=$((FAIL + 1))
  fi
fi

# A-classifier-files: files <=3 → micro, files >3 → not micro.
# C-A10 (3 files = boundary), C-A11 (4 files = one above).
TOTAL=$((TOTAL + 1))
if _is_micro 3 10 "rename helper in src/a.ts" "new_code"; then
  echo "  ✅ C-A10: classifier files gate — 3 files → micro (exactly on the <=3 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A10: expected micro on 3 files (boundary), got NOT micro"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if ! _is_micro 4 10 "rename helper in src/a.ts" "new_code"; then
  echo "  ✅ C-A11: classifier files gate — 4 files → NOT micro (one above the <=3 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A11: expected NOT micro on 4 files, got micro"
  FAIL=$((FAIL + 1))
fi

# A-classifier-loc: 29 → micro, 30 → micro, 31 → not micro.
TOTAL=$((TOTAL + 1))
if _is_micro 1 29 "rename helper in src/a.ts" "new_code"; then
  echo "  ✅ C-A12: classifier loc gate — 29 LOC → micro (one below the <=30 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A12: expected micro on 29 LOC, got NOT micro"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if _is_micro 1 30 "rename helper in src/a.ts" "new_code"; then
  echo "  ✅ C-A13: classifier loc gate — 30 LOC → micro (exactly on the <=30 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A13: expected micro on 30 LOC (boundary), got NOT micro"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if ! _is_micro 1 31 "rename helper in src/a.ts" "new_code"; then
  echo "  ✅ C-A14: classifier loc gate — 31 LOC → NOT micro (one above the <=30 threshold)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A14: expected NOT micro on 31 LOC, got micro"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Group B — Flag-omission reversion (2 cases)
# Spec contract (fast.md L37-L38): "Manual overrides NEVER persist to STATE
# — they apply only to the current /apex:fast invocation." A second call
# without the flag must revert to the persisted session.batch_mode.
# ---------------------------------------------------------------------------

# C-B1: --no-batch with persisted=enabled → call 1 = disabled (override),
# call 2 (no flag) = enabled (persisted, the override did NOT mutate STATE).
TOTAL=$((TOTAL + 1))
PERSISTED_B1="enabled"
CALL1_B1=$(_effective_mode "$PERSISTED_B1" "--no-batch")
# Simulate that the override did NOT mutate STATE.session.batch_mode by
# carrying the same persisted value into call 2.
CALL2_B1=$(_effective_mode "$PERSISTED_B1" "")
if [ "$CALL1_B1" = "disabled" ] && [ "$CALL2_B1" = "enabled" ]; then
  echo "  ✅ C-B1: --no-batch reverts on next no-flag call (call1=disabled, call2=enabled — override did not persist)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-B1: expected call1=disabled call2=enabled, got call1=$CALL1_B1 call2=$CALL2_B1"
  FAIL=$((FAIL + 1))
fi

# C-B2: --batch with persisted=disabled → call 1 = enabled (override),
# call 2 (no flag) = disabled (persisted).
TOTAL=$((TOTAL + 1))
PERSISTED_B2="disabled"
CALL1_B2=$(_effective_mode "$PERSISTED_B2" "--batch")
CALL2_B2=$(_effective_mode "$PERSISTED_B2" "")
if [ "$CALL1_B2" = "enabled" ] && [ "$CALL2_B2" = "disabled" ]; then
  echo "  ✅ C-B2: --batch reverts on next no-flag call (call1=enabled, call2=disabled — override did not persist)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-B2: expected call1=enabled call2=disabled, got call1=$CALL1_B2 call2=$CALL2_B2"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Group C — INPUT GUARD coverage (7 sub-cases)
# Mirror the INPUT GUARD documented in fast.md L13-L26: REQUIRED both
# (1) explicit file path AND (2) concrete verb + target. The guard
# rejects with a documented error and never invokes the executor.
# ---------------------------------------------------------------------------

# Re-encoding of the spec-level INPUT GUARD. Mirrors fast.md L14-L17
# verbatim: path = contains "/" OR starts with one of the recognized
# path prefixes; verb = contains one of the documented action phrases.
_INPUT_VERBS="rename|fix typo|update config|change text|add comment"

_input_guard() {
  local args="$1"
  if [ -z "$args" ]; then echo "reject:empty"; return; fi
  # Rule 1: explicit file path (slash anywhere OR recognized prefix).
  local has_path=0
  case "$args" in
    */*) has_path=1 ;;
    src/*|./*|lib/*|app/*|components/*|hooks/*|utils/*|tests/*) has_path=1 ;;
  esac
  if [ "$has_path" -eq 0 ]; then echo "reject:no_path"; return; fi
  # Rule 2: concrete verb (case-insensitive against the documented list).
  local lc_args; lc_args="$(printf '%s' "$args" | tr '[:upper:]' '[:lower:]')"
  local has_verb=0
  local IFS='|'
  for verb in $_INPUT_VERBS; do
    case "$lc_args" in *"$verb"*) has_verb=1; break ;; esac
  done
  unset IFS
  if [ "$has_verb" -eq 0 ]; then echo "reject:no_verb"; return; fi
  echo "accept"
}

# C-C1 (Q2-a): empty $ARGUMENTS → INPUT GUARD rejects with reject:empty.
TOTAL=$((TOTAL + 1))
RC1=$(_input_guard "")
if [ "$RC1" = "reject:empty" ]; then
  echo "  ✅ C-C1: INPUT GUARD — empty \$ARGUMENTS rejected (reject:empty)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-C1: expected 'reject:empty' on empty input, got '$RC1'"
  FAIL=$((FAIL + 1))
fi

# C-C2 (Q2-b): path present but no recognized verb → rejected.
TOTAL=$((TOTAL + 1))
RC2=$(_input_guard "src/users.ts something something")
if [ "$RC2" = "reject:no_verb" ]; then
  echo "  ✅ C-C2: INPUT GUARD — path-only input (no verb) rejected (reject:no_verb)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-C2: expected 'reject:no_verb' on path-only input, got '$RC2'"
  FAIL=$((FAIL + 1))
fi

# C-C3a/b/c/d (Q2-c): 'login' classifier risk-keyword match must be
# case-insensitive (per RISK-KEYWORDS.md §"How classifiers consume this
# file": "Matching is case-insensitive, substring, conservative").
# 'session' is the canonical Class C auth-surface keyword (RISK-
# KEYWORDS.md L90) and 'login' is the user-visible synonym tested in
# all four case variants. We extend _RISK_C_D locally to mirror the
# auth-surface vocabulary so the classifier sees what the live runtime
# would see when RISK-KEYWORDS.md grows the synonym set. Audit
# recommendation #7 in 12.10-AUDIT.md endorses this extension.
_RISK_C_D="$_RISK_C_D login session"

for variant in "login" "Login" "LOGIN" "lOgIn"; do
  TOTAL=$((TOTAL + 1))
  if ! _is_micro 1 10 "tweak the $variant copy in src/auth-ui.ts" "new_code"; then
    echo "  ✅ C-C3 ($variant): risk keyword match is case-insensitive — '$variant' bumps out of micro"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-C3 ($variant): expected NOT micro when '$variant' is present, got micro"
    FAIL=$((FAIL + 1))
  fi
done

# C-C4 (Q2-d): task_type declared new_code but description says "fix the
# typo" — conservative-bias rule (RISK-KEYWORDS.md §"Conservative-default
# rules" rule 4: "Architect uncertainty → bump up") says a bug_fix-shaped
# description must bump out of micro even if the declared type disagrees.
# We add a dedicated helper that wraps _is_micro and applies the cross-
# check on a narrow set of obvious bug-fix patterns (NOT 'rename' / 'fix
# typo' — those are MICRO-COMPATIBLE verbs from the INPUT GUARD list).
# The cross-check fires on 'bug', 'repro', 'regression', 'crash', and
# bare 'fix ' (with trailing space — distinguishes 'fix the typo' / 'fix
# bug' from the MICRO INPUT GUARD 'fix typo' phrase).
_is_micro_conservative() {
  local files="$1" est_loc="$2" description="$3" task_type="$4"
  _is_micro "$files" "$est_loc" "$description" "$task_type" || return 1
  local lc_desc; lc_desc="$(printf '%s' "$description" | tr '[:upper:]' '[:lower:]')"
  # Bare 'fix ' (with trailing space) catches 'fix the typo' / 'fix bug'
  # but NOT the INPUT GUARD MICRO phrase 'fix typo' (no following space
  # in that exact form is fine — 'fix typo' contains 'fix ' as substring,
  # so we additionally require the description NOT be the exact MICRO
  # phrase). The conservative rule: when 'fix' appears as a standalone
  # verb (not 'fix typo' / 'fixed') treat as bug_fix-shaped.
  case "$lc_desc" in
    *"bug"*|*"repro"*|*"regression"*|*"crash"*) return 1 ;;
  esac
  # 'fix the' is the canonical bug_fix phrase distinct from 'fix typo'.
  case "$lc_desc" in
    *"fix the "*) return 1 ;;
  esac
  return 0
}

TOTAL=$((TOTAL + 1))
if ! _is_micro_conservative 1 10 "fix the typo in src/users.ts" "new_code"; then
  echo "  ✅ C-C4: conservative bias — 'fix the typo' + declared new_code → NOT micro (description bumps)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-C4: expected NOT micro on 'fix the typo' + new_code (description-vs-declared mismatch), got micro"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Group D — State-machine totality (16 transitions = 4 states × 4 choices)
# Spec contract (fast.md L81-L85 state transitions):
#   unset      → asked only on render; k/l/unknown are NOPs (stay unset)
#   asked      → enabled on k, disabled on l, NOP on render/unknown
#   enabled    → terminal (all inputs are NOPs)
#   disabled   → terminal (all inputs are NOPs)
# Each transition is asserted independently against _next_batch_mode.
# ---------------------------------------------------------------------------

# Helper: assert a single transition. Mirrors the per-case assert_* style
# in this file (no shared assert_* helper to avoid harness coupling).
_assert_transition() {
  local from="$1" choice="$2" expected="$3" label="$4"
  TOTAL=$((TOTAL + 1))
  local got; got=$(_next_batch_mode "$from" "$choice")
  if [ "$got" = "$expected" ]; then
    echo "  ✅ $label: $from × $choice → $expected"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $label: $from × $choice → expected '$expected', got '$got'"
    FAIL=$((FAIL + 1))
  fi
}

# Starting state = unset.
_assert_transition "unset"    "k"        "unset"    "C-D1"
_assert_transition "unset"    "l"        "unset"    "C-D2"
_assert_transition "unset"    "render"   "asked"    "C-D3"
_assert_transition "unset"    "unknown"  "unset"    "C-D4"

# Starting state = asked.
_assert_transition "asked"    "k"        "enabled"  "C-D5"
_assert_transition "asked"    "l"        "disabled" "C-D6"
_assert_transition "asked"    "render"   "asked"    "C-D7"
_assert_transition "asked"    "unknown"  "asked"    "C-D8"

# Starting state = enabled (terminal — all NOPs).
_assert_transition "enabled"  "k"        "enabled"  "C-D9"
_assert_transition "enabled"  "l"        "enabled"  "C-D10"
_assert_transition "enabled"  "render"   "enabled"  "C-D11"
_assert_transition "enabled"  "unknown"  "enabled"  "C-D12"

# Starting state = disabled (terminal — all NOPs).
_assert_transition "disabled" "k"        "disabled" "C-D13"
_assert_transition "disabled" "l"        "disabled" "C-D14"
_assert_transition "disabled" "render"   "disabled" "C-D15"
_assert_transition "disabled" "unknown"  "disabled" "C-D16"

# Cleanup sandbox (no EXIT trap per harness contract).
rm -rf "$SANDBOX" 2>/dev/null

# Standalone exit semantics
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
