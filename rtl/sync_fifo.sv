// -----------------------------------------------------------------------------
// Bug injection (verification only). All switches are OFF by default, so the
// design below behaves as the clean RTL. Enable one with +define+<NAME>:
//   BUG_FULL_EARLY       full asserts at DEPTH-1 entries
//   BUG_WRITE_WHEN_FULL  write is not blocked when full (overwrites oldest data)
//   BUG_READ_WHEN_EMPTY  read is not blocked when empty (pointer underflow)
//   BUG_COUNT_RW         simultaneous read+write increments count
//   BUG_DATA_BITFLIP     bit 0 of data_out flips when reading entry 5
// Used by: tb/Makefile target "bugs" (see doc/results/bug_report.txt)
// -----------------------------------------------------------------------------
module sync_fifo #(
  parameter int DATA_WIDTH = 8, 
  parameter int DEPTH = 32
) 
(
  input logic clk,
  input logic rst_n,
  input logic wr_en,
  input logic rd_en,
  input logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  output logic full,
  output logic empty
);

localparam PTR_WIDTH  = $clog2(DEPTH); 

//memory array
logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

//pointers
logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;

//status counter
logic [PTR_WIDTH:0] count;

//full / empty logic
assign empty = (count == 0);
`ifdef BUG_FULL_EARLY
assign full = (count == DEPTH-1);
`else
assign full = (count == DEPTH);
`endif


//pointers' operations
//write
always_ff @(posedge clk) begin
  if (!rst_n) begin
    wr_ptr <= 0;
`ifdef BUG_WRITE_WHEN_FULL
  end else if (wr_en) begin
`else
  end else if (wr_en && !full) begin
`endif
    mem[wr_ptr] <= data_in;
    wr_ptr <= wr_ptr + 1;
  end
end

//read
always_ff @(posedge clk) begin
  if (!rst_n) begin
    rd_ptr <= 0;
    data_out <= 0;
`ifdef BUG_READ_WHEN_EMPTY
  end else if (rd_en) begin
`else
  end else if (rd_en && !empty) begin
`endif
`ifdef BUG_DATA_BITFLIP
    data_out <= mem[rd_ptr] ^ ((rd_ptr == 5) ? 1 : 0);
`else
    data_out <= mem[rd_ptr];
`endif
    rd_ptr <= rd_ptr + 1;
  end
end

//counter
always_ff @(posedge clk) begin
  if (!rst_n) begin
    count <= 0;
  end else begin
    case ({wr_en && !full, rd_en && !empty})
      2'b00: count <= count;
      2'b01: count <= count - 1; //rd only
      2'b10: count <= count + 1; //wr only
`ifdef BUG_COUNT_RW
      2'b11: count <= count + 1; //wr + rd (injected bug)
`else
      2'b11: count <= count; //wr + rd
`endif
      default: count <= count;
    endcase
  end
end

endmodule