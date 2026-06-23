# How to use it?

This project is **directed-only** — there is no UVM environment here (and none
is planned). All commands below target `verification/directed`.

1. Copy your `setup_synopsys_eda.sh` (or `.tcsh`) file — it sets up your VCS/
   Verdi toolchain env vars and is gitignored, so it's safe to drop in:

```bash
cp $HOME/snps_scripts/setup_synopsys_eda.sh verification/common/setup
```

2. The first time, from the repo root run:

```bash
# bash
source verification/directed/scripts/setup/setup_tb.sh
# tcsh
source verification/directed/scripts/setup/setup_tb.tcsh
```

> Remember: this should be run JUST ONCE per shell session.

This creates `work/tb/`, symlinks `verification/directed/scripts/mk/project.mk`
there as `Makefile`, and sources `setup_synopsys_eda.sh`. From then on, run
`make <target>` from inside `work/tb/`.

The user needs to modify just:
- `verification/directed/scripts/mk/project.mk`
- `verification/directed/tb.f`
- `verification/directed/tests/test.sv` (and `sva/sva.sv`, `sva/fcover.sv` as needed)

Touch only if you know what you are doing:
- `verification/common/mk/common.mk`

## Control variables

Defaults below are `common.mk`'s, with `project.mk`'s overrides noted.

```plain
TEST                    = top_test
VERBOSITY               = UVM_MEDIUM
TIMESCALE               = 1ps/100fs
ENABLE_DEBUG_DB         = true            # project.mk override (common.mk default: false)
ENABLE_UVM              = false           # untouched — no UVM env in this project
ENABLE_UVM_RECORDING    = false
CODE_COV_TYPES_COMPILE  = line+cond+tgl   # project.mk override
CODE_COV_TYPES_RUN      = line+cond+tgl   # project.mk override
ENABLE_CODE_COV_COMPILE = true            # project.mk override (common.mk default: false)
ENABLE_CODE_COV_RUN     = true            # project.mk override (common.mk default: false)
ENABLE_SVA_COMPILE      = true            # project.mk override (common.mk default: false)
ENABLE_SVA_RUN          = true            # project.mk override (common.mk default: false)
SEED_MODE               = fixed
SEED                    = 5081996
DUMP_MODE               = default         # project.mk override (common.mk default: none)
DEFINES                 =
COMPILE_ARGS            =
RUN_ARGS                =
SIMV_NAME               = simv2           # project.mk override (common.mk default: simv)
JOB_NAME                = miguel_test     # project.mk override (common.mk default: debug)
UVCS_FILELIST           =                 # empty — no UVCs, directed-only
DPI_FILE                =                 # empty by default; set to link the DPI-C reference model (see verification/common/dpi)
```

## Typical flow

```bash
cd work/tb
make compile           # builds simv2 with coverage + SVA compiled in
make sim TEST=top_test # runs it, writes a run manifest + coverage db
make cov-latest        # urg report from the latest run
make verdi-cov         # opens the coverage report in Verdi
```

`make help`, `make help-common`, and `make help-cov` list every target and
variable group.
