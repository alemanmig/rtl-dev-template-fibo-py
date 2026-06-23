//==============================================================================
// [Filename]     fibonacci.h
// [Project]      fibonacci-seq-gen
// [Author]       -
// [Language]     C++
// [Created]      2026
// [Modified]     -
// [Description]  -
// [Notes]        -
// [Status]       stable
// [Revisions]    -
//==============================================================================

#ifndef FIBONACCI_H
#define FIBONACCI_H

#include <iostream>
#include <cstdio>
#include <cstdint>
#include <fstream>

class Fibonacci {
  public:
    Fibonacci(uint32_t width);
    void step(bool rst_n, bool enable);
    void print_state(std::string const& msg = "State");

    uint64_t get_fib_out()   const { return a_q;  }
    uint64_t get_a()         const { return a_q;  }
    uint64_t get_b()         const { return b_q;  }
    uint32_t get_width()     const { return width; }

  private:

    uint32_t width;
    uint64_t mask;

    // State (mirrors RTL registers a_q / b_q in rtl/fibonacci.sv)
    uint64_t a_q = 0;
    uint64_t b_q = 1;
};

/*
 * SystemVerilog DPI-C Data Type Mappings
 * ========================================
 *
 * BASIC DATA TYPES
 * -------------------------------------------------------------------------------
 * SystemVerilog      | C/C++ (svdpi.h)    | Size   | Notes
 * -------------------------------------------------------------------------------
 * byte               | char               | 8-bit  | Signed
 * shortint           | short int          | 16-bit | Signed
 * int                | int                | 32-bit | Signed
 * longint            | long long          | 64-bit | Signed
 * real               | double             | 64-bit | IEEE 754
 * shortreal          | float              | 32-bit | IEEE 754
 * chandle            | void*              | Ptr    | Opaque handle
 * string             | const char*        | Ptr    | Null-terminated
 * bit                | svBit              | 1-bit  | Unsigned
 * logic              | svLogic            | 1-bit  | 4-state (0,1,X,Z)
 *
 * PACKED ARRAYS (VECTORS)
 * -------------------------------------------------------------------------------
 * SystemVerilog      | C/C++ (svdpi.h)    | Notes
 * -------------------------------------------------------------------------------
 * bit [N:0]          | svBitVecVal*       | 2-state vector
 * logic [N:0]        | svLogicVecVal*     | 4-state vector
 *
 * UNPACKED ARRAYS
 * -------------------------------------------------------------------------------
 * SystemVerilog      | C/C++ (svdpi.h)           | Notes
 * -------------------------------------------------------------------------------
 * Open array []      | const svOpenArrayHandle   | Read-only array
 * Open array []      | svOpenArrayHandle         | Writable array
 *
 * SPECIAL TYPES
 * -------------------------------------------------------------------------------
 * Type               | Usage
 * -------------------------------------------------------------------------------
 * svScope            | Get/set current scope
 * svBitVecVal        | Structure for bit vectors
 * svLogicVecVal      | Structure for logic vectors (aval/bval)
 *
 * EXAMPLE USAGE:
 * -------------------------------------------------------------------------------
 * #include "svdpi.h"
 *
 * extern "C" void my_dpi_func(
 *     int a,              // SystemVerilog: int
 *     long long b,        // SystemVerilog: longint
 *     double c,           // SystemVerilog: real
 *     const char* str,    // SystemVerilog: string
 *     void* handle        // SystemVerilog: chandle
 * );
 */

#endif // FIBONACCI_H
