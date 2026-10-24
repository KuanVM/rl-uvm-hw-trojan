// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Tạo mới. Config object chứa knob vector (k_mix, k_burst, k_gap,
//             k_data, k_reset, k_replay), 10 preset đặt tên A0..A9, giải mã chỉ
//             số lưới đầy đủ 1.080 hành động (from_grid) cho giai đoạn bandit
//             tách theo từng núm sau này.
// =============================================================================
//
// Knob vector DÙNG CHUNG cho mọi DUT (scope §9.1). Không chứa kịch bản riêng
// của FIFO: chỉ là tham số phân phối áp lên "kind" của item (WR/RD/WR+RD/IDLE),
// độ dài burst, khoảng nghỉ, chế độ dữ liệu, tỉ lệ reset và replay.
//
// Lưới đầy đủ: 5 (mix) x 3 (burst) x 3 (gap) x 4 (data) x 3 (reset) x 2 (replay)
//            = 1.080 hành động.
// A0 (baseline) KHÔNG nằm trong lưới: nó dùng nguyên ràng buộc mặc định của
// fifo_seq_item (wr_en 60/40, rd_en 40/60, i.i.d. từng chu kỳ) để khớp đúng
// phân phối của fifo_random_test.

typedef enum int {MIX_BASE, MIX_WR, MIX_RD, MIX_WRRD, MIX_BAL}      k_mix_e;
typedef enum int {BURST_SHORT, BURST_MED, BURST_LONG}               k_burst_e;
typedef enum int {GAP_NONE, GAP_SHORT, GAP_LONG}                    k_gap_e;
typedef enum int {DATA_UNIFORM, DATA_CORNER, DATA_REPEAT, DATA_REUSE} k_data_e;
typedef enum int {RST_NONE, RST_RARE, RST_FREQ}                     k_reset_e;
typedef enum int {REPLAY_OFF, REPLAY_ON}                            k_replay_e;

