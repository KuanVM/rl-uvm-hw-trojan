// fifo_assertions: concurrent assertions and cover properties for sync_fifo.
// Bound to the DUT in tb_top, so wr_ptr, rd_ptr and count are visible.

module fifo_assertions #(
  parameter int DATA_WIDTH = 8,
  parameter int DEPTH      = 32
) (
  input logic                    clk,
  input logic                    rst_n,
  input logic                    wr_en,
  input logic                    rd_en,
  input logic [DATA_WIDTH-1:0]   data_in,
  input logic [DATA_WIDTH-1:0]   data_out,
  input logic                    full,
  input logic                    empty,
  // DUT internal signals, connected through bind
  input logic [$clog2(DEPTH)-1:0] wr_ptr,
  input logic [$clog2(DEPTH)-1:0] rd_ptr,
  input logic [$clog2(DEPTH):0]   count
);

  // A01: empty and not full when reset is released
  property p_reset_state;
    @(posedge clk) $rose(rst_n) |-> (empty && !full);
  endproperty
  A01_RESET_STATE: assert property (p_reset_state)
    else `ifdef UVM_PKG_SV
      `uvm_error("SVA", "A01: FIFO not in clean state after reset")
    `else
      $error("A01: FIFO not in clean state after reset");
    `endif

  // A02: full == (count == DEPTH)

  property p_full_iff_depth;
    @(posedge clk) disable iff (!rst_n)
      full == (count == DEPTH);
  endproperty
  A02_FULL_IFF_DEPTH: assert property (p_full_iff_depth)
    else $error("A02: full=%0b but count=%0d (DEPTH=%0d)", full, count, DEPTH);

  // A03: empty == (count == 0)

  property p_empty_iff_zero;
    @(posedge clk) disable iff (!rst_n)
      empty == (count == 0);
  endproperty
  A03_EMPTY_IFF_ZERO: assert property (p_empty_iff_zero)
    else $error("A03: empty=%0b but count=%0d", empty, count);

  // A04: a write while full does not move wr_ptr
  property p_no_wr_when_full;
    @(posedge clk) disable iff (!rst_n)
      (full && wr_en) |=> $stable(wr_ptr);
  endproperty
  A04_NO_WR_WHEN_FULL: assert property (p_no_wr_when_full)
    else $error("A04: wr_ptr changed while FIFO was full!");

  // A05: a read while empty does not move rd_ptr

  property p_no_rd_when_empty;
    @(posedge clk) disable iff (!rst_n)
      (empty && rd_en) |=> $stable(rd_ptr);
  endproperty
  A05_NO_RD_WHEN_EMPTY: assert property (p_no_rd_when_empty)
    else $error("A05: rd_ptr changed while FIFO was empty!");

  // A06: count never exceeds DEPTH
  property p_count_bounds;
    @(posedge clk) disable iff (!rst_n)
      count <= DEPTH;
  endproperty
  A06_COUNT_BOUNDS: assert property (p_count_bounds)
    else $error("A06: count=%0d exceeds DEPTH=%0d!", count, DEPTH);

  // A07: full and empty are never both high

  property p_full_empty_mutex;
    @(posedge clk) disable iff (!rst_n)
      !(full && empty);
  endproperty
  A07_FULL_EMPTY_MUTEX: assert property (p_full_empty_mutex)
    else $error("A07: full and empty are both asserted!");

  // A08: count +1 on a write without a read

  property p_count_inc_on_write;
    @(posedge clk) disable iff (!rst_n)
      (wr_en && !full && !(rd_en && !empty)) |=> (count == $past(count) + 1);
  endproperty
  A08_COUNT_INC_ON_WRITE: assert property (p_count_inc_on_write)
    else $error("A08: count did not increment on valid write");

  // A09: count -1 on a read without a write

  property p_count_dec_on_read;
    @(posedge clk) disable iff (!rst_n)
      (rd_en && !empty && !(wr_en && !full)) |=> (count == $past(count) - 1);
  endproperty
  A09_COUNT_DEC_ON_READ: assert property (p_count_dec_on_read)
    else $error("A09: count did not decrement on valid read");

  // A10: count unchanged on a read and a write in the same cycle

  property p_count_stable_on_rw;
    @(posedge clk) disable iff (!rst_n)
      (wr_en && !full && rd_en && !empty) |=> $stable(count);
  endproperty
  A10_COUNT_STABLE_ON_RW: assert property (p_count_stable_on_rw)
    else $error("A10: count changed on simultaneous valid R+W");

  // Cover properties: corner cases that must occur

  C01_FULL_REACHED:  cover property (@(posedge clk) $rose(full));
  C02_EMPTY_REACHED: cover property (@(posedge clk) $rose(empty));
  C03_SIMULTANEOUS:  cover property (@(posedge clk) (wr_en && !full && rd_en && !empty));
  C04_WR_WHEN_FULL:  cover property (@(posedge clk) (wr_en && full));
  C05_RD_WHEN_EMPTY: cover property (@(posedge clk) (rd_en && empty));

endmodule
