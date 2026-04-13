// ============================================================================
// wptr_full.sv — Write pointer and full flag generation (Cummings style)
// ============================================================================
module wptr_full #(
  parameter int ADDR_WIDTH = 3
)(
  input  logic                    wclk,
  input  logic                    wrst_n,
  input  logic                    winc,       // write request
  input  logic [ADDR_WIDTH:0]     rptr_gray_sync, // synced read pointer (Gray)
  output logic [ADDR_WIDTH-1:0]   waddr,      // RAM write address
  output logic [ADDR_WIDTH:0]     wptr_gray,  // Gray write pointer (to sync)
  output logic                    wfull
);

  logic [ADDR_WIDTH:0] wbin, wbin_next;
  logic [ADDR_WIDTH:0] wgray_next;
  logic                wfull_next;

  // Binary counter
  assign wbin_next  = wbin + (winc & ~wfull);
  assign wgray_next = wbin_next ^ (wbin_next >> 1);

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin      <= '0;
      wptr_gray <= '0;
    end else begin
      wbin      <= wbin_next;
      wptr_gray <= wgray_next;
    end
  end

  // RAM address is lower bits of binary counter
  assign waddr = wbin[ADDR_WIDTH-1:0];

  // Full when Gray pointer MSB and MSB-1 differ, rest equal
  assign wfull_next = (wgray_next == {~rptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                                       rptr_gray_sync[ADDR_WIDTH-2:0]});

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)
      wfull <= 1'b0;
    else
      wfull <= wfull_next;
  end

endmodule
