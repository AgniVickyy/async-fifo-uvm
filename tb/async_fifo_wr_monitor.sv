// ============================================================================
// async_fifo_wr_monitor.sv — Write-side monitor
// ============================================================================
class async_fifo_wr_monitor #(parameter int DATA_WIDTH = 8) extends uvm_monitor;

  `uvm_component_param_utils(async_fifo_wr_monitor#(DATA_WIDTH))

  virtual async_fifo_if #(DATA_WIDTH) vif;

  uvm_analysis_port #(async_fifo_seq_item#(DATA_WIDTH)) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("wr_mon_ap", this);
    if (!uvm_config_db#(virtual async_fifo_if#(DATA_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found for wr_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    async_fifo_seq_item#(DATA_WIDTH) item;

    forever begin
      @(vif.wr_mon_cb);
      if (vif.wr_mon_cb.winc && !vif.wr_mon_cb.wfull) begin
        item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("wr_item");
        item.op        = 0;  // write
        item.data      = vif.wr_mon_cb.wdata;
        item.full_flag = vif.wr_mon_cb.wfull;
        ap.write(item);
        `uvm_info("WR_MON", item.convert2string(), UVM_HIGH)
      end
    end
  endtask

endclass
