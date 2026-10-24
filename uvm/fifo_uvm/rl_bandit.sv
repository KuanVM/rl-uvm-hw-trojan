// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Tạo mới. Bandit K tay viết thuần SystemVerilog (không DPI/Python):
//             chính sách FIXED (B0), RANDOM (B1), UCB1, EPSILON-GREEDY (dự phòng).
//             Tie-break ngẫu nhiên, vòng khởi động chơi mỗi tay 1 lần theo thứ
//             tự xáo trộn. Không phụ thuộc FIFO: dùng lại được cho DUT khác và
//             cho bandit tách theo từng núm (mỗi núm một instance).
// =============================================================================
//
// UCB1 (Auer et al., 2002): chọn a = argmax  mean(a) + c * sqrt(2 ln t / n(a)),
// với c = 1 là công thức gốc. Reward phải nằm trong [0, 1].
// Mọi số ngẫu nhiên lấy từ RNG của thread gọi (run_phase của test), nên cùng
// -sv_seed sẽ cho cùng chuỗi quyết định.

typedef enum int {POL_FIXED, POL_RANDOM, POL_UCB1, POL_EGREEDY} rl_policy_e;

class rl_bandit extends uvm_object;
  `uvm_object_utils(rl_bandit)

  rl_policy_e  policy    = POL_UCB1;
  int unsigned num_arms  = 1;
  int unsigned fixed_arm = 0;      // dùng cho POL_FIXED
  real         ucb_c     = 1.0;    // hệ số khám phá UCB1
  real         epsilon   = 0.1;    // xác suất khám phá của ε-greedy

  int unsigned pulls[];
  real         sum_r[];
  int unsigned t_total;            // tổng số lần update
  protected int unsigned init_order[$];  // vòng khởi động UCB1 / ε-greedy

  function new(string name = "rl_bandit");
    super.new(name);
  endfunction

  // Gọi trong run_phase (để RNG ổn định theo seed)
  function void configure(rl_policy_e p, int unsigned k);
    if (k == 0) `uvm_fatal("BANDIT", "num_arms phải > 0")
    policy   = p;
    num_arms = k;
    pulls    = new[k];
    sum_r    = new[k];
    foreach (pulls[i]) begin pulls[i] = 0; sum_r[i] = 0.0; end
    t_total  = 0;
    init_order.delete();
    for (int i = 0; i < k; i++) init_order.push_back(i);
    init_order.shuffle();
  endfunction

  static function rl_policy_e parse_policy(string s);
    case (s)
      "fixed"  , "B0" : return POL_FIXED;
      "random" , "B1" : return POL_RANDOM;
      "ucb1"          : return POL_UCB1;
      "egreedy", "eps": return POL_EGREEDY;
      default: begin
        `uvm_fatal("BANDIT", {"RL_POLICY không hợp lệ: ", s, " (fixed|random|ucb1|egreedy)"})
        return POL_UCB1;
      end
    endcase
  endfunction

  function real mean(int unsigned a);
    return (pulls[a] == 0) ? 0.0 : sum_r[a] / pulls[a];
  endfunction

  function real ucb_index(int unsigned a);
    if (pulls[a] == 0) return 1.0e30;
    return mean(a) + ucb_c * $sqrt(2.0 * $ln(real'(t_total)) / pulls[a]);
  endfunction

  // ---------------------------------------------------------------------------
  function int unsigned select_arm();
    case (policy)
      POL_FIXED : return fixed_arm;
      POL_RANDOM: return $urandom_range(num_arms-1, 0);
      default: begin
        // khởi động: chơi mỗi tay 1 lần (thứ tự đã xáo)
        while (init_order.size() > 0) begin
          int unsigned a;
          a = init_order.pop_front();
          if (pulls[a] == 0) return a;
        end
        if (policy == POL_EGREEDY) begin
          if ($urandom_range(999_999, 0) < int'(epsilon * 1_000_000.0))
            return $urandom_range(num_arms-1, 0);
          return argmax(0);
        end
        return argmax(1);
      end
    endcase
  endfunction

  // use_ucb = 1: argmax chỉ số UCB; 0: argmax trung bình. Hoà -> chọn ngẫu nhiên.
  protected function int unsigned argmax(bit use_ucb);
    int unsigned ties[$];
    real best;
    real v;
    best = -1.0e30;
    for (int a = 0; a < num_arms; a++) begin
      v = use_ucb ? ucb_index(a) : mean(a);
      if (v > best + 1.0e-12) begin
        best = v; ties.delete(); ties.push_back(a);
      end else if (v > best - 1.0e-12) begin
        ties.push_back(a);
      end
    end
    return ties[$urandom_range(ties.size()-1, 0)];
  endfunction

  function void update(int unsigned arm, real reward);
    if (arm >= num_arms) `uvm_fatal("BANDIT", $sformatf("arm %0d ngoài khoảng", arm))
    pulls[arm]++;
    sum_r[arm] += reward;
    t_total++;
  endfunction

  function string stats_str(string arm_names[$]);
    string s;
    s = $sformatf("policy=%s t=%0d", policy.name(), t_total);
    for (int a = 0; a < num_arms; a++)
      s = {s, $sformatf("\n  arm %2d %-18s pulls=%4d mean=%.4f", a,
                        (a < arm_names.size()) ? arm_names[a] : "", pulls[a], mean(a))};
    return s;
  endfunction
endclass : rl_bandit
