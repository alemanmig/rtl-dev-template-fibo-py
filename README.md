# RTL Development Template

## Overview

The RTL Development Template provides a structured and maintainable framework
for RTL design and digital verification projects.

The main goal of this template is to provide a unified entry point for both RTL
and Design Verification (DV) engineers. It offers a common project structure and
a compatible build flow for both traditional directed verification and Universal
Verification Methodology (UVM)-based verification environments.

The template is built around a modular Makefile-based architecture. Common
activities such as compilation, simulation, waveform dumping, coverage
collection, assertion control, DPI integration, and regression execution are
centralized and controlled through configurable project variables.

## Motivation

In many RTL verification projects, different teams work on different parts of
the environment at the same time. For example, one engineer may be developing
C/C++ DPI models, another may be working on UVM components, while another may be
debugging RTL or running regressions.

This template is designed to support that workflow by keeping each part of the
project modular and independent, while still allowing everything to integrate
cleanly through a common build and simulation infrastructure.

The framework allows engineers to work on:

- RTL source code
- Directed testbenches
- UVM environments
- UVC integration
- C/C++ DPI components
- Coverage setup
- Regression infrastructure

without requiring each team member to manually modify compile commands or
duplicate project-specific Makefile logic.

## Key Features

- Unified Makefile flow for directed and UVM verification
- Modular project architecture
- Support for Synopsys VCS and Verdi-based debug flows
- Configurable compile-time and run-time options
- Optional UVM compilation support
- Optional C/C++ DPI integration
- Optional UVC filelist integration
- Independent control of debug database generation
- Independent control of compile-time and run-time code coverage
- Optional SVA compilation and run-time reporting
- Configurable waveform dumping modes
- Support for multiple simulation binaries
- Support for multiple simulation jobs and output directories
- Regression-friendly project organization

## Build and Run Concept

The template separates the flow into two main stages:

1. **Compile time**
2. **Run time**

Compile-time variables control how the simulation executable is built. These
options include the timescale, UVM support, debug database generation, coverage
instrumentation, assertion compilation, DPI libraries, filelists, and the name of
the generated simulation binary.

Run-time variables control how the compiled simulation executable is executed.
These options include the UVM test name, verbosity, seed configuration, waveform
dumping mode, UVM recording, coverage collection during simulation, assertion
reporting, job name, and additional run arguments.

This separation makes it possible to generate multiple simulation binaries with
different compile-time configurations and then execute multiple simulation jobs
using different run-time configurations.

For example, the same project can support:

- A fast regression build with minimal debug information
- A debug build with Verdi database generation enabled
- A coverage build with code coverage instrumentation
- A gate-level build using a different filelist
- Multiple simulation runs using different seeds and tests

## Getting Started

To get started, refer to the appropriate verification flow:

- [Directed Verification Instructions](verification/directed/README.md)
- [UVM Verification Instructions](verification/uvm/README.md)

These documents explain how to set up the environment and run simulations using
the directed or UVM-based flows.

> Note: make sure the UVM path is correct. In the original text it was written as
> `verification/ucm/README.md`, but it should probably be
> `verification/uvm/README.md`.

## Configuration Variables

The project behavior is controlled using Makefile variables. These variables can
be overridden from the command line to customize the compile and run flow.

Example:

```bash
make compile ENABLE_DEBUG_DB=false ENABLE_CODE_COV_COMPILE=true
make run TEST=top_test SEED_MODE=fixed SEED=5081996 JOB_NAME=debug
```


## Compile-Time Variables


