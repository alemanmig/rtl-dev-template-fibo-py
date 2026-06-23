// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module  : test
// File    : verification/directed/tests/test.sv
// Project : fibonacci-seq-gen
// Spec    : docs/test_plan.md, docs/verif_plan.md
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Directed test module for the fibonacci DUT. Implements all test cases
// defined in test_plan.md and compares the DUT output against an inline
// reference model (golden model) on every checked cycle.
//
// Signal names accessed through the virtual interface (vif.clk_i, vif.rst_ni,
// vif.enable_i, vif.fib_out_o) match the DUT ports exactly, following the
// lowRISC Verilog Coding Style Guide's _i/_o/_ni suffix convention.
//
// Test cases executed (in order): 
//   TC-RST-01 — Async reset from arbitrary state
//   TC-RST-02 — Reset independent of enable
//   TC-RST-03 — Correct sequence after reset release
//   TC-SEQ-01 — Continuous enable: full sequence check
//   TC-SEQ-02 — F(n) = F(n-1) + F(n-2) property
//   TC-SEQ-03 — Single-cycle pulsed enable
//   TC-HLD-01 — Hold stable for N cycles
//   TC-HLD-02 — Resume from held value
//   TC-HLD-03 — Reset during hold dominates
//   TC-OVF-01 — Wrap-around at 2^W (natural overflow)
//   TC-OVF-02 — Continuity after overflow
//
// Reference model
// ---------------
// ref_a / ref_b mirror the DUT state registers (a_q, b_q) using identical
// reset and advance rules. check_output() asserts DUT fib_out_o == ref_a
// every call.
//
// DPI-C reference model
// ----------------------
// fibonacci_step() (verification/common/dpi/src/fibonacci.cpp /
// fibonacci_dpi.cpp) is a second, fully independent C++ implementation of the
// same recurrence. It is kept in lockstep with ref_a/ref_b inside ref_reset()
// / ref_step(), and check_output() / check_value() also assert DUT
// fib_out_o == dpi_fib_out. A real bug that happened to also be present in
// the inline SV reference model would still be caught by this cross-check.
//
// -----------------------------------------------------------------------------

