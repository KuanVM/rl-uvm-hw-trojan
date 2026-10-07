`timescale 1ns/1ps

module fifo_top;
  import uvm_pkg::*;
  import fifo_pkg::*;
  `include "uvm_macros.svh"

  // Clk generation

  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // Interface insta

  fifo_if vif(.clk(clk));

  // DUT insta
  sync_fifo #(
    .DATA_WIDTH(8),
    .DEPTH(32)
  ) dut (
    .clk(clk),
    .rst_n(vif.rst_n),
    .wr_en(vif.wr_en),
    .rd_en(vif.rd_en),
    .data_in(vif.data_in),
    .data_out(vif.data_out),
    .full(vif.full),
    .empty(vif.empty)
  );

  // Pass interface to UVM world
  initial begin
    uvm_config_db #(virtual fifo_if)::set(null, "*", "vif", vif);
    run_test();       // test selected by +UVM_TESTNAME
  end

  // Timeout watchdog
  initial begin
    #1000000ns;
    `uvm_fatal("TIMEOUT", $sformatf("Simulation exceeded time limit"))
  end

  initial begin
    $dumpfile("fifo_dump.vcd");
    $dumpvars(0, fifo_top);
  end

endmodule