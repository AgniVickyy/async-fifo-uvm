// ============================================================================
// async_fifo_wr_driver.sv — Write-side driver
// ============================================================================
class async_fifo_wr_driver #(parameter int DATA_WIDTH = 8) extends uvm_driver #(async_fifo_seq_item#(DATA_WIDTH));

  `uvm_component_param_utils(async_fifo_wr_driver#(DATA_WIDTH))

  virtual async_fifo_if #(DATA_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual async_fifo_if#(DATA_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found for wr_driver")
  endfunction

  task run_phase(uvm_phase phase);
    async_fifo_seq_item#(DATA_WIDTH) item;

    // Initialize
    vif.wr_cb.winc  <= 1'b0;
    vif.wr_cb.wdata <= '0;

    forever begin
      seq_item_port.get_next_item(item);

      // Inter-transaction delay
      repeat (item.delay) @(vif.wr_cb);

      // Drive write
      @(vif.wr_cb);
      vif.wr_cb.winc  <= 1'b1;
      vif.wr_cb.wdata <= item.data;

      @(vif.wr_cb);
      vif.wr_cb.winc <= 1'b0;

      seq_item_port.item_done();
    end
  endtask

endclass