module test #(
  parameter int unsigned W = 32
) (
  vif_if vif
);

  import config_pkg::*;

  // ---------------------------------------------------------------------------
  // DPI-C reference model
  //
  // Independent C++ implementation of the recurrence (see
  // verification/common/dpi/src/fibonacci.cpp). g_dut on the C++ side is
  // fixed at width=32 (matches config_pkg::FibW); dpi_fib_out is masked to
  // [W-1:0] at the comparison site so this still works if W is ever reduced.
  // ---------------------------------------------------------------------------
  import "DPI-C" function void fibonacci_step(
    input  bit          rst_n,
    input  bit          enable,
    output int unsigned fib_out
  );

  int unsigned dpi_fib_out;

  // ---------------------------------------------------------------------------
  // Reference model state
  // ---------------------------------------------------------------------------
  logic [W-1:0] ref_a, ref_b, ref_next_b;

  // Error and pass counters (reported at end of simulation).
  int unsigned  err_count  = 0;
  int unsigned  chk_count  = 0;

  // ---------------------------------------------------------------------------
  // Main sequence
  // ---------------------------------------------------------------------------
  initial begin
    $display("─────────────────────────────────────────────────────");
    $display("[TEST] Begin of Simulation  (W=%0d)", W);
    $display("─────────────────────────────────────────────────────");

    initialize_signals();

    // ── Reset group ──────────────────────────────────────────
    tc_rst_01();
    tc_rst_02();
    tc_rst_03();

    // ── Sequence group ────────────────────────────────────────
    tc_seq_01();
    tc_seq_02();
    tc_seq_03();

    // ── Hold group ────────────────────────────────────────────
    tc_hld_01();
    tc_hld_02();
    tc_hld_03();

    // ── Overflow group ────────────────────────────────────────
    tc_ovf_01();
    tc_ovf_02();

    // ── Final report ──────────────────────────────────────────
    repeat (4) @(posedge vif.clk_i);
    $display("─────────────────────────────────────────────────────");
    $display("[TEST] End of Simulation");
    $display("[TEST] Checks : %0d  |  Errors : %0d", chk_count, err_count);
    if (err_count == 0)
      $display("[TEST] *** ALL TESTS PASSED ***");
    else
      $display("[TEST] *** %0d TEST(S) FAILED ***", err_count);
    $display("─────────────────────────────────────────────────────");
    $finish;
  end

  // ===========================================================================
  // Reference model tasks
  // ===========================================================================

  // Reset the reference model (mirrors DUT reset state).
  task automatic ref_reset();
    ref_a = '0;
    ref_b = W'(1);
    fibonacci_step(1'b0, 1'b0, dpi_fib_out);  // keep DPI model in lockstep
  endtask : ref_reset

  // Advance the reference model one step (mirrors DUT enable path).
  task automatic ref_step();
    ref_next_b = ref_a + ref_b;
    ref_a      = ref_b;
    ref_b      = ref_next_b;
    fibonacci_step(1'b1, 1'b1, dpi_fib_out);  // keep DPI model in lockstep
  endtask : ref_step

  // ===========================================================================
  // Scoreboard / checker
  // ===========================================================================

  // Compare DUT output against the reference model.
  // Call AFTER the clock edge that produces the expected output.
  task automatic check_output(input string tc_name);
    chk_count++;
    if (vif.fib_out_o !== ref_a) begin
      err_count++;
      $display("[FAIL] %s | t=%0t | fib_out_o=%0d  expected=%0d",
               tc_name, $realtime, vif.fib_out_o, ref_a);
    end else if (vif.fib_out_o !== dpi_fib_out[W-1:0]) begin
      err_count++;
      $display("[FAIL] %s (DPI mismatch) | t=%0t | fib_out_o=%0d  dpi=%0d",
               tc_name, $realtime, vif.fib_out_o, dpi_fib_out[W-1:0]);
    end else begin
      $display("[PASS] %s | t=%0t | fib_out_o=%0d", tc_name, $realtime, vif.fib_out_o);
    end
  endtask : check_output

  // Check that fib_out_o equals an explicit expected value (no ref model).
  task automatic check_value(input string tc_name, input logic [W-1:0] expected);
    chk_count++;
    if (vif.fib_out_o !== expected) begin
      err_count++;
      $display("[FAIL] %s | t=%0t | fib_out_o=%0d  expected=%0d",
               tc_name, $realtime, vif.fib_out_o, expected);
    end else if (vif.fib_out_o !== dpi_fib_out[W-1:0]) begin
      err_count++;
      $display("[FAIL] %s (DPI mismatch) | t=%0t | fib_out_o=%0d  dpi=%0d",
               tc_name, $realtime, vif.fib_out_o, dpi_fib_out[W-1:0]);
    end else begin
      $display("[PASS] %s | t=%0t | fib_out_o=%0d", tc_name, $realtime, vif.fib_out_o);
    end
  endtask : check_value

  // ===========================================================================
  // Utility tasks
  // ===========================================================================

  task automatic initialize_signals();
    vif.rst_ni      = 1'b1;
    vif.enable_i <= 1'b0;
  endtask : initialize_signals

  // Apply asynchronous reset for reset_cycles clock periods, then release.
  task automatic apply_reset(input int unsigned reset_cycles = 2);
    vif.rst_ni = 1'b0;          // assert reset immediately (asynchronous)
    ref_reset();
    repeat (reset_cycles) @(posedge vif.clk_i);
    #1ns;                        // small delay to avoid race on release edge
    vif.rst_ni = 1'b1;
  endtask : apply_reset

  // Drive enable for N cycles and advance the reference model in lockstep.
  task automatic drive_enable(
    input int unsigned cycles,
    input string       tc_name  = "unnamed",
    input logic        check    = 1'b1
  );
    repeat (cycles) begin
      vif.enable_i <= 1'b1;
      @(posedge vif.clk_i);
      #1step;                    // wait past clock edge before sampling
      ref_step();
      if (check) check_output(tc_name);
    end
  endtask : drive_enable

  // Deassert enable and hold for N cycles; ref model should not advance.
  task automatic drive_hold(
    input int unsigned cycles,
    input string       tc_name = "unnamed",
    input logic        check   = 1'b1
  );
    logic [W-1:0] held_val;
    vif.enable_i <= 1'b0;
    @(posedge vif.clk_i);
    #1step;
    held_val = vif.fib_out_o;   // capture value to check stability
    repeat (cycles - 1) begin
      @(posedge vif.clk_i);
      #1step;
      if (check) begin
        chk_count++;
        if (vif.fib_out_o !== held_val) begin
          err_count++;
          $display("[FAIL] %s (hold) | t=%0t | fib_out_o changed: %0d → %0d",
                   tc_name, $realtime, held_val, vif.fib_out_o);
        end else begin
          $display("[PASS] %s (hold) | t=%0t | fib_out_o stable=%0d",
                   tc_name, $realtime, vif.fib_out_o);
        end
      end
    end
  endtask : drive_hold

  // ===========================================================================
  // Test cases
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // TC-RST-01 — Asynchronous reset from arbitrary state
  //
  // Goal    : Assert rst_ni=0 while DUT is running; fib_out_o must go to 0
  //           immediately (asynchronous), without waiting for a clock edge.
  // Req     : RST-001
  // ---------------------------------------------------------------------------
  task automatic tc_rst_01();
    $display("\n[TEST] TC-RST-01 — Async reset from arbitrary state");
    // Reach an advanced state first.
    apply_reset();
    drive_enable(6, "TC-RST-01-advance", .check(1'b0));
    vif.enable_i <= 1'b0;

    // Assert reset asynchronously (between clock edges).
    #3ns;
    vif.rst_ni = 1'b0;
    ref_reset();
    #1ns;
    // Sample immediately — must be 0 without waiting for posedge.
    check_value("TC-RST-01", '0);

    // Release reset.
    @(posedge vif.clk_i);
    #1ns;
    vif.rst_ni = 1'b1;
  endtask : tc_rst_01

  // ---------------------------------------------------------------------------
  // TC-RST-02 — Reset independent of enable
  //
  // Goal    : Reset asserted while enable_i=0; fib_out_o must still become 0.
  // Req     : RST-001
  // ---------------------------------------------------------------------------
  task automatic tc_rst_02();
    $display("\n[TEST] TC-RST-02 — Reset independent of enable");
    // Reach state: a_q=13, b_q=21 (F(6)/F(7) with default W).
    apply_reset();
    drive_enable(6, "TC-RST-02-advance", .check(1'b0));

    // Deassert enable then assert reset.
    vif.enable_i <= 1'b0;
    @(posedge vif.clk_i);
    vif.rst_ni = 1'b0;
    ref_reset();
    #1ns;
    check_value("TC-RST-02", '0);

    @(posedge vif.clk_i);
    #1ns;
    vif.rst_ni = 1'b1;
  endtask : tc_rst_02

  // ---------------------------------------------------------------------------
  // TC-RST-03 — Correct sequence after reset release
  //
  // Goal    : After releasing reset with enable_i=1, sequence must be
  //           0, 1, 1, 2, 3, 5, 8, 13  (first 8 values, F(0)..F(7)).
  // Req     : RST-002
  // ---------------------------------------------------------------------------
  task automatic tc_rst_03();
    $display("\n[TEST] TC-RST-03 — Correct sequence after reset release");
    apply_reset();
    // fib_out_o = 0 immediately after reset (ref_a = 0).
    check_value("TC-RST-03[F0=0]", '0);
    // Drive 7 enable cycles → F(1)..F(7).
    drive_enable(7, "TC-RST-03");
  endtask : tc_rst_03

  // ---------------------------------------------------------------------------
  // TC-SEQ-01 — Continuous enable: full sequence check (12 values)
  //
  // Goal    : With enable_i=1 continuously the DUT must match the golden model
  //           for 12 consecutive cycles starting from reset.
  // Req     : SEQ-001
  // ---------------------------------------------------------------------------
  task automatic tc_seq_01();
    $display("\n[TEST] TC-SEQ-01 — Continuous enable, 12 cycles");
    apply_reset();
    drive_enable(12, "TC-SEQ-01");
  endtask : tc_seq_01

  // ---------------------------------------------------------------------------
  // TC-SEQ-02 — F(n) = F(n-1) + F(n-2) property (20 cycles, W=16 values)
  //
  // Goal    : Verify the additive recurrence property at every step by keeping
  //           a rolling window of the last two outputs and checking the sum.
  // Req     : SEQ-002
  // ---------------------------------------------------------------------------
  task automatic tc_seq_02();
    logic [W-1:0] prev1, prev2, expected_sum;
    int unsigned  local_i;
    $display("\n[TEST] TC-SEQ-02 — Recurrence F(n)=F(n-1)+F(n-2), 20 cycles");
    apply_reset();

    prev2 = '0;          // F(-1) virtual seed
    prev1 = '0;          // F(0)
    local_i = 0;

    repeat (20) begin
      vif.enable_i <= 1'b1;
      @(posedge vif.clk_i);
      #1step;
      ref_step();
      // After the first two steps the sum relationship is verifiable.
      expected_sum = prev1 + prev2;   // F(n-1)+F(n-2), wraps at 2^W
      chk_count++;
      if (local_i >= 2) begin         // skip first two seed steps (LOCAL to this task,
                                       // not the global chk_count, which is already
                                       // >2 from prior test cases by the time we get here)
        if (vif.fib_out_o !== expected_sum) begin
          err_count++;
          $display("[FAIL] TC-SEQ-02 | t=%0t | out=%0d  prev1=%0d  prev2=%0d  sum=%0d",
                   $realtime, vif.fib_out_o, prev1, prev2, expected_sum);
        end else begin
          $display("[PASS] TC-SEQ-02 | t=%0t | F(n)=%0d = %0d+%0d",
                   $realtime, vif.fib_out_o, prev1, prev2);
        end
      end
      local_i++;
      prev2 = prev1;
      prev1 = vif.fib_out_o;
    end
  endtask : tc_seq_02

  // ---------------------------------------------------------------------------
  // TC-SEQ-03 — Pulsed enable: one cycle on, one cycle off
  //
  // Goal    : Sequence advances only on cycles where enable_i=1; hold on the
  //           rest. Output must follow: 1,1,1,2,2,3,3,5,5,...
  // Req     : SEQ-001, HLD-001
  // ---------------------------------------------------------------------------
  task automatic tc_seq_03();
    $display("\n[TEST] TC-SEQ-03 — Pulsed enable (1 on / 1 off), 8 cycles");
    apply_reset();
    ref_reset();

    repeat (8) begin
      // Enable pulse.
      vif.enable_i <= 1'b1;
      @(posedge vif.clk_i);
      #1step;
      ref_step();
      check_output("TC-SEQ-03-en");

      // Hold pulse.
      vif.enable_i <= 1'b0;
      @(posedge vif.clk_i);
      #1step;
      // ref model does NOT advance; DUT must hold.
      check_output("TC-SEQ-03-hld");
    end
  endtask : tc_seq_03

  // ---------------------------------------------------------------------------
  // TC-HLD-01 — Hold stable for 10 consecutive cycles
  //
  // Goal    : After reaching fib_out_o=5, deassert enable_i for 10 cycles;
  //           output must remain 5.
  // Req     : HLD-001
  // ---------------------------------------------------------------------------
  task automatic tc_hld_01();
    $display("\n[TEST] TC-HLD-01 — Hold for 10 cycles");
    apply_reset();
    drive_enable(5, "TC-HLD-01-advance", .check(1'b0));
    // ref_a should now be F(5)=5.
    drive_hold(10, "TC-HLD-01");
  endtask : tc_hld_01

  // ---------------------------------------------------------------------------
  // TC-HLD-02 — Resume from held value
  //
  // Goal    : After 5 hold cycles, re-enable and verify the sequence continues
  //           from where it was held (not restarted).
  // Req     : HLD-002
  // ---------------------------------------------------------------------------
  task automatic tc_hld_02();
    $display("\n[TEST] TC-HLD-02 — Resume after 5 hold cycles");
    apply_reset();
    drive_enable(5, "TC-HLD-02-advance", .check(1'b0));
    // Hold 5 cycles (ref model freezes, DUT must freeze too).
    vif.enable_i <= 1'b0;
    repeat (5) @(posedge vif.clk_i);
    // Resume and check next 4 values against the reference model.
    drive_enable(4, "TC-HLD-02-resume");
  endtask : tc_hld_02

  // ---------------------------------------------------------------------------
  // TC-HLD-03 — Reset during hold dominates
  //
  // Goal    : While enable_i=0 (hold), asserting rst_ni=0 must immediately
  //           bring fib_out_o to 0.
  // Req     : RST-001, HLD-001
  // ---------------------------------------------------------------------------
  task automatic tc_hld_03();
    $display("\n[TEST] TC-HLD-03 — Reset during hold");
    apply_reset();
    drive_enable(6, "TC-HLD-03-advance", .check(1'b0));
    // Enter hold.
    vif.enable_i <= 1'b0;
    @(posedge vif.clk_i);
    // Assert reset while in hold.
    #3ns;
    vif.rst_ni = 1'b0;
    ref_reset();
    #1ns;
    check_value("TC-HLD-03", '0);
    @(posedge vif.clk_i);
    #1ns;
    vif.rst_ni = 1'b1;
  endtask : tc_hld_03

  // ---------------------------------------------------------------------------
  // TC-OVF-01 — Natural wrap-around at 2^W
  //
  // Goal    : Run the DUT until the sequence overflows 2^W bits. Both DUT and
  //           reference model use the same unsigned arithmetic, so they must
  //           stay identical after the wrap-around point.
  // Req     : OVF-001
  //
  // For W=32: first overflow occurs at F(48)=4807526976 → wraps to
  //           4807526976 mod 2^32 = 512559680.
  // For W=8 : first overflow occurs at F(14)=377        → wraps to
  //           377 mod 256 = 121.
  //
  // The loop below runs enough cycles to guarantee at least one overflow for
  // any W <= 32.
  // ---------------------------------------------------------------------------
  task automatic tc_ovf_01();
    int unsigned cycles;
    $display("\n[TEST] TC-OVF-01 — Overflow / wrap-around (W=%0d)", W);
    apply_reset();
    // Number of cycles needed to reach first overflow for common widths:
    //   W=8  → 14 steps,  W=16 → 24 steps,  W=32 → 48 steps.
    cycles = (W <= 8)  ? 16 :
             (W <= 16) ? 26 : 50;
    drive_enable(cycles, "TC-OVF-01");
  endtask : tc_ovf_01

  // ---------------------------------------------------------------------------
  // TC-OVF-02 — Continuity after overflow (20 additional cycles)
  //
  // Goal    : After overflow the DUT must continue to match the reference model
  //           for at least 20 more cycles, proving the recurrence is intact.
  // Req     : OVF-001
  // ---------------------------------------------------------------------------
  task automatic tc_ovf_02();
    int unsigned cycles;
    $display("\n[TEST] TC-OVF-02 — Post-overflow continuity (W=%0d)", W);
    apply_reset();
    // Advance past overflow, then check 20 more steps.
    cycles = (W <= 8)  ? 16 :
             (W <= 16) ? 26 : 50;
    drive_enable(cycles, "TC-OVF-02-pre", .check(1'b0));
    drive_enable(20,     "TC-OVF-02-post");
  endtask : tc_ovf_02

endmodule : test
