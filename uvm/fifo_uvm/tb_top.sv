// tb_top: clock, DUT, interface, assertion bind, config_db setup and run_test().

`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import fifo_pkg::*;

  // Parameters
  parameter int DATA_WIDTH = 8;
  parameter int DEPTH      = 32;
  parameter int CLK_PERIOD = 10; // 10ns → 100MHz

  logic clk;
  logic rst_n;

  // 100 MHz clock
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  fifo_if vif(clk);

  sync_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
  ) dut (
    .clk      (clk),
    .rst_n    (vif.rst_n),
    .wr_en    (vif.wr_en),
    .rd_en    (vif.rd_en),
    .data_in  (vif.data_in),
    .data_out (vif.data_out),
    .full     (vif.full),
    .empty    (vif.empty)
  );

  bind sync_fifo fifo_assertions #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
  ) sva_inst (.*);

  initial begin
    uvm_config_db #(virtual fifo_if)::set(null, "*", "fifo_vif", vif);

    // Waveform dump
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);

    // Test selected with +UVM_TESTNAME
    run_test();
  end

  // Watchdog: stop after 1 ms of simulation time
  initial begin
    #1_000_000; // 1ms of simulation time
    `uvm_fatal("TIMEOUT", "Simulation timed out after 1ms!")
  end

endmodule
