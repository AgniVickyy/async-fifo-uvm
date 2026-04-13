// ============================================================================
// sync_2ff.sv — 2-flop synchronizer for Gray-coded pointers
// ============================================================================
module sync_2ff #(
  parameter int WIDTH = 4
)(
  input  logic             clk,
  input  logic             rst_n,
  input  logic [WIDTH-1:0] din,
  output logic [WIDTH-1:0] dout
);

  logic [WIDTH-1:0] meta;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      meta <= '0;
      dout <= '0;
    end else begin
      meta <= din;
      dout <= meta;
    end
  end

endmodule