class fifo_knobs extends uvm_object;
  `uvm_object_utils(fifo_knobs)

  // số lượng
  localparam int NUM_MIX     = 5;
  localparam int NUM_BURST   = 3;
  localparam int NUM_GAP     = 3;
  localparam int NUM_DATA    = 4;
  localparam int NUM_RESET   = 3;
  localparam int NUM_REPLAY  = 2;
  localparam int NUM_GRID    = NUM_MIX*NUM_BURST*NUM_GAP*NUM_DATA*NUM_RESET*NUM_REPLAY; // 1080
  localparam int NUM_PRESETS = 10;

  // định danh
  string     arm_name   = "custom";
  bit        legacy_iid = 0;      // 1 = A0: dùng ràng buộc mặc định của seq_item

  // knob vector
  k_mix_e    k_mix    = MIX_BASE;
  k_burst_e  k_burst  = BURST_SHORT;
  k_gap_e    k_gap    = GAP_NONE;
  k_data_e   k_data   = DATA_UNIFORM;
  k_reset_e  k_reset  = RST_NONE;
  k_replay_e k_replay = REPLAY_OFF;

  // tham số của một "test"
  int unsigned num_txn        = 200;  // N giao dịch (không tính reset đầu test và idle cuối)
  bit          reset_at_start = 1;    // reset FIFO ở đầu mỗi test

  function new(string name = "fifo_knobs");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Ánh xạ knob -> tham số phân phối
  // ---------------------------------------------------------------------------

  // Trọng số WR / RD / WR+RD / IDLE (tổng = 100).
  // MIX_BASE = phân phối biên của A0: P(wr)=.6, P(rd)=.4 độc lập
  //   -> WR .36, RD .16, WR+RD .24, IDLE .24
  function void get_mix_weights(output int unsigned w_wr, w_rd, w_wrrd, w_idle);
    case (k_mix)
      MIX_BASE: begin w_wr = 36; w_rd = 16; w_wrrd = 24; w_idle = 24; end
      MIX_WR  : begin w_wr = 70; w_rd = 10; w_wrrd = 10; w_idle = 10; end
      MIX_RD  : begin w_wr = 10; w_rd = 70; w_wrrd = 10; w_idle = 10; end
      MIX_WRRD: begin w_wr = 15; w_rd = 15; w_wrrd = 60; w_idle = 10; end
      default : begin w_wr = 25; w_rd = 25; w_wrrd = 25; w_idle = 25; end // MIX_BAL
    endcase
  endfunction

  // Độ dài burst (số chu kỳ giữ cùng một loại thao tác)
  function void get_burst_range(output int unsigned lo, hi);
    case (k_burst)
      BURST_SHORT: begin lo = 1; hi = 2;  end
      BURST_MED  : begin lo = 3; hi = 8;  end
      default    : begin lo = 9; hi = 40; end // BURST_LONG
    endcase
  endfunction

  // Số chu kỳ nghỉ (IDLE) chèn giữa các burst
  function void get_gap_range(output int unsigned lo, hi);
    case (k_gap)
      GAP_NONE : begin lo = 0; hi = 0;  end
      GAP_SHORT: begin lo = 1; hi = 4;  end
      default  : begin lo = 5; hi = 20; end // GAP_LONG
    endcase
  endfunction

  // Xác suất reset mỗi giao dịch, đơn vị phần 100.000
  //   RST_RARE = 0,1 % ; RST_FREQ = 1 %
  function int unsigned reset_per_100k();
    case (k_reset)
      RST_NONE: return 0;
      RST_RARE: return 100;
      default : return 1000; // RST_FREQ
    endcase
  endfunction

  // Chuỗi mô tả knob vector, KHÔNG có dấu phẩy để nhét được vào một ô CSV
  function string vec2str();
    if (legacy_iid)
      return $sformatf("legacy_iid;reset_at_start=%0b", reset_at_start);
    return $sformatf("mix=%s;burst=%s;gap=%s;data=%s;reset=%s;replay=%s",
                     k_mix.name(), k_burst.name(), k_gap.name(),
                     k_data.name(), k_reset.name(), k_replay.name());
  endfunction

  // ---------------------------------------------------------------------------
  // Preset đặt tên (8–12 vector ban đầu; ở đây 10)
  // ---------------------------------------------------------------------------
  static function string preset_name(int idx);
    case (idx)
      0: return "A0_BASELINE";
      1: return "A1_WR_HEAVY";
      2: return "A2_RD_HEAVY";
      3: return "A3_WRRD_HEAVY";
      4: return "A4_LONG_BURST";
      5: return "A5_RESET_1PCT";
      6: return "A6_DATA_CORNER";
      7: return "A7_DATA_REPEAT";
      8: return "A8_SPARSE_GAP";
      9: return "A9_REPLAY_REUSE";
      default: return "INVALID";
    endcase
  endfunction

  static function fifo_knobs preset(int idx);
    fifo_knobs k = new(preset_name(idx));
    k.arm_name = preset_name(idx);
    case (idx)
      //          mix        burst        gap        data          reset     replay
      0: k.legacy_iid = 1;
      1: k.set_vec(MIX_WR  , BURST_MED  , GAP_NONE , DATA_UNIFORM, RST_NONE, REPLAY_OFF);
      2: k.set_vec(MIX_RD  , BURST_MED  , GAP_NONE , DATA_UNIFORM, RST_NONE, REPLAY_OFF);
      3: k.set_vec(MIX_WRRD, BURST_MED  , GAP_NONE , DATA_UNIFORM, RST_NONE, REPLAY_OFF);
      4: k.set_vec(MIX_BAL , BURST_LONG , GAP_SHORT, DATA_UNIFORM, RST_NONE, REPLAY_OFF);
      5: k.set_vec(MIX_BASE, BURST_SHORT, GAP_NONE , DATA_UNIFORM, RST_FREQ, REPLAY_OFF);
      6: k.set_vec(MIX_BASE, BURST_SHORT, GAP_NONE , DATA_CORNER , RST_NONE, REPLAY_OFF);
      7: k.set_vec(MIX_BAL , BURST_MED  , GAP_NONE , DATA_REPEAT , RST_NONE, REPLAY_OFF);
      8: k.set_vec(MIX_BAL , BURST_SHORT, GAP_LONG , DATA_UNIFORM, RST_NONE, REPLAY_OFF);
      9: k.set_vec(MIX_BAL , BURST_MED  , GAP_SHORT, DATA_REUSE  , RST_RARE, REPLAY_ON );
      default: `uvm_fatal("KNOBS", $sformatf("preset index %0d ngoài khoảng 0..%0d", idx, NUM_PRESETS-1))
    endcase
    return k;
  endfunction

  // Giải mã chỉ số lưới 0..1079 (thứ tự: replay thay đổi nhanh nhất)
  static function fifo_knobs from_grid(int idx);
    fifo_knobs k = new($sformatf("G%0d", idx));
    int r = idx;
    if (idx < 0 || idx >= NUM_GRID)
      `uvm_fatal("KNOBS", $sformatf("grid index %0d ngoài khoảng 0..%0d", idx, NUM_GRID-1))
    k.k_replay = k_replay_e'(r % NUM_REPLAY); r /= NUM_REPLAY;
    k.k_reset  = k_reset_e'(r % NUM_RESET);   r /= NUM_RESET;
    k.k_data   = k_data_e'(r % NUM_DATA);     r /= NUM_DATA;
    k.k_gap    = k_gap_e'(r % NUM_GAP);       r /= NUM_GAP;
    k.k_burst  = k_burst_e'(r % NUM_BURST);   r /= NUM_BURST;
    k.k_mix    = k_mix_e'(r);
    k.arm_name = $sformatf("G%04d", idx);
    return k;
  endfunction

  function void set_vec(k_mix_e m, k_burst_e b, k_gap_e g, k_data_e d,
                        k_reset_e rs, k_replay_e rp);
    k_mix = m; k_burst = b; k_gap = g; k_data = d; k_reset = rs; k_replay = rp;
    legacy_iid = 0;
  endfunction

  virtual function void do_copy(uvm_object rhs);
    fifo_knobs rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "fifo_knobs::do_copy cast failed")
    super.do_copy(rhs);
    arm_name       = rhs_.arm_name;
    legacy_iid     = rhs_.legacy_iid;
    k_mix          = rhs_.k_mix;
    k_burst        = rhs_.k_burst;
    k_gap          = rhs_.k_gap;
    k_data         = rhs_.k_data;
    k_reset        = rhs_.k_reset;
    k_replay       = rhs_.k_replay;
    num_txn        = rhs_.num_txn;
    reset_at_start = rhs_.reset_at_start;
  endfunction

  virtual function string convert2string();
    return $sformatf("%s [%s] N=%0d", arm_name, vec2str(), num_txn);
  endfunction
endclass : fifo_knobs
