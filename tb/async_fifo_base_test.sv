// ============================================================================
// async_fifo_base_test.sv — Base test + derived tests
// ============================================================================

// ---------------------------------------------------------------------------
// Base test — sets up env, resets, provides hooks
// ---------------------------------------------------------------------------
class async_fifo_base_test #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends uvm_test;

  `uvm_component_param_utils(async_fifo_base_test#(DATA_WIDTH, ADDR_WIDTH))

  async_fifo_env #(DATA_WIDTH, ADDR_WIDTH) env;
  virtual async_fifo_if #(DATA_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = async_fifo_env#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("env", this);

    if (!uvm_config_db#(virtual async_fifo_if#(DATA_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "No virtual interface in config_db")
  endfunction

  task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    vif.wrst_n = 1'b0;
    vif.rrst_n = 1'b0;
    vif.winc   = 1'b0;
    vif.rinc   = 1'b0;
    vif.wdata  = '0;
    #100;
    vif.wrst_n = 1'b1;
    vif.rrst_n = 1'b1;
    #50;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 1: Simple write then read — basic data integrity
// ---------------------------------------------------------------------------
class async_fifo_simple_test #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends async_fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(async_fifo_simple_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    async_fifo_wr_incr_seq #(DATA_WIDTH) wr_seq;
    async_fifo_rd_base_seq #(DATA_WIDTH) rd_seq;

    phase.raise_objection(this);

    // Write phase
    wr_seq = async_fifo_wr_incr_seq#(DATA_WIDTH)::type_id::create("wr_seq");
    wr_seq.num_items = (1 << ADDR_WIDTH);  // fill exactly
    wr_seq.start(env.wr_agent.sequencer);

    // Small gap for CDC sync
    #200;

    // Read phase
    rd_seq = async_fifo_rd_base_seq#(DATA_WIDTH)::type_id::create("rd_seq");
    rd_seq.num_items = (1 << ADDR_WIDTH);
    rd_seq.start(env.rd_agent.sequencer);

    #500;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 2: Concurrent read/write — stress CDC
// ---------------------------------------------------------------------------
class async_fifo_concurrent_test #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends async_fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(async_fifo_concurrent_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    async_fifo_wr_base_seq #(DATA_WIDTH) wr_seq;
    async_fifo_rd_base_seq #(DATA_WIDTH) rd_seq;

    phase.raise_objection(this);

    wr_seq = async_fifo_wr_base_seq#(DATA_WIDTH)::type_id::create("wr_seq");
    rd_seq = async_fifo_rd_base_seq#(DATA_WIDTH)::type_id::create("rd_seq");
    wr_seq.num_items = 50;
    rd_seq.num_items = 50;

    fork
      wr_seq.start(env.wr_agent.sequencer);
      begin
        #80;  // let writes get ahead
        rd_seq.start(env.rd_agent.sequencer);
      end
    join

    #1000;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 3: Overflow + underflow stress
// ---------------------------------------------------------------------------
class async_fifo_overflow_test #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends async_fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(async_fifo_overflow_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    async_fifo_wr_burst_seq #(DATA_WIDTH, ADDR_WIDTH) wr_burst;
    async_fifo_rd_burst_seq #(DATA_WIDTH, ADDR_WIDTH) rd_burst;

    phase.raise_objection(this);

    // Overflow: write beyond capacity
    wr_burst = async_fifo_wr_burst_seq#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("wr_burst");
    wr_burst.start(env.wr_agent.sequencer);
    #300;

    // Underflow: read beyond content
    rd_burst = async_fifo_rd_burst_seq#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("rd_burst");
    rd_burst.start(env.rd_agent.sequencer);

    #1000;
    phase.drop_objection(this);
  endtask

endclass
