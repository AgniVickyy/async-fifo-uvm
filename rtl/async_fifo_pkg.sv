// ============================================================================
// async_fifo_pkg.sv — Shared parameters and types
// ============================================================================
package async_fifo_pkg;

  parameter int DEFAULT_DEPTH = 8;
  parameter int DEFAULT_WIDTH = 8;

  // Utility: binary to Gray
  function automatic logic [31:0] bin2gray(input logic [31:0] bin);
    return bin ^ (bin >> 1);
  endfunction

  // Utility: Gray to binary
  function automatic logic [31:0] gray2bin(input logic [31:0] gray);
    logic [31:0] bin;
    bin[31] = gray[31];
    for (int i = 30; i >= 0; i--)
      bin[i] = bin[i+1] ^ gray[i];
    return bin;
  endfunction

endpackage
