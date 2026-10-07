# 🧭 UVM FIFO Testbench — Skeleton Guide & Hints

> **Purpose:** Starter skeletons + hints for every component. Fill in the logic yourself.  
> **Build order:** Follow the numbering — each file only depends on files before it.

---

## Build Order at a Glance

```
 1. fifo_seq_item.sv     ← no dependencies, start here
 2. fifo_sequence.sv     ← depends on seq_item
 3. fifo_sequencer.sv    ← depends on seq_item (one-liner)
 4. fifo_driver.sv       ← depends on seq_item + interface
 5. fifo_monitor.sv      ← depends on seq_item + interface
 6. fifo_agent.sv        ← depends on driver + monitor + sequencer
 7. fifo_scoreboard.sv   ← depends on seq_item
 8. fifo_coverage.sv     ← depends on seq_item
 9. fifo_env.sv          ← depends on agent + scoreboard + coverage
10. fifo_test.sv         ← depends on env + sequences
11. fifo_assertions.sv   ← standalone SVA module (no UVM)
12. fifo_pkg.sv          ← includes all of the above
13. top.sv               ← instantiates everything
14. Makefile             ← compile & run
```

---

## 1. `fifo_seq_item.sv` — The Transaction

This is your "packet" — one clock cycle of stimulus + observed outputs.

