#!/usr/bin/env python3
#==============================================================================
# [Filename]     fibonacci_model.py
# [Project]      fibonacci-seq-gen
# [Language]     Python 3
# [Created]      2026
# [Description]  Pure-Python reference model for the Fibonacci DPI step.
#                 Bit-for-bit port of verification/common/dpi/src/fibonacci.cpp
#                 (the `Fibonacci` C++ class):
#
#                   reset (rst_n = 0)  -> a_q = 0, b_q = 1  (fib_out_o = 0)
#                   enable             -> a_q <= b_q, b_q <= a_q + b_q
#                   hold (enable = 0)  -> a_q, b_q unchanged
#
#                 Arithmetic wraps naturally at 2^WIDTH, matching the unsigned
#                 wraparound behaviour of rtl/fibonacci.sv and of the C++
#                 model (Python ints don't overflow on their own, so the mask
#                 is applied explicitly after every add).
#
#                 Called from fibonacci_dpi_py.cpp via the embedded CPython
#                 interpreter -- this module is never run by VCS/simv itself,
#                 it is imported into the simv process.
# [Notes]         WIDTH is fixed at 32 to match config_pkg::FibW, mirroring
#                 the C++ model's `static Fibonacci g_dut(32);`.
# [Status]        experimental (DPI_BACKEND=python)
#==============================================================================

WIDTH = 32
MASK = (1 << WIDTH) - 1

# Module-level state == g_dut in fibonacci_dpi.cpp (one persistent instance
# for the lifetime of the simv process / embedded interpreter).
_a_q = 0
_b_q = 1 & MASK


def step(rst_n: int, enable: int) -> int:
    """Advance one clock cycle; mirrors Fibonacci::step(). Returns fib_out
    (== a_q) as an unsigned WIDTH-bit int, exactly like get_fib_out()."""
    global _a_q, _b_q

    if not rst_n:
        _a_q = 0
        _b_q = 1 & MASK
    elif enable:
        a_d = _b_q
        b_d = (_a_q + _b_q) & MASK
        _a_q = a_d
        _b_q = b_d
    # else: hold - a_q, b_q unchanged

    return _a_q


def get_state():
    """Debug helper, analogous to Fibonacci::print_state()."""
    return {"width": WIDTH, "a_q": _a_q, "b_q": _b_q}


if __name__ == "__main__":
    # Standalone sanity check: `python3 fibonacci_model.py`
    # Reproduces the classic 0,1,1,2,3,5,8,... sequence.
    print(step(0, 0))           # reset -> 0
    for _ in range(15):
        print(step(1, 1))
