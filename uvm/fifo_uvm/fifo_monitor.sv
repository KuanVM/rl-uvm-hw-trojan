// fifo_monitor: samples all FIFO signals every clock through mon_cb
// and writes one item per clock to the analysis port.

class fifo_monitor extends uvm_monitor;

  `uvm_component_utils(fifo_monitor)

  virtual fifo_if vif;

  uvm_analysis_port #(fifo_seq_item) ap;

  function new(string name = "fifo_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "Executing build_phase: creating analysis port and fetching virtual interface...", UVM_HIGH)

    ap = new("ap", this);

    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif)) begin
      if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("MON_NOVIF", {"Virtual interface 'fifo_vif' not found in config_db for: ", get_full_name()})
      end
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    `uvm_info(get_type_name(), "Starting monitor run_phase sampling loop...", UVM_MEDIUM)

    forever begin
      fifo_seq_item item;

      @(vif.mon_cb);

      item = fifo_seq_item::type_id::create("item");

      // Sample every signal at the mon_cb edge
      item.rst_n    = vif.mon_cb.rst_n;
      item.wr_en    = vif.mon_cb.wr_en;
      item.rd_en    = vif.mon_cb.rd_en;
      item.data_in  = vif.mon_cb.data_in;
      item.data_out = vif.mon_cb.data_out;
      item.full     = vif.mon_cb.full;
      item.empty    = vif.mon_cb.empty;

      ap.write(item);

      `uvm_info(get_type_name(),
        $sformatf("Sampled transaction: %s", item.convert2string()),
        UVM_HIGH)
    end
  endtask : run_phase

endclass : fifo_monitor