| Variable                  | Description                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| `TIMESCALE`               | Simulation timescale in Verilog format, for example `1ns/1ps`.                                 |
| `ENABLE_UVM`              | Enables UVM support during compilation. Valid values: `true`, `false`.                         |
| `UVM_VERSION`             | Selects the UVM version to compile. Valid values: `1.2`, `1.1`.                                |
| `ENABLE_DEBUG_DB`         | Enables generation of debug database files for Verdi. Valid values: `true`, `false`.           |
| `DEFINES`                 | Additional Verilog/SystemVerilog defines passed to VCS.                                        |
| `COMPILE_ARGS`            | Additional arguments passed to the VCS compile command.                                        |
| `SIMV_NAME`               | Name of the generated simulation executable.                                                   |
| `ENABLE_CODE_COV_COMPILE` | Enables code coverage instrumentation during compilation. Valid values: `true`, `false`.       |
| `CODE_COV_TYPES_COMPILE`  | Code coverage types enabled during compilation, for example `line+cond+fsm+branch+tgl+assert`. |
| `ENABLE_SVA_COMPILE`      | Enables SVA compilation support in VCS. Valid values: `true`, `false`.                         |
| `UVCS_FILELIST`           | Optional UVC filelist passed to VCS. Empty by default.                                         |
| `DPI_FILE`                | Optional DPI shared library passed to VCS. Empty by default.                                   |


## Run-Time Variables


| Variable               | Description                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `TEST`                 | Name of the UVM test to run.                                                                                             |
| `VERBOSITY`            | UVM verbosity level used during simulation.                                                                              |
| `SEED_MODE`            | Random seed mode. Valid values: `auto`, `fixed`.                                                                         |
| `SEED`                 | Simulation random seed. Used only when `SEED_MODE=fixed`.                                                                |
| `ENABLE_UVM_RECORDING` | Enables UVM transaction and object recording. Valid values: `true`, `false`.                                             |
| `ENABLE_CODE_COV_RUN`  | Enables code coverage collection during simulation. Valid values: `true`, `false`.                                       |
| `CODE_COV_TYPES_RUN`   | Code coverage types enabled during simulation, for example `line+cond+fsm+branch+tgl+assert`.                            |
| `ENABLE_SVA_RUN`       | Enables SVA run-time reporting and control. Valid values: `true`, `false`.                                               |
| `DUMP_MODE`            | Selects the waveform dump configuration/script. Valid values: `all`, `default`, `none`. Requires `ENABLE_DEBUG_DB=true`. |
| `JOB_NAME`             | Name of the simulation job and output directory.                                                                         |
| `RUN_ARGS`             | Additional run-time arguments passed to the simulation executable.                                                       |


## Example Configuration

The following is an example configuration printed by the project Makefile.

```plain
---------------------------------- COMPILE TIME --------------------------------
  TIMESCALE                 = 1ps/100fs
  ENABLE_UVM                = true
  UVM_VERSION               = 1.2
  ENABLE_DEBUG_DB           = true
  DEFINES                   =
  COMPILE_ARGS              =
  SIMV_NAME                 = simv
  ENABLE_CODE_COV_COMPILE   = true
  CODE_COV_TYPES_COMPILE    = line+cond+tgl
  ENABLE_SVA_COMPILE        = false
  UVCS_FILELIST             = -F verification/uvm/uvcs.f
  DPI_FILE                  = verification/common/dpi/lib/libdpi.so

------------------------------------ RUN TIME ----------------------------------
  TEST                      = top_test
  VERBOSITY                 = UVM_MEDIUM
  SEED_MODE                 = fixed
  SEED                      = 5081996
  ENABLE_UVM_RECORDING      = false
  ENABLE_CODE_COV_RUN       = true
  CODE_COV_TYPES_RUN        = line+cond+tgl
  ENABLE_SVA_RUN            = false
  DUMP_MODE                 = all
  JOB_NAME                  = debug
  RUN_ARGS                  = +uvm_set_config_int=uvm_test_top.m_env.vsqr,m_cli_iter,300
```


## Debug and Regression Usage

The template can be used to emulate regression behavior manually by changing the
project variables from the command line. This allows the user to create multiple
simulation binaries and run multiple simulation jobs with different
configurations.

For example, users can control:

- Which test is executed
- Which seed is used
- Which waveform dump mode is enabled
- Whether UVM recording is enabled
- Whether coverage is collected
- Whether assertions are enabled
- Which binary is used
- Which output directory is generated

This makes the framework useful for both interactive debugging and regression
execution.

For faster simulations, debug database generation, waveform dumping, UVM
recording, and coverage collection can be disabled when they are not required.
For deeper debug, these options can be enabled independently without modifying
the testbench source code or the core Makefile logic.