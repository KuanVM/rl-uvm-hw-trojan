# =============================================================================
# LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
# 2026-10-13: Sửa plusarg có khoảng trắng/tab trước dấu "=" (Questa nhận thành
#             2 đối số riêng). Seed dùng -sv_seed (Questa) thay +ntb_random_seed
#             (cú pháp VCS, Questa bỏ qua); SEED mặc định 1. Thêm PLUSARGS tự do.
#             Thêm target rl / rl_run (vòng lặp RL một seed) và rl_sweep (nhiều
#             policy x nhiều seed), ghi CSV + log vào results/rl/, tắt VCD.
# =============================================================================
# FIFO UVM TESTBENCH - Makefile
# Tool: Questa

# -- PATHS --
RTL_DIR   = ./rtl
UVM_DIR   = ./uvm/fifo_uvm
TOP       = fifo_top

# -- Src files --
RTL_SRC   = $(RTL_DIR)/sync_fifo_clean.sv
UVM_SRC   = $(UVM_DIR)/fifo_if.sv \
            $(UVM_DIR)/fifo_pkg.sv \
            $(UVM_DIR)/fifo_sva.sv \
            $(UVM_DIR)/$(TOP).sv

# -- Sim settings --
VLOG      = vlog
VSIM      = vsim
VLOG_OPTS = -sv +acc -timescale 1ns/1ps +incdir+$(UVM_DIR)
VSIM_OPTS = -c -do "run -all; quit -f"

# -- Default test --
TEST      ?= fifo_random_test
SEED      ?= 1
VERBOSITY ?= UVM_MEDIUM
PLUSARGS  ?=

# -- RL loop --
RL_POLICY ?= ucb1
RL_REWARD ?= binary
RL_TESTS  ?= 100
RL_TXN    ?= 200
RL_DIR    ?= results/rl
RL_TAG     = rl_$(RL_POLICY)_$(RL_REWARD)_s$(SEED)
SEEDS     ?= 1 2 3 4 5 6 7 8 9 10
POLICIES  ?= fixed random ucb1

#_____________________________________
# -- Targets --
# compile only
compile:
	vlib work
	vmap work work
	$(VLOG) $(VLOG_OPTS) $(RTL_SRC) $(UVM_SRC)

# compile + simulate
sim: compile
	$(VSIM) $(VSIM_OPTS) -sv_seed $(SEED) \
	  +UVM_TESTNAME=$(TEST) \
	  +UVM_VERBOSITY=$(VERBOSITY) \
	  $(PLUSARGS) \
	  work.$(TOP)

wave: compile
	$(VSIM) -sv_seed $(SEED) -do "add wave -r /*; run -all" \
	  +UVM_TESTNAME=$(TEST) \
	  +UVM_VERBOSITY=$(VERBOSITY) \
	  $(PLUSARGS) \
	  work.$(TOP)

# quick smoke test
smoke: TEST = fifo_random_test
smoke: sim

# RL loop: B test trong MỘT lần mô phỏng, một seed
#   make rl RL_POLICY=ucb1 SEED=3 RL_TESTS=1000
rl: compile rl_run

# chạy không biên dịch lại (dùng trong rl_sweep)
rl_run:
	mkdir -p $(RL_DIR)
	$(VSIM) $(VSIM_OPTS) -sv_seed $(SEED) -l $(RL_DIR)/$(RL_TAG).log \
	  +UVM_TESTNAME=fifo_rl_loop_test \
	  +UVM_VERBOSITY=UVM_LOW \
	  +NODUMP \
	  +RL_POLICY=$(RL_POLICY) +RL_REWARD=$(RL_REWARD) \
	  +RL_TESTS=$(RL_TESTS) +RL_TXN=$(RL_TXN) +RL_SEED=$(SEED) \
	  +RL_CSV=$(RL_DIR)/$(RL_TAG).csv \
	  $(PLUSARGS) \
	  work.$(TOP)

# nhiều policy x nhiều seed, biên dịch một lần
#   make rl_sweep POLICIES="random ucb1" SEEDS="1 2 3" RL_REWARD=graded
rl_sweep: compile
	@for p in $(POLICIES); do for s in $(SEEDS); do \
	  $(MAKE) --no-print-directory rl_run RL_POLICY=$$p SEED=$$s || exit 1; \
	done; done
	@grep -h "RL_SUMMARY" $(RL_DIR)/*.log | sed 's/.*RL_SUMMARY/RL_SUMMARY/'

# clean build artifacts
clean:
	rm -rf work transcript vsim.wlf *.vcd *.log

.PHONY: compile sim wave smoke rl rl_run rl_sweep clean
