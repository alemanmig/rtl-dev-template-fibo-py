#!/usr/bin/env bash

##==============================================================================
## [Filename]       cov_checked_all_runs.sh
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       Bash scripting
## [Created]        -
## [Modified]       -
## [Description]    Perform the coverage of all runs, all runs must have code 
##                  code coverage enable or disable, if they are mixed the script
##                  will stop.
##                  
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

find_all_files() {
    local search_dir="${1:?missing search_dir}"
    local pattern="${2:?missing pattern}"

    [[ -d "$search_dir" ]] || fail "Directory does not exist: $search_dir"

    find "$search_dir" -type f -name "$pattern" -printf '%T@ %p\n' |
        sort -n |
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

# ------------------------------------ LOAD ------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_RUN_SCRIPT="$SCRIPT_DIR/check_run.sh"
COV_ALL_RUNS_SCRIPT="$SCRIPT_DIR/cov_all_runs.sh"

check_required_file "CHECK_RUN_SCRIPT" "$CHECK_RUN_SCRIPT"
check_required_file "COV_ALL_RUNS_SCRIPT" "$COV_ALL_RUNS_SCRIPT"
check_required_file "FAIL_PATTERNS_FILE" "$FAIL_PATTERNS_FILE"

# Get all run manifests
MANIFEST_LIST="$(find_all_files "$RUN_DIR" "$RUN_MANIFEST_GLOB")"

# Check if no manifests are found
[[ -n "$MANIFEST_LIST" ]] || fail "No run manifests found"

# Convert to an array
mapfile -t MANIFEST_ARRAY <<< "$MANIFEST_LIST"

# Create temporary directory and schedule deletion
TMP_MANIFEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_MANIFEST_DIR"' EXIT

num_total=0
num_passed=0
num_skipped=0

for manifest in "${MANIFEST_ARRAY[@]}"; do
    num_total=$((num_total + 1))

    if "$CHECK_RUN_SCRIPT" "$manifest" "$FAIL_PATTERNS_FILE"; then
        cp "$manifest" "$TMP_MANIFEST_DIR/"
        num_passed=$((num_passed + 1))
    else
        printf '[SKIP] %s\n' "Run did not pass checks: $manifest"
        num_skipped=$((num_skipped + 1))
    fi
done

# Stats
info "Total manifests:   $num_total"
info "Passing manifests: $num_passed"
info "Skipped manifests: $num_skipped"

# Check if no passing runs
[[ "$num_passed" -gt 0 ]] || fail "No passing runs found"

# Run with temporal directory
"$COV_ALL_RUNS_SCRIPT" "$TMP_MANIFEST_DIR" "$RUN_MANIFEST_GLOB" "$URG_COMMON_FLAGS"
