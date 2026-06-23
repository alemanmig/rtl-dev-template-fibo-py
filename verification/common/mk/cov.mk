##==============================================================================
## [Filename]       cov.mk
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       GNU Makefile
## [Created]        -
## [Modified]       -
## [Description]    -
## [Notes]          -
##                    Merge across tests/seeds for the same build_manifest.mk.
##                    Do not merge across different build manifests unless you explicitly declare them compatible.
## [Status]         stable
## [Revisions]      -
##==============================================================================

# ============================= COVERAGE MANIFESTS =============================

# File matching patterns (globs)
BUILD_MANIFEST_GLOB ?= $(BUILD_MANIFEST_EXT)
RUN_MANIFEST_GLOB   ?= *_$(RUN_MANIFEST_EXT)

# ================================ DIRECTORIES =================================

COV_MERGE_NAME ?= merged.vdb
COV_MERGE_DB   ?= $(COV_MERGE_DIR)/$(COV_MERGE_NAME)

# ================================ TOOLS SETUP =================================

URG_COMMON_FLAGS = -full64 -format both \
				 -report $(COV_REPORT_DIR) \
				 -dbname $(COV_MERGE_DB) \
				 -show tests \
				 -log $(COV_LOGS_DIR)/$(CUR_DATE)_cov.log

VERDI_COV_FLAGS ?= -q -cov -covdir $(COV_MERGE_DB)

FAIL_PATTERNS_FILE ?= $(COMMON_COV_DIR)/fail_patterns.txt

# ================================  TARGETS  ==================================

.PHONY: latest
latest: # COV: Get latest logs
	@bash $(COMMON_COV_DIR)/get_latest_logs.sh \
	"$(BUILD_DIR)" "*_compile.log" \
	"$(RUN_DIR)" "*_run.log" \
	"$(COV_DIR)" "*_cov.log" \
	"$(RUN_DIR)" "*_run_manifest.mk"
#______________________________________________________________________________

.PHONY: list-builds
list-builds: ## COV: List all build coverage manifests
	@printf "$(C_CYN)%s$(C_RST)\n" "Build manifests"
	@find $(BUILD_DIR) -type f -name "$(BUILD_MANIFEST_GLOB)" | sort
#______________________________________________________________________________

.PHONY: cov-list-runs
list-runs: ## COV: List all run coverage manifests
	@printf "$(C_CYN)%s$(C_RST)\n" "Run manifests"
	@find $(RUN_DIR) -type f -name "$(RUN_MANIFEST_GLOB)" | sort
#______________________________________________________________________________

.PHONY: clean-cov
clean-cov: ## COV: Remove coverage files and manifests
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing coverage merge and reports"
	@rm -rf $(COV_DIR)
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing coverage manifests"
	@find $(BUILD_DIR) -type f -name "$(BUILD_MANIFEST_GLOB)" -delete
	@find $(RUN_DIR)   -type f -name "$(RUN_MANIFEST_GLOB)"   -delete
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing run coverage databases"
	@find $(RUN_DIR)   -depth -type d -name "*.vdb" -exec rm -rf {} +
# 	@printf "$(C_CYN)%s$(C_RST)\n" "Removing build coverage databases"
# 	@find $(BUILD_DIR) -depth -type d -name "*.vdb" -exec rm -rf {} +
#______________________________________________________________________________

.PHONY: cov-latest
cov-latest: ## COV: Generating coverage from last run
	@printf "$(C_CYN)%s$(C_RST)\n" "Generating coverage from latest run"
	@mkdir -p $(COV_LOGS_DIR)
	@bash $(COMMON_COV_DIR)/cov_last_run.sh \
	"$(RUN_DIR)" "$(RUN_MANIFEST_GLOB)" "$(URG_COMMON_FLAGS)"
#______________________________________________________________________________

.PHONY: cov-latest-checked
cov-latest-checked: ## COV: Generating coverage from last passing run
	@printf "$(C_CYN)%s$(C_RST)\n" "Generating coverage from latest passing run"
	@mkdir -p $(COV_LOGS_DIR)
	@bash $(COMMON_COV_DIR)/cov_checked_last_run.sh \
	"$(RUN_DIR)" "$(RUN_MANIFEST_GLOB)" "$(URG_COMMON_FLAGS)" "$(FAIL_PATTERNS_FILE)"
#______________________________________________________________________________

.PHONY: cov-all
cov-all: ## COV: Generating coverage report of all runs
	@printf "$(C_CYN)%s$(C_RST)\n" "Generating coverage of all run"
	@mkdir -p $(COV_LOGS_DIR)
	@bash $(COMMON_COV_DIR)/cov_all_runs.sh \
	"$(RUN_DIR)" "$(RUN_MANIFEST_GLOB)" "$(URG_COMMON_FLAGS)"
#______________________________________________________________________________

.PHONY: cov-all-checked
cov-all-checked: ## COV: Generating coverage report of all passing runs
	@printf "$(C_CYN)%s$(C_RST)\n" "Generating coverage of all passing run"
	@mkdir -p $(COV_LOGS_DIR)
	@bash $(COMMON_COV_DIR)/cov_checked_all_runs.sh \
	"$(RUN_DIR)" "$(RUN_MANIFEST_GLOB)" "$(URG_COMMON_FLAGS)" "$(FAIL_PATTERNS_FILE)"
#______________________________________________________________________________

.PHONY: verdi-cov
verdi-cov: ## COV: Open coverage report in Verdi
	@printf "$(C_CYN)%s: $(C_RST)\n" "Opening coverage report in Verdi"
	@mkdir -p $(VERDI_DIR)
	cd $(VERDI_DIR) && verdi $(VERDI_COV_FLAGS) &
#_______________________________________________________________________________

.PHONY: print-cov
print-cov: ## COV: Print Makefile variables
	$(call print_var,URG_COMMON_FLAGS)
	$(call print_var,VERDI_COV_FLAGS)
#______________________________________________________________________________

help-cov: ## COV: Displays help message
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "                                       COV.MK                                   "
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "Usage: make <target> [variables]"
	@printf "%s\n" "------------------------------------ TARGETS -----------------------------------"
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(COMMON_MK_DIR)/cov.mk | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "- make $(C_CYN)%-20s$(C_RST) %s\n", $$1, $$2}'
	@printf "%s\n" "================================================================================"
#_______________________________________________________________________________
