# =============================================================================
# LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
# 2026-11-25: Dùng top chung tb_top (có bind SVA fifo_assertions) thay cho
#             fifo_top (W-06, ISSUE-014); bỏ ghi chú "fifo_sva.sv tạm bỏ"
#             (fifo_sva.sv không còn được dùng, SVA nay là fifo_assertions.sv).
# 2026-10-22: Xoá thư mục work bằng "file delete -force" thay cho vdel (vdel
#             không xoá được _opt bị khoá bởi máy Linux cũ). Thêm -l sim.log để
#             có file log UTF-8 đầy đủ. In báo cáo covergroup chi tiết ra
#             cov_report.txt để biết bin nào chưa chạm.
# 2026-10-21: Tạo mới. Script Questa chạy được trên cả Windows và Linux, thay cho
#             Makefile (Windows không có make). Tự tạo lại thư viện work,
#             biên dịch, mô phỏng; GUI thì add wave, batch (-c) thì tự thoát.
# =============================================================================
#
# Chạy từ THƯ MỤC GỐC của repo (nơi có rtl/ và uvm/):
#   Batch : vsim -c -do run.do
#   GUI   : vsim -do run.do
#   Đổi test/seed:
#     vsim -c -do "set TEST fifo_test_random; set SEED 7; do run.do"
# Trong cửa sổ Questa đang mở: File > Change Directory... tới thư mục repo, rồi gõ: do run.do

if {![info exists TEST]}      {set TEST fifo_test_random}
if {![info exists SEED]}      {set SEED 1}
if {![info exists VERBOSITY]} {set VERBOSITY UVM_MEDIUM}

# --- tạo lại thư viện work (xoá hẳn thư mục cũ, kể cả _opt bị khoá) ---
if {[file exists work]} {file delete -force work}
vlib work
vmap work work

# --- biên dịch (SVA A01–A10 trong fifo_assertions.sv, bind vào DUT ở tb_top) ---
vlog -sv +acc -timescale 1ns/1ps +incdir+uvm/fifo_uvm \
  rtl/sync_fifo_clean.sv \
  uvm/fifo_uvm/fifo_if.sv \
  uvm/fifo_uvm/fifo_pkg.sv \
  uvm/fifo_uvm/fifo_assertions.sv \
  uvm/fifo_uvm/tb_top.sv

# --- mô phỏng ---
vsim -sv_seed $SEED -onfinish stop -l sim.log \
  +UVM_TESTNAME=$TEST +UVM_VERBOSITY=$VERBOSITY \
  work.tb_top

if {![batch_mode]} {add wave -r /*}
run -all

# --- báo cáo covergroup chi tiết (bin nào chưa chạm) ---
catch {coverage report -cvg -details -file cov_report.txt}

if {[batch_mode]} {quit -f}
