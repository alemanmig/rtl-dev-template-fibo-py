// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module   : fib_gen
// File     : rtl/fibonacci.sv
// ID       : rtl8
// Project  : fibonacci-seq-gen
// Spec     : docs/Specs.md
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Parameterizable Fibonacci sequence generator with synchronous enable and
// asynchronous active-low reset.
//
// The module maintains two state registers (a_q, b_q) implementing the
// recurrence:
//
//   F(0) = 0,  F(1) = 1,  F(n) = F(n-1) + F(n-2)  for n >= 2
//
// State transition on rising clock edge:
//   - reset  : a_q <= 0,  b_q <= 1            → fib_out_o = 0
//   - enable : a_q <= b_q,  b_q <= a_q + b_q  → fib_out_o advances
//   - hold   : a_q <= a_q,  b_q <= b_q        → fib_out_o unchanged
//
// Output convention:
//   fib_out_o is a registered copy of 'a_q', updated on each enabled clock
//   edge. The output is 0 after reset and follows the sequence
//   0,1,1,2,3,5,8,... when enable_i is continuously asserted.
//
// Overflow behaviour:
//   Arithmetic is unsigned and wraps naturally at 2^W. No saturation logic is
//   included. The verification model mirrors this behaviour (see verif_plan.md).
//
// Naming convention:
//   Signal naming follows the lowRISC Verilog Coding Style Guide: module
//   inputs/outputs use _i/_o suffixes, the active-low asynchronous reset uses
//   _ni, and register pairs use _d (next-state) / _q (registered) suffixes.
//
// Parameters
// ----------
//   W : integer — Output and internal register width in bits (default 32).
//
// Ports
// -----
//   clk_i      : i 1   System clock, active on rising edge.
//   rst_ni     : i 1   Asynchronous reset, active-low.
//   enable_i   : i 1   Sequence advance enable, active-high.
//   fib_out_o  : o W   Current Fibonacci value.
//
// -----------------------------------------------------------------------------

`default_nettype none

module fib_gen #(
  parameter int unsigned W = 32
) (
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic          enable_i,
  output logic [W-1:0]  fib_out_o
);

  // ---------------------------------------------------------------------------
  // Signal declarations
  // ---------------------------------------------------------------------------

  // State registers.
  // a_q : holds the current Fibonacci value  → driven to fib_out_o.
  // b_q : holds the next Fibonacci value     → loaded into a_q on next advance.
  logic [W-1:0] a_q, b_q;

  // Combinational next-state for the registers (lowRISC _d/_q convention).
  logic [W-1:0] a_d, b_d;

  // ---------------------------------------------------------------------------
  // Combinational logic — next-state values for a_q and b_q
  //
  // Keeping the next-state computation in always_comb makes the intent
  // explicit and allows synthesis tools to optimise the adder independently.
  // ---------------------------------------------------------------------------
  always_comb begin : comb_next_state
    a_d = b_q;
    b_d = a_q + b_q;
  end

  // ---------------------------------------------------------------------------
  // Sequential logic — state registers a_q and b_q
  //
  // Reset  (asynchronous, active-low): initialise to produce sequence
  //        starting with 0,1,1,2,3,5,...  → a_q=0, b_q=1 so fib_out_o=0 at reset.
  // Enable (synchronous, active-high) : advance the recurrence.
  // Hold   (enable de-asserted)        : retain current state.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin : seq_regs
    if (!rst_ni) begin
      a_q <= '0;                      // fib_out_o = 0 after reset (REQ: RST-001)
      b_q <= {{(W-1){1'b0}}, 1'b1};   // b_q = 1 so next advance yields F(1)=1
    end else if (enable_i) begin
      a_q <= a_d;                     // advance (REQ: SEQ-001)
      b_q <= b_d;                     // advance (REQ: SEQ-002)
    end
    // else: hold — implicit retention of a_q and b_q              (REQ: HLD-001)
  end

  // ---------------------------------------------------------------------------
  // Output assignment
  //
  // fib_out_o is the registered value of 'a_q'. No additional logic on the
  // output path keeps the timing clean and avoids glitches on hold cycles.
  // ---------------------------------------------------------------------------
  assign fib_out_o = a_q;

  // ---------------------------------------------------------------------------
  // Assertions (inline, for simulation only)
  //
  // These are companion checks to the SVA checker in verification/.
  // Synthesis tools should strip them automatically; for explicit exclusion
  // wrap with `ifndef SYNTHESIS ... `endif if required by the flow.
  // ---------------------------------------------------------------------------

  // After reset is released fib_out_o must be 0.
  // RST-001
  `ifndef SYNTHESIS
  assert_rst_out_zero : assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    ($rose(rst_ni) |-> (fib_out_o == '0))
  ) else $error("[fib_gen] RST-001 FAIL: fib_out_o is not 0 after reset release");

  // fib_out_o must not change while enable_i is de-asserted.
  // HLD-001
  assert_hold_stable : assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (!enable_i |=> $stable(fib_out_o))
  ) else $error("[fib_gen] HLD-001 FAIL: fib_out_o changed while enable_i=0");
  `endif

endmodule : fib_gen
 
`default_nettype wire
