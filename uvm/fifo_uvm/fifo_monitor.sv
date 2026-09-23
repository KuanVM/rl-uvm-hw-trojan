class fifo_monitor extends uvm_monitor;

  `uvm_component_utils(fifo_monitor)

  //broadcast to scoreboard + coverage
  uvm_analysis_port #(fifo_seq_item) analysis_port;

  // virtual interface
  virtual fifo_if vif;

  //constructor
  function new(string name = "fifo_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //  uvm_phase___________________________________

  // build_phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_port = new("analysis_port", this);    // create the port
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  // run_phase
  virtual task run_phase(uvm_phase phase);
    
    // wait for rst_n to complete b4 sampling
    wait (vif.rst_n === 1'b1);
    @(posedge vif.clk);

    forever begin
      fifo_seq_item item;
      item = fifo_seq_item::type_id::create("item");
      collect_transaction(item);
      analysis_port.write(item); // broadcast to all subscribers
    end
  endtask

  //_______________________________
  // collect_transaction(item)
  virtual task collect_transaction(fifo_seq_item item);
    @(vif.mon_cb); // sync to mon clock edge (clocking block)

    item.wr_en   = vif.mon_cb.wr_en;
    item.rd_en   = vif.mon_cb.rd_en;
    item.data_in = vif.mon_cb.data_in;
    item.data_out = vif.mon_cb.data_out;
    item.full    = vif.mon_cb.full;
    item.empty   = vif.mon_cb.empty;
  endtask