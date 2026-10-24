// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Thêm fifo_knobs, fifo_knob_seq, fifo_rl_observer, rl_bandit,
//             rl_csv_logger, fifo_rl_test theo đúng thứ tự phụ thuộc.
// =============================================================================
package fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // include classes in dependency order
  `include "fifo_seq_item.sv"        // 1. no dependencies
  `include "fifo_knobs.sv"           // 2. knob vector (uvm_object)
  `include "fifo_sequence.sv"        // 3. depends on seq_item
  `include "fifo_knob_seq.sv"        // 4. depends on seq_item + knobs
  `include "fifo_sequencer.sv"       // 5. depends on seq_item
  `include "fifo_driver.sv"          // 6. depends on seq_item
  `include "fifo_monitor.sv"         // 7. depends on seq_item
  `include "fifo_agent.sv"           // 8. depends on drv + mon + seqr
  `include "fifo_scoreboard.sv"      // 9. depends on seq_item
  `include "fifo_coverage.sv"        // 10. depends on seq_item
  `include "fifo_rl_observer.sv"     // 11. depends on seq_item
  `include "fifo_env.sv"             // 12. depends on agent + scb + cov + rl_obs
  `include "rl_bandit.sv"            // 13. generic, no FIFO dependency
  `include "rl_csv_logger.sv"        // 14. generic, no FIFO dependency
  `include "fifo_test.sv"            // 15. depends on env + sequences
  `include "fifo_rl_test.sv"         // 16. depends on base test + bandit + logger + knob_seq
endpackage
