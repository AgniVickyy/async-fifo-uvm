// ============================================================================
// dual_port_ram.sv — True dual-port RAM (1 write port, 1 read port)
// ============================================================================
module dual_port_ram #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
)(
  // Write port
  input  logic                  wclk,
  input  logic                  wen,
  input  logic [ADDR_WIDTH-1:0] waddr,
  input  logic [DATA_WIDTH-1:0] wdata,

  // Read port
  input  logic                  rclk,
  input  logic                  ren,
  input  logic [ADDR_WIDTH-1:0] raddr,
  output logic [DATA_WIDTH-1:0] rdata
);

  logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

  // Write
  always_ff @(posedge wclk)
    if (wen)
      mem[waddr] <= wdata;

  // Read — registered output for timing closure
  always_ff @(posedge rclk)
    if (ren)
      rdata <= mem[raddr];

endmodule
