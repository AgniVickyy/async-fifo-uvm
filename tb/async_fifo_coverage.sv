// ============================================================================
// async_fifo_coverage.sv — Functional coverage collector
//
// Collects covergroups for both write and read domains.
// Subscribes to monitors via analysis ports.
// ============================================================================
class async_fifo_coverage #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends uvm_subscriber #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_component_param_utils(async_fifo_coverage#(DATA_WIDTH, ADDR_WIDTH))

  localparam int DEPTH = 1 << ADDR_WIDTH;

  // Sampled signals
  logic [DATA_WIDTH-1:0] data;
  bit                    full_flag;
  bit                    empty_flag;
  bit                    op;  // 0=WR, 1=RD

  // Track fill level in reference model (approximate)
  int fill_level;

  // ---- Write-side covergroup ----
  covergroup cg_write @(wr_sample_event);
    cp_wdata: coverpoint data {
      bins zero     = {0};
      bins max_val  = {{DATA_WIDTH{1'b1}}};
      bins low      = {[1:63]};
      bins mid      = {[64:191]};
      bins high     = {[192:254]};
    }

    cp_wfull: coverpoint full_flag {
      bins not_full = {0};
      bins full     = {1};
    }

    cp_fill_level: coverpoint fill_level {
      bins empty       = {0};
      bins low         = {[1:DEPTH/4]};
      bins mid         = {[DEPTH/4+1:3*DEPTH/4]};
      bins high        = {[3*DEPTH/4+1:DEPTH-1]};
      bins full        = {DEPTH};
    }

    cross_wdata_full: cross cp_wdata, cp_wfull;
  endgroup

  // ---- Read-side covergroup ----
  covergroup cg_read @(rd_sample_event);
    cp_rdata: coverpoint data {
      bins zero     = {0};
      bins max_val  = {{DATA_WIDTH{1'b1}}};
      bins low      = {[1:63]};
      bins mid      = {[64:191]};
      bins high     = {[192:254]};
    }

    cp_rempty: coverpoint empty_flag {
      bins not_empty = {0};
      bins empty     = {1};
    }

    cp_fill_level: coverpoint fill_level {
      bins empty       = {0};
      bins low         = {[1:DEPTH/4]};
      bins mid         = {[DEPTH/4+1:3*DEPTH/4]};
      bins high        = {[3*DEPTH/4+1:DEPTH-1]};
      bins full        = {DEPTH};
    }

    cross_rdata_empty: cross cp_rdata, cp_rempty;
  endgroup

  // ---- Transition covergroup — tracks state machine behavior ----
  covergroup cg_transitions @(any_sample_event);
    cp_op: coverpoint op {
      bins write      = {0};
      bins read       = {1};
      bins wr_then_rd = (0 => 1);
      bins rd_then_wr = (1 => 0);
      bins wr_wr      = (0 => 0);
      bins rd_rd      = (1 => 1);
    }

    cp_fill_transitions: coverpoint fill_level {
      bins empty_to_nonempty = (0      => [1:DEPTH]);
      bins nonempty_to_empty = ([1:$]  => 0);
      bins fill_to_full      = ([0:$]  => DEPTH);
      bins full_to_notfull   = (DEPTH  => [0:DEPTH-1]);
    }
  endgroup

  // Events for covergroup sampling
  event wr_sample_event;
  event rd_sample_event;
  event any_sample_event;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_write       = new();
    cg_read        = new();
    cg_transitions = new();
    fill_level     = 0;
  endfunction

  // uvm_subscriber write() — called by analysis port
  function void write(async_fifo_seq_item#(DATA_WIDTH) t);
    op = t.op;

    if (t.op == 0) begin  // Write transaction
      data       = t.data;
      full_flag  = t.full_flag;
      if (fill_level < DEPTH) fill_level++;
      -> wr_sample_event;
    end else begin         // Read transaction
      data       = t.rdata;
      empty_flag = t.empty_flag;
      if (fill_level > 0) fill_level--;
      -> rd_sample_event;
    end

    -> any_sample_event;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV", $sformatf("Write  coverage: %.1f%%", cg_write.get_coverage()), UVM_LOW)
    `uvm_info("COV", $sformatf("Read   coverage: %.1f%%", cg_read.get_coverage()), UVM_LOW)
    `uvm_info("COV", $sformatf("Trans  coverage: %.1f%%", cg_transitions.get_coverage()), UVM_LOW)
  endfunction

endclass
