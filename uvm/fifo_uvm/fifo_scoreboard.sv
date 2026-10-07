//checker + golden model 

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)
  uvm_tlm_analysis_fifo #(fifo_seq_item) analysis_fifo; // receive from monitor

  // Golden model state
  // 1: FIFO
  bit [7:0] ref_queue[$];
  bit       pending_read = 0;
  bit [7:0] pending_expected = 0;

  // counters for reporting
  int unsigned pass_match_count        = 0;
  int unsigned failed_mismatch_count   = 0;
  int unsigned total_count             = 0;
  int unsigned flag_mismatch_count     = 0;
  localparam int DEPTH                 = 32;

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

    // 1.1 FIFO_data_out check (result of previous cycle's read)
    if (pending_read) begin
      if (item.data_out === pending_expected) begin
        `uvm_info(get_type_name(),
        $sformatf("1.1 [FIFO_DATA_OUT_CHK] PASS: data_out = 0x%02h, expected = 0x%02h", item.data_out, pending_expected), UVM_HIGH)
        
        pass_match_count++;
      end else begin
        `uvm_error(get_type_name(),
        $sformatf("1.1 [FIFO_DATA_OUT_CHK] FAIL: data_out = 0x%02h, expected = 0x%02h | ref_queue size = %0d", item.data_out, pending_expected,ref_queue.size()))
        
        failed_mismatch_count++;
      end
      pending_read = 0;
    end

    // 1.2 FIFO flag check (full / empty must match ref_queue size)
    begin
      bit expected_full  = (ref_queue.size() == DEPTH);
      bit expected_empty = (ref_queue.size() == 0 );

      // full check
      if (item.full !== expected_full) begin
      `uvm_error(get_type_name(),
        $sformatf("1.2 [FIFO_FLAG_CHK] FLAG FAIL: full = %0b, expected = %0b, | ref_queue size = %0d", item.full, expected_full, ref_queue.size()))
          flag_mismatch_count++;
      end

      // empty check

      if (item.empty != expected_empty) begin
        `uvm_error(get_type_name(),
          $sformatf("1.2 [FIFO_FLAG_CHK] FLAG FAIL: empty = %0b, expected = %0b | ref_queue size = %0d", item.empty, expected_empty, ref_queue.size()))
        flag_mismatch_count++;
        end
    end

    // 1.3 FIFO compute actual accept signals - gate by REF occupancy, not DUT flags
    begin 
      bit wr_accept = item.wr_en && (ref_queue.size() != DEPTH);
      bit rd_accept = item.rd_en && (ref_queue.size() != 0);
    
      // --- process READ first: pop expected value, store for next cycle
        if (rd_accept) begin
          pending_expected = ref_queue.pop_front();
          pending_read = 1;
        end

      // --- process WRITE: push into golden model ---
        if (wr_accept) begin
          ref_queue.push_back(item.data_in);
        end

      // --- unchanged data_out check; if no valid read, data_out must be stable ---
        
    end
    total_count++;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
      $sformatf("\n========================================\n  SCOREBOARD SUMMARY\n  Total transactions : %0d\n  Data matches (1.1 FIFO_data_out check): %0d\n  Data mismatches: %0d\n  Flag mismatches (1.2): %0d\n========================================", total_count, pass_match_count, failed_mismatch_count, flag_mismatch_count), UVM_LOW
    )
    if (failed_mismatch_count >0 || flag_mismatch_count > 0) begin 
      `uvm_error(get_type_name(), "SCOREBOARD: TEST FAILED - mismatches detected")
    end
  endfunction
endclass  