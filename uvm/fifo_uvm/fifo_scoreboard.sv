// =============================================================================
// CHANGE LOG
// 2026-11-25: Reuse the PR #1 scoreboard (2a4f920) in place of the handwritten
//             one from PR #2. Check logic unchanged (1.1 data, 1.2 flags,
//             1.4 data_out hold, reset clears the model). Adapted to the current
//             project: analysis port named mon_fifo (fifo_env); DEPTH can be set
//             through config_db "depth"; one-line-per-field summary with the
//             labels that uvm/scripts/*.sh and build_report.py grep, plus the
//             "SCOREBOARD CHECK PASSED/FAILED" line; write/read counters;
//             leftover items reported at end of test; empty flag compared with !==.
//
// 2026-10-13: Added check 1.4 "data_out holds when there is no read" (issue 4):
//             track exp_dout (0 after reset, else the last value read), count
//             hold_mismatch_count separately; after each failure resync to the
//             DUT to avoid cascading reports. Count reset_count. Hold mismatches
//             added to the summary.
// =============================================================================
// fifo_scoreboard: checker + golden model (queue).
//
// The model tracks its own occupancy and NEVER trusts the DUT's full/empty
// flags, so a corrupted flag (bug or Trojan) cannot steer the model. For each
// monitor sample (pre-edge values):
//   rst_n = 0      : clear the queue, expected data_out = 0, skip all checks
//   1.1 data       : if the previous sample had an accepted read,
//                    data_out == the value popped then
//   1.4 hold       : if there was no accepted read, data_out is unchanged
//   1.2 flags      : full == (size == DEPTH), empty == (size == 0)
//   update         : wr_acc = wr_en && size != DEPTH; rd_acc = rd_en && size != 0
//                    (pop before push; data_out is registered, so the popped
//                    value is compared on the NEXT sample)

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)

  uvm_tlm_analysis_fifo #(fifo_seq_item) mon_fifo; // from the monitor (connected in fifo_env)

  // FIFO depth, can be overridden with config_db key "depth"
  int depth = 32;

  // Golden model state
  bit [7:0] ref_queue[$];
  bit       pending_read     = 0;
  bit [7:0] pending_expected = 0;
  bit [7:0] exp_dout         = 0;   // expected data_out at this sample (0 after reset)

  // Counters (fifo_rl_test reads failed/flag/hold_mismatch_count)
  int unsigned pass_match_count      = 0;  // 1.1 PASS
  int unsigned failed_mismatch_count = 0;  // 1.1 FAIL: wrong data_out
  int unsigned flag_mismatch_count   = 0;  // 1.2 FAIL: wrong full/empty
  int unsigned hold_mismatch_count   = 0;  // 1.4 FAIL: data_out changed without a read
  int unsigned num_writes            = 0;  // writes accepted by the model
  int unsigned reset_count           = 0;  // samples with rst_n = 0
  int unsigned total_count           = 0;  // total samples

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_fifo = new("mon_fifo", this);
    void'(uvm_config_db#(int)::get(this, "", "depth", depth));
    `uvm_info(get_type_name(), $sformatf("Built scoreboard with configured DEPTH = %0d", depth), UVM_MEDIUM)
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_seq_item item;
    forever begin
      mon_fifo.get(item);
      compare(item);
    end
  endtask

  virtual function void compare(fifo_seq_item item);
    bit expected_full, expected_empty, wr_accept, rd_accept;

    total_count++;

    // synchronous reset: the DUT clears the FIFO and data_out at this edge
    if (!item.rst_n) begin
      ref_queue.delete();
      pending_read = 0;
      exp_dout     = 8'h00;
      reset_count++;
      return;
    end

    // 1.1 data (read on the previous sample, data_out is registered) / 1.4 data_out hold
    if (pending_read) begin
      if (item.data_out === pending_expected) begin
        pass_match_count++;
        `uvm_info(get_type_name(), $sformatf("1.1 [FIFO_DATA_OUT_CHK] PASS: data_out = 0x%02h, expected = 0x%02h",
                  item.data_out, pending_expected), UVM_HIGH)
      end else begin
        failed_mismatch_count++;
        `uvm_error(get_type_name(), $sformatf("1.1 [FIFO_DATA_OUT_CHK] FAIL: data_out = 0x%02h, expected = 0x%02h | ref_queue size = %0d",
                   item.data_out, pending_expected, ref_queue.size()))
      end
      exp_dout     = item.data_out;   // resync to the DUT (no cascading 1.4 reports)
      pending_read = 0;
    end else if (item.data_out !== exp_dout) begin
      hold_mismatch_count++;
      `uvm_error(get_type_name(), $sformatf("1.4 [FIFO_DOUT_HOLD_CHK] FAIL: data_out = 0x%02h changed without a read, expected hold = 0x%02h",
                 item.data_out, exp_dout))
      exp_dout = item.data_out;       // resync
    end

    // 1.2 flags, against the model's occupancy
    expected_full  = (ref_queue.size() == depth);
    expected_empty = (ref_queue.size() == 0);
    if (item.full !== expected_full) begin
      flag_mismatch_count++;
      `uvm_error(get_type_name(), $sformatf("1.2 [FIFO_FLAG_CHK] FAIL: full = %0b, expected = %0b | ref_queue size = %0d",
                 item.full, expected_full, ref_queue.size()))
    end
    if (item.empty !== expected_empty) begin
      flag_mismatch_count++;
      `uvm_error(get_type_name(), $sformatf("1.2 [FIFO_FLAG_CHK] FAIL: empty = %0b, expected = %0b | ref_queue size = %0d",
                 item.empty, expected_empty, ref_queue.size()))
    end

    // update the model from its own occupancy (DUT flags not used)
    wr_accept = item.wr_en && (ref_queue.size() != depth);
    rd_accept = item.rd_en && (ref_queue.size() != 0);
    if (rd_accept) begin
      pending_expected = ref_queue.pop_front();
      pending_read     = 1;
    end
    if (wr_accept) begin
      ref_queue.push_back(item.data_in);
      num_writes++;
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    int unsigned n_reads = pass_match_count + failed_mismatch_count;
    super.report_phase(phase);

    // The labels below are grepped by uvm/scripts/run_one.sh and build_report.py
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "             FIFO SCOREBOARD SUMMARY              ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Configured DEPTH       : %0d", depth), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Samples Processed      : %0d", total_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Writes Processed : %0d", num_writes), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Reads Verified   : %0d", n_reads), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Data Matches           : %0d", pass_match_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Data Mismatches        : %0d", failed_mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Flag Mismatches        : %0d", flag_mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Hold Mismatches        : %0d", hold_mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Unread Items in Queue  : %0d", ref_queue.size()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Reset cycles seen      : %0d", reset_count), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    if (failed_mismatch_count > 0 || flag_mismatch_count > 0 || hold_mismatch_count > 0) begin
      `uvm_error(get_type_name(), $sformatf("SCOREBOARD CHECK FAILED: %0d data, %0d flag, %0d hold mismatches",
                 failed_mismatch_count, flag_mismatch_count, hold_mismatch_count))
    end else begin
      `uvm_info(get_type_name(), "SCOREBOARD CHECK PASSED: Zero mismatches detected.", UVM_LOW)
    end

    // A read still pending at the end was never checked
    if (pending_read)
      `uvm_warning(get_type_name(), $sformatf("Simulation ended with a pending read check (expected_data=0x%02h)",
                   pending_expected))
  endfunction

endclass : fifo_scoreboard
