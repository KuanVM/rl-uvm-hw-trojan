// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-11-25: Gộp fifo_top.sv vào đây (W-06, ISSUE-014). Từ nay chỉ còn MỘT top
//             có SVA cho cả testbench viết tay lẫn vòng lặp RL, nên hai luồng
//             dùng cùng một bộ detector.
//             - config_db set cả "fifo_vif" (testbench viết tay) lẫn "vif"
//               (key cũ của fifo_top); driver/monitor/fifo_rl_test vẫn đọc được.
//             - Watchdog chỉnh bằng +WATCHDOG_NS=<ns>. Mặc định vẫn 1 ms như cũ
//               để regress/bugs/run_one không đổi hành vi; run_rl.do và Makefile
//               gốc truyền +WATCHDOG_NS=100000000 (100 ms) cho vòng lặp RL.
//             - Dump VCD (dump.vcd) tắt được bằng +NODUMP (lấy từ fifo_top).
//             - Bind fifo_assertions (A01–A10) vào sync_fifo giữ nguyên.
// trước 2026-11-25: Bản của testbench viết tay (PR #2): clock, DUT, bind SVA,
//             key "fifo_vif", watchdog cố định 1 ms, luôn dump VCD.
// =============================================================================
// tb_top: clock, DUT, interface, assertion bind, config_db setup and run_test().
// Single top for both flows:
//   handwritten tests : +UVM_TESTNAME=fifo_test_*        (uvm/scripts/*.sh)
//   RL loop           : +UVM_TESTNAME=fifo_rl_loop_test  (run_rl.do, Makefile)
// Plusargs: +WATCHDOG_NS=<ns> (default 1 ms), +NODUMP (no dump.vcd).

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
    // Both keys: "fifo_vif" is read first by driver, monitor and fifo_rl_test;
    // "vif" is the key of the former fifo_top and is kept as a fallback.
    uvm_config_db #(virtual fifo_if)::set(null, "*", "fifo_vif", vif);
    uvm_config_db #(virtual fifo_if)::set(null, "*", "vif", vif);

    // Test selected with +UVM_TESTNAME
    run_test();
  end

  // Waveform dump, off with +NODUMP (long RL runs would write a very large VCD)
  initial begin
    if (!$test$plusargs("NODUMP")) begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb_top);
    end
  end

  // Watchdog: default 1 ms of simulation time (handwritten tests).
  // The RL loop passes +WATCHDOG_NS=100000000 (100 ms).
  longint unsigned watchdog_ns = 64'd1_000_000;
  initial begin
    void'($value$plusargs("WATCHDOG_NS=%d", watchdog_ns));
    #(watchdog_ns * 1ns);
    `uvm_fatal("TIMEOUT", $sformatf("Simulation timed out after %0d ns (+WATCHDOG_NS)", watchdog_ns))
  end

endmodule
