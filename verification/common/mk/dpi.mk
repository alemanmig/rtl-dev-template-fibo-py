##==============================================================================
## [Filename]       dpi.mk
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudez@gmail.com
## [Language]       GNU Makefile
## [Created]        -
## [Modified]       -
## [Description]    Makefile to manage DPI
## [Notes]          
##                  g++ -fPIC -c $(DPI_FILE) -I ${VCS_HOME}/include -o $(DPI_DIR)/dpi.o
##                  -fPIC Flag to generate position-independent code (shared library)
##                  If you want to compile dpi repeatedly and include the .o to simv
##                  but it's better to compile from vcs command
## [Status]         stable
## [Revisions]      -
##==============================================================================
 
# ================================ DIRECTORIES =================================

DPI_SRC_DIR := $(COMMON_DPI_DIR)/src
DPI_OBJ_DIR := $(COMMON_DPI_DIR)/obj
DPI_BIN_DIR := $(COMMON_DPI_DIR)/bin
DPI_INC_DIR := $(COMMON_DPI_DIR)/include
DPI_LIB_DIR := $(COMMON_DPI_DIR)/lib

DPI_DIR_VARS := DPI_SRC_DIR DPI_OBJ_DIR DPI_BIN_DIR DPI_INC_DIR DPI_LIB_DIR

# Compiler and flags
CXX      := g++
CXXFLAGS := -Wall -Wextra -std=c++17 -I $(DPI_INC_DIR)
LDFLAGS  :=

DPI_LIB_NAME ?= libdpi.so

# Output executable
TARGET := $(DPI_BIN_DIR)/app
DPI_WRAPPER = fibonacci_dpi.cpp

# Files
SRCS := $(shell find $(DPI_SRC_DIR) \( -name "*.cpp" -o -name "*.cc" \) ! -name "$(DPI_WRAPPER)")
OBJS := $(patsubst $(DPI_SRC_DIR)/%.cpp, $(DPI_OBJ_DIR)/%.o, $(SRCS))
OBJS := $(patsubst $(DPI_SRC_DIR)/%.cc, $(DPI_OBJ_DIR)/%.o, $(OBJS))

# ================================  TARGETS  ==================================

# Rule to compile source files to object files cpp
$(DPI_OBJ_DIR)/%.o: $(DPI_SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	@printf "$(C_CYN)%s$(C_RST)\n" "Compiled: $< -> $@"
	$(CXX) $(CXXFLAGS) -c $< -o $@
#______________________________________________________________________________
	
# Rule to compile source files to object files
$(DPI_OBJ_DIR)/%.o: $(DPI_SRC_DIR)/%.cc
	@mkdir -p $(dir $@)
	@printf "$(C_CYN)%s$(C_RST)\n" "Compiled: $< -> $@"
	$(CXX) $(CXXFLAGS) -c $< -o $@
#______________________________________________________________________________

# Rule to create the executable
$(TARGET): $(OBJS)
	@mkdir -p $(DPI_BIN_DIR)
	@printf "$(C_CYN)%s$(C_RST)\n" "Linked: $@"
	$(CXX) $(CXXFLAGS) $(OBJS) -o $@ $(LDFLAGS)
#______________________________________________________________________________

.PHONY: build
build: $(TARGET) ## DPI: Build standalone DPI application
#______________________________________________________________________________

.PHONY: run
run: ## DPI: Run standalone DPI application
	@printf "$(C_CYN)%s$(C_RST)\n" "Running $(TARGET)"
	$(TARGET)
#______________________________________________________________________________

.PHONY: build-dpi
build-dpi: ## DPI: Build DPI shared library for VCS
	@printf "$(C_CYN)%s$(C_RST)\n" "Compiling DPI shared library"
	@mkdir -p $(DPI_LIB_DIR)
	$(CXX) -fPIC -shared -std=c++17 -o $(DPI_LIB_DIR)/$(DPI_LIB_NAME) \
	-I ${VCS_HOME}/include -I $(DPI_INC_DIR) \
	$(DPI_SRC_DIR)/fibonacci.cpp \
	$(DPI_SRC_DIR)/$(DPI_WRAPPER)
#______________________________________________________________________________

# ------------------------- PYTHON DPI BACKEND (experimental) ------------------
# Same DPI-C symbol (fibonacci_step), but the recurrence lives in
# fibonacci_model.py and fibonacci_dpi_py.cpp just embeds CPython and calls
# into it. test.sv is unchanged either way. Selected at run time via
# DPI_BACKEND=python in project.mk (see DPI_RUN_FLAGS there).
#
# python3-config must be on PATH (python3-dev / python3-devel package).
PYTHON3        ?= python3
PY_CFLAGS      := $(shell $(PYTHON3)-config --includes 2>/dev/null)
PY_LDFLAGS     := $(shell $(PYTHON3)-config --ldflags --embed 2>/dev/null || $(PYTHON3)-config --ldflags 2>/dev/null)
DPI_PY_WRAPPER ?= fibonacci_dpi_py.cpp
DPI_LIB_NAME_PY ?= libdpi_py.so

.PHONY: build-dpi-py
build-dpi-py: ## DPI: Build DPI shared library with embedded-Python backend
	@printf "$(C_CYN)%s$(C_RST)\n" "Compiling DPI shared library (Python backend)"
	@mkdir -p $(DPI_LIB_DIR)
	$(CXX) -fPIC -shared -std=c++17 -o $(DPI_LIB_DIR)/$(DPI_LIB_NAME_PY) \
	-I ${VCS_HOME}/include -I $(DPI_INC_DIR) $(PY_CFLAGS) \
	$(DPI_SRC_DIR)/$(DPI_PY_WRAPPER) \
	$(PY_LDFLAGS)
#______________________________________________________________________________

.PHONY: clean-dpi
clean-dpi: ## DPI: Remove DPI files
	@printf "$(C_CYN)%s$(C_RST)\n" "Removing compilation files"
	rm -rf $(DPI_OBJ_DIR) $(DPI_BIN_DIR) $(DPI_LIB_DIR)
#______________________________________________________________________________

.PHONY: print-dpi
print-dpi: ## DPI: Print Makefile variables
	$(call print_vars,DPI Directory variables,$(DPI_DIR_VARS))
#______________________________________________________________________________

help-dpi: ## DPI: Displays help message
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "                                       DPI.MK                                   "
	@printf "%s\n" "================================================================================"
	@printf "%s\n" "Usage: make <target> [variables]"
	@printf "%s\n" "------------------------------------ TARGETS -----------------------------------"
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(COMMON_MK_DIR)/dpi.mk | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "- make $(C_CYN)%-15s$(C_RST) %s\n", $$1, $$2}'
	@printf "%s\n" "================================================================================"
#_______________________________________________________________________________