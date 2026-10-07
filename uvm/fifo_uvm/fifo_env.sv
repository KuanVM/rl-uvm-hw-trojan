class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  // uvc handles
  fifo_agent        agent;
  fifo_scoreboard   scoreboard;
  fifo_coverage     coverage;

  // agents for multi-if DUTS /* will write later


  // constructor
  function new(string name = "fifo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // build phase - create all children
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = fifo_agent::type_id::create("agent", this);
    scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    coverage = fifo_coverage::type_id::create("coverage", this);
  endfunction

  // connect phase - wire tlm ports
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // monitor -> scoreboard (via analysis_fifo)
    agent.monitor.analysis_port.connect(scoreboard.analysis_fifo.analysis_export);

    // monitor -> coverage (via subscriber's built in export)
    agent.monitor.analysis_port.connect(coverage.analysis_export);
  endfunction

endclass