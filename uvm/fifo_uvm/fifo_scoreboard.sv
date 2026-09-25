//checker + golden model 

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils((fifo_scoreboard)
  uvm_tlm_analysis_fifo #(fifo_seq_item) analysis_fifo; // receive from monitor

  // Golden model state
  // 1: FIFO
  bit [7:0] gold_queue[$];

  // counters for reporting
  int unsigned match_count      = 0;
  int unsigned mismatch_count   = 0;
  int unsigned total_count      = 0;

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
  virtual task run_phae(uvm_phase phase);
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
    
    // if valid_write:
    gold_queue.push_back(item.data_in)


  endfunction

endclass