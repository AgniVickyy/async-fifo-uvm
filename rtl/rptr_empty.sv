// ============================================================================
// rptr_empty.sv — Read pointer and empty flag generation
// ============================================================================
module rptr_empty #(
  parameter int ADDR_WIDTH = 3
)(
  input  logic                    rclk,
  input  logic                    rrst_n,
  input  logic                    rinc,       // read request
  input  logic [ADDR_WIDTH:0]     wptr_gray_sync, // synced write pointer (Gray)
  output logic [ADDR_WIDTH-1:0]   raddr,      // RAM read address
  output logic [ADDR_WIDTH:0]     rptr_gray,  // Gray read pointer (to sync)
  output logic                    rempty
);

  logic [ADDR_WIDTH:0] rbin, rbin_next;
  logic [ADDR_WIDTH:0] rgray_next;
  logic                rempty_next;

  // Binary counter
  assign rbin_next  = rbin + (rinc & ~rempty);
  assign rgray_next = rbin_next ^ (rbin_next >> 1);

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin      <= '0;
      rptr_gray <= '0;
    end else begin
      rbin      <= rbin_next;
      rptr_gray <= rgray_next;
    end
  end

  assign raddr = rbin[ADDR_WIDTH-1:0];

  // Empty when Gray pointers match exactly
  assign rempty_next = (rgray_next == wptr_gray_sync);

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)
      rempty <= 1'b1;  // reset to empty
    else
      rempty <= rempty_next;
  end

endmodule
