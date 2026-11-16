// fifo_test: base test and the four regression tests.

class fifo_base_test extends uvm_test;

  `uvm_component_utils(fifo_base_test)

  fifo_env env;

  function new(string name = "fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Executing build_phase: creating fifo_env...", UVM_HIGH)
    env = fifo_env::type_id::create("env", this);
  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Testbench Topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  virtual task run_phase(uvm_phase phase);
    fifo_base_sequence seq;

    super.run_phase(phase);

    `uvm_info(get_type_name(), "Starting run_phase...", UVM_LOW)
    phase.raise_objection(this, "Starting fifo_base_sequence in fifo_base_test");

    // Drain time lets the last read reach the scoreboard
    phase.phase_done.set_drain_time(this, 50ns);

    seq = fifo_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Executing default sequence on env.agt.sqr...", UVM_MEDIUM)
    seq.start(env.agt.sqr);

    `uvm_info(get_type_name(), "Sequence finished. Dropping objection...", UVM_LOW)
    phase.drop_objection(this, "Completed fifo_base_sequence in fifo_base_test");
  endtask : run_phase

endclass : fifo_base_test

// Reset sequence only.

class fifo_test_reset extends fifo_base_test;

  `uvm_component_utils(fifo_test_reset)

  function new(string name = "fifo_test_reset", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    fifo_reset_sequence seq;

    `uvm_info(get_type_name(), "Starting run_phase: executing fifo_reset_sequence...", UVM_LOW)
    phase.raise_objection(this, "Starting fifo_reset_sequence");

    phase.phase_done.set_drain_time(this, 50ns);

    seq = fifo_reset_sequence::type_id::create("seq");
    seq.start(env.agt.sqr);

    `uvm_info(get_type_name(), "Reset sequence completed. Dropping objection...", UVM_LOW)
    phase.drop_objection(this, "Completed fifo_reset_sequence");
  endtask : run_phase

endclass : fifo_test_reset

// Fill to full, then drain to empty.

class fifo_test_fill_drain extends fifo_base_test;

  `uvm_component_utils(fifo_test_fill_drain)

  function new(string name = "fifo_test_fill_drain", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    fifo_fill_sequence  fill_seq;
    fifo_drain_sequence drain_seq;

    `uvm_info(get_type_name(), "Starting run_phase: executing fill followed by drain sequence...", UVM_LOW)
    phase.raise_objection(this, "Starting fifo_test_fill_drain");

    phase.phase_done.set_drain_time(this, 50ns);

    `uvm_info(get_type_name(), "Executing fifo_fill_sequence...", UVM_MEDIUM)
    fill_seq = fifo_fill_sequence::type_id::create("fill_seq");
    fill_seq.start(env.agt.sqr);

    `uvm_info(get_type_name(), "Executing fifo_drain_sequence...", UVM_MEDIUM)
    drain_seq = fifo_drain_sequence::type_id::create("drain_seq");
    drain_seq.start(env.agt.sqr);

    `uvm_info(get_type_name(), "Fill and drain sequences completed. Dropping objection...", UVM_LOW)
    phase.drop_objection(this, "Completed fifo_test_fill_drain");
  endtask : run_phase

endclass : fifo_test_fill_drain

// Writes while full must not corrupt stored data.

class fifo_test_write_when_full extends fifo_base_test;

  `uvm_component_utils(fifo_test_write_when_full)

  function new(string name = "fifo_test_write_when_full", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    fifo_write_when_full_sequence seq;

    `uvm_info(get_type_name(), "Starting run_phase: executing fifo_write_when_full_sequence...", UVM_LOW)
    phase.raise_objection(this, "Starting fifo_write_when_full_sequence");

    phase.phase_done.set_drain_time(this, 50ns);

    seq = fifo_write_when_full_sequence::type_id::create("seq");
    seq.start(env.agt.sqr);

    `uvm_info(get_type_name(), "Write-when-full sequence completed. Dropping objection...", UVM_LOW)
    phase.drop_objection(this, "Completed fifo_write_when_full_sequence");
  endtask : run_phase

endclass : fifo_test_write_when_full

// 2000 random items.

class fifo_test_random extends fifo_base_test;

  `uvm_component_utils(fifo_test_random)

  function new(string name = "fifo_test_random", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    fifo_random_stress_sequence seq;

    `uvm_info(get_type_name(), "Starting run_phase: executing 2000-item random stress sequence...", UVM_LOW)
    phase.raise_objection(this, "Starting fifo_random_stress_sequence");

    phase.phase_done.set_drain_time(this, 50ns);

    seq = fifo_random_stress_sequence::type_id::create("seq");
    seq.start(env.agt.sqr);

    `uvm_info(get_type_name(), "Random stress sequence completed. Dropping objection...", UVM_LOW)
    phase.drop_objection(this, "Completed fifo_random_stress_sequence");
  endtask : run_phase

endclass : fifo_test_random
