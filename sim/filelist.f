// ============================================================================
// filelist.f — Compilation file list for async FIFO project
// Usage: vcs -f filelist.f  |  xrun -f filelist.f  |  vlog -f filelist.f
// ============================================================================

// Include paths
+incdir+../tb

// RTL (order matters — dependencies first)
../rtl/async_fifo_pkg.sv
../rtl/dual_port_ram.sv
../rtl/sync_2ff.sv
../rtl/wptr_full.sv
../rtl/rptr_empty.sv
../rtl/async_fifo.sv
../rtl/async_fifo_sva.sv

// Testbench
../tb/async_fifo_if.sv
../tb/async_fifo_tb_pkg.sv
../tb/tb_top.sv
