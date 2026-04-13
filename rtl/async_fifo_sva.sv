// ============================================================================
// async_fifo_sva.sv — SystemVerilog Assertions for Async FIFO
//
// Bind to async_fifo in testbench:
//   bind async_fifo async_fifo_sva #(.DATA_WIDTH(DATA_WIDTH),
//     .ADDR_WIDTH(ADDR_WIDTH)) u_sva (.*);
// ============================================================================
module async_fifo_sva #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
)(
  // Write domain
  input logic                  wclk,
  input logic                  wrst_n,
  input logic                  winc,
  input logic [DATA_WIDTH-1:0] wdata,
  input logic                  wfull,

  // Read domain
  input logic                  rclk,
  input logic                  rrst_n,
  input logic                  rinc,
  input logic [DATA_WIDTH-1:0] rdata,
  input logic                  rempty
);

  localparam int DEPTH = 1 << ADDR_WIDTH;

  // =========================================================================
  // WRITE DOMAIN ASSERTIONS
  // =========================================================================

  // W1: No write when full — pointer must not advance
  property p_no_write_when_full;
    @(posedge wclk) disable iff (!wrst_n)
    (wfull && winc) |-> $stable(u_wptr_full.wbin);
  endproperty
  a_no_write_when_full: assert property (p_no_write_when_full)
    else $error("SVA FAIL: Write pointer advanced while FIFO full");

  // W2: After full asserts, it must deassert within 2*sync_depth+2 cycles
  // of any read occurring (tests CDC pipeline liveness)
  // Track: when full and the synced rptr changes, full must eventually clear
  property p_full_eventually_clears;
    @(posedge wclk) disable iff (!wrst_n)
    (wfull && !$stable(u_sync_r2w.dout)) |-> ##[1:6] (!wfull);
  endproperty
  a_full_eventually_clears: assert property (p_full_eventually_clears)
    else $error("SVA FAIL: wfull stuck after synced read pointer changed");

  // W3: After reset, FIFO must not be full
  property p_reset_not_full;
    @(posedge wclk)
    (!wrst_n) |-> ##1 (!wfull);
  endproperty
  a_reset_not_full: assert property (p_reset_not_full)
    else $error("SVA FAIL: FIFO full immediately after write reset deassert");

  // W4: Write pointer is Gray-coded (at most 1 bit changes per cycle)
  property p_wptr_gray_onehot;
    logic [ADDR_WIDTH:0] prev_gray;
    @(posedge wclk) disable iff (!wrst_n)
    (1, prev_gray = u_wptr_full.wptr_gray)
    |=> $onehot0(u_wptr_full.wptr_gray ^ prev_gray);
  endproperty
  a_wptr_gray_onehot: assert property (p_wptr_gray_onehot)
    else $error("SVA FAIL: Write Gray pointer changed >1 bit");

  // =========================================================================
  // READ DOMAIN ASSERTIONS
  // =========================================================================

  // R1: No read when empty — pointer must not advance
  property p_no_read_when_empty;
    @(posedge rclk) disable iff (!rrst_n)
    (rempty && rinc) |-> $stable(u_rptr_empty.rbin);
  endproperty
  a_no_read_when_empty: assert property (p_no_read_when_empty)
    else $error("SVA FAIL: Read pointer advanced while FIFO empty");

  // R2: After reset, FIFO must be empty
  property p_reset_empty;
    @(posedge rclk)
    (!rrst_n) |-> ##1 (rempty);
  endproperty
  a_reset_empty: assert property (p_reset_empty)
    else $error("SVA FAIL: FIFO not empty after read reset deassert");

  // R3: Read pointer is Gray-coded (at most 1 bit changes per cycle)
  property p_rptr_gray_onehot;
    logic [ADDR_WIDTH:0] prev_gray;
    @(posedge rclk) disable iff (!rrst_n)
    (1, prev_gray = u_rptr_empty.rptr_gray)
    |=> $onehot0(u_rptr_empty.rptr_gray ^ prev_gray);
  endproperty
  a_rptr_gray_onehot: assert property (p_rptr_gray_onehot)
    else $error("SVA FAIL: Read Gray pointer changed >1 bit");

  // R4: Empty must deassert after synced write pointer changes
  property p_empty_eventually_clears;
    @(posedge rclk) disable iff (!rrst_n)
    (rempty && !$stable(u_sync_w2r.dout)) |-> ##[1:6] (!rempty);
  endproperty
  a_empty_eventually_clears: assert property (p_empty_eventually_clears)
    else $error("SVA FAIL: rempty stuck after synced write pointer changed");

  // =========================================================================
  // CROSS-DOMAIN / FUNCTIONAL ASSERTIONS
  // =========================================================================

  // F1: Overflow — RAM write must be gated when full
  property p_no_overflow;
    @(posedge wclk) disable iff (!wrst_n)
    wfull |-> !u_ram.wen;
  endproperty
  a_no_overflow: assert property (p_no_overflow)
    else $error("SVA FAIL: RAM write enabled while FIFO full — OVERFLOW");

  // F2: Underflow — RAM read must be gated when empty
  property p_no_underflow;
    @(posedge rclk) disable iff (!rrst_n)
    rempty |-> !u_ram.ren;
  endproperty
  a_no_underflow: assert property (p_no_underflow)
    else $error("SVA FAIL: RAM read enabled while FIFO empty — UNDERFLOW");

  // F3: Write pointer binary counter must be monotonically increasing
  property p_wptr_monotonic;
    logic [ADDR_WIDTH:0] prev_bin;
    @(posedge wclk) disable iff (!wrst_n)
    (1, prev_bin = u_wptr_full.wbin)
    |=> (u_wptr_full.wbin == prev_bin || u_wptr_full.wbin == prev_bin + 1);
  endproperty
  a_wptr_monotonic: assert property (p_wptr_monotonic)
    else $error("SVA FAIL: Write binary pointer skipped or went backwards");

  // F4: Read pointer binary counter must be monotonically increasing
  property p_rptr_monotonic;
    logic [ADDR_WIDTH:0] prev_bin;
    @(posedge rclk) disable iff (!rrst_n)
    (1, prev_bin = u_rptr_empty.rbin)
    |=> (u_rptr_empty.rbin == prev_bin || u_rptr_empty.rbin == prev_bin + 1);
  endproperty
  a_rptr_monotonic: assert property (p_rptr_monotonic)
    else $error("SVA FAIL: Read binary pointer skipped or went backwards");

  // =========================================================================
  // COVER PROPERTIES — functional coverage targets
  // =========================================================================

  // C1: FIFO reaches full
  c_fifo_full: cover property (@(posedge wclk) $rose(wfull));

  // C2: FIFO reaches empty after being non-empty
  c_fifo_empty: cover property (@(posedge rclk) $rose(rempty));

  // C3: Write while FIFO is full (tests backpressure)
  c_write_when_full: cover property (@(posedge wclk) wfull && winc);

  // C4: Read while FIFO is empty (tests underflow protection)
  c_read_when_empty: cover property (@(posedge rclk) rempty && rinc);

  // C5: Back-to-back writes filling FIFO from empty
  c_back2back_write_full: cover property (
    @(posedge wclk) (winc && !wfull) [*DEPTH] ##[0:4] wfull
  );

  // C6: Full-to-empty drain
  c_full_to_empty: cover property (
    @(posedge rclk) disable iff (!rrst_n)
    (!rempty) ##1 (rinc && !rempty) [*1:$] ##1 rempty
  );

  // C7: Full deasserts (proves read-side CDC works)
  c_full_deasserts: cover property (@(posedge wclk) $fell(wfull));

  // C8: Empty deasserts (proves write-side CDC works)
  c_empty_deasserts: cover property (@(posedge rclk) $fell(rempty));

endmodule
