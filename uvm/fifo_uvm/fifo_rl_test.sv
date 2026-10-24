// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Tạo mới. fifo_rl_loop_test: chạy B test liên tiếp trong MỘT lần
//             mô phỏng; giữa các test agent (rl_bandit) chọn preset knob A0..A9,
//             nhận reward giả từ RB-01, ghi một dòng CSV mỗi test.
//             Chính sách: fixed (B0 = A0), random (B1), ucb1, egreedy.
// =============================================================================
//
// Plusarg (mặc định trong ngoặc):
//   +RL_POLICY=fixed|random|ucb1|egreedy   (ucb1)
//   +RL_TESTS=<B>                          (100)   số test trong lần mô phỏng
//   +RL_TXN=<N>                            (200)   giao dịch mỗi test
//   +RL_REWARD=binary|graded               (binary)
//        binary : 1 nếu test có >=1 sự kiện RB-01, ngược lại 0
//        graded : min(max_chuoi_ghi_khi_day, 3) / 3   (cùng định nghĩa RB-01,
//                 không có trọng số nào để chỉnh)
//   +RL_FIXED_ARM=<k>                      (0)     tay dùng cho policy=fixed
//   +RL_UCB_C=<real>                       (1.0)
//   +RL_EPS=<real>                         (0.1)
//   +RL_SEED=<int>                         (0)     chỉ để ghi vào CSV; RNG thật do -sv_seed
//   +RL_CSV=<path>                         (rl_<policy>_<reward>_s<seed>.csv)
//   +RL_STOP_ON_HIT                        dừng ở test đầu tiên chạm RB-01
//
// Cuối mô phỏng in một dòng "RL_SUMMARY ..." để script grep nhanh.

