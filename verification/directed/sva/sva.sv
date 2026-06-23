// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module  : sva
// File    : verification/directed/sva/sva.sv
// Project : fibonacci-seq-gen
// Spec    : docs/verif_plan.md (Section 4.2)
// -----------------------------------------------------------------------------
//
// Description
// -----------
// SystemVerilog Assertions (SVA) checker for the fibonacci DUT (fib_gen).
// Instantiated via bind in tb.sv inside the DUT scope, giving direct
// visibility of both ports and internal state registers (a_q, b_q).
//
// Assertion map 
// ─────────────────────────────────────────────────────────────────────────────
//  ID            | Requirement | Type    | Description
// ───────────────┼─────────────┼─────────┼─────────────────────────────────────
//  AST_RST_ASYNC | RST-001     | assert  | rst_ni low → fib_out_o = 0 (async)
//  AST_RST_A     | RST-001     | assert  | rst_ni low → a_q = 0 (async)
//  AST_RST_B     | RST-002     | assert  | rst_ni low → b_q = 1 (async)
//  AST_SEQ_A     | SEQ-001     | assert  | enable_i → a_q takes prev b_q (1-cycle)
//  AST_SEQ_B     | SEQ-002     | assert  | enable_i → b_q = prev_a_q + prev_b_q
//  AST_HOLD_OUT  | HLD-001     | assert  | !enable_i → fib_out_o stable
//  AST_HOLD_B    | HLD-001     | assert  | !enable_i → b_q stable
//  COV_EN_RISE   | —           | cover   | enable_i 0→1 transition observed
//  COV_EN_FALL   | —           | cover   | enable_i 1→0 transition observed
//  COV_RST_ASRT  | —           | cover   | rst_ni asserted (1→0)
//  COV_RST_REL   | —           | cover   | rst_ni released (0→1)
//  COV_EN_HOLD3  | HLD-001     | cover   | enable_i=0 for at least 3 cycles
//  COV_OVERFLOW  | OVF-001     | cover   | wrap-around: out[n] < out[n-1]
//                |             |         | while enable_i was high
// ─────────────────────────────────────────────────────────────────────────────
//
// Notes
// -----
// • All synchronous assert properties use "disable iff (!rst_ni)" so they
//   are vacuously true during reset and only fire during normal operation.
// • Async-reset assertions clock on (posedge clk_i or negedge rst_ni) so
//   they fire immediately when rst_ni falls — not just at the next posedge.
// • The module is bound in the DUT scope; a_i and b_i connect directly to
//   the DUT's internal registers a_q and b_q (see bind statement in tb.sv).
// • Port names follow the lowRISC _i/_o/_ni suffix convention, matching
//   rtl/fibonacci.sv exactly.
//
// -----------------------------------------------------------------------------

