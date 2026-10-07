# FIFO UVM TESTBENCH - Makefile
# Tool: Questa

# -- PATHS --
RTL_DIR		=	/mnt/4cd7130a-027f-496a-87a6-6cc6aded2046/Q2/rl-uvm-hardware-trojan/rl-uvm-hw-trojan/rtl
UVM_DIR		=	/mnt/4cd7130a-027f-496a-87a6-6cc6aded2046/Q2/rl-uvm-hardware-trojan/rl-uvm-hw-trojan/uvm/fifo_uvm
TOP			=	fifo_top

# -- Src files --
RTL_SRC		=	$(RTL_DIR)/sync_fifo_clean.sv
UVM_SRC		=	$(UVM_DIR)/fifo_if.sv \
					$(UVM_DIR)/fifo_pkg.sv \
            		$(UVM_DIR)/fifo_sva.sv \
            		$(UVM_DIR)/$(TOP).sv

# -- Sim settings --
VLOG		=	vlog 
VSIM		= 	vsim 
VLOG_OPTS 	= -sv +acc -timescale 1ns/1ps
VSIM_OPTS 	= -c -do "run -all; quit -f"

# -- Default test -- 
TEST 		?= fifo_random_test
SEED		?= random 
VERBOSITY	?= UVM_MEDIUM

#_____________________________________
# -- Targets -- 
# compile only
compile: 
	vlib work
	vmap work
	$(VLOG) $(VLOG_OPTS) $(RTL_SRC) $(UVM_SRC)

# compile + simulate
sim: compile
	$(VSIM) $(VSIM_OPTS) \
	  	+UVM_TESTNAME=$(TEST) \
	  	+UVM_VERBOSITY=$(VERBOSITY) \
	  	+ntb_random_seed=$(SEED) \
	  	work.$(TOP)

# quick smoke test
smoke: TEST	= fifo_random_test
smoke: sim

# clean build artifacts
clean:
	rm -rf work transcript vsim.wlf *.vcd *.log

.PHONY: compile sim smoke clean
