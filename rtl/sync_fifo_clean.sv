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
assign full = (count == DEPTH);


//pointers' operations
//write
always_ff @(posedge clk) begin
  if (!rst_n) begin
    wr_ptr <= 0;
  end else if (wr_en && !full) begin
    mem[wr_ptr] <= data_in;
    wr_ptr <= wr_ptr + 1;
  end
end

//read
always_ff @(posedge clk) begin
  if (!rst_n) begin
    rd_ptr <= 0;
    data_out <= 0;
  end else if (rd_en && !empty) begin
    data_out <= mem[rd_ptr];
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
      2'b11: count <= count; //wr + rd
      default: count <= count;
    endcase
  end
end

endmodule