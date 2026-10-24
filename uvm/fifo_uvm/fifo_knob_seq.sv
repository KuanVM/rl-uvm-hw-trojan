// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Tạo mới. fifo_knob_seq sinh N giao dịch theo một fifo_knobs:
//             burst theo k_mix/k_burst, nghỉ theo k_gap, dữ liệu theo k_data,
//             reset ngẫu nhiên theo k_reset, replay burst cũ theo k_replay;
//             reset đầu test và 2 chu kỳ idle cuối test (không tính vào N).
// =============================================================================
//
// Quy ước đếm: mỗi item gửi cho driver = 1 chu kỳ = 1 "giao dịch".
//   - Reset đầu test (start_reset_cycles item) và idle cuối test (tail_idle)
//     KHÔNG tính vào N.
//   - Chu kỳ nghỉ (gap) và reset chèn ngẫu nhiên (k_reset) CÓ tính vào N.
// Lịch sử dữ liệu (k_data = REUSE) và bộ đệm replay chỉ sống trong một test
// (test sau bắt đầu sạch vì DUT cũng được reset).

class fifo_burst_rec;
  bit       wr[$];
  bit       rd[$];
  bit [7:0] d[$];
endclass

class fifo_knob_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_knob_seq)

  fifo_knobs knobs;                     // bắt buộc gán trước start()

  // tham số phụ (cố định, không phải knob của agent)
  int unsigned start_reset_cycles = 2;
  int unsigned tail_idle          = 2;  // để driver không giữ wr/rd của item cuối
  int unsigned replay_pct         = 25; // xác suất replay ở mỗi ranh giới burst khi REPLAY_ON
  int unsigned replay_depth       = 8;  // số burst gần nhất được giữ để replay
  int unsigned hist_depth         = 32; // số giá trị ghi gần nhất cho DATA_REUSE

  // thống kê để logger ghi
  int unsigned n_sent;
  int unsigned n_reset_injected;
  int unsigned n_replayed_bursts;

  // trạng thái nội bộ
  protected bit [7:0]      wr_hist[$];
  protected fifo_burst_rec replay_buf[$];
  protected bit [7:0]      corner_vals[10] = '{8'h00, 8'hFF, 8'h01, 8'h02, 8'h04,
                                               8'h08, 8'h10, 8'h20, 8'h40, 8'h80};

  function new(string name = "fifo_knob_seq");
    super.new(name);
  endfunction

  virtual task body();
    if (knobs == null)
      `uvm_fatal("KNOBSEQ", "knobs chưa được gán trước khi start()")

    n_sent = 0; n_reset_injected = 0; n_replayed_bursts = 0;
    wr_hist.delete(); replay_buf.delete();

    if (knobs.reset_at_start)
      repeat (start_reset_cycles) send_raw(1'b1, 1'b0, 1'b0, 8'h00);

    if (knobs.legacy_iid) gen_legacy();
    else                  gen_knobbed();

    repeat (tail_idle) send_raw(1'b0, 1'b0, 1'b0, 8'h00);
  endtask

  // A0: đúng phân phối cũ (ràng buộc mặc định của fifo_seq_item)
  protected virtual task gen_legacy();
    fifo_seq_item it;
    while (n_sent < knobs.num_txn) begin
      it = fifo_seq_item::type_id::create("it");
      start_item(it);
      if (!it.randomize()) `uvm_fatal("RAND", "Randomization failed!")
      it.rst_req = 1'b0;
      finish_item(it);
      n_sent++;
    end
  endtask

  protected virtual task gen_knobbed();
    int unsigned w_wr, w_rd, w_wrrd, w_idle;
    int unsigned b_lo, b_hi, g_lo, g_hi, len, gap;
    bit          op_wr, op_rd;
    bit [7:0]    rep_val, d;
    fifo_burst_rec rec;

    knobs.get_mix_weights(w_wr, w_rd, w_wrrd, w_idle);
    knobs.get_burst_range(b_lo, b_hi);
    knobs.get_gap_range(g_lo, g_hi);
    rep_val = $urandom_range(255, 0);

    while (n_sent < knobs.num_txn) begin
      // ---- burst: replay một burst cũ, hoặc sinh burst mới ----
      if (knobs.k_replay == REPLAY_ON && replay_buf.size() > 0 &&
          $urandom_range(99, 0) < replay_pct) begin
        rec = replay_buf[$urandom_range(replay_buf.size()-1, 0)];
        foreach (rec.wr[i]) begin
          if (n_sent >= knobs.num_txn) break;
          send_txn(rec.wr[i], rec.rd[i], rec.d[i]);
        end
        n_replayed_bursts++;
      end else begin
        randcase
          w_wr  : begin op_wr = 1; op_rd = 0; end
          w_rd  : begin op_wr = 0; op_rd = 1; end
          w_wrrd: begin op_wr = 1; op_rd = 1; end
          w_idle: begin op_wr = 0; op_rd = 0; end
        endcase
        len     = $urandom_range(b_hi, b_lo);
        rep_val = $urandom_range(255, 0);
        rec     = new();
        for (int i = 0; i < len && n_sent < knobs.num_txn; i++) begin
          d = gen_data(rep_val);
          send_txn(op_wr, op_rd, d);
          rec.wr.push_back(op_wr); rec.rd.push_back(op_rd); rec.d.push_back(d);
        end
        replay_buf.push_back(rec);
        if (replay_buf.size() > replay_depth) void'(replay_buf.pop_front());
      end

      // ---- gap: chu kỳ nghỉ giữa các burst ----
      gap = $urandom_range(g_hi, g_lo);
      for (int i = 0; i < gap && n_sent < knobs.num_txn; i++)
        send_txn(1'b0, 1'b0, gen_data(rep_val));
    end
  endtask

  protected virtual function bit [7:0] gen_data(bit [7:0] rep_val);
    case (knobs.k_data)
      DATA_UNIFORM: return $urandom_range(255, 0);
      DATA_CORNER : return corner_vals[$urandom_range(9, 0)];
      DATA_REPEAT : return rep_val;
      default     : begin // DATA_REUSE
        if (wr_hist.size() == 0) return $urandom_range(255, 0);
        return wr_hist[$urandom_range(wr_hist.size()-1, 0)];
      end
    endcase
  endfunction

  // Một giao dịch tính vào N; có thể bị thay bằng reset theo k_reset
  protected virtual task send_txn(bit wr, bit rd, bit [7:0] d);
    if (knobs.reset_per_100k() > 0 &&
        $urandom_range(99999, 0) < knobs.reset_per_100k()) begin
      send_raw(1'b1, 1'b0, 1'b0, d);
      n_reset_injected++;
    end else begin
      send_raw(1'b0, wr, rd, d);
      if (wr) begin
        wr_hist.push_back(d);
        if (wr_hist.size() > hist_depth) void'(wr_hist.pop_front());
      end
    end
    n_sent++;
  endtask

  // Gửi đúng một item (1 chu kỳ) cho driver
  protected virtual task send_raw(bit rst, bit wr, bit rd, bit [7:0] d);
    fifo_seq_item it = fifo_seq_item::type_id::create("it");
    start_item(it);
    it.rst_req = rst;
    it.wr_en   = rst ? 1'b0 : wr;
    it.rd_en   = rst ? 1'b0 : rd;
    it.data_in = d;
    finish_item(it);
  endtask
endclass : fifo_knob_seq
