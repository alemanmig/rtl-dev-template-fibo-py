#!/usr/bin/env bash

##==============================================================================
## [Filename]       get_latest_logs.sh
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       Bash scripting
## [Created]        -
## [Modified]       -
## [Description]    -
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

print_latest_file() {
    local label="${1:?missing label}"
    local search_dir="${2:?missing search_dir}"
    local pattern="${3:?missing pattern}"

    local latest_file
    latest_file="$(find_latest_file "$search_dir" "$pattern")"

    if [[ -z "$latest_file" ]]; then
        printf '[WARN] %s\n' "No $label found"
    else
        printf '[INFO] %s\n' "LATEST ${label^^}"
        printf '[INFO] %s\n' "$latest_file"
    fi
}

# -------------------------------- CLI PARSING ---------------------------------

BUILD_DIR="${1:?missing BUILD_DIR}"
BUILD_LOG_PATTERN="${2:?missing BUILD_LOG_PATTERN}"

RUN_DIR="${3:?missing RUN_DIR}"
RUN_LOG_PATTERN="${4:?missing RUN_LOG_PATTERN}"

COV_DIR="${5:?missing COV_DIR}"
COV_LOG_PATTERN="${6:?missing COV_LOG_PATTERN}"

MANIFEST_DIR="${7:?missing MANIFEST_DIR}"
RUN_MANIFEST_GLOB="${8:?missing RUN_MANIFEST_GLOB}"

# ------------------------------------ FIND ------------------------------------

BUILD_LOG="$(find_latest_file "$BUILD_DIR" "$BUILD_LOG_PATTERN")"
RUN_LOG="$(find_latest_file "$RUN_DIR" "$RUN_LOG_PATTERN")"
COV_LOG="$(find_latest_file "$COV_DIR" "$COV_LOG_PATTERN")"
RUN_MANIFEST_FILE="$(find_latest_file "$MANIFEST_DIR" "$RUN_MANIFEST_GLOB")"

# ----------------------------------- PRINT ------------------------------------

print_latest_file "build log" "$BUILD_DIR" "$BUILD_LOG_PATTERN"
print_latest_file "run log" "$RUN_DIR" "$RUN_LOG_PATTERN"
print_latest_file "cov log" "$COV_DIR" "$COV_LOG_PATTERN"
print_latest_file "run manifest" "$MANIFEST_DIR" "$RUN_MANIFEST_GLOB"
