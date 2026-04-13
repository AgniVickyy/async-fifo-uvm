// ============================================================================
// async_fifo_sequences.sv — Test sequences
// ============================================================================

// ---------------------------------------------------------------------------
// Base write sequence
// ---------------------------------------------------------------------------
class async_fifo_wr_base_seq #(parameter int DATA_WIDTH = 8)
  extends uvm_sequence #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_object_param_utils(async_fifo_wr_base_seq#(DATA_WIDTH))

  int unsigned num_items = 20;

  function new(string name = "wr_base_seq");
    super.new(name);
  endfunction

  task body();
    async_fifo_seq_item#(DATA_WIDTH) item;
    repeat (num_items) begin
      item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with { op == 0; })
        `uvm_fatal("SEQ", "Randomization failed")
      finish_item(item);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// Base read sequence
// ---------------------------------------------------------------------------
class async_fifo_rd_base_seq #(parameter int DATA_WIDTH = 8)
  extends uvm_sequence #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_object_param_utils(async_fifo_rd_base_seq#(DATA_WIDTH))

  int unsigned num_items = 20;

  function new(string name = "rd_base_seq");
    super.new(name);
  endfunction

  task body();
    async_fifo_seq_item#(DATA_WIDTH) item;
    repeat (num_items) begin
      item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with { op == 1; })
        `uvm_fatal("SEQ", "Randomization failed")
      finish_item(item);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// Burst write — fill FIFO completely, then write more (overflow stress)
// ---------------------------------------------------------------------------
class async_fifo_wr_burst_seq #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends uvm_sequence #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_object_param_utils(async_fifo_wr_burst_seq#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "wr_burst_seq");
    super.new(name);
  endfunction

  task body();
    async_fifo_seq_item#(DATA_WIDTH) item;
    // Write DEPTH + 4 items (tests overflow protection)
    repeat ((1 << ADDR_WIDTH) + 4) begin
      item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with { op == 0; delay == 0; })
        `uvm_fatal("SEQ", "Randomization failed")
      finish_item(item);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// Burst read — drain FIFO completely, then read more (underflow stress)
// ---------------------------------------------------------------------------
class async_fifo_rd_burst_seq #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends uvm_sequence #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_object_param_utils(async_fifo_rd_burst_seq#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "rd_burst_seq");
    super.new(name);
  endfunction

  task body();
    async_fifo_seq_item#(DATA_WIDTH) item;
    repeat ((1 << ADDR_WIDTH) + 4) begin
      item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with { op == 1; delay == 0; })
        `uvm_fatal("SEQ", "Randomization failed")
      finish_item(item);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// Incremental data write — deterministic pattern for debug
// ---------------------------------------------------------------------------
class async_fifo_wr_incr_seq #(parameter int DATA_WIDTH = 8)
  extends uvm_sequence #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_object_param_utils(async_fifo_wr_incr_seq#(DATA_WIDTH))

  int unsigned num_items = 16;

  function new(string name = "wr_incr_seq");
    super.new(name);
  endfunction

  task body();
    async_fifo_seq_item#(DATA_WIDTH) item;
    for (int i = 0; i < num_items; i++) begin
      item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with { op == 0; data == local::i[DATA_WIDTH-1:0]; delay inside {[0:2]}; })
        `uvm_fatal("SEQ", "Randomization failed")
      finish_item(item);
    end
  endtask

endclass
