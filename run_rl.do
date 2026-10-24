# =============================================================================
# LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
# 2026-10-24: Tạo mới. Thay cho "make rl" / "make rl_sweep" trên Windows:
#             biên dịch + vopt MỘT lần, rồi chạy fifo_rl_loop_test cho mọi
#             policy x seed; mỗi lần chạy ghi CSV + log vào results/rl/.
# =============================================================================
#
# Chạy từ THƯ MỤC GỐC của repo, chế độ batch:
#   Mặc định (fixed, random, ucb1  x  seed 1..10, B=200 test, N=40 txn):
#     vsim -c -do run_rl.do
#   Chạy thử 1 lần:
#     vsim -c -do "set POLICIES ucb1; set SEEDS 1; do run_rl.do"
#   Đổi tham số:
#     vsim -c -do "set POLICIES {random ucb1}; set SEEDS {1 2 3}; set TESTS 500; set TXN 40; set REWARD graded; do run_rl.do"
# Kết quả: results/rl/rl_<policy>_<reward>_s<seed>.csv và .log
# Tổng hợp: python scripts/rl_summary.py results/rl

if {![info exists POLICIES]} {set POLICIES {fixed random ucb1}}
if {![info exists SEEDS]}    {set SEEDS {1 2 3 4 5 6 7 8 9 10}}
if {![info exists TESTS]}    {set TESTS 200}
if {![info exists TXN]}      {set TXN 40}
if {![info exists REWARD]}   {set REWARD binary}
set OUTDIR results/rl

# --- biên dịch + tối ưu một lần (không +acc: không cần xem sóng, chạy nhanh hơn) ---
if {[file exists work]} {file delete -force work}
vlib work
vmap work work
vlog -sv -timescale 1ns/1ps +incdir+uvm/fifo_uvm \
  rtl/sync_fifo_clean.sv \
  uvm/fifo_uvm/fifo_if.sv \
  uvm/fifo_uvm/fifo_pkg.sv \
  uvm/fifo_uvm/fifo_top.sv
vopt work.fifo_top -o fifo_top_opt

file mkdir $OUTDIR

# --- vòng lặp policy x seed ---
foreach p $POLICIES {
  foreach s $SEEDS {
    set tag rl_${p}_${REWARD}_s${s}
    echo "===== RUN $tag ====="
    vsim -c -sv_seed $s -onfinish stop -l $OUTDIR/$tag.log \
      +UVM_TESTNAME=fifo_rl_loop_test +UVM_VERBOSITY=UVM_LOW +UVM_NO_RELNOTES +NODUMP \
      +RL_POLICY=$p +RL_REWARD=$REWARD +RL_TESTS=$TESTS +RL_TXN=$TXN +RL_SEED=$s \
      +RL_CSV=$OUTDIR/$tag.csv \
      work.fifo_top_opt
    run -all
    quit -sim
  }
}

echo "===== XONG. Tổng hợp: python scripts/rl_summary.py $OUTDIR ====="
if {[batch_mode]} {quit -f}
