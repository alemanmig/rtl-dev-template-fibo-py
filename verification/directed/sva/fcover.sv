// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module  : fcover
// File    : verification/directed/sva/fcover.sv
// Project : fibonacci-seq-gen
// Spec    : docs/verif_plan.md (Section 4.3)
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Functional coverage collector for the fibonacci DUT (fib_gen). Instantiated
// via bind in tb.sv inside the DUT scope. Completely independent of sva.sv
// and the testbench: a bug here cannot mask assertion failures or corrupt
// test stimulus.
//
// Coverage model (fib_cg)
// ─────────────────────────────────────────────────────────────────────────────
//  Coverpoint      | Description
// ─────────────────┼───────────────────────────────────────────────────────────
//  cp_enable       | enable_i sampled high / low
//  cp_rst          | rst_ni sampled active / inactive
//  cp_enable_rst   | cross of cp_enable x cp_rst
//  cp_fib_out      | output value buckets: zero/small/medium/large
//  cp_en_edge      | enable_i 0→1 and 1→0 transitions observed
// ─────────────────────────────────────────────────────────────────────────────
//
// Notes
// -----
// • Port names follow the lowRISC _i/_o/_ni suffix convention, matching
//   rtl/fibonacci.sv exactly.
// • No internal register visibility (a_q/b_q) is needed for this module, so
//   the bind in tb.sv only connects the four DUT ports.
//
// -----------------------------------------------------------------------------

`default_nettype none

module fcover #(
  parameter int unsigned W = 32
) (
  input logic          clk_i,
  input logic          rst_ni,
  input logic          enable_i,
  input logic [W-1:0]  fib_out_o
);

  covergroup fib_cg @(posedge clk_i);

    cp_enable : coverpoint enable_i {
      bins enabled  = {1};
      bins disabled = {0};
    }

    cp_rst : coverpoint rst_ni {
      bins active   = {0};
      bins inactive = {1};
    }

    cp_enable_rst : cross cp_enable, cp_rst;

    cp_fib_out : coverpoint fib_out_o {
      bins zero    = {0};
      bins smal    = {[1:15]};
      bins mediu   = {[16:127]};
      bins larg    = default;
    }

    cp_en_edge : coverpoint enable_i {
      bins en_to_dis = (1 => 0);
      bins dis_to_en = (0 => 1);
    }

  endgroup : fib_cg

  fib_cg cg = new();

endmodule : fcover

`default_nettype wire
