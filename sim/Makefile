# ============================================================================
# Makefile for Async FIFO simulation
# Supports: VCS, Xcelium, Questa/ModelSim
# ============================================================================

RTL_DIR  = ../rtl
TB_DIR   = ../tb
TOP      = tb_top
TEST     ?= async_fifo_simple_test

# RTL files (order matters)
RTL_FILES = \
  $(RTL_DIR)/async_fifo_pkg.sv \
  $(RTL_DIR)/dual_port_ram.sv \
  $(RTL_DIR)/sync_2ff.sv \
  $(RTL_DIR)/wptr_full.sv \
  $(RTL_DIR)/rptr_empty.sv \
  $(RTL_DIR)/async_fifo.sv \
  $(RTL_DIR)/async_fifo_sva.sv

# TB files
TB_FILES = \
  $(TB_DIR)/async_fifo_if.sv \
  $(TB_DIR)/async_fifo_tb_pkg.sv \
  $(TB_DIR)/tb_top.sv

# ---- VCS ----
vcs: compile_vcs run_vcs

compile_vcs:
	vcs -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
	    +incdir+$(TB_DIR) \
	    $(RTL_FILES) $(TB_FILES) \
	    -o simv -debug_access+all

run_vcs:
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM

# ---- Xcelium ----
xrun:
	xrun -sv -uvm -access +rwc -timescale 1ns/1ps \
	     +incdir+$(TB_DIR) \
	     $(RTL_FILES) $(TB_FILES) \
	     -top $(TOP) \
	     +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM

# ---- Questa/ModelSim ----
questa: compile_questa run_questa

compile_questa:
	vlib work
	vlog -sv +incdir+$(TB_DIR) $(RTL_FILES) $(TB_FILES)

run_questa:
	vsim -c $(TOP) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM -do "run -all; quit"

# ---- Utilities ----
clean:
	rm -rf simv simv.daidir csrc *.vcd work transcript *.log xcelium.d .bpad

.PHONY: vcs compile_vcs run_vcs xrun questa compile_questa run_questa clean
