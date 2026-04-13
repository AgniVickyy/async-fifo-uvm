// ============================================================================
// async_fifo_tb_pkg.sv — Package with all UVM components
// ============================================================================
package async_fifo_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import async_fifo_pkg::*;

  // Transaction
  `include "async_fifo_seq_item.sv"

  // Drivers
  `include "async_fifo_wr_driver.sv"
  `include "async_fifo_rd_driver.sv"

  // Monitors
  `include "async_fifo_wr_monitor.sv"
  `include "async_fifo_rd_monitor.sv"

  // Scoreboard (includes `uvm_analysis_imp_decl macros at file scope)
  `include "async_fifo_scoreboard.sv"

  // Coverage
  `include "async_fifo_coverage.sv"

  // Agents
  `include "async_fifo_wr_agent.sv"
  `include "async_fifo_rd_agent.sv"

  // Environment
  `include "async_fifo_env.sv"

  // Sequences
  `include "async_fifo_sequences.sv"

  // Tests
  `include "async_fifo_base_test.sv"

endpackage
