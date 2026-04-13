// ============================================================================
// async_fifo_rd_driver.sv — Read-side driver
// ============================================================================
class async_fifo_rd_driver #(parameter int DATA_WIDTH = 8) extends uvm_driver #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_component_param_utils(async_fifo_rd_driver#(DATA_WIDTH))

  virtual async_fifo_if #(DATA_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual async_fifo_if#(DATA_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found for rd_driver")
  endfunction

  task run_phase(uvm_phase phase);
    async_fifo_seq_item#(DATA_WIDTH) item;

    vif.rd_cb.rinc <= 1'b0;

    forever begin
      seq_item_port.get_next_item(item);

      repeat (item.delay) @(vif.rd_cb);

      @(vif.rd_cb);
      vif.rd_cb.rinc <= 1'b1;

      @(vif.rd_cb);
      vif.rd_cb.rinc <= 1'b0;

      seq_item_port.item_done();
    end
  endtask

endclass
