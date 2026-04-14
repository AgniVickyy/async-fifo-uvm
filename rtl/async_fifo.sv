// ============================================================================
// async_fifo.sv — Top-level Async FIFO 
//
// Features:
//   - Parameterized depth (power-of-2) and width
//   - Gray-code pointer CDC with 2-FF synchronizers
//   - Registered RAM output
//   - Asynchronous resets per clock domain
// ============================================================================
module async_fifo #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3   // FIFO depth = 2^ADDR_WIDTH
)(
  // Write interface
  input  logic                  wclk,
  input  logic                  wrst_n,
  input  logic                  winc,
  input  logic [DATA_WIDTH-1:0] wdata,
  output logic                  wfull,

  // Read interface
  input  logic                  rclk,
  input  logic                  rrst_n,
  input  logic                  rinc,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic                  rempty
);

  // ---- Internal signals ----
  logic [ADDR_WIDTH-1:0] waddr, raddr;
  logic [ADDR_WIDTH:0]   wptr_gray, rptr_gray;
  logic [ADDR_WIDTH:0]   wptr_gray_sync, rptr_gray_sync;

  // ---- Dual-port RAM ----
  dual_port_ram #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_ram (
    .wclk  (wclk),
    .wen   (winc & ~wfull),
    .waddr (waddr),
    .wdata (wdata),
    .rclk  (rclk),
    .ren   (rinc & ~rempty),
    .raddr (raddr),
    .rdata (rdata)
  );

  // ---- Write pointer + full logic ----
  wptr_full #(
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_wptr_full (
    .wclk           (wclk),
    .wrst_n         (wrst_n),
    .winc           (winc),
    .rptr_gray_sync (rptr_gray_sync),
    .waddr          (waddr),
    .wptr_gray      (wptr_gray),
    .wfull          (wfull)
  );

  // ---- Read pointer + empty logic ----
  rptr_empty #(
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_rptr_empty (
    .rclk           (rclk),
    .rrst_n         (rrst_n),
    .rinc           (rinc),
    .wptr_gray_sync (wptr_gray_sync),
    .raddr          (raddr),
    .rptr_gray      (rptr_gray),
    .rempty         (rempty)
  );

  // ---- Synchronizers: wptr → rclk domain ----
  sync_2ff #(
    .WIDTH (ADDR_WIDTH + 1)
  ) u_sync_w2r (
    .clk   (rclk),
    .rst_n (rrst_n),
    .din   (wptr_gray),
    .dout  (wptr_gray_sync)
  );

  // ---- Synchronizers: rptr → wclk domain ----
  sync_2ff #(
    .WIDTH (ADDR_WIDTH + 1)
  ) u_sync_r2w (
    .clk   (wclk),
    .rst_n (wrst_n),
    .din   (rptr_gray),
    .dout  (rptr_gray_sync)
  );

endmodule
