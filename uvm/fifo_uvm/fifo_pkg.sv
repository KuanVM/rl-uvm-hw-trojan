package fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // include classes in dependency order
  `include "fifo_seq_item.sv"        // 1. no dependencies
  `include "fifo_sequence.sv"        // 2. depends on seq_item
  `include "fifo_sequencer.sv"       // 3. depends on seq_item
  `include "fifo_driver.sv"          // 4. depends on seq_item
  `include "fifo_monitor.sv"         // 5. depends on seq_item
  `include "fifo_agent.sv"           // 6. depends on drv + mon + seqr
  `include "fifo_scoreboard.sv"      // 7. depends on seq_item
  `include "fifo_coverage.sv"        // 8. depends on seq_item
  `include "fifo_env.sv"             // 9. depends on agent + scb + cov
  `include "fifo_test.sv"            // 10. depends on env + sequences
endpackage
