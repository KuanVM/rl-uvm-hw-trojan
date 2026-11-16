// fifo_agent: sequencer, driver and monitor.
// The sequencer and driver are created only when the agent is UVM_ACTIVE.

class fifo_agent extends uvm_agent;

  `uvm_component_utils(fifo_agent)

  fifo_sequencer sqr;  // Sequencer: arbitrates transactions from sequences
  fifo_driver    drv;  // Driver: wiggles DUT interface pins
  fifo_monitor   mon;  // Monitor: passive observer of interface traffic

  uvm_analysis_port #(fifo_seq_item) ap;

  function new(string name = "fifo_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "Executing build_phase...", UVM_HIGH)

    ap = new("ap", this);

    mon = fifo_monitor::type_id::create("mon", this);

    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_info(get_type_name(), "Agent configured as UVM_ACTIVE: creating sequencer and driver", UVM_MEDIUM)
      sqr = fifo_sequencer::type_id::create("sqr", this);
      drv = fifo_driver::type_id::create("drv", this);
    end else begin
      `uvm_info(get_type_name(), "Agent configured as UVM_PASSIVE: skipping sequencer and driver", UVM_MEDIUM)
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    `uvm_info(get_type_name(), "Executing connect_phase...", UVM_HIGH)

    // Connect driver to sequencer only when active
    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_info(get_type_name(), "Connecting drv.seq_item_port -> sqr.seq_item_export", UVM_HIGH)
      drv.seq_item_port.connect(sqr.seq_item_export);
    end

    mon.ap.connect(this.ap);
  endfunction : connect_phase

endclass : fifo_agent
