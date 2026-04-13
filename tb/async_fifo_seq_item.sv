// ============================================================================
// async_fifo_seq_item.sv — Transaction object
// ============================================================================
class async_fifo_seq_item #(parameter int DATA_WIDTH = 8) extends uvm_sequence_item;

  `uvm_object_param_utils(async_fifo_seq_item#(DATA_WIDTH))

  // Randomizable fields
  rand logic [DATA_WIDTH-1:0] data;
  rand int unsigned           delay;  // inter-transaction delay (cycles)
  rand bit                    op;     // 0 = write, 1 = read

  // Constraints
  constraint c_delay { delay inside {[0:10]}; }

  // Response fields (filled by monitor)
  logic [DATA_WIDTH-1:0] rdata;
  bit                    full_flag;
  bit                    empty_flag;

  function new(string name = "async_fifo_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("op=%s data=0x%0h delay=%0d full=%0b empty=%0b",
                     op ? "RD" : "WR", data, delay, full_flag, empty_flag);
  endfunction

endclass
