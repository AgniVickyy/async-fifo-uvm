// ============================================================================
// async_fifo_rd_monitor.sv — Read-side monitor
// ============================================================================
class async_fifo_rd_monitor #(parameter int DATA_WIDTH = 8) extends uvm_monitor;

  `uvm_component_param_utils(async_fifo_rd_monitor#(DATA_WIDTH))

  virtual async_fifo_if #(DATA_WIDTH) vif;

  uvm_analysis_port #(async_fifo_seq_item#(DATA_WIDTH)) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("rd_mon_ap", this);
    if (!uvm_config_db#(virtual async_fifo_if#(DATA_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found for rd_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    async_fifo_seq_item#(DATA_WIDTH) item;

    forever begin
      @(vif.rd_mon_cb);
      if (vif.rd_mon_cb.rinc && !vif.rd_mon_cb.rempty) begin
        // Wait one more cycle for registered RAM output
        @(vif.rd_mon_cb);
        item = async_fifo_seq_item#(DATA_WIDTH)::type_id::create("rd_item");
        item.op         = 1;  // read
        item.rdata      = vif.rd_mon_cb.rdata;
        item.empty_flag = vif.rd_mon_cb.rempty;
        ap.write(item);
        `uvm_info("RD_MON", item.convert2string(), UVM_HIGH)
      end
    end
  endtask

endclass
