##==============================================================================
## [Filename]       project.mk
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       GNU Makefile
## [Created]        -
## [Modified]       -
## [Description]    Directed project
## [Notes]          -
## [Status]         stable
## [Revisions]      -
##==============================================================================

# ================================ DIRECTORIES =================================
# Project paths and directory hierarchy

GIT_DIR       := $(shell git rev-parse --show-toplevel)
TB_DIR        ?= $(GIT_DIR)/verification/directed
COMMON_MK_DIR := $(GIT_DIR)/verification/common/mk

# =============================== CONFIGURATION ================================
# Project-specific defaults

# -------------------------------- COMPILE-TIME --------------------------------

# TIMESCALE               ?= 1ps/100fs
# ENABLE_UVM              ?= false
# UVM_VERSION             ?= 1.2
ENABLE_DEBUG_DB         ?= true
DEFINES                 ?=
# COMPILE_ARGS            ?=
SIMV_NAME               ?= simv2
ENABLE_CODE_COV_COMPILE ?= true
CODE_COV_TYPES_COMPILE  ?= line+cond+tgl+assert
ENABLE_SVA_COMPILE      ?= true
UVCS_FILELIST           ?=
# DPI_FILE is only for .cpp/.o DPI sources linked statically at vcs compile time.
# We use the shared lib (libdpi.so) instead, loaded at run time below.
DPI_FILE                ?=

# -sv_lib loads the shared lib built by `make build-dpi`
# (verification/common/dpi/lib/libdpi.so). This is a simv RUN-TIME option —
# vcs silently rejects it at compile time ("Unknown option ... ignoring"),
# then chokes trying to parse the next token as a source file. It must be
# appended to SIMV_FLAGS (see below, after common.mk is included), not DPI_FILE.
#
# -sv_lib takes a path WITHOUT the .so suffix; it does NOT auto-prepend "lib"
# (confirmed: `-sv_lib dpi -sv_root <dir>` made simv look for literal
# "./dpi.so" in the CWD, not "<dir>/libdpi.so" — -sv_root was not honored for
# a bare name with no path component). Passing the full absolute path
# including the "lib" prefix sidesteps both problems: no -sv_root needed, no
# relative-path/CWD ambiguity at run time.
#
# DPI_BACKEND selects WHICH .so gets loaded (test.sv is identical either way):
#   cpp    (default) -> `make build-dpi`    -> libdpi.so    (fibonacci_dpi.cpp,
#                        pure C++ Fibonacci class)
#   python            -> `make build-dpi-py` -> libdpi_py.so (fibonacci_dpi_py.cpp,
#                        embeds CPython, calls fibonacci_model.py)
# Pass it on every invocation that needs it, same as FIB_W below, e.g.:
#   make build-dpi-py DPI_BACKEND=python
#   make compile DPI_BACKEND=python && make sim DPI_BACKEND=python
DPI_BACKEND ?= cpp
PYTHON3     ?= python3
ifeq ($(DPI_BACKEND),python)
  DPI_LIB_NAME_RUN ?= libdpi_py
  # Embedded CPython needs to find fibonacci_model.py; RUN_SIM cd's into
  # JOB_DIR before invoking simv, so PYTHONPATH/cwd tricks don't help here —
  # the .cpp shim reads this env var explicitly instead.
  export DPI_PY_SRC_DIR := $(GIT_DIR)/verification/common/dpi/src
  # libdpi_py.so links against libpython3.x.so (e.g. via a conda env's
  # python3-config --embed), but that lib usually is NOT on the default
  # dynamic-linker search path, and `conda activate` does NOT add
  # $CONDA_PREFIX/lib to LD_LIBRARY_PATH by default. Without this, simv finds
  # libdpi_py.so itself (via the absolute -sv_lib path) but then fails to
  # open ITS dependency: "libpython3.x.so.1.0: cannot open shared object
  # file". Resolve the prefix from the same PYTHON3 used in build-dpi-py and
  # prepend its lib dir explicitly so it doesn't depend on shell state.
  PYTHON3_PREFIX := $(shell $(PYTHON3)-config --prefix 2>/dev/null)
  export LD_LIBRARY_PATH := $(PYTHON3_PREFIX)/lib:$(LD_LIBRARY_PATH)
else
  DPI_LIB_NAME_RUN ?= libdpi
endif
DPI_RUN_FLAGS           ?= -sv_lib $(GIT_DIR)/verification/common/dpi/lib/$(DPI_LIB_NAME_RUN)

# ---------------------------------- RUN-TIME ----------------------------------

# TEST                      ?= top_test
# VERBOSITY                 ?= UVM_MEDIUM
# SEED_MODE                 ?= fixed
# SEED                      ?= 5081996
ENABLE_UVM_RECORDING      ?= false
ENABLE_CODE_COV_RUN       ?= true
CODE_COV_TYPES_RUN        ?= line+cond+tgl+assert
ENABLE_SVA_RUN            ?= true
DUMP_MODE                 ?= default
JOB_NAME                  ?= miguel_test
RUN_ARGS                  ?=

# ---------------------- PARAMETRIC WIDTH OVERRIDE (PAR-001) --------------------
# TC-PAR-01..03 require separate builds for W=8/16/32. Each width must land in
# its own SIMV_NAME/JOB_NAME, otherwise the next `make compile` overwrites the
# previous width's BUILD_COV_DB before it gets merged (see cov.mk header note).
#
# Usage:
#   make compile FIB_W=8  && make sim FIB_W=8
#   make compile FIB_W=16 && make sim FIB_W=16
#   make compile FIB_W=32 && make sim FIB_W=32
#
# NOTE: verify the -pvalue+<pkg>::<param>=<val> separator against your VCS
# version's docs (some releases expect '.' instead of '::'). If it errors,
# override config_pkg::FibW by hand for that build instead.
FIB_W ?=
ifneq ($(strip $(FIB_W)),)
  COMPILE_ARGS += -pvalue+config_pkg::FibW=$(FIB_W)
  SIMV_NAME     = simv2_w$(FIB_W)
  JOB_NAME      = miguel_test_w$(FIB_W)
endif

# ================================== INCLUDES ==================================

# Main framework
include $(COMMON_MK_DIR)/common.mk

# Append the DPI shared-lib load flags onto the simv run-time command line
# (must come after common.mk, since that's where SIMV_FLAGS is first defined).
SIMV_FLAGS += $(DPI_RUN_FLAGS)

# DPI
-include $(COMMON_MK_DIR)/dpi.mk

# Coverage
-include $(COMMON_MK_DIR)/cov.mk

# Regression Manager
# -include $(MK_DIR)/regression.mk

# ================================= HELP MENU ==================================

.PHONY: help
help: ## COMMON: Displays help message
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "                                    PROJECT.MK                                  "
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "Usage: make <target> [variables]"
	@printf "%s\n" "------------------------------------ TARGETS -----------------------------------"
	@grep -h -E '^help-[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "- make $(C_CYN)%-15s$(C_RST) %s\n", $$1, $$2}'
	@printf "%s\n" "================================================================================"
