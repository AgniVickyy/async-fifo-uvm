// ============================================================================
// async_fifo_rd_agent.sv — Read-side agent
// ============================================================================
class async_fifo_rd_agent #(parameter int DATA_WIDTH = 8) extends uvm_agent;

  `uvm_component_param_utils(async_fifo_rd_agent#(DATA_WIDTH))

  async_fifo_rd_driver  #(DATA_WIDTH) driver;
  async_fifo_rd_monitor #(DATA_WIDTH) monitor;
  uvm_sequencer         #(async_fifo_seq_item#(DATA_WIDTH)) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = async_fifo_rd_monitor#(DATA_WIDTH)::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = async_fifo_rd_driver#(DATA_WIDTH)::type_id::create("driver", this);
      sequencer = uvm_sequencer#(async_fifo_seq_item#(DATA_WIDTH))::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
