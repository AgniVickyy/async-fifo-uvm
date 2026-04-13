// ============================================================================
// async_fifo_if.sv — Virtual interface for Async FIFO
// ============================================================================
interface async_fifo_if #(
  parameter int DATA_WIDTH = 8
)(
  input logic wclk,
  input logic rclk
);

  // Write side
  logic                  wrst_n;
  logic                  winc;
  logic [DATA_WIDTH-1:0] wdata;
  logic                  wfull;

  // Read side
  logic                  rrst_n;
  logic                  rinc;
  logic [DATA_WIDTH-1:0] rdata;
  logic                  rempty;

  // Write driver clocking block
  clocking wr_cb @(posedge wclk);
    default input #1 output #1;
    output winc, wdata;
    input  wfull;
  endclocking

  // Read driver clocking block
  clocking rd_cb @(posedge rclk);
    default input #1 output #1;
    output rinc;
    input  rdata, rempty;
  endclocking

  // Write monitor clocking block
  clocking wr_mon_cb @(posedge wclk);
    default input #1;
    input winc, wdata, wfull;
  endclocking

  // Read monitor clocking block
  clocking rd_mon_cb @(posedge rclk);
    default input #1;
    input rinc, rdata, rempty;
  endclocking

  // Modports
  modport WR_DRV  (clocking wr_cb);
  modport RD_DRV  (clocking rd_cb);
  modport WR_MON  (clocking wr_mon_cb);
  modport RD_MON  (clocking rd_mon_cb);

endinterface
