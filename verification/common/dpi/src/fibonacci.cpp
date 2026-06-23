//==============================================================================
// [Filename]     fibonacci.cpp
// [Project]      fibonacci-seq-gen
// [Author]       -
// [Language]     C++
// [Created]      2026
// [Modified]     -
// [Description]  DPI (Direct Programming Interface) model
// [Notes]
//                 reset (rst_n = 0)  -> a_q = 0, b_q = 1  (fib_out_o = 0)
//                 enable             -> a_q <= b_q, b_q <= a_q + b_q
//                 hold (enable = 0)  -> a_q, b_q unchanged
//                 Arithmetic wraps naturally at 2^width, matching the
//                 unsigned wraparound behaviour of rtl/fibonacci.sv.
// [Status]       stable
// [Revisions]    -
//==============================================================================

#include "fibonacci.h"

Fibonacci::Fibonacci(uint32_t width)
  : width(width),
    mask(width >= 64 ? ~0ULL : ((1ULL << width) - 1ULL))
{
  a_q = 0;
  b_q = 1ULL & mask;
}

void Fibonacci::step(bool rst_n, bool enable) {

  if (!rst_n) {
    a_q = 0;
    b_q = 1ULL & mask;
  } else if (enable) {
    uint64_t a_d = b_q;
    uint64_t b_d = (a_q + b_q) & mask;

    a_q = a_d;
    b_q = b_d;
  }
  // else: hold - a_q, b_q unchanged
}


void Fibonacci::print_state(std::string const& msg) {
  std::cout << "\n================" << msg << "==============\n";
  printf("Width:            0d%04u\n", width);
  printf("a_q (fib_out_o):  0d%llu\n", (unsigned long long)a_q);
  printf("b_q (next):       0d%llu\n", (unsigned long long)b_q);
}