```systemverilog
class fifo_seq_item extends uvm_sequence_item;

  // --- Randomizable stimulus fields (what the DRIVER sends to DUT) ---
  rand bit       wr_en;
  rand bit       rd_en;
  rand bit [7:0] data_in;

  // --- Observed response fields (what the MONITOR captures back) ---
  // These are NOT randomized — they come from the DUT
  bit [7:0] data_out;
  bit       full;
  bit       empty;

  // --- UVM boilerplate: register with factory ---
  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(wr_en,    UVM_ALL_ON)
    `uvm_field_int(rd_en,    UVM_ALL_ON)
    `uvm_field_int(data_in,  UVM_ALL_ON)
    `uvm_field_int(data_out, UVM_ALL_ON)
    `uvm_field_int(full,     UVM_ALL_ON)
    `uvm_field_int(empty,    UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction

  // --- Constraints ---
  // HINT: Add distribution constraints here for random tests.
  //       For directed tests, the sequence will override with inline constraints.
  //
  // Example shape (fill in the weights yourself):
  //   constraint c_wr_bias { wr_en dist { ... }; }
  //   constraint c_rd_bias { rd_en dist { ... }; }

endclass
```

### 💡 Hints
- `rand` fields = **inputs** you drive. Non-rand fields = **outputs** you observe
- `uvm_field_int` gives you free `print()`, `copy()`, `compare()`, `pack()`/`unpack()` — very useful for debug
- Constraints here are **defaults**. Directed sequences override them with `item.randomize() with { ... }`
- Think about: what `dist` weights would make a random test naturally hit both full and empty states?

---

## 2. `fifo_sequence.sv` — Stimulus Generation

Replaces your old `fifo_generator`. Creates N randomized items and feeds them to the sequencer.

```systemverilog
class fifo_base_sequence extends uvm_sequence #(fifo_seq_item);

  `uvm_object_utils(fifo_base_sequence)

  int num_transactions = 100;  // override per test

  function new(string name = "fifo_base_sequence");
    super.new(name);
  endfunction

  task body();
    // HINT: This is the main loop. For each transaction:
    //   1. Create a seq_item          → req = fifo_seq_item::type_id::create("req")
    //   2. Tell sequencer you're ready → start_item(req)
    //   3. Randomize it               → req.randomize()  (or with inline constraints)
    //   4. Send it to driver           → finish_item(req)
    //
    // Skeleton loop:
    //   repeat (num_transactions) begin
    //     req = fifo_seq_item::type_id::create("req");
    //     start_item(req);
    //     if (!req.randomize()) `uvm_fatal(...)
    //     finish_item(req);
    //   end
  endtask

endclass
```

### 💡 Hints
- `start_item()` blocks until the driver calls `get_next_item()` — this is the handshake
- `finish_item()` blocks until the driver calls `item_done()` — this completes the handshake
- For **directed tests**, make new sequence classes that extend this one and override `body()` with inline constraints:
  ```systemverilog
  // Example: a fill-to-full sequence
  class fifo_seq_fill extends fifo_base_sequence;
    task body();
      repeat (32) begin
        req = fifo_seq_item::type_id::create("req");
        start_item(req);
        // HINT: use "randomize() with { ... }" to force wr_en=1, rd_en=0
        finish_item(req);
      end
    endtask
  endclass
  ```
- You'll eventually need sequences for: reset, fill, drain, write-when-full, read-when-empty, simultaneous R/W, ordering, alternating R/W, and random stress

---

## 3. `fifo_sequencer.sv` — Sequencer (Shortest File)

This is almost always just a typedef. The real logic is in `uvm_sequencer` base class.

```systemverilog
class fifo_sequencer extends uvm_sequencer #(fifo_seq_item);

  `uvm_component_utils(fifo_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
```

### 💡 Hints
- That's it. Really. The `#(fifo_seq_item)` parameterization tells UVM what type of items flow through
- The sequencer arbitrates if you run multiple sequences — for now, one at a time is fine

---

## 4. `fifo_driver.sv` — Pin Wiggler

Gets seq_items from the sequencer, drives DUT pins through the interface's clocking block.

```systemverilog
class fifo_driver extends uvm_driver #(fifo_seq_item);

  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;  // handle to the interface

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // HINT: Get the virtual interface from config_db
    //   if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
    //     `uvm_fatal("NOVIF", "Virtual interface not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // HINT: Two things happen here:
    //   1. Initial reset sequence
    //   2. Forever loop: get item → drive pins → signal done
    //
    // Skeleton:
    //   // --- Reset ---
    //   vif.rst_n <= 0;
    //   repeat(5) @(posedge vif.clk);  // hold reset for 5 cycles
    //   vif.rst_n <= 1;
    //   @(posedge vif.clk);
    //
    //   // --- Main drive loop ---
    //   forever begin
    //     seq_item_port.get_next_item(req);
    //
    //     // Drive signals via clocking block:
    //     //   vif.drv_cb.wr_en   <= req.wr_en;
    //     //   vif.drv_cb.rd_en   <= req.rd_en;
    //     //   vif.drv_cb.data_in <= req.data_in;
    //     //   @(vif.drv_cb);   // wait one clock cycle
    //
    //     seq_item_port.item_done();
    //   end
  endtask

endclass
```

### 💡 Hints
- **`drv_cb`** is the clocking block from your interface — it adds the `#1ns` input/output skew to avoid race conditions
- `@(vif.drv_cb)` waits for one clock edge as seen by the clocking block — **use this, not `@(posedge vif.clk)`** inside the drive loop
- Reset is driven **directly** (not through `drv_cb`) because reset is asynchronous to the clocking block. That's why your interface's `DRV` modport has `output rst_n` separately
- `get_next_item()` + `item_done()` is the handshake with the sequencer. Don't call `item_done()` until you've finished driving the pins for this cycle
- Think about: what if a sequence wants to assert reset mid-test? You might want a way to handle that

---

## 5. `fifo_monitor.sv` — Passive Observer

Watches DUT pins, creates seq_items from observations, broadcasts via analysis port.

```systemverilog
class fifo_monitor extends uvm_monitor;

  `uvm_component_utils(fifo_monitor)

  virtual fifo_if vif;
  uvm_analysis_port #(fifo_seq_item) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_port = new("analysis_port", this);
    // HINT: Also get vif from config_db, same pattern as driver
  endfunction

  task run_phase(uvm_phase phase);
    // HINT: Forever loop — each iteration captures one transaction:
    //
    //   forever begin
    //     @(vif.mon_cb);  // wait for clock edge
    //
    //     // Create a new seq_item and fill it with OBSERVED values:
    //     //   txn = fifo_seq_item::type_id::create("txn");
    //     //   txn.wr_en   = vif.mon_cb.wr_en;
    //     //   txn.rd_en   = vif.mon_cb.rd_en;
    //     //   txn.data_in = vif.mon_cb.data_in;
    //     //   txn.data_out = vif.mon_cb.data_out;
    //     //   txn.full    = vif.mon_cb.full;
    //     //   txn.empty   = vif.mon_cb.empty;
    //
    //     // Broadcast to scoreboard + coverage:
    //     //   analysis_port.write(txn);
    //   end
  endtask

endclass
```

### 💡 Hints
- The monitor is **passive** — it never drives anything, only reads
- Uses `mon_cb` (monitor clocking block) which has **all signals as inputs**
- `analysis_port.write()` is a **broadcast** — every subscriber (scoreboard, coverage) gets a copy automatically
- ⚠️ **Critical timing issue** (Risk R1 from your plan): `data_out` is **registered** — it updates 1 cycle after `rd_en`. Your monitor samples `data_out` on the same edge as `rd_en`. The scoreboard needs to account for this 1-cycle latency. Think about where to handle this — in the monitor? Or in the scoreboard?

---

## 6. `fifo_agent.sv` — Component Bundle

Groups sequencer + driver + monitor. Supports active/passive mode.

```systemverilog
class fifo_agent extends uvm_agent;

  `uvm_component_utils(fifo_agent)

  fifo_sequencer seqr;
  fifo_driver    drv;
  fifo_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // HINT: Monitor is ALWAYS created (passive observation)
    //   mon = fifo_monitor::type_id::create("mon", this);

    // HINT: Driver + Sequencer only in ACTIVE mode
    //   if (get_is_active() == UVM_ACTIVE) begin
    //     drv  = fifo_driver::type_id::create("drv", this);
    //     seqr = fifo_sequencer::type_id::create("seqr", this);
    //   end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // HINT: Connect driver's port to sequencer (ACTIVE mode only)
    //   if (get_is_active() == UVM_ACTIVE) begin
    //     drv.seq_item_port.connect(seqr.seq_item_export);
    //   end
  endfunction

endclass
```

### 💡 Hints
- `UVM_ACTIVE` = drives stimulus (has driver + sequencer). `UVM_PASSIVE` = observe only (monitor only)
- For this project you only need `UVM_ACTIVE` — but building passive support now is good practice
- `connect_phase` runs AFTER `build_phase` — all components exist before you wire them
- The driver-sequencer connection is the **TLM port** that carries seq_items

---

## 7. `fifo_scoreboard.sv` — Checker

Maintains a reference FIFO queue. Compares DUT output against expected values.

```systemverilog
class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)

  uvm_tlm_analysis_fifo #(fifo_seq_item) analysis_fifo;

  // HINT: Your reference model state:
  //   bit [7:0] ref_queue[$];    // SystemVerilog queue — behaves like a FIFO
  //   int pass_count, fail_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_fifo = new("analysis_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_seq_item txn;

    forever begin
      analysis_fifo.get(txn);  // blocks until monitor sends something

      // HINT: Your checking logic goes here. Think about:
      //
      //   1. If wr_en && !full → push data_in onto ref_queue
      //      ref_queue.push_back(txn.data_in);
      //
      //   2. If rd_en && !empty → pop from ref_queue and compare
      //      expected = ref_queue.pop_front();
      //      // But WHEN does data_out actually have the value?
      //      // Remember: data_out is REGISTERED (1-cycle delay)
      //      // This is the trickiest part of your scoreboard.
      //
      //   3. Simultaneous R/W? Process write first, then read
      //      (matches RTL behavior)
      //
      //   4. Use `uvm_info` / `uvm_error` for pass/fail reporting
    end
  endtask

  function void report_phase(uvm_phase phase);
    // HINT: Print final summary
    //   `uvm_info(get_type_name(),
    //     $sformatf("Scoreboard: %0d passed, %0d failed", pass_count, fail_count),
    //     UVM_LOW)
  endfunction

endclass
```

### 💡 Hints
- `uvm_tlm_analysis_fifo` has a built-in `analysis_export` — you'll connect this to the monitor's `analysis_port` in the environment
- **The `data_out` latency problem**: When the monitor sees `rd_en=1 && empty=0`, the `data_out` on that SAME cycle is still the old value. The new value appears NEXT cycle. Two strategies:
  - **(A) Delay in scoreboard**: When you see a valid read, save the expected value. On the NEXT transaction, compare `data_out` against that saved value
  - **(B) Delay in monitor**: Have the monitor sample `data_out` one cycle later when a read was observed
  - Strategy (A) is generally cleaner — the monitor stays simple, complexity lives in the scoreboard
- `ref_queue[$]` — the `$` makes it an unbounded queue. `push_back` / `pop_front` gives you FIFO behavior
- Think about edge cases: what if `ref_queue` is empty but DUT says `empty=0`? That's a mismatch in your model

---

## 8. `fifo_coverage.sv` — Functional Coverage Collector

Subscribes to monitor transactions, samples a covergroup.

```systemverilog
class fifo_coverage extends uvm_subscriber #(fifo_seq_item);

  `uvm_component_utils(fifo_coverage)

  fifo_seq_item txn;

  // HINT: Define your covergroup here
  //   covergroup fifo_cg;
  //     cp_wr_en: coverpoint txn.wr_en;
  //     cp_rd_en: coverpoint txn.rd_en;
  //     cx_wr_rd: cross cp_wr_en, cp_rd_en;
  //     cp_full:  coverpoint txn.full;
  //     cp_empty: coverpoint txn.empty;
  //     // ... add more from your coverage plan (Section 4 of the vplan)
  //     // Think about: cx_wr_full, cx_rd_empty, cp_data_in bins, cp_occupancy
  //   endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    // HINT: Construct the covergroup here
    //   fifo_cg = new();
  endfunction

  // This is called automatically for every transaction the monitor broadcasts
  function void write(fifo_seq_item t);
    txn = t;
    // HINT: Sample the covergroup
    //   fifo_cg.sample();
  endfunction

endclass
```

### 💡 Hints
- `uvm_subscriber` automatically gives you an `analysis_export` — no need to create one manually
- The `write()` function is the callback — UVM calls it every time the monitor's `analysis_port.write()` fires
- For `cp_occupancy` — you don't have `count` as a DUT output port. Options:
  - **(A)** Track occupancy in the coverage collector with your own counter (same logic as scoreboard's queue size)
  - **(B)** Use a hierarchical reference like `top.dut.count` (quick but not portable)
  - Strategy (A) is better practice
- Transition coverage (`0 => 1`, `1 => 0`) uses SystemVerilog transition bins — look up the syntax if you haven't used it before

---

## 9. `fifo_env.sv` — Environment

Instantiates all components and wires their TLM ports.

```systemverilog
class fifo_env extends uvm_env;

  `uvm_component_utils(fifo_env)

  fifo_agent      agent;
  fifo_scoreboard scoreboard;
  fifo_coverage   coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // HINT: Create all components using the factory
    //   agent      = fifo_agent::type_id::create("agent", this);
    //   scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    //   coverage   = fifo_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // HINT: Wire the monitor's analysis_port to scoreboard and coverage
    //   The monitor broadcasts, both subscribers receive.
    //
    //   agent.mon.analysis_port.connect(scoreboard.analysis_fifo.analysis_export);
    //   agent.mon.analysis_port.connect(coverage.analysis_export);
  endfunction

endclass
```

### 💡 Hints
- This is where the "plumbing" diagram from your verification plan (Section 3.1) becomes real code
- The two `connect()` calls implement the fan-out: monitor → {scoreboard, coverage}
- If you get `connection error` at runtime, double-check that the port/export names match exactly
- Common mistake: connecting in `build_phase` instead of `connect_phase` — components don't exist yet in build!

---

## 10. `fifo_test.sv` — Test(s)

Creates the environment, selects and starts a sequence.

```systemverilog
// --- Base test (shared setup) ---
class fifo_base_test extends uvm_test;

  `uvm_component_utils(fifo_base_test)

  fifo_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  // HINT: run_phase is where you start sequences
  //   task run_phase(uvm_phase phase);
  //     // Raise objection to keep simulation running
  //     phase.raise_objection(this);
  //
  //     // Create and start a sequence on the agent's sequencer
  //     // (to be overridden in child test classes)
  //
  //     phase.drop_objection(this);  // simulation ends after this
  //   endtask

endclass

// --- Example: Random stress test ---
// class fifo_test_random extends fifo_base_test;
//   `uvm_component_utils(fifo_test_random)
//
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction
//
//   task run_phase(uvm_phase phase);
//     fifo_base_sequence seq;
//     phase.raise_objection(this);
//
//     seq = fifo_base_sequence::type_id::create("seq");
//     seq.num_transactions = 2000;
//     seq.start(env.agent.seqr);  // <-- this runs the sequence
//
//     phase.drop_objection(this);
//   endtask
// endclass

// HINT: Create one test class per test scenario from your test plan (T01–T10).
//       Each test creates the appropriate sequence and starts it.
//       You select which test to run via command line:
//         +UVM_TESTNAME=fifo_test_random
```

### 💡 Hints
- **Objections** control simulation lifetime: `raise_objection` = "I'm still doing stuff", `drop_objection` = "I'm done". Simulation ends when all objections are dropped
- `seq.start(env.agent.seqr)` — this is the key call. It runs the sequence's `body()` task on the specified sequencer
- Each test from your plan (T01–T10) maps to a test class + sequence pair
- For tests that chain sequences (e.g., T04 = fill then drain), just call `seq.start()` twice with different sequences

---

## 11. `fifo_assertions.sv` — SVA Bind Module

This is a **plain module** (not a class). Contains concurrent properties.

```systemverilog
module fifo_sva (
  input logic       clk,
  input logic       rst_n,
  input logic       wr_en,
  input logic       rd_en,
  input logic [7:0] data_in,
  input logic [7:0] data_out,
  input logic       full,
  input logic       empty,
  input logic [4:0] wr_ptr,
  input logic [4:0] rd_ptr,
  input logic [5:0] count
);

  // HINT: Each assertion follows this pattern:
  //
  //   property p_name;
  //     @(posedge clk) disable iff (!rst_n)
  //       <antecedent> |-> <consequent>;
  //   endproperty
  //   a_name: assert property (p_name)
  //     else `uvm_error("SVA", "p_name failed")
  //
  // From your assertion plan (Section 5):
  //   A01: p_reset_state     — after reset rises, empty=1 and full=0
  //   A02: p_full_at_depth   — full iff count == DEPTH
  //   A03: p_empty_at_zero   — empty iff count == 0
  //   A04: p_no_wr_when_full — wr_ptr stable when full (unless full drops)
  //   A05: p_no_rd_when_empty— rd_ptr stable when empty (unless empty drops)
  //   A06: p_count_bounds    — count <= DEPTH (always)
  //   A07: p_full_empty_mutex— !(full && empty) (always)
  //
  // HINT for "always true" assertions (A06, A07):
  //   No antecedent needed. Just:
  //     @(posedge clk) disable iff (!rst_n) !(full && empty);

endmodule
```

### 💡 Hints
- `|->` = same-cycle implication. `|=>` = next-cycle implication. Choose carefully based on timing
- `disable iff (!rst_n)` prevents false failures during reset
- The `bind` statement goes in `top.sv` — it connects this module's ports to the DUT's internal signals using `.*` (auto-connect by name)
- You access DUT internals (`wr_ptr`, `rd_ptr`, `count`) through bind — this is legal because bind can see inside the module it's bound to

---

## 12. `fifo_pkg.sv` — Package

Bundles all class files in dependency order.

```systemverilog
package fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // HINT: Include in DEPENDENCY ORDER (leaf classes first)
  `include "fifo_seq_item.sv"
  `include "fifo_sequence.sv"
  `include "fifo_sequencer.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_agent.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_env.sv"
  `include "fifo_test.sv"
endpackage
```

### 💡 Hints
- Order matters! If file B references a class from file A, A must be included first
- `fifo_if.sv` and `fifo_assertions.sv` are **modules**, not classes — they are NOT included in the package. They're compiled separately
- If you get "type not found" errors, it's almost always an include order issue

---

## 13. `top.sv` — Top Module

Clock gen, DUT instantiation, interface wiring, UVM launch.

```systemverilog
module top;

  import uvm_pkg::*;
  import fifo_pkg::*;

  // --- Clock generation ---
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;  // 100MHz, 10ns period

  // --- Interface instantiation ---
  fifo_if intf(.clk(clk));

  // --- DUT instantiation ---
  // HINT: Connect DUT ports to interface signals
  //   sync_fifo #(.DATA_WIDTH(8), .DEPTH(32)) dut (
  //     .clk      (clk),
  //     .rst_n    (intf.rst_n),
  //     .wr_en    (intf.wr_en),
  //     .rd_en    (intf.rd_en),
  //     .data_in  (intf.data_in),
  //     .data_out (intf.data_out),
  //     .full     (intf.full),
  //     .empty    (intf.empty)
  //   );

  // --- Bind assertions to DUT ---
  // HINT: bind sync_fifo fifo_sva sva_inst (.*);

  // --- Pass interface to UVM via config_db ---
  initial begin
    // HINT: This is how the driver and monitor get the interface handle:
    //   uvm_config_db #(virtual fifo_if)::set(null, "*", "vif", intf);

    // HINT: Launch UVM — test selected via +UVM_TESTNAME on command line
    //   run_test();
  end

endmodule
```

### 💡 Hints
- `uvm_config_db::set(null, "*", "vif", intf)` — the `"*"` means "any component can grab it". The `"vif"` is the key string that must match the `get()` call in driver/monitor
- `run_test()` with no argument means UVM reads `+UVM_TESTNAME=...` from the command line
- The `bind` statement auto-maps ports by name — make sure your SVA module's port names match the DUT's internal signal names exactly

---

## 14. `Makefile` — Build & Run

```makefile
# HINT: Adjust paths for your simulator (Questa shown)

UVM_HOME  ?= /path/to/uvm          # adjust this
VLOG      = vlog
VSIM      = vsim

# Compile
compile:
	$(VLOG) +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
	$(VLOG) fifo_pkg.sv
	$(VLOG) fifo_if.sv
	$(VLOG) sync_fifo.sv
	$(VLOG) fifo_assertions.sv
	$(VLOG) top.sv

# Run (specify test via TEST variable)
run: compile
	$(VSIM) -c top +UVM_TESTNAME=$(TEST) -do "run -all; quit"

# Example: make run TEST=fifo_test_random
```

### 💡 Hints
- Compile order matters: UVM lib → package → interface → DUT → assertions → top
- For **iverilog** (free), the flow is different — iverilog doesn't have native UVM support. You'd need the open-source UVM library. Questa is much easier for UVM
- Add coverage flags: `-coverage` on compile, `vcover merge` and `vcover report` after runs

---

## 🗺️ When You're Stuck — Decision Map

```
Stuck on what?
│
├─ "Nothing compiles"
│   → Start with JUST: seq_item + pkg + interface + DUT + top
│   → Get `run_test()` to print the UVM banner. That's your first win.
│
├─ "Driver doesn't drive anything"
│   → Add $display / `uvm_info inside run_phase
│   → Check: did you get vif from config_db? (null vif = silent failure)
│   → Check: is the sequence actually calling start_item/finish_item?
│
├─ "Scoreboard always fails"
│   → 90% chance it's the data_out latency (1-cycle delay)
│   → Add `uvm_info` to print expected vs actual on every comparison
│   → Process writes BEFORE reads for simultaneous R/W
│
├─ "Coverage is stuck at 0%"
│   → Is the covergroup constructed? (must call `new()` in constructor)
│   → Is `sample()` being called in `write()`?
│   → Is the monitor actually connected to the coverage subscriber?
│
├─ "UVM_FATAL: Virtual interface not found"
│   → Check config_db::set() in top.sv — is the key string "vif"?
│   → Check config_db::get() in driver/monitor — same key?
│   → Is set() called BEFORE run_test()?
│
├─ "Simulation ends immediately"
│   → You forgot raise_objection / drop_objection in the test
│   → UVM ends when no objections are raised
│
└─ "Assertion fires during reset"
    → Add `disable iff (!rst_n)` to every concurrent assertion
```

---

## 🔨 Suggested Build Milestones

Build incrementally. Don't write all 14 files then try to compile.

| Step | What to write | How to test it |
|------|--------------|----------------|
| **S1** | `seq_item` + `sequencer` + `pkg` (with only these 2 includes) + `top` (clock + DUT + interface only, no UVM yet) | Compiles without errors |
| **S2** | Add `driver` (with reset + simple drive loop) to pkg. Add `config_db::set` to top. | Driver prints `UVM_INFO` messages |
| **S3** | Add `monitor` + `agent`. Wire in agent. | Monitor prints observed transactions |
| **S4** | Add `scoreboard`. Wire in env. | Scoreboard reports pass/fail |
| **S5** | Add `sequence` (basic random). Add `test`. | End-to-end random test runs |
| **S6** | Add `coverage`. | Coverage report shows non-zero numbers |
| **S7** | Add `assertions`. Bind in top. | SVA fires on injected errors, silent on clean |
| **S8** | Write directed sequences for T01–T10. | All tests pass |
