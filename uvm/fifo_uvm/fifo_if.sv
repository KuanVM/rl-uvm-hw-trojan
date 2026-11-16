// fifo_if: FIFO signals with driver and monitor clocking blocks (1 ns skew).

`timescale 1ns/1ps

interface fifo_if #(
  parameter int DATA_WIDTH = 8
)(
  input logic clk
);

  // DUT signals

  logic                    rst_n;     // Active-low asynchronous/synchronous reset
  logic                    wr_en;     // Write enable (active high)
  logic                    rd_en;     // Read enable (active high)
  logic [DATA_WIDTH-1:0]   data_in;   // Write data bus into FIFO
  logic [DATA_WIDTH-1:0]   data_out;  // Read data bus out of FIFO
  logic                    full;      // FIFO full flag (cannot accept writes)
  logic                    empty;     // FIFO empty flag (cannot accept reads)

  clocking drv_cb @(posedge clk);
    default input #1ns output #1ns;

    output wr_en;
    output rd_en;
    output data_in;

    input  full;
    input  empty;
    input  data_out;
  endclocking : drv_cb

  clocking mon_cb @(posedge clk);
    default input #1ns output #1ns;

    input  rst_n;
    input  wr_en;
    input  rd_en;
    input  data_in;
    input  data_out;
    input  full;
    input  empty;
  endclocking : mon_cb

  modport DRV (
    clocking drv_cb,
    output   rst_n
  );

  modport MON (
    clocking mon_cb
  );

endinterface : fifo_if
