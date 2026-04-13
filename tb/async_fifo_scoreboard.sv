// ============================================================================
// async_fifo_scoreboard.sv — Reference model + checker
// ============================================================================
// IMP macros MUST be at package scope — they generate new classes
`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class async_fifo_scoreboard #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends uvm_scoreboard;

  `uvm_component_param_utils(async_fifo_scoreboard#(DATA_WIDTH, ADDR_WIDTH))

  uvm_analysis_imp_wr #(async_fifo_seq_item#(DATA_WIDTH), async_fifo_scoreboard#(DATA_WIDTH, ADDR_WIDTH)) wr_imp;
  uvm_analysis_imp_rd #(async_fifo_seq_item#(DATA_WIDTH), async_fifo_scoreboard#(DATA_WIDTH, ADDR_WIDTH)) rd_imp;

  // Reference FIFO
  logic [DATA_WIDTH-1:0] ref_queue[$];

  // Out-of-order buffer: reads that arrive before corresponding write
  // (due to CDC + simulator event scheduling across clock domains)
  async_fifo_seq_item#(DATA_WIDTH) pending_rd[$];

  // Statistics
  int unsigned wr_count;
  int unsigned rd_count;
  int unsigned match_count;
  int unsigned mismatch_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_imp = new("wr_imp", this);
    rd_imp = new("rd_imp", this);
  endfunction

  // Called by write monitor
  function void write_wr(async_fifo_seq_item#(DATA_WIDTH) item);
    ref_queue.push_back(item.data);
    wr_count++;
    `uvm_info("SCB", $sformatf("WR: data=0x%0h ref_queue_size=%0d", item.data, ref_queue.size()), UVM_MEDIUM)

    // Drain any pending reads that arrived before this write
    while (pending_rd.size() > 0 && ref_queue.size() > 0) begin
      check_rd(pending_rd.pop_front());
    end
  endfunction

  // Called by read monitor
  function void write_rd(async_fifo_seq_item#(DATA_WIDTH) item);
    rd_count++;

    if (ref_queue.size() == 0) begin
      // Write monitor hasn't fired yet due to CDC / event ordering — buffer it
      pending_rd.push_back(item);
      `uvm_info("SCB", $sformatf("RD: data=0x%0h buffered (ref_queue empty, awaiting write)", item.rdata), UVM_MEDIUM)
      return;
    end

    check_rd(item);
  endfunction

  // Internal: compare read data against reference
  function void check_rd(async_fifo_seq_item#(DATA_WIDTH) item);
    logic [DATA_WIDTH-1:0] expected;

    expected = ref_queue.pop_front();
    if (item.rdata === expected) begin
      match_count++;
      `uvm_info("SCB", $sformatf("RD MATCH: got=0x%0h exp=0x%0h", item.rdata, expected), UVM_MEDIUM)
    end else begin
      mismatch_count++;
      `uvm_error("SCB", $sformatf("RD MISMATCH: got=0x%0h exp=0x%0h", item.rdata, expected))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB", "========== SCOREBOARD SUMMARY ==========", UVM_LOW)
    `uvm_info("SCB", $sformatf("  Writes:     %0d", wr_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Reads:      %0d", rd_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Matches:    %0d", match_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Mismatches: %0d", mismatch_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Residual:   %0d entries in ref_queue", ref_queue.size()), UVM_LOW)

    if (pending_rd.size() > 0)
      `uvm_error("SCB", $sformatf("  Unresolved pending reads: %0d", pending_rd.size()))

    if (mismatch_count > 0 || pending_rd.size() > 0)
      `uvm_error("SCB", "*** TEST FAILED — data mismatches detected ***")
    else
      `uvm_info("SCB", "*** TEST PASSED ***", UVM_LOW)
  endfunction

endclass
