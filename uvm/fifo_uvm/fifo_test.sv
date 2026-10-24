// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: fifo_base_test lấy vif từ config_db và có task drain(): chạy
//             fifo_idle_seq rồi chờ vài chu kỳ cho monitor/scoreboard xử lý xong.
//             fifo_random_test gọi drain() trước khi hạ objection, không còn mất
//             giao dịch cuối (vấn đề 3).
// =============================================================================
// =============================================
//          Base Test- for all setups
// =============================================

class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)
  fifo_env env;
  virtual fifo_if vif;

  function new(string name = "fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // build phase - create environment
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found in config_db")
  
    // config via config_db
    uvm_config_db#(int)::set(this, "env.agent", "num_transactions", 1000);
  endfunction

  // Kết thúc sạch: N chu kỳ idle (driver không giữ wr/rd của item cuối),
  // rồi chờ thêm wait_cycles để monitor lấy mẫu và scoreboard so xong.
  virtual task drain(int unsigned idle_cycles = 2, int unsigned wait_cycles = 2);
    fifo_idle_seq idle = fifo_idle_seq::type_id::create("idle");
    idle.num_transaction = idle_cycles;
    idle.start(env.agent.sequencer);
    repeat (wait_cycles) @(posedge vif.clk);
  endtask

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_FATAL) > 0) begin
      `uvm_info(get_type_name(), "═══ TEST FAILED ═══", UVM_NONE)
    end else begin
      `uvm_info(get_type_name(), "═══ TEST PASSED ═══", UVM_NONE)
    end
  endfunction
endclass


//==========================================
//              Specific tests
//========================================

class fifo_random_test extends fifo_base_test;
  `uvm_component_utils(fifo_random_test)

  function new(string name = "fifo_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // run phase - start the sequence
  virtual task run_phase(uvm_phase phase);
    fifo_base_sequence seq;
    phase.raise_objection(this, "Starting test sequence");

    // raise objection to keep sim running
    seq = fifo_base_sequence::type_id::create("seq");
    seq.num_transaction = 2000;
    seq.start(env.agent.sequencer);
    drain();   // idle + chờ monitor/scoreboard, không mất giao dịch cuối

    // drop objection when sequence is done
    phase.drop_objection(this, "Test sequence complete");
  endtask
     
endclass