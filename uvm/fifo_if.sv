interface fifo_if (input logic clk);
  //signals wire from actual hardware
  logic rst_n;
  logic wr_en;
  logic rd_en;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic full;
  logic empty;

//clocking block cho Driver (prevent Race cond)
  clocking drv_cb @(posedge clk);
    default input #1ns output #1ns;
    output wr_en, rd_en, data_in, rst_n;
    input full, empty;
  endclocking: drv_cb

//clocking block cho monitor
clocking mon_cb @(posedge clk);
  default input #1ns output #1ns; 
  input wr_en, rd_en, data_in, data_out, full, empty, rst_n;
endclocking: mon_cb

//modports
modport DRV (
  clocking drv_cb,
    output rst_n
);

modport MON (
    clocking mon_cb
);


endinterface