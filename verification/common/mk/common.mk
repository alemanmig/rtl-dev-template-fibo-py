##==============================================================================
## [Filename]       common.mk
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       GNU Makefile
## [Created]        -
## [Modified]       -
## [Description]    -
## [Notes]          -
## [Status]         stable
## [Revisions]      -
##==============================================================================

# ================================= VARIABLES ==================================
# Miscellaneous variables

CUR_DATE := $(shell date +%Y-%m-%d_%H-%M-%S)

# ------------------------------ TERMINAL COLORS -------------------------------
C_RED := \033[31m
C_GRN := \033[32m
C_BLU := \033[34m
C_YEL := \033[33m
C_CYN := \033[36m
C_RST := \033[0m

# ------------------------------ MESSAGE HELPERS -------------------------------
MSG_INFO  = @printf "$(C_BLU)[INFO]$(C_RST) %s\n"
MSG_OK    = @printf "$(C_GRN)[ OK ]$(C_RST) %s\n"
MSG_WARN  = @printf "$(C_YEL)[WARN]$(C_RST) %s\n"
MSG_ERROR = @printf "$(C_RED)[FAIL]$(C_RST) %s\n"

define print_vars
	@printf "$(C_CYN)%s$(C_RST)\n" "$(1)"
	@$(foreach var,$(2), \
		printf "%-25s = %s\n" \
		"$(var)" \
		"$($(var))";)
	@printf "\n"
endef

define print_var
	@printf "$(C_CYN)%s$(C_RST)\n" "$(1)"
	@printf "%s\n" "$(strip $($(1)))";
	@printf "\n"
endef

define print_var_help
	@$(foreach var,$(1), \
		printf "  %-25s : %s\n" \
		"$(var)" \
		"$(HELP_$(var))";)
endef

define print_vars_help_values
	@$(foreach var,$(1), \
		printf "  %-25s = %s\n" \
		"$(var)" \
		"$($(var))";)
endef

# ================================ DIRECTORIES =================================
# Project paths and directory hierarchy

# ---------------------------------- GENERAL -----------------------------------
GIT_DIR          := $(shell git rev-parse --show-toplevel)
RTL_DIR          := $(GIT_DIR)/rtl
VRF_DIR          := $(GIT_DIR)/verification
COMMON_DIR       := $(VRF_DIR)/common
TB_DIR           ?= $(VRF_DIR)/uvm
GENERAL_DIR_VARS := GIT_DIR RTL_DIR VRF_DIR COMMON_DIR TB_DIR

# ----------------------------------- COMMON -----------------------------------
COMMON_COV_DIR   := $(COMMON_DIR)/cov
COMMON_DPI_DIR   := $(COMMON_DIR)/dpi
COMMON_MK_DIR    := $(COMMON_DIR)/mk
COMMON_TCL_DIR   := $(COMMON_DIR)/tcl
TCL_DUMP_DIR     := $(COMMON_TCL_DIR)/dump
COMMON_DIR_VARS  := COMMON_COV_DIR COMMON_DPI_DIR COMMON_MK_DIR COMMON_TCL_DIR TCL_DUMP_DIR

# ---------------------------------- SCRIPTS -----------------------------------
SCRIPTS_DIR      := $(TB_DIR)/scripts
MK_DIR           := $(SCRIPTS_DIR)/mk
SETUP_DIR        := $(SCRIPTS_DIR)/setup
TCL_DIR          := $(SCRIPTS_DIR)/tcl
WAVES_DIR        := $(SCRIPTS_DIR)/waves
SCRIPTS_DIR_VARS := SCRIPTS_DIR MK_DIR SETUP_DIR TCL_DIR WAVES_DIR  

# ------------------------------------ WORK ------------------------------------
ROOT_DIR       ?= $(CURDIR)
BUILD_DIR       = $(ROOT_DIR)/build
RUN_DIR         = $(ROOT_DIR)/run
LOGS_DIR        = $(ROOT_DIR)/logs
VERDI_DIR       = $(ROOT_DIR)/verdi
COV_DIR         = $(ROOT_DIR)/cov
WORK_DIR_VARS  := ROOT_DIR BUILD_DIR RUN_DIR LOGS_DIR VERDI_DIR COV_DIR 

# ---------------------------------- COVERAGE ----------------------------------
COV_REPORT_DIR  = $(COV_DIR)/report
COV_MERGE_DIR   = $(COV_DIR)/merge
COV_LOGS_DIR    = $(COV_DIR)/logs
COV_DIR_VARS   := COV_DIR COV_REPORT_DIR COV_MERGE_DIR COV_LOGS_DIR

# ------------------------------------ UVCS ------------------------------------
UVCS_DIR = $(TB_DIR)/uvcs

EXTRA_DIR_VARS := UVCS_DIR

# =============================== CONFIGURATION ================================
# User-editable knobs and defaults

# ---------------------------------- TEST RUN ----------------------------------
# Test selection and basic UVM runtime options

# Options: [UVM_LOW, UVM_MEDIUM, UVM_HIGH, UVM_DEBUG]
VERBOSITY ?= UVM_MEDIUM
TEST      ?= top_test

# Options: [auto, fixed]
SEED_MODE  ?= fixed
SEED       ?= 5081996
SEED_FLAGS  =

SEED_VARS  := SEED SEED_MODE SEED_FLAGS

# Timescale
TIMESCALE ?= 1ps/100fs

# Workspace
SIMV_NAME ?= simv
JOB_NAME  ?= debug
SIMV_DIR  = $(BUILD_DIR)/$(SIMV_NAME)
JOB_DIR   = $(RUN_DIR)/$(JOB_NAME)

WORKSPACE_DIR_VARS := SIMV_DIR JOB_DIR
WORKSPACE_VARS := SIMV_NAME JOB_NAME $(WORKSPACE_DIR_VARS) 

# ---------------------------- UCLI DUMP SELECTION -----------------------------
# Options: [default, all, none]
DUMP_MODE    ?= none
DUMP_LIB_TCL := $(TCL_DUMP_DIR)/dump_lib.tcl
UCLI_FLAGS    = -ucli -do $(TCL_DUMP_DIR)/$(DUMP_MODE).tcl

# Necessary to import the library
export DUMP_LIB_TCL

UCLI_VARS := DUMP_MODE DUMP_LIB_TCL UCLI_FLAGS

TEST_RUN_VARS := TEST VERBOSITY TIMESCALE \
				$(SEED_VARS) \
				$(WORKSPACE_VARS) \
				$(UCLI_VARS)

# --------------------- DEFINES / COMPILE ARGS / RUN ARGS ----------------------

# Defines and extra compile arguments
# Example: +define+GIT_DIR=\"$(GIT_DIR)\"
DEFINES      ?=
COMPILE_ARGS ?=

# Runtime extra arguments
RUN_ARGS ?=

USER_ARG_VARS := DEFINES COMPILE_ARGS RUN_ARGS

# ---------------------------------- GUI MODE ----------------------------------
# Options: [true, false]
# ENABLE_GUI ?= false
# Run Tcl by default
# GUI_FLAGS  ?= -gui=verdi
# GUI_VARS   := ENABLE_GUI GUI_FLAGS

# --------------------------------- DEBUG MODE ---------------------------------
# Options: [true, false]
ENABLE_DEBUG_DB ?= false
DEBUG_FLAGS_VCS ?=

DEBUG_VARS := ENABLE_DEBUG_DB DEBUG_FLAGS_VCS

# ------------------------------------ UVM -------------------------------------
# Options: [true, false]
ENABLE_UVM           ?= false
ENABLE_UVM_RECORDING ?= false
UVM_VERSION          ?= 1.2

UVM_FLAGS_VCS  ?=
UVM_FLAGS_SIMV ?=

UVM_VARS := ENABLE_UVM ENABLE_UVM_RECORDING UVM_VERSION UVM_FLAGS_SIMV UVM_FLAGS_VCS

# ------------------------------- CODE COVERAGE --------------------------------
# Options: [true, false]
ENABLE_CODE_COV_COMPILE ?= false
ENABLE_CODE_COV_RUN     ?= false

# Options: line+cond+fsm+branch+tgl+assert
CODE_COV_TYPES_COMPILE  ?=
CODE_COV_TYPES_RUN      ?=

# Default coverage name
COV_DB_NAME   ?= $(SIMV_NAME).vdb
BUILD_COV_DB  ?= $(SIMV_DIR)/$(COV_DB_NAME)
COV_HIER_FILE ?= $(COMMON_COV_DIR)/cm_hier.cfg

# Compile time code coverage flags
COV_FLAGS_VCS ?=

# Run time code coverage flags
COV_FLAGS_SIMV   ?=

CODE_COV_VARS = \
	$(COV_DIR_VARS) \
	ENABLE_CODE_COV_COMPILE ENABLE_CODE_COV_RUN \
	CODE_COV_TYPES_COMPILE CODE_COV_TYPES_RUN \
	COV_DB_NAME BUILD_COV_DB COV_HIER_FILE \
	COV_FLAGS_VCS COV_FLAGS_SIMV

# ------------------------------------ SVA -------------------------------------
# Options: [true, false]
ENABLE_SVA_COMPILE ?= false
ENABLE_SVA_RUN     ?= $(ENABLE_SVA_COMPILE)

SVA_FLAGS_VCS  ?=
SVA_FLAGS_SIMV ?=

SVA_VARS := ENABLE_SVA_COMPILE ENABLE_SVA_RUN SVA_FLAGS_VCS SVA_FLAGS_SIMV

# ================================== CONTROL ===================================
# Derived flags / logic

# --------------------------------- DEBUG MODE ---------------------------------
# Options: [true, false]
ifeq ($(ENABLE_DEBUG_DB),true)
	DEBUG_FLAGS_VCS += -lca -debug_access+all -kdb
endif

# ------------------------------------ UVM -------------------------------------
# Options: [true, false]
ifeq ($(ENABLE_UVM),true)
	UVM_FLAGS_VCS  += -ntb_opts uvm-$(UVM_VERSION)
	UVM_FLAGS_SIMV += +UVM_NO_RELNOTES
endif

# Options: [true, false]
ifeq ($(ENABLE_UVM_RECORDING),true)
	UVM_FLAGS_SIMV += +UVM_VERDI_TRACE=UVM_AWARE+RAL+HIER+TLM \
					+UVM_TR_RECORD +UVM_LOG_RECORD
endif

# --------------------------------- SEED MODE ----------------------------------
# Options: [auto, fixed]
ifeq ($(SEED_MODE),auto)
  SEED_FLAGS = +ntb_random_seed_automatic
else
  SEED_FLAGS = +ntb_random_seed=$(SEED)
endif

# ------------------------------- CODE COVERAGE --------------------------------
# Options: [true, false]
ifeq ($(ENABLE_CODE_COV_COMPILE),true)
	COV_FLAGS_VCS += -cm $(CODE_COV_TYPES_COMPILE) \
					 -cm_dir $(BUILD_COV_DB) \
					 -cm_hier $(COV_HIER_FILE)
endif

# Options: [true, false]
ifeq ($(ENABLE_CODE_COV_RUN),true)
	COV_FLAGS_SIMV += -cm $(CODE_COV_TYPES_RUN)
endif

# ------------------------------------ SVA -------------------------------------
# Options: [true, false]
ifeq ($(ENABLE_SVA_COMPILE),true)
	SVA_FLAGS_VCS  += -assert enable_diag+enable_hier
endif

# Options: [true, false]
ifeq ($(ENABLE_SVA_RUN),true)
	SVA_FLAGS_SIMV += -assert summary+quiet1
endif
#-assert report=$(LOGS_DIR)/$(CUR_DATE)_sva.log

# ================================ TOOLS SETUP =================================

# --------------------------------- FILE LISTS ---------------------------------
RTL_FILELIST  ?= -F $(RTL_DIR)/rtl.f
TB_FILELIST   ?= -F $(TB_DIR)/tb.f
UVCS_FILELIST ?=
FILES         ?= $(UVCS_FILELIST) $(RTL_FILELIST) $(TB_FILELIST)
FILELIST_VARS := RTL_FILELIST TB_FILELIST UVCS_FILELIST

# ------------------------------------ DPI -------------------------------------
DPI_FILE ?=

# ------------------------------------ VCS -------------------------------------
VCS_FLAGS = -full64 -sverilog \
			$(UVM_FLAGS_VCS) \
			$(DEBUG_FLAGS_VCS) \
			-timescale=$(TIMESCALE) \
			$(FILES) \
			-l $(SIMV_DIR)/logs/$(CUR_DATE)_compile.log \
			-top tb \
			-j8 \
			-o $(SIMV_NAME) \
			$(DEFINES) \
			$(COV_FLAGS_VCS) \
			$(SVA_FLAGS_VCS) \
			$(COMPILE_ARGS) \
			$(DPI_FILE)

# ------------------------------------ SIMV ------------------------------------
SIMV_FLAGS = +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) \
			$(UVM_FLAGS_SIMV) \
			-no_save \
			$(SEED_FLAGS) \
			$(COV_FLAGS_SIMV) \
			$(SVA_FLAGS_SIMV) \
			$(UCLI_FLAGS) \
			$(RUN_ARGS)

# ----------------------------------- VERDI ------------------------------------
VERDI_FLAGS     ?= -nologo -q -ssf $(JOB_DIR)/novas.fsdb 
# VERDI_FLAGS    = -ssf $(RUN_DIR)/$(JOB_NAME)/novas.fsdb -dbdir simv.daidir -nologo -q

TOOLS_FLAGS_VARS := VCS_FLAGS SIMV_FLAGS VERDI_FLAGS

# ============================== VARIABLE GROUPS ===============================

DIR_VARS := \
	$(GENERAL_DIR_VARS) \
	$(COMMON_DIR_VARS) \
	$(SCRIPTS_DIR_VARS) \
	$(WORK_DIR_VARS) \
	$(COV_DIR_VARS) \
	$(EXTRA_DIR_VARS) \
	$(WORKSPACE_DIR_VARS)

COMPILE_TIME_VARIABLES := \
	TIMESCALE \
	ENABLE_UVM \
	UVM_VERSION \
	ENABLE_DEBUG_DB \
	DEFINES \
	COMPILE_ARGS \
	SIMV_NAME \
	ENABLE_CODE_COV_COMPILE \
	CODE_COV_TYPES_COMPILE \
	ENABLE_SVA_COMPILE \
	UVCS_FILELIST \
	DPI_FILE

SIMULATION_VARIABLES := \
	TEST \
	VERBOSITY \
	SEED_MODE \
	SEED \
	ENABLE_UVM_RECORDING \
	ENABLE_CODE_COV_RUN \
	CODE_COV_TYPES_RUN \
	ENABLE_SVA_RUN \
	DUMP_MODE \
	JOB_NAME \
	RUN_ARGS

CONTROL_VARS := \
	$(COMPILE_TIME_VARIABLES) \
	$(SIMULATION_VARIABLES)

# ------------------------------- HELP MESSAGES --------------------------------

# Compile time
HELP_TIMESCALE               := Simulation timescale in Verilog format (e.g. 1ns/1ps)
HELP_ENABLE_UVM              := Enables UVM support during compilation [true|false]
HELP_UVM_VERSION             := Selects the UVM version to compile [1.2|1.1]
HELP_ENABLE_DEBUG_DB         := Enables generation of debug database files for Verdi [true|false]
HELP_DEFINES                 := Additional Verilog/SystemVerilog defines passed to vcs
HELP_COMPILE_ARGS            := Additional arguments passed to the vcs compile command
HELP_SIMV_NAME               := Name of the generated simulation executable
HELP_ENABLE_CODE_COV_COMPILE := Enables code coverage collection during compilation [true|false]
HELP_CODE_COV_TYPES_COMPILE  := Code coverage types during compilation [line+cond+fsm+branch+tgl+assert]
HELP_ENABLE_SVA_COMPILE      := Enables SVA compilation support in VCS [true|false]
HELP_UVCS_FILELIST           := Optional UVC filelist passed to VCS. Empty by default
HELP_DPI_FILE                := Optional DPI shared library passed to VCS. Empty by default

# Runtime
HELP_TEST                    := Name of the UVM test to run
HELP_VERBOSITY               := UVM verbosity level used during simulation
HELP_SEED_MODE               := Random seed mode [auto|fixed]
HELP_SEED                    := Simulation random seed (integer > 0). Used only when SEED_MODE=fixed
HELP_ENABLE_UVM_RECORDING    := Enables UVM transaction and object recording [true|false]
HELP_ENABLE_CODE_COV_RUN     := Enables code coverage collection during simulation [true|false]
HELP_CODE_COV_TYPES_RUN      := Code coverage types during simulation [line+cond+fsm+branch+tgl+assert]
HELP_ENABLE_SVA_RUN          := Enables SVA runtime reporting/control [true|false]
HELP_DUMP_MODE               := Select waveform dump configuration/script [all, default, none]. Requires ENABLE_DEBUG_DB=true
HELP_RUN_ARGS                := Additional runtime arguments passed to simv
HELP_JOB_NAME                := Name of the simulation job/output directory

SYNOPSYS_TOOLS := vcs urg verdi wv

# =================================== MACROS ===================================

# ------------------------------ COMPILE MANIFEST ------------------------------

BUILD_MANIFEST_EXT  ?= build_manifest.mk
BUILD_MANIFEST_FILE ?= $(SIMV_DIR)/$(BUILD_MANIFEST_EXT)

define WRITE_BUILD_MANIFEST
	@printf "$(C_CYN)%s$(C_RST)\n" "Writing build manifest"
	@mkdir -p $(SIMV_DIR)
	@{ \
		printf "SIMV_NAME=%s\n" "$(SIMV_NAME)"; \
		printf "SIMV_DIR=%s\n" "$(SIMV_DIR)"; \
		printf "BUILD_COV_DB=%s\n" "$(BUILD_COV_DB)"; \
		printf "ENABLE_CODE_COV_COMPILE=%s\n" "$(ENABLE_CODE_COV_COMPILE)"; \
		printf "CODE_COV_TYPES_COMPILE=%s\n" "$(CODE_COV_TYPES_COMPILE)"; \
		printf "ENABLE_SVA_COMPILE=%s\n" "$(ENABLE_SVA_COMPILE)"; \
		printf "BUILD_LOG=%s\n" "$(SIMV_DIR)/logs/$(CUR_DATE)_compile.log"; \
	} > $(BUILD_MANIFEST_FILE)
endef

# -------------------------------- COMPILATION ---------------------------------
define RUN_COMPILE
	@printf "$(C_CYN)%s$(C_RST)\n" "Compiling project"
	@mkdir -p $(SIMV_DIR) $(SIMV_DIR)/logs $(LOGS_DIR)
	cd $(SIMV_DIR) && vcs $(VCS_FLAGS)
	$(WRITE_BUILD_MANIFEST)
endef

# ---------------------------- SIMULATION MANIFEST -----------------------------

RUN_MANIFEST_EXT ?= run_manifest.mk

define WRITE_RUN_MANIFEST
	{ \
		printf "TEST=%s\n" "$(TEST)"; \
		printf "TEST_ID=%s\n" "$${TEST_ID}"; \
		printf "JOB_NAME=%s\n" "$(JOB_NAME)"; \
		printf "SIMV_NAME=%s\n" "$(SIMV_NAME)"; \
		printf "SIMV_DIR=%s\n" "$(SIMV_DIR)"; \
		printf "RUN_COV_DB=%s\n" "$${RUN_COV_DB}"; \
		printf "RUN_MANIFEST=%s\n" "$(JOB_DIR)/manifests/$${TEST_ID}_$(RUN_MANIFEST_EXT)"; \
		printf "BUILD_MANIFEST_FILE=%s\n" "$(BUILD_MANIFEST_FILE)"; \
		printf "ENABLE_CODE_COV_RUN=%s\n" "$(ENABLE_CODE_COV_RUN)"; \
		printf "CODE_COV_TYPES_RUN=%s\n" "$(CODE_COV_TYPES_RUN)"; \
		printf "ENABLE_SVA_RUN=%s\n" "$(ENABLE_SVA_RUN)"; \
		printf "RUN_LOG=%s\n" "$(JOB_DIR)/logs/$${TEST_ID}_run.log"; \
		printf "SIM_STATUS=%s\n" "$${SIM_STATUS}"; \
	} > $(JOB_DIR)/manifests/$${TEST_ID}_$(RUN_MANIFEST_EXT);
endef

# --------------------------------- SIMULATION ---------------------------------
define RUN_SIM
	@printf "$(C_CYN)%s$(C_RST)\n" \
		"Running simulation SEED=$(SEED_MODE) SEED=$(SEED)"
	@mkdir -p $(JOB_DIR) $(LOGS_DIR) $(JOB_DIR)/logs $(JOB_DIR)/cov $(JOB_DIR)/manifests
	@TEST_ID="$(CUR_DATE)_$(TEST)_$$$$"; \
	LOG_FILE="-l $(JOB_DIR)/logs/$${TEST_ID}_run.log"; \
	RUN_COV_DB="$(JOB_DIR)/cov/$${TEST_ID}.vdb"; \
	COV_TEST_FLAGS="-cm_test $(TEST) -cm_name $${TEST_ID} -cm_dir $${RUN_COV_DB}"; \
	cd $(JOB_DIR) && \
	$(SIMV_DIR)/$(SIMV_NAME) $(SIMV_FLAGS) \
		$${COV_TEST_FLAGS} $${LOG_FILE}; \
	SIM_STATUS=$$?; \
	$(WRITE_RUN_MANIFEST) \
	exit $$SIM_STATUS
endef

# ================================  TARGETS  ==================================
.DEFAULT_GOAL := all
SHELL         := bash

.PHONY: all
all: help-common
#_______________________________________________________________________________

.PHONY: check-tools
check-tools: ## COMMON: Check required Synopsys tools
	@printf "$(C_CYN)%s$(C_RST)\n" "Checking Synopsys tools..."
	@for tool in $(SYNOPSYS_TOOLS); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			printf "$(C_RED)%-7s is MISSING$(C_RST)\n" "$$tool"; \
			printf "Please source synopsys_eda_setup.[tc]sh before running Make targets\n"; \
			exit 1; \
		else \
			printf "$(C_GRN)%-7s FOUND$(C_RST)\n" "$$tool"; \
		fi; \
	done
	@printf "$(C_GRN)%s$(C_RST)\n" "All Synopsys tools are available"
#_______________________________________________________________________________

.PHONY: compile
compile: ## COMMON: Runs VCS compilation
	$(RUN_COMPILE)
#_______________________________________________________________________________

.PHONY: sim
sim: ## COMMON: Runs simv simulation
	$(RUN_SIM)
#_______________________________________________________________________________

.PHONY: verdi
verdi: ## COMMON: Opens Verdi GUI
	@printf "$(C_CYN)%s: %s$(C_RST)\n" \
		"Opening Verdi GUI" "$(JOB_NAME)"
	@mkdir -p $(VERDI_DIR)
	cd $(VERDI_DIR) && verdi $(VERDI_FLAGS) &
#_______________________________________________________________________________

.PHONY: fsdb2vcd
fsdb2vcd: ## COMMON: Convert FSDB to VCD
	@printf "$(C_CYN)%s$(C_RST)\n" "Convert FSDB to VCD"
	cd $(JOB_DIR) && fsdb2vcd novas.fsdb -o novas.vcd -sv
#_______________________________________________________________________________

.PHONY: vcd2fsdb
vcd2fsdb: ## COMMON: Convert VCD to FSDB
	@printf "$(C_CYN)%s$(C_RST)\n" "Convert VCD to FSDB"
	cd $(JOB_DIR) && vcd2fsdb novas.vcd -o novas.fsdb -sv
#_______________________________________________________________________________

.PHONY: clean
clean: ## COMMON: Remove all simulation files
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing all generated files"
	@rm -rf $(BUILD_DIR) $(RUN_DIR) $(LOGS_DIR) $(COV_DIR) $(VERDI_DIR)
#_______________________________________________________________________________

.PHONY: clean-logs
clean-logs: ## COMMON: Remove compilation and simulation logs
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing log files"
	@find $(BUILD_DIR) -name "*_compile.log" -delete
	@find $(RUN_DIR)   -name "*_run.log"     -delete
#_______________________________________________________________________________

.PHONY: clean-runs
clean-runs: ## COMMON: Remove runs files
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing runs files"
	@rm -rf $(RUN_DIR)
#_______________________________________________________________________________

.PHONY: clean-builds
clean-builds: ## COMMON: Remove builds files
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing builds files"
	@rm -rf $(BUILD_DIR)
#_______________________________________________________________________________

.PHONY: print-common
print-common: ## COMMON: Print Makefile variables
	$(call print_vars,Directory variables,$(DIR_VARS))
	$(call print_vars,Workspace variables,$(WORKSPACE_VARS))
	$(call print_vars,Test variables,$(TEST_RUN_VARS))
	$(call print_vars,Filelist variables,$(FILELIST_VARS))
	$(call print_vars,UVM variables,$(UVM_VARS))
	$(call print_vars,Seed variables,$(SEED_VARS))
	$(call print_vars,UCLI variables,$(UCLI_VARS))
	$(call print_vars,Coverage variables,$(CODE_COV_VARS))
	$(call print_vars,SVA variables,$(SVA_VARS))
	$(call print_vars,Debug variables,$(DEBUG_VARS))
	$(call print_vars,Control variables,$(CONTROL_VARS))
	$(call print_vars,Compile-time variables,$(COMPILE_TIME_VARIABLES))
	$(call print_vars,Simulation variables,$(SIMULATION_VARIABLES))
	$(call print_var,VCS_FLAGS)
	$(call print_var,SIMV_FLAGS)
	$(call print_var,VERDI_FLAGS)
#_______________________________________________________________________________

.PHONY: help-common
help-common: ## COMMON: Displays help message
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "                                    COMMON.MK                                   "
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "Usage: make <target> [variables]"
	@printf "%s\n" "------------------------------------ TARGETS -----------------------------------"
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(COMMON_MK_DIR)/common.mk | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "- make $(C_CYN)%-15s$(C_RST) %s\n", $$1, $$2}'
	@printf "%s\n" "----------------------------------- VARIABLES ----------------------------------"
	$(call print_var_help,$(CONTROL_VARS))
	@printf "%s\n" "---------------------------------- COMPILE TIME --------------------------------"
	$(call print_vars_help_values,$(COMPILE_TIME_VARIABLES))
	@printf "%s\n" "------------------------------------ RUN TIME ----------------------------------"
	$(call print_vars_help_values,$(SIMULATION_VARIABLES))
	@printf "%s\n" "================================================================================"
#_______________________________________________________________________________
