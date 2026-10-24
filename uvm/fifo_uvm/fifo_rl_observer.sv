// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Tạo mới. Subscriber theo dõi từng test cho vòng lặp RL:
//             mô hình chiếm chỗ theo spec, 45 bin spec-derived (đếm bin mới
//             theo test), bộ phát hiện RB-01 (>=3 chu kỳ liên tiếp wr_en=1 khi
//             FIFO đầy), số chu kỳ, số reset.
// =============================================================================
//
// Chống rò rỉ oracle: mọi thứ ở đây chỉ dựa trên SPEC của FIFO (độ sâu 32,
// ghi bị chặn khi đầy, đọc bị chặn khi rỗng, reset đồng bộ xoá FIFO).
// Độ chiếm chỗ lấy từ mô hình tham chiếu riêng (giống scoreboard), KHÔNG đọc
// cờ full/empty hay tín hiệu nội bộ của DUT — để detector không phụ thuộc vào
// một DUT có thể đã bị cài Trojan.
//
// RB-01 (mục tiêu giả để kiểm tra vòng lặp, KHÔNG phải kết quả nghiên cứu):
//   "≥3 lần ghi liên tiếp khi FIFO đầy" = có RB01_LEN mẫu LIÊN TIẾP (chu kỳ
//   liền nhau) mà wr_en=1 và occ==DEPTH. Một chu kỳ khác (kể cả idle) làm đứt
//   chuỗi. Mỗi lần chuỗi chạm đúng RB01_LEN tính là 1 sự kiện.
//
// Danh sách bin (đánh số cố định, phải đóng băng trước khi có Trojan):
//   [ 0..27] occ_bucket(7) x op(4)      op: 0 IDLE, 1 RD, 2 WR, 3 WR+RD
//   [28..32] chuỗi ghi-khi-đầy  >=1,>=2,>=3,>=4,>=8
//   [33..37] chuỗi đọc-khi-rỗng >=1,>=2,>=3,>=4,>=8
//   [38..44] reset xảy ra ở occ_bucket(7)
//   occ_bucket: 0 | 1-7 | 8-15 | 16-23 | 24-30 | 31 | 32

class fifo_rl_observer extends uvm_subscriber #(fifo_seq_item);
  `uvm_component_utils(fifo_rl_observer)

  localparam int DEPTH    = 32;
  localparam int N_OCC    = 7;
  localparam int N_OP     = 4;
  localparam int N_RUN    = 5;
  localparam int B_OCC_OP = 0;
  localparam int B_WFULL  = B_OCC_OP + N_OCC*N_OP;   // 28
  localparam int B_REMPTY = B_WFULL  + N_RUN;        // 33
  localparam int B_RST    = B_REMPTY + N_RUN;        // 38
  localparam int NUM_BINS = B_RST    + N_OCC;        // 45
  localparam int RB01_LEN = 3;

  // trạng thái toàn mô phỏng
  bit          hit_ever[NUM_BINS];
  int unsigned occ;
  int unsigned wfull_run;
  int unsigned rempty_run;
  int unsigned total_bins_hit;

  // thống kê của test hiện tại
  bit          in_test;
  int unsigned t_cycles;
  int unsigned t_new_bins;
  int unsigned t_rb01_events;
  int          t_rb01_first_cycle;   // -1 nếu chưa xảy ra
  int unsigned t_max_wfull_run;
  int unsigned t_resets;

  function new(string name = "fifo_rl_observer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  function void start_test();
    in_test            = 1;
    t_cycles           = 0;
    t_new_bins         = 0;
    t_rb01_events      = 0;
    t_rb01_first_cycle = -1;
    t_max_wfull_run    = 0;
    t_resets           = 0;
  endfunction

  function void end_test();
    in_test = 0;
  endfunction

  // ---------------------------------------------------------------------------
  static function int occ_bucket(int unsigned o);
    if (o == 0)          return 0;
    if (o <= 7)          return 1;
    if (o <= 15)         return 2;
    if (o <= 23)         return 3;
    if (o <= DEPTH-2)    return 4;
    if (o == DEPTH-1)    return 5;
    return 6;            // đầy
  endfunction

  // chỉ số ngưỡng (>=1,>=2,>=3,>=4,>=8) khi chuỗi vừa đạt độ dài run; -1 nếu không phải ngưỡng
  static function int run_bin(int unsigned run);
    case (run)
      1: return 0;
      2: return 1;
      3: return 2;
      4: return 3;
      8: return 4;
      default: return -1;
    endcase
  endfunction

  protected function void mark(int b);
    if (!hit_ever[b]) begin
      hit_ever[b] = 1;
      total_bins_hit++;
      if (in_test) t_new_bins++;
    end
  endfunction

  // ---------------------------------------------------------------------------
  virtual function void write(fifo_seq_item t);
    int  op, rb;
    bit  wr_acc, rd_acc;

    if (in_test) t_cycles++;

    // reset đồng bộ: FIFO rỗng sau cạnh này
    if (!t.rst_n) begin
      mark(B_RST + occ_bucket(occ));
      if (in_test) t_resets++;
      occ = 0; wfull_run = 0; rempty_run = 0;
      return;
    end

    op = {t.wr_en, t.rd_en};   // 0 IDLE, 1 RD, 2 WR, 3 WR+RD
    mark(B_OCC_OP + occ_bucket(occ)*N_OP + op);

    // chuỗi ghi khi đầy (RB-01)
    if (t.wr_en && occ == DEPTH) begin
      wfull_run++;
      rb = run_bin(wfull_run);
      if (rb >= 0) mark(B_WFULL + rb);
      if (wfull_run == RB01_LEN && in_test) begin
        t_rb01_events++;
        if (t_rb01_first_cycle < 0) t_rb01_first_cycle = t_cycles;
      end
    end else begin
      wfull_run = 0;
    end
    if (in_test && wfull_run > t_max_wfull_run) t_max_wfull_run = wfull_run;

    // chuỗi đọc khi rỗng
    if (t.rd_en && occ == 0) begin
      rempty_run++;
      rb = run_bin(rempty_run);
      if (rb >= 0) mark(B_REMPTY + rb);
    end else begin
      rempty_run = 0;
    end

    // cập nhật mô hình chiếm chỗ theo spec
    wr_acc = t.wr_en && (occ != DEPTH);
    rd_acc = t.rd_en && (occ != 0);
    if (wr_acc && !rd_acc)      occ++;
    else if (rd_acc && !wr_acc) occ--;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
      $sformatf("RL observer: %0d/%0d spec bins hit", total_bins_hit, NUM_BINS), UVM_LOW)
  endfunction
endclass : fifo_rl_observer
