// fifo_seq_item: one clock of stimulus (wr_en, rd_en, data_in) and the sampled outputs.

class fifo_seq_item extends uvm_sequence_item;

  // Stimulus

  rand bit       wr_en;    // Write enable command (1: push into FIFO)
  rand bit       rd_en;    // Read enable command  (1: pop from FIFO)
  rand bit [7:0] data_in;  // 8-bit data payload to write

  // Reset control, used by the RL knob sequence (fifo_knob_seq). Not randomized;
  // the directed and random tests leave rst_req = 0.
  bit       rst_req = 1'b0; // 1: driver holds rst_n low for this cycle (no read/write)
  bit       rst_n;          // rst_n as sampled by the monitor

  bit [7:0] data_out;     // 8-bit data payload read from FIFO
  bit       full;          // FIFO full status indicator
  bit       empty;         // FIFO empty status indicator

  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(wr_en,    UVM_ALL_ON)
    `uvm_field_int(rd_en,    UVM_ALL_ON)
    `uvm_field_int(data_in,  UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(data_out, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(full,     UVM_ALL_ON)
    `uvm_field_int(empty,    UVM_ALL_ON)
  `uvm_object_utils_end

  constraint c_valid_op {
    (wr_en || rd_en) dist {
      1'b1 := 80,
      1'b0 := 20
    };
  }

  // Writes 60%, reads 40%: the FIFO drifts toward full, so full and empty are both reached
  constraint c_wr_dist {
    wr_en dist {
      1'b1 := 60,
      1'b0 := 40
    };
  }

  constraint c_rd_dist {
    rd_en dist {
      1'b1 := 40,
      1'b0 := 60
    };
  }

  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction : new

  virtual function void do_copy(uvm_object rhs);
    fifo_seq_item rhs_;

    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal(get_type_name(), "Cast failed in do_copy(): rhs is not of type fifo_seq_item")
      return;
    end

    super.do_copy(rhs);

    this.wr_en    = rhs_.wr_en;
    this.rd_en    = rhs_.rd_en;
    this.data_in  = rhs_.data_in;
    this.rst_req  = rhs_.rst_req;
    this.rst_n    = rhs_.rst_n;
    this.data_out = rhs_.data_out;
    this.full     = rhs_.full;
    this.empty    = rhs_.empty;
  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    fifo_seq_item rhs_;

    if (!$cast(rhs_, rhs)) begin
      `uvm_warning(get_type_name(), "Cast failed in do_compare(): rhs is not of type fifo_seq_item")
      return 0;
    end

    return (super.do_compare(rhs, comparer) &&
            (this.wr_en    == rhs_.wr_en)   &&
            (this.rd_en    == rhs_.rd_en)   &&
            (this.data_in  == rhs_.data_in)  &&
            (this.data_out == rhs_.data_out) &&
            (this.full     == rhs_.full)     &&
            (this.empty    == rhs_.empty));
  endfunction : do_compare

  virtual function string convert2string();
    return $sformatf("wr_en=%0b rd_en=%0b data_in=0x%02h data_out=0x%02h full=%0b empty=%0b",
                     wr_en, rd_en, data_in, data_out, full, empty);
  endfunction : convert2string

endclass : fifo_seq_item
