//checker + golden model 

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)
  uvm_tlm_analysis_fifo #(fifo_seq_item) analysis_fifo; // receive from monitor

  // Golden model state
  // 1: FIFO
  bit [7:0] gold_queue[$];
  bit [7:0] ref_queue[$];
  bit       pending_read = 0;
  bit [7:0] pending_expected = 0;

  // counters for reporting
  int unsigned pass_match_count      = 0;
  int unsigned failed_mismatch_count   = 0;
  int unsigned total_count      = 0;
  localparam int DEPTH = 32;

  // constructor
  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // UVM phase
  // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_fifo = new("analysis_fifo", this);
  endfunction

  // run phase
  virtual task run_phase(uvm_phase phase);
    fifo_seq_item item;

    forever begin
      analysis_fifo.get(item);

      // blocking - waits for monitor data
      compare(item);
    end
  endtask

  // comparison logic - put golden model to life
  
  // 1. FIFO
  virtual function void compare(fifo_seq_item item);
    // compare item.actual_output vs expected_output
    // 1.0 reset check
    if (!item.rst_n) begin
      ref_queue.delete();
      pending_read = 0;
      total_count++;
      return; // skip all other checks during reset
    end

    // 1.1 data_out check (result of previous cycle's read)
    if (pending_read) begin
      if (item.data_out === pending_expected) begin
        `uvm_info(get)
      end
    end

  endfunction

endclass