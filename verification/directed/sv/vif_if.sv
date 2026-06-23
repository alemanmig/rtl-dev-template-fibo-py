// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Interface : vif_if
// File      : verification/directed/sv/vif_if.sv
// Project   : fibonacci-seq-gen
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Virtual interface for the fibonacci DUT (rtl module: fib_gen). Bundles all
// DUT signals and provides a clocking block for synchronous stimulus and
// sampling in the testbench / test layers.
//
// Signal names match the DUT ports exactly (clk_i, rst_ni, enable_i,
// fib_out_o), following the lowRISC Verilog Coding Style Guide's _i/_o/_ni
// suffix convention — consistent with rtl/fibonacci.sv.
//
// Clocking block (cb):
//   - Input  skew : #1step  (sample just before clock edge — avoids race).
//   - Output skew : #1ns    (drive 1 ns after clock edge).
//
// -----------------------------------------------------------------------------

`ifndef VIF_IF_SV
`define VIF_IF_SV

interface vif_if #(
  parameter int unsigned W = 32
) (
  input logic clk_i
);

  timeunit      1ns;
  timeprecision 100ps;

  import config_pkg::*;

  // ---------------------------------------------------------------------------
  // DUT signals (names match fib_gen ports exactly)
  // ---------------------------------------------------------------------------
  logic          rst_ni;
  logic          enable_i;
  logic [W-1:0]  fib_out_o;

  // ---------------------------------------------------------------------------
  // Clocking block — synchronous testbench view
  //
  // Use cb.enable_i and cb.fib_out_o inside clocked tasks/test sequences
  // to guarantee setup/hold timing relative to clk_i.
  // ---------------------------------------------------------------------------
  /*clocking cb @(posedge clk_i);
    default input #1step output #1ns;
    output enable_i;
    input  fib_out_o;
  endclocking : cb

  */

endinterface : vif_if

`endif // VIF_IF_SV
