class fifo_agent extends uvm_agent;
  `uvm_component_utils(fifo_agent)

  // component handles
  fifo_sequencer sequencer;
  fifo_driver    driver;
  fifo_monitor   monitor;

  // constructor
  function new(string name = "fifo_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // uvm_phase
  // build phase
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // monitor is always created
      monitor = fifo_monitor::type_id::create("monitor", this);

      // sequencer + driver only in active mode
      if (get_is_active() == UVM_ACTIVE) begin
        sequencer = fifo_sequencer::type_id::create("sequencer", this);
        driver    = fifo_driver::type_id::create("driver", this);
      end
    endfunction

    // connect phase - wire TLM ports
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      if (get_is_active() == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
      end 
    endfunction

endclass
