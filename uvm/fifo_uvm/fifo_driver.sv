// fifo_driver: drives one item per clock through drv_cb and returns the sampled outputs.
// Applies the initial reset when rst_n is not yet driven.

class fifo_driver extends uvm_driver #(fifo_seq_item);

  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;

  function new(string name = "fifo_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "Executing build_phase: fetching virtual interface...", UVM_HIGH)

    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif)) begin
      if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("DRV_NOVIF", {"Virtual interface 'fifo_vif' not found in config_db for: ", get_full_name()})
      end
    end
  endfunction : build_phase

  virtual task reset_dut();
    `uvm_info(get_type_name(), "Asserting DUT reset (rst_n = 0) for 5 clock cycles...", UVM_MEDIUM)

    vif.rst_n          = 1'b0;

    // Inputs idle during reset
    vif.drv_cb.wr_en   <= 1'b0;
    vif.drv_cb.rd_en   <= 1'b0;
    vif.drv_cb.data_in <= '0;

    // Hold reset for 5 clocks
    repeat (5) @(vif.drv_cb);

    vif.rst_n = 1'b1;
    @(vif.drv_cb);

    `uvm_info(get_type_name(), "DUT reset de-asserted (rst_n = 1).", UVM_MEDIUM)
  endtask : reset_dut

  virtual task drive_item(fifo_seq_item item);
    `uvm_info(get_type_name(),
      $sformatf("Driving item -> wr_en=%0b rd_en=%0b data_in=0x%02h",
                item.wr_en, item.rd_en, item.data_in),
      UVM_HIGH)

    if (item.rst_req) begin
      // Reset request (RL knob sequence): rst_n low for this cycle, no read/write.
      // rst_n is not in drv_cb, so it is driven with the same 1 ns output skew.
      vif.rst_n          <= #1ns 1'b0;
      vif.drv_cb.wr_en   <= 1'b0;
      vif.drv_cb.rd_en   <= 1'b0;
      vif.drv_cb.data_in <= item.data_in;
    end else begin
      if (vif.rst_n !== 1'b1) vif.rst_n <= #1ns 1'b1;  // release after a reset item
      vif.drv_cb.wr_en   <= item.wr_en;
      vif.drv_cb.rd_en   <= item.rd_en;
      vif.drv_cb.data_in <= item.data_in;
    end

    // One item per clock; outputs are sampled at this edge
    @(vif.drv_cb);

    // Return the sampled outputs in the item
    item.data_out = vif.drv_cb.data_out;
    item.full     = vif.drv_cb.full;
    item.empty    = vif.drv_cb.empty;

    // Enables back to 0 between items
    vif.drv_cb.wr_en <= 1'b0;
    vif.drv_cb.rd_en <= 1'b0;

    `uvm_info(get_type_name(),
      $sformatf("Driven transaction completed: %s", item.convert2string()),
      UVM_HIGH)
  endtask : drive_item

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    `uvm_info(get_type_name(), "Starting driver run_phase...", UVM_MEDIUM)

    vif.drv_cb.wr_en   <= 1'b0;
    vif.drv_cb.rd_en   <= 1'b0;
    vif.drv_cb.data_in <= '0;

    // Wait for reset, or apply it if rst_n is not driven yet
    `uvm_info(get_type_name(), "Waiting for reset to complete (rst_n == 1)...", UVM_MEDIUM)

    if (vif.rst_n === 1'bx || vif.rst_n === 1'bz) begin
      `uvm_info(get_type_name(), "rst_n uninitialized. Driving initial reset via reset_dut()...", UVM_MEDIUM)
      reset_dut();
    end else begin

      wait(vif.rst_n === 1'b1);
      @(vif.drv_cb);
    end

    `uvm_info(get_type_name(), "Reset complete. Ready to receive and drive transactions.", UVM_MEDIUM)

    forever begin
      seq_item_port.get_next_item(req);

      drive_item(req);

      seq_item_port.item_done();
    end
  endtask : run_phase

endclass : fifo_driver
