#!/usr/bin/env bash

##==============================================================================
## [Filename]       cov_checked_last_run.sh
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       Bash scripting
## [Created]        -
## [Modified]       -
## [Description]    Performs the coverage of the last run
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

find_latest_file() {
    local search_dir="${1:?missing search_dir}"
    local pattern="${2:?missing pattern}"

    if [[ ! -d "$search_dir" ]]; then
        return 0
    fi

    find "$search_dir" -type f -name "$pattern" -printf '%T@ %p\n' |
        sort -n |
        tail -n 1 |
        cut -d' ' -f2-
}

check_required_dir() {
    local name="$1"
    local value="${2:-}"

    [[ -n "$value" ]] || fail "$name is empty"
    [[ -d "$value" ]] || fail "$name does not exist: $value"
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

# -------------------------------- CLI PARSING ---------------------------------

RUN_DIR="${1:?missing RUN_DIR}"
RUN_MANIFEST_GLOB="${2:?missing RUN_MANIFEST_GLOB}"
URG_COMMON_FLAGS="${3:?missing URG_COMMON_FLAGS}"
FAIL_PATTERNS_FILE="${4:?missing FAIL_PATTERNS_FILE}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_RUN_SCRIPT="$SCRIPT_DIR/check_run.sh"
COV_LAST_RUN_SCRIPT="$SCRIPT_DIR/cov_last_run.sh"

check_required_file "CHECK_RUN_SCRIPT" "$CHECK_RUN_SCRIPT"
check_required_file "COV_LAST_RUN_SCRIPT" "$COV_LAST_RUN_SCRIPT"
check_required_file "FAIL_PATTERNS_FILE" "$FAIL_PATTERNS_FILE"

# ----------------------------- LOAD RUN MANIFEST ------------------------------

# Get the last run manifest file
RUN_MANIFEST_FILE="$(find_latest_file "$RUN_DIR" "$RUN_MANIFEST_GLOB")"

# Check if no manifest is found
[[ -n "$RUN_MANIFEST_FILE" ]] || fail "No run manifest found"

info  "Checking latest run status"
"$CHECK_RUN_SCRIPT" "$RUN_MANIFEST_FILE" "$FAIL_PATTERNS_FILE"

info "Latest run passed, merging coverage"
"$COV_LAST_RUN_SCRIPT" "$RUN_DIR" "$RUN_MANIFEST_GLOB" "$URG_COMMON_FLAGS"
