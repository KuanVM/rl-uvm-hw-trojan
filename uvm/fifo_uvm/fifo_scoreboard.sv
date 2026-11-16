// fifo_scoreboard: queue reference model.
// A read sets an expectation that is checked on the next item, because data_out is registered.

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)

  // FIFO depth, can be overridden with config_db key "depth"
  int depth = 32;

  uvm_tlm_analysis_fifo #(fifo_seq_item) mon_fifo;

  // Reference model
  bit [7:0] ref_queue[$];

  // Model occupancy
  int ref_count = 0;

  // Set when a read was accepted on the previous item; data_out is checked on this item
  bit expect_read = 0;

  // Value popped for the pending read
  bit [7:0] expected_data;

  int num_writes     = 0;  // Total valid write operations accepted by reference model
  int num_reads      = 0;  // Total read operations verified against reference model
  int num_matches    = 0;  // Successful comparisons where data_out === expected_data
  int num_mismatches = 0;  // Comparison errors where data_out !== expected_data
  int num_reset_cycles = 0; // Cycles sampled with rst_n = 0 (model cleared)

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    mon_fifo = new("mon_fifo", this);

    void'(uvm_config_db#(int)::get(this, "", "depth", depth));

    `uvm_info(get_type_name(),
      $sformatf("Built scoreboard with configured DEPTH = %0d", depth),
      UVM_MEDIUM)
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    fifo_seq_item item;

    forever begin
      mon_fifo.get(item);

      `uvm_info(get_type_name(),
        $sformatf("Processing item: %s | ref_count=%0d, queue_size=%0d, expect_read=%0b",
                  item.convert2string(), ref_count, ref_queue.size(), expect_read),
        UVM_DEBUG)

      // Synchronous reset: the DUT empties at this edge, so clear the model.
      // Also covers the initial reset (the monitor samples from time 0).
      if (!item.rst_n) begin
        ref_queue.delete();
        ref_count   = 0;
        expect_read = 1'b0;
        num_reset_cycles++;
        continue;
      end

      if (expect_read) begin
        num_reads++;
        if (item.data_out === expected_data) begin
          num_matches++;
          `uvm_info(get_type_name(),
            $sformatf("[MATCH] Read #%0d verified: data_out=0x%02h matched expected=0x%02h",
                      num_reads, item.data_out, expected_data),
            UVM_HIGH)
        end else begin
          num_mismatches++;
          `uvm_error(get_type_name(),
            $sformatf("[MISMATCH] Read #%0d failed: data_out=0x%02h != expected=0x%02h",
                      num_reads, item.data_out, expected_data))
        end
        expect_read = 1'b0;
      end

      if (item.wr_en && (ref_count < depth)) begin
        ref_queue.push_back(item.data_in);
        ref_count++;
        num_writes++;
        `uvm_info(get_type_name(),
          $sformatf("[WRITE #%0d] Accepted: data_in=0x%02h | queue_size=%0d, ref_count=%0d",
                    num_writes, item.data_in, ref_queue.size(), ref_count),
          UVM_HIGH)
      end else if (item.wr_en && (ref_count >= depth)) begin
        `uvm_info(get_type_name(),
          $sformatf("[WRITE IGNORED] FIFO is FULL (ref_count=%0d == DEPTH=%0d), data_in=0x%02h dropped",
                    ref_count, depth, item.data_in),
          UVM_HIGH)
      end

      if (item.rd_en && !item.empty) begin
        if (ref_queue.size() > 0) begin
          expected_data = ref_queue.pop_front();
          expect_read   = 1'b1;
          ref_count--;
          `uvm_info(get_type_name(),
            $sformatf("[READ TRIGGERED] Popped expected_data=0x%02h from ref_queue (remaining ref_count=%0d, awaiting next cycle check)",
                      expected_data, ref_count),
            UVM_HIGH)
        end else begin
          `uvm_error(get_type_name(),
            $sformatf("[UNDERFLOW ANOMALY] DUT !empty but scoreboard ref_queue is empty!"))
        end
      end else if (item.rd_en && item.empty) begin
        `uvm_info(get_type_name(),
          "[READ IGNORED] FIFO is EMPTY, rd_en ignored by DUT",
          UVM_HIGH)
      end

    end
  endtask : run_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "             FIFO SCOREBOARD SUMMARY              ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Configured DEPTH       : %0d", depth), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Writes Processed : %0d", num_writes), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Reads Verified   : %0d", num_reads), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Data Matches           : %0d", num_matches), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Data Mismatches        : %0d", num_mismatches), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Unread Items in Queue  : %0d", ref_queue.size()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Final ref_count        : %0d", ref_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Reset cycles seen      : %0d", num_reset_cycles), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    if (num_mismatches > 0) begin
      `uvm_error(get_type_name(),
        $sformatf("SCOREBOARD CHECK FAILED: %0d mismatches detected!", num_mismatches))
    end else begin
      `uvm_info(get_type_name(),
        "SCOREBOARD CHECK PASSED: Zero mismatches detected.", UVM_LOW)
    end

    // A read still pending at the end was never checked
    if (expect_read) begin
      `uvm_warning(get_type_name(),
        $sformatf("Simulation terminated with a pending read check unfulfilled (expected_data=0x%02h)",
                  expected_data))
    end
  endfunction : report_phase

endclass : fifo_scoreboard
