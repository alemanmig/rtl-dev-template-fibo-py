//==============================================================================
// [Filename]     fibonacci_dpi.cpp
// [Project]      fibonacci-seq-gen
// [Author]       -
// [Language]     C++
// [Created]      2026
// [Modified]     -
// [Description]  DPI-C wrapper exposing the Fibonacci reference model
//                 (Fibonacci class) to SystemVerilog via "import DPI-C".
// [Notes]         g_dut is fixed at width = 32 to match config_pkg::FibW.
//                 If fib_gen is instantiated with a different W, rebuild
//                 this file with a matching width.
// [Status]       stable
// [Revisions]    -
//==============================================================================

#include "svdpi.h"
#include "fibonacci.h"

static Fibonacci g_dut(32);

extern "C" void fibonacci_step(
    svBit rst_n,
    svBit enable,
    unsigned int* fib_out
) {
    g_dut.step(static_cast<bool>(rst_n), static_cast<bool>(enable));
    *fib_out = static_cast<unsigned int>(g_dut.get_fib_out());
}
