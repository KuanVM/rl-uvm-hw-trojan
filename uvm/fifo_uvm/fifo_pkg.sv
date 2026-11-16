// fifo_pkg: testbench classes, included in dependency order.
// The RL loop files (knobs, knob seq, RL observer, bandit, CSV logger, RL test)
// are included after the classes they depend on.

package fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "fifo_seq_item.sv"
  `include "fifo_knobs.sv"          // RL: knob vector (uvm_object)
  `include "fifo_sequence.sv"
  `include "fifo_knob_seq.sv"       // RL: depends on seq_item + knobs
  `include "fifo_sequencer.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_agent.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_rl_observer.sv"    // RL: depends on seq_item
  `include "fifo_env.sv"
  `include "rl_bandit.sv"           // RL: generic, no FIFO dependency
  `include "rl_csv_logger.sv"       // RL: generic, no FIFO dependency
  `include "fifo_test.sv"
  `include "fifo_rl_test.sv"        // RL: depends on base test + env + RL classes
endpackage
