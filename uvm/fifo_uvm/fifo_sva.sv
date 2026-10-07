module fifo_sva #(
  parameter int DATA_WIDTH = 8,
  parameter int DEPTH      = 32
)(
  input logic                    clk,
  input logic                    rst_n,
  input logic                    wr_en,
  input logic                    rd_en,
  input logic [DATA_WIDTH-1:0]   data_in,
  input logic [DATA_WIDTH-1:0]   data_out,
  input logic                    full,
  input logic                    empty,
  // Internal signals (accessible via bind)
  input logic [$clog2(DEPTH)-1:0] wr_ptr,
  input logic [$clog2(DEPTH)-1:0] rd_ptr,
  input logic [$clog2(DEPTH):0]   count
);

default clocking cb@(posedge clk); 
endclocking

default disable iff (!rst_n); // supress during reset

// Property definitions + assertions

// Safety properties (must always hold)

property p_count_bounds;
  count <= DEPTH;
endproperty

a_count_bounds: assert property (p_count_bounds)
  else begin
    $error("Count out of bounds: %0d", count);
  end

property p_full_empty_mutex;
  !(full && empty);
endproperty

a_full_empty_mutex: assert property (p_full_empty_mutex)
  else begin
    error("Full & Empty both asserted!");
  end

// Equiv properties

property p_full_iff_depth;
  full == (count == DEPTH);
endproperty

a_full_iff_depth: assert property (p_full_iff_depth)
  else begin
$error("Full flag mismatch: full=%b, count=%0d", full, count);  
end

// Tempo properties (sequence of events)

property p_stable_wr_ptr_when_full;
  full |=> $stable(wr_ptr) || !full;
endproperty

a_stable_wr_ptr_when_full: assert property (p_stable_wr_ptr_when_full)
  else begin
    $error("wr_ptr changed while full!");  
  end

// Cover properties (for coverage)
c_full_reached:   cover property (full);
c_empty_reached:  cover property (empty);
c_simul_rw:       cover property (wr_en && rd_en && !full && !empty);

endmodule