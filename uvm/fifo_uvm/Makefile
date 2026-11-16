# Makefile for UVM FIFO Testbench
RTL_DIR = ../../rtl
TB_DIR = .
WORK = work

# Default test name
TESTNAME ?= fifo_test_random

# Targets
all: questa_sim

questa_compile:
	vlib $(WORK)
	vmap work $(WORK)

	# Compile Interface and Package first
	vlog -sv $(TB_DIR)/fifo_if.sv
	vlog -sv $(TB_DIR)/fifo_pkg.sv

	# Compile RTL
	vlog -sv $(RTL_DIR)/sync_fifo.sv

	# Compile Assertions and Top
	vlog -sv $(TB_DIR)/fifo_assertions.sv
	vlog -sv $(TB_DIR)/tb_top.sv

questa_sim: questa_compile
	vsim -voptargs="+acc" -c -do "run -all; quit" tb_top +UVM_TESTNAME=$(TESTNAME)

questa_gui: questa_compile
	@if [ -f wave.do ]; then \
		vsim -voptargs="+acc" -do "do wave.do; run -all" tb_top +UVM_TESTNAME=$(TESTNAME); \
	else \
		vsim -voptargs="+acc" -do "add wave -r /*; run -all" tb_top +UVM_TESTNAME=$(TESTNAME); \
	fi

# One test, one seed, full result set -> out/runs/<test>_s<seed>/
#   make result TESTNAME=fifo_test_random SEED=3 [BUG=BUG_COUNT_RW]
SEED ?= 1
result:
	TESTNAME=$(TESTNAME) SEED=$(SEED) BUG=$(BUG) bash ../scripts/run_one.sh

# One test in the Questa GUI, all signals logged, optional bug and saved wave layout
#   make gui TESTNAME=fifo_test_fill_drain SEED=1 [BUG=BUG_FULL_EARLY] [WAVE=../doc/waves/W1.do]
gui:
	TESTNAME=$(TESTNAME) SEED=$(SEED) BUG=$(BUG) WAVE=$(WAVE) bash ../scripts/gui.sh

# Regression: all tests x SEEDS, merged coverage -> out/regress/summary.txt
regress:
	bash ../scripts/regress.sh

# Bug injection: each RTL bug x all tests -> out/bugs/bug_report.txt
bugs:
	bash ../scripts/bugs.sh

clean:
	rm -rf $(WORK) work_reg work_gui* work_run gui_compile.log work_BUG_* out covhtmlreport transcript vsim.wlf dump.vcd modelsim.ini

.PHONY: all questa_compile questa_sim questa_gui gui result regress bugs clean
