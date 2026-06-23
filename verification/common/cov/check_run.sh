#!/usr/bin/env bash

##==============================================================================
## [Filename]       check_run.sh
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       Bash scripting
## [Created]        -
## [Modified]       -
## [Description]    Using the run manifest of a test it access the log file
##                  and performs checks to detect if the UVM summary has 
##                  UVM_ERRORS or UVM_FATALS then it looks for FAIL_PATTERNS 
##                  using a fail_patterns.txt file.
## [Notes]          -
## [Status]         stable
## [Revisions]      -
##==============================================================================

# Exit on errors, undefined variables, and pipeline failures
set -euo pipefail

# --------------------------------- FUNCTIONS ----------------------------------

info() {
    printf '[INFO] %s\n' "$1"
}

pass() {
    printf '[PASS] %s\n' "$1"
    exit 0
}

fail() {
    printf '[FAIL] %s\n' "$1"
    exit 1
}

check_required_file() {
    local name="$1"
    local value="${2:-}"

    [[ -n "$value" ]] || fail "$name is empty"
    [[ -f "$value" ]] || fail "$name does not exist: $value"
}

check_non_empty() {
    local name="$1"
    local value="${2:-}"

    [[ -n "$value" ]] || fail "$name is empty"
}

get_uvm_count() {
    local key="${1:?missing key}"
    local log="${2:?missing log}"

    tail -n 50 "$log" |
        grep -E "^[[:space:]]*${key}[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]*$" |
        tail -n 1 |
        grep -oE '[0-9]+'
}

check_uvm_summary() {
    local log="${1:?missing log}"
    local uvm_errors uvm_fatals uvm_warnings

    uvm_errors="$(get_uvm_count UVM_ERROR "$log" || true)"
    uvm_fatals="$(get_uvm_count UVM_FATAL "$log" || true)"
    uvm_warnings="$(get_uvm_count UVM_WARNING "$log" || true)"

    uvm_errors="${uvm_errors:-0}"
    uvm_fatals="${uvm_fatals:-0}"
    uvm_warnings="${uvm_warnings:-0}"

    info "UVM_WARNING: $uvm_warnings, UVM_ERROR: $uvm_errors, UVM_FATAL: $uvm_fatals"

    [[ "$uvm_errors" -eq 0 && "$uvm_fatals" -eq 0 ]]
}

# -------------------------------- CLI PARSING ---------------------------------

RUN_MANIFEST_FILE="${1:?missing RUN_MANIFEST_FILE}"
check_required_file "RUN_MANIFEST_FILE" "$RUN_MANIFEST_FILE"

FAIL_PATTERNS_FILE="${2:?missing FAIL_PATTERNS_FILE}"
check_required_file "FAIL_PATTERNS_FILE" "$FAIL_PATTERNS_FILE"

# ------------------------------------ LOAD ------------------------------------

# Load manifest
source "$RUN_MANIFEST_FILE"

# Check RUN_LOG
check_required_file "RUN_LOG" "${RUN_LOG:-}"

# Check SIM_STATUS
check_non_empty "SIM_STATUS" "${SIM_STATUS:-}"

# Gate 1: simulator exit code
if [[ "$SIM_STATUS" != "0" ]]; then
    fail "TEST_ID=${TEST_ID:-unknown} SIM_STATUS=$SIM_STATUS"
fi

# Gate 2: UVM summary counts
if ! check_uvm_summary "$RUN_LOG"; then
    fail "UVM summary reports failures"
fi

# Gate 3: crash/timeout patterns (sim may have died before printing summary)
match="$(grep -nE -f "$FAIL_PATTERNS_FILE" "$RUN_LOG" | head -1 || true)"

if [[ -n "$match" ]]; then
    info "Matched fail pattern: ${RUN_LOG}:${match}"
    fail "TEST_ID=${TEST_ID:-unknown}"
fi

pass "TEST_ID=${TEST_ID:-unknown} passed"