`default_nettype none

module sva #(
  parameter int unsigned W = 32
) (
  input logic          clk_i,
  input logic          rst_ni,
  input logic          enable_i,
  input logic [W-1:0]  fib_out_o,  // DUT port  — equals register a_q
  input logic [W-1:0]  a_i,        // DUT internal register a_q
  input logic [W-1:0]  b_i         // DUT internal register b_q
);

  // ---------------------------------------------------------------------------
  // Default clocking and disable condition for synchronous properties
  // ---------------------------------------------------------------------------
  default clocking cb @(posedge clk_i); endclocking
  default disable iff (!rst_ni);

  // ===========================================================================
  // 1. Reset assertions  (clocked on posedge OR negedge rst_ni — async)
  // ===========================================================================

  // AST_RST_ASYNC — RST-001
  // As soon as rst_ni falls (asynchronous), fib_out_o must be 0 immediately.
  // Clocking on both edges captures the async response without waiting for
  // the next posedge clk_i.
  ast_rst_async : assert property (
    @(posedge clk_i or negedge rst_ni)
    !rst_ni |-> (fib_out_o == '0)
  ) else $error("[SVA] AST_RST_ASYNC FAIL  t=%0t  fib_out_o=%0d (expected 0)",
                $realtime, fib_out_o);

  // AST_RST_A — RST-001
  // Internal register a_q must also be 0 during reset.
  ast_rst_a : assert property (
    @(posedge clk_i or negedge rst_ni)
    !rst_ni |-> (a_i == '0)
  ) else $error("[SVA] AST_RST_A FAIL  t=%0t  a=%0d (expected 0)",
                $realtime, a_i);

  // AST_RST_B — RST-002
  // Internal register b_q must be 1 during reset so the first enabled
  // advance produces F(1) = 1.
  ast_rst_b : assert property (
    @(posedge clk_i or negedge rst_ni)
    !rst_ni |-> (b_i == W'(1))
  ) else $error("[SVA] AST_RST_B FAIL  t=%0t  b=%0d (expected 1)",
                $realtime, b_i);

  // ===========================================================================
  // 2. Sequence advancement assertions  (synchronous, disabled during reset)
  // ===========================================================================

  // AST_SEQ_A — SEQ-001
  // One cycle after enable_i is asserted, register a_q must equal the
  // previous value of b_q: implements the recurrence a_q(n) <= b_q(n-1).
  ast_seq_a : assert property (
    enable_i |=> (a_i == $past(b_i))
  ) else $error("[SVA] AST_SEQ_A FAIL  t=%0t  a=%0d  expected $past(b)=%0d",
                $realtime, a_i, $past(b_i));

  // AST_SEQ_B — SEQ-002
  // One cycle after enable_i is asserted, register b_q must equal
  // $past(a_q)+$past(b_q), verifying the Fibonacci recurrence
  // F(n) = F(n-1) + F(n-2) at register level.
  ast_seq_b : assert property (
    enable_i |=> (b_i == ($past(a_i) + $past(b_i)))
  ) else $error("[SVA] AST_SEQ_B FAIL  t=%0t  b=%0d  expected %0d+%0d=%0d",
                $realtime, b_i, $past(a_i), $past(b_i),
                $past(a_i) + $past(b_i));

  // ===========================================================================
  // 3. Hold / stability assertions  (synchronous, disabled during reset)
  // ===========================================================================

  // AST_HOLD_OUT — HLD-001
  // When enable_i is de-asserted, fib_out_o must not change on the next clock.
  ast_hold_out : assert property (
    !enable_i |=> $stable(fib_out_o)
  ) else $error("[SVA] AST_HOLD_OUT FAIL  t=%0t  fib_out_o changed during hold",
                $realtime);

  // AST_HOLD_B — HLD-001
  // Internal register b_q must also remain stable while enable_i is low,
  // guaranteeing the full state is frozen — not just the observable output.
  ast_hold_b : assert property (
    !enable_i |=> $stable(b_i)
  ) else $error("[SVA] AST_HOLD_B FAIL  t=%0t  b changed during hold",
                $realtime);

  // ===========================================================================
  // 4. Cover properties — witness that all interesting scenarios were reached
  // ===========================================================================

  // COV_EN_RISE — enable_i observed going 0 → 1
  cov_en_rise : cover property (
    $rose(enable_i)
  );

  // COV_EN_FALL — enable_i observed going 1 → 0
  cov_en_fall : cover property (
    $fell(enable_i)
  );

  // COV_RST_ASRT — reset asserted at least once (rst_ni 1 → 0)
  cov_rst_asrt : cover property (
    @(posedge clk_i) $fell(rst_ni)
  );

  // COV_RST_REL — reset released at least once (rst_ni 0 → 1)
  cov_rst_rel : cover property (
    @(posedge clk_i) $rose(rst_ni)
  );

  // COV_EN_HOLD3 — enable_i held low for at least 3 consecutive cycles,
  // confirming a meaningful hold scenario was exercised.
  cov_en_hold3 : cover property (
    (!enable_i) ##1 (!enable_i) ##1 (!enable_i)
  );

  // COV_OVERFLOW — modular wrap-around observed while advancing.
  // When enable_i is active and fib_out_o decreases (unsigned), the output
  // has wrapped around 2^W — exercising the OVF-001 requirement.
  cov_overflow : cover property (
    enable_i ##1 (enable_i && (fib_out_o < $past(fib_out_o)))
  );

endmodule : sva

`default_nettype wire
