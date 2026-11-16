// fifo_env: agent, scoreboard and coverage. The monitor feeds both checkers.

class fifo_env extends uvm_env;

  `uvm_component_utils(fifo_env)

  fifo_agent      agt;  // FIFO interface agent (sequencer, driver, monitor)
  fifo_scoreboard scb;  // Scoreboard checking DUT against reference model
  fifo_coverage   cov;  // Coverage subscriber tracking verification closure

  function new(string name = "fifo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "Executing build_phase: creating sub-components...", UVM_HIGH)

    agt = fifo_agent::type_id::create("agt", this);
    scb = fifo_scoreboard::type_id::create("scb", this);
    cov = fifo_coverage::type_id::create("cov", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    `uvm_info(get_type_name(), "Executing connect_phase: connecting analysis ports...", UVM_HIGH)

    // Monitor to scoreboard
    `uvm_info(get_type_name(), "Connecting agt.mon.ap -> scb.mon_fifo.analysis_export", UVM_HIGH)
    agt.mon.ap.connect(scb.mon_fifo.analysis_export);

    // Monitor to coverage
    `uvm_info(get_type_name(), "Connecting agt.mon.ap -> cov.analysis_export", UVM_HIGH)
    agt.mon.ap.connect(cov.analysis_export);
  endfunction : connect_phase

endclass : fifo_env
