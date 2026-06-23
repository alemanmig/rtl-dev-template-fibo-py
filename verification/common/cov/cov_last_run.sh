#!/usr/bin/env bash

##==============================================================================
## [Filename]       cov_last_run.sh
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       Bash scripting
## [Created]        -
## [Modified]       -
## [Description]    Performs the coverage for latest run, gated only by 
##                  simulator success and coverage DB presence
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

    [[ -d "$search_dir" ]] || fail "Directory does not exist: $search_dir"

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

# ----------------------------- LOAD RUN MANIFEST ------------------------------

# Get the last run manifest file
RUN_MANIFEST_FILE="$(find_latest_file "$RUN_DIR" "$RUN_MANIFEST_GLOB")"

# Check if no manifest is found
[[ -n "$RUN_MANIFEST_FILE" ]] || fail "No run manifest found"

# Load it
source "$RUN_MANIFEST_FILE"

# Check non empty fields
check_non_empty "SIM_STATUS" "${SIM_STATUS:-}"

# Check SIM_STATUS
if [[ "$SIM_STATUS" != "0" ]]; then
    fail "TEST_ID=${TEST_ID:-unknown} SIM_STATUS=$SIM_STATUS"
fi

# Check if run coverage database exists
check_required_dir "RUN_COV_DB" "${RUN_COV_DB:-}"

# --------------------------------- MAIN LOGIC ---------------------------------

# Convert Make-provided string into an array
read -r -a URG_FLAGS <<< "$URG_COMMON_FLAGS"

# Check if code coverage was enabled at run time
if [[ "${ENABLE_CODE_COV_RUN:-false}" == "true" ]]; then

    # Check if build manifest exists
    check_required_file "BUILD_MANIFEST_FILE" "${BUILD_MANIFEST_FILE:-}"

    # Load it
    source "$BUILD_MANIFEST_FILE"

    # Check if build coverage database exists
    check_required_dir "BUILD_COV_DB" "${BUILD_COV_DB:-}"

    # Merge both databases
    info "Merging run + build coverage"
    urg -dir "$RUN_COV_DB" -dir "$BUILD_COV_DB" "${URG_FLAGS[@]}"
else
    # Merge just run coverage
    info "Merging run coverage only"
    urg -dir "$RUN_COV_DB" "${URG_FLAGS[@]}"
fi
