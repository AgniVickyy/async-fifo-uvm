// ============================================================================
// tb_top.sv — Top-level testbench module
// ============================================================================
`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Parameters
  localparam int DATA_WIDTH = 8;
  localparam int ADDR_WIDTH = 3;

  // Clocks — intentionally asynchronous (relatively prime periods)
  logic wclk = 0;
  logic rclk = 0;

  always #5.0  wclk = ~wclk;   // 100 MHz write clock
  always #7.3  rclk = ~rclk;   //  68 MHz read clock (prime ratio)

  // Interface
  async_fifo_if #(.DATA_WIDTH(DATA_WIDTH)) afifo_if (.wclk(wclk), .rclk(rclk));

  // DUT
  async_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) dut (
    .wclk   (wclk),
    .wrst_n (afifo_if.wrst_n),
    .winc   (afifo_if.winc),
    .wdata  (afifo_if.wdata),
    .wfull  (afifo_if.wfull),
    .rclk   (rclk),
    .rrst_n (afifo_if.rrst_n),
    .rinc   (afifo_if.rinc),
    .rdata  (afifo_if.rdata),
    .rempty (afifo_if.rempty)
  );

  // Bind SVA assertions
  bind async_fifo async_fifo_sva #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_sva (.*);

  // UVM config & run
  initial begin
    uvm_config_db#(virtual async_fifo_if#(DATA_WIDTH))::set(null, "*", "vif", afifo_if);
    run_test();
  end

  // Timeout safety
  initial begin
    #1_000_000;
    `uvm_fatal("TIMEOUT", "Simulation timed out at 1ms")
  end

  // Waveform dump (VCS/Verilator compatible)
  initial begin
    $dumpfile("async_fifo.vcd");
    $dumpvars(0, tb_top);
  end

endmodule
