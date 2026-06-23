#!/usr/bin/env bash

##==============================================================================
## [Filename]       cov_all_runs.sh
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

# ------------------------------------ LOAD ------------------------------------

# Get all run manifests
MANIFEST_LIST="$(find_all_files "$RUN_DIR" "$RUN_MANIFEST_GLOB")"

# Check if no manifest is found
[[ -n "$MANIFEST_LIST" ]] || fail "No run manifest found"

# Convert to an array
mapfile -t MANIFEST_ARRAY <<< "$MANIFEST_LIST"
RUN_COV_DBS=()
BUILD_COV_DBS=()

num_valid_tests=0
num_cov_run_true=0
num_cov_run_false=0

for manifest in "${MANIFEST_ARRAY[@]}"; do
    # Reset values before sourcing to avoid keeping old values
    SIM_STATUS=""
    ENABLE_CODE_COV_RUN=""
    RUN_COV_DB=""
    BUILD_MANIFEST_FILE=""

    # Load manifest
    source "$manifest"

    # Check non empty fields
    check_non_empty "SIM_STATUS" "${SIM_STATUS:-}"

    # Skip failed tests
    if [[ "$SIM_STATUS" != "0" ]]; then
        printf "[SKIP] %s\n" "Test failed, skipping coverage merge: $manifest"
        continue
    fi
    
    # Increase counter
    num_valid_tests=$((num_valid_tests + 1))
        
    # Check non empty fields
    check_non_empty "ENABLE_CODE_COV_RUN" "${ENABLE_CODE_COV_RUN:-}"

    # Check if run coverage database exists
    check_required_dir "RUN_COV_DB" "${RUN_COV_DB:-}"

    # Append values to list
    RUN_COV_DBS+=("$RUN_COV_DB")

    if [[ "$ENABLE_CODE_COV_RUN" == "true" ]]; then
        # Increase counter
        num_cov_run_true=$((num_cov_run_true + 1))
        
        # Check non empty field
        check_required_file "BUILD_MANIFEST_FILE" "${BUILD_MANIFEST_FILE:-}"

        # Reset value before sourcing to avoid keeping old values
        BUILD_COV_DB=""
        
        # Load build manifest
        source "$BUILD_MANIFEST_FILE"

        # Check non empty field
        check_required_dir "BUILD_COV_DB" "${BUILD_COV_DB:-}"

        # Append 
        BUILD_COV_DBS+=("$BUILD_COV_DB")

    elif [[ "$ENABLE_CODE_COV_RUN" == "false" ]]; then
        num_cov_run_false=$((num_cov_run_false + 1))
    else
      fail "Invalid ENABLE_CODE_COV_RUN value in $manifest: $ENABLE_CODE_COV_RUN"
    fi
done

# If empty
if [[ "$num_valid_tests" -eq 0 ]]; then
    fail "No successful tests found"
fi

# Stats
info "Number of tests:        $num_valid_tests"
info "Tests with COV ENABLE:  $num_cov_run_true"
info "Tests with COV DISABLE: $num_cov_run_false"

if [[ "$num_cov_run_false" -eq "$num_valid_tests" ]]; then
    info "All successful runs use normal coverage DBs"

    MERGE_COV_DBS=("${RUN_COV_DBS[@]}")

elif [[ "$num_cov_run_true" -eq "$num_valid_tests" ]]; then
    info "All successful runs use split build/run coverage DBs"

    # Remove duplicate BUILD_COV_DB entries
    mapfile -t UNIQUE_BUILD_COV_DBS < <(printf '%s\n' "${BUILD_COV_DBS[@]}" | sort -u)

    if [[ "${#UNIQUE_BUILD_COV_DBS[@]}" -ne 1 ]]; then
        info "Build coverage DBs found"
        printf '  %s\n' "${UNIQUE_BUILD_COV_DBS[@]}"
        fail "Expected exactly one unique BUILD_COV_DB, found ${#UNIQUE_BUILD_COV_DBS[@]}"
    fi

    MERGE_COV_DBS=("${UNIQUE_BUILD_COV_DBS[0]}" "${RUN_COV_DBS[@]}")

else
    fail "Mixed ENABLE_CODE_COV_RUN values found. Some runs are true and some are false."
fi

# Apply coverage
URG_DIR_ARGS=()

for cov_db in "${MERGE_COV_DBS[@]}"; do
    URG_DIR_ARGS+=("-dir" "$cov_db")
done

info "Coverage DBs to merge:"
printf "  %s\n" "${MERGE_COV_DBS[@]}"

# Convert Make-provided string into an array
read -r -a URG_FLAGS <<< "$URG_COMMON_FLAGS"

# Execute URG
urg "${URG_DIR_ARGS[@]}" "${URG_FLAGS[@]}"
