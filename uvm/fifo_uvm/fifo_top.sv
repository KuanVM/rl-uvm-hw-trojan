// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Watchdog mặc định 100.000.000 ns (100 ms), chỉnh bằng
//             +WATCHDOG_NS=<ns> (vấn đề 5); in thời điểm hết giờ. Dump VCD tắt
//             được bằng +NODUMP (vòng lặp RL dài sẽ sinh VCD rất lớn).
// =============================================================================
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

  // Timeout watchdog: mặc định 100 ms thời gian mô phỏng (~10^7 chu kỳ @10 ns).
  // 1.000 test x ~204 chu kỳ x 10 ns ~ 2 ms, nên còn dư nhiều. Đổi bằng +WATCHDOG_NS=<ns>.
  longint unsigned watchdog_ns = 64'd100_000_000;
  initial begin
    void'($value$plusargs("WATCHDOG_NS=%d", watchdog_ns));
    #(watchdog_ns * 1ns);
    `uvm_fatal("TIMEOUT", $sformatf("Simulation exceeded time limit (%0d ns, +WATCHDOG_NS)", watchdog_ns))
  end

  initial begin
    if (!$test$plusargs("NODUMP")) begin
      $dumpfile("fifo_dump.vcd");
      $dumpvars(0, fifo_top);
    end
  end

endmodule