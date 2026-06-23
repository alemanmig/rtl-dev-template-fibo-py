//==============================================================================
// [Filename]     sim.cpp
// [Project]      fibonacci-seq-gen
// [Author]       -
// [Language]     C++
// [Created]      2026
// [Modified]     -
// [Description]  DPI (Direct Programming Interface) simulation
// [Notes]        -
// [Status]       stable
// [Revisions]    -
//==============================================================================

#include <iostream>
#include <cstdio>
#include "fibonacci.h"

int main(int argc, char* argv[]) {
  (void)argc;
  (void)argv;

  // Initialization
  uint32_t width = 32;
  bool rst_n = 0;
  bool enable = 0;

  // Create object
  Fibonacci dut(width);

  std::cout << "Begin of simulation" << "\n";

  // Reset
  rst_n = 0; enable = 0;
  dut.step(rst_n, enable);
  dut.print_state(" RESET ");

  // Reset released, not enabled (hold)
  rst_n = 1; enable = 0;
  dut.step(rst_n, enable);
  dut.print_state(" RESET OFF: ");

  // Execution
  std::string idx;
  rst_n = 1; enable = 1;
  for (std::size_t i = 0; i < 20; i++) {
    idx = std::to_string(i) + " ";
    dut.step(rst_n, enable);
    dut.print_state(" ITER: " + idx);
  }

  rst_n = 1; enable = 0;
  dut.step(rst_n, enable);
  dut.print_state(" HOLD ");

  rst_n = 1; enable = 0;
  dut.step(rst_n, enable);
  dut.print_state(" HOLD ");

  std::cout << "End of simulation" << "\n";

  return 0;
}
