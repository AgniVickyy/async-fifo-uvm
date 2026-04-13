// ============================================================================
// async_fifo_env.sv — UVM Environment
// ============================================================================
class async_fifo_env #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 3
) extends uvm_env;

  `uvm_component_param_utils(async_fifo_env#(DATA_WIDTH, ADDR_WIDTH))

  async_fifo_wr_agent    #(DATA_WIDTH)              wr_agent;
  async_fifo_rd_agent    #(DATA_WIDTH)              rd_agent;
  async_fifo_scoreboard  #(DATA_WIDTH, ADDR_WIDTH)  scoreboard;
  async_fifo_coverage    #(DATA_WIDTH, ADDR_WIDTH)  wr_cov;
  async_fifo_coverage    #(DATA_WIDTH, ADDR_WIDTH)  rd_cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_agent   = async_fifo_wr_agent#(DATA_WIDTH)::type_id::create("wr_agent", this);
    rd_agent   = async_fifo_rd_agent#(DATA_WIDTH)::type_id::create("rd_agent", this);
    scoreboard = async_fifo_scoreboard#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("scoreboard", this);
    wr_cov     = async_fifo_coverage#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("wr_cov", this);
    rd_cov     = async_fifo_coverage#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("rd_cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Scoreboard connections
    wr_agent.monitor.ap.connect(scoreboard.wr_imp);
    rd_agent.monitor.ap.connect(scoreboard.rd_imp);

    // Coverage connections
    wr_agent.monitor.ap.connect(wr_cov.analysis_export);
    rd_agent.monitor.ap.connect(rd_cov.analysis_export);
  endfunction

endclass