class fifo_rl_loop_test extends fifo_base_test;
  `uvm_component_utils(fifo_rl_loop_test)

  // cấu hình
  string       policy_s    = "ucb1";
  string       reward_s    = "binary";
  string       csv_path    = "";
  int unsigned num_tests   = 100;
  int unsigned num_txn     = 200;
  int unsigned fixed_arm   = 0;
  int unsigned seed_tag    = 0;
  real         ucb_c       = 1.0;
  real         eps         = 0.1;
  bit          stop_on_hit = 0;

  string       method_version = "rl-loop-v0.1";
  string       dut_id         = "sync_fifo_clean";

  rl_bandit     agent;
  rl_csv_logger logger;
  string        arm_names[$];

  // kết quả tổng
  int          first_hit_test = -1;
  int unsigned n_hit_tests    = 0;
  int unsigned n_done         = 0;

  function new(string name = "fifo_rl_loop_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'($value$plusargs("RL_POLICY=%s",    policy_s));
    void'($value$plusargs("RL_REWARD=%s",    reward_s));
    void'($value$plusargs("RL_CSV=%s",       csv_path));
    void'($value$plusargs("RL_TESTS=%d",     num_tests));
    void'($value$plusargs("RL_TXN=%d",       num_txn));
    void'($value$plusargs("RL_FIXED_ARM=%d", fixed_arm));
    void'($value$plusargs("RL_SEED=%d",      seed_tag));
    void'($value$plusargs("RL_UCB_C=%f",     ucb_c));
    void'($value$plusargs("RL_EPS=%f",       eps));
    stop_on_hit = $test$plusargs("RL_STOP_ON_HIT");

    if (reward_s != "binary" && reward_s != "graded")
      `uvm_fatal("RLCFG", {"RL_REWARD không hợp lệ: ", reward_s, " (binary|graded)"})
    if (fixed_arm >= fifo_knobs::NUM_PRESETS)
      `uvm_fatal("RLCFG", $sformatf("RL_FIXED_ARM=%0d ngoài khoảng 0..%0d", fixed_arm, fifo_knobs::NUM_PRESETS-1))
    if (csv_path == "")
      csv_path = $sformatf("rl_%s_%s_s%0d.csv", policy_s, reward_s, seed_tag);
  endfunction

  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    string cols[$];
    bit    stop;

    phase.raise_objection(this, "RL loop");

    for (int a = 0; a < fifo_knobs::NUM_PRESETS; a++)
      arm_names.push_back(fifo_knobs::preset_name(a));

    agent = rl_bandit::type_id::create("agent");
    agent.configure(rl_bandit::parse_policy(policy_s), fifo_knobs::NUM_PRESETS);
    agent.fixed_arm = fixed_arm;
    agent.ucb_c     = ucb_c;
    agent.epsilon   = eps;

    cols = '{"run_id", "method", "method_version", "dut_id", "seed", "test_id",
             "action_id", "arm_name", "knob_vector", "reward_mode", "reward_total",
             "new_coverage_bins", "total_bins_hit", "num_bins",
             "detector_event", "rb01_hit", "rb01_first_cycle", "max_wfull_run",
             "resets_seen", "resets_injected", "replayed_bursts",
             "det_sb_data", "det_sb_flag", "det_sb_hold",
             "cycles", "sim_time_ns", "exit_reason"};
    logger = new();
    if (!logger.open(csv_path, cols))
      `uvm_fatal("RLCSV", {"Không mở được file CSV: ", csv_path, " (thư mục có tồn tại không?)"})

    `uvm_info(get_type_name(), $sformatf(
      "RL loop: policy=%s reward=%s B=%0d N=%0d seed_tag=%0d csv=%s",
      policy_s, reward_s, num_tests, num_txn, seed_tag, csv_path), UVM_LOW)

    // chờ reset ban đầu của driver xong
    wait (vif.rst_n === 1'b1);
    repeat (2) @(posedge vif.clk);

    for (int t = 0; t < num_tests; t++) begin
      run_one_test(t, stop);
      if (stop) break;
    end

    logger.close();
    `uvm_info(get_type_name(), {"Bandit stats: ", agent.stats_str(arm_names)}, UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(
      "RL_SUMMARY policy=%s reward=%s seed=%0d tests_run=%0d first_hit_test=%s hit_tests=%0d",
      policy_s, reward_s, seed_tag, n_done,
      (first_hit_test < 0) ? "NA" : $sformatf("%0d", first_hit_test), n_hit_tests), UVM_NONE)

    phase.drop_objection(this, "RL loop done");
  endtask

  // Một test: chọn tay -> chạy sequence -> đo -> reward -> update -> ghi CSV.
  // stop = 1 nếu cần dừng vòng lặp.
  protected virtual task run_one_test(int t, output bit stop);
    int unsigned  arm;
    fifo_knobs    k;
    fifo_knob_seq seq;
    real          reward;
    time          t0, t1;
    int unsigned  sb_data0, sb_flag0, sb_hold0;
    int unsigned  capped;
    bit           hit;
    string        vals[$];

    arm = agent.select_arm();
    k   = fifo_knobs::preset(arm);
    k.num_txn = num_txn;

    sb_data0 = env.scoreboard.failed_mismatch_count;
    sb_flag0 = env.scoreboard.flag_mismatch_count;
    sb_hold0 = env.scoreboard.hold_mismatch_count;

    env.rl_obs.start_test();
    t0  = $time;
    seq = fifo_knob_seq::type_id::create($sformatf("knob_seq_%0d", t));
    seq.knobs = k;
    seq.start(env.agent.sequencer);
    repeat (2) @(posedge vif.clk);   // monitor lấy mẫu xong item idle cuối
    env.rl_obs.end_test();
    t1  = $time;

    hit = (env.rl_obs.t_rb01_events > 0);
    if (reward_s == "binary") begin
      reward = hit ? 1.0 : 0.0;
    end else begin
      capped = (env.rl_obs.t_max_wfull_run >= fifo_rl_observer::RB01_LEN) ?
               fifo_rl_observer::RB01_LEN : env.rl_obs.t_max_wfull_run;
      reward = real'(capped) / real'(fifo_rl_observer::RB01_LEN);
    end

    agent.update(arm, reward);

    if (hit) begin
      n_hit_tests++;
      if (first_hit_test < 0) first_hit_test = t;
    end
    n_done++;

    vals = '{
      $sformatf("%s_%s_s%0d", policy_s, reward_s, seed_tag),
      policy_s, method_version, dut_id,
      $sformatf("%0d", seed_tag),
      $sformatf("%0d", t),
      $sformatf("%0d", arm),
      arm_names[arm],
      k.vec2str(),
      reward_s,
      $sformatf("%.4f", reward),
      $sformatf("%0d", env.rl_obs.t_new_bins),
      $sformatf("%0d", env.rl_obs.total_bins_hit),
      $sformatf("%0d", fifo_rl_observer::NUM_BINS),
      $sformatf("%0d", env.rl_obs.t_rb01_events),
      $sformatf("%0d", hit),
      (env.rl_obs.t_rb01_first_cycle < 0) ? "NA" : $sformatf("%0d", env.rl_obs.t_rb01_first_cycle),
      $sformatf("%0d", env.rl_obs.t_max_wfull_run),
      $sformatf("%0d", env.rl_obs.t_resets),
      $sformatf("%0d", seq.n_reset_injected),
      $sformatf("%0d", seq.n_replayed_bursts),
      $sformatf("%0d", env.scoreboard.failed_mismatch_count - sb_data0),
      $sformatf("%0d", env.scoreboard.flag_mismatch_count   - sb_flag0),
      $sformatf("%0d", env.scoreboard.hold_mismatch_count   - sb_hold0),
      $sformatf("%0d", env.rl_obs.t_cycles),
      $sformatf("%0d", t1 - t0),          // timeunit của package = 1ns (-timescale 1ns/1ps)
      (stop_on_hit && hit) ? "stop_on_hit" : "ok"
    };
    logger.write_row(vals);

    `uvm_info(get_type_name(), $sformatf("test %0d arm=%0d(%s) reward=%.3f rb01=%0d new_bins=%0d cycles=%0d",
              t, arm, arm_names[arm], reward, env.rl_obs.t_rb01_events,
              env.rl_obs.t_new_bins, env.rl_obs.t_cycles), UVM_MEDIUM)

    stop = stop_on_hit && hit;
  endtask
endclass : fifo_rl_loop_test
