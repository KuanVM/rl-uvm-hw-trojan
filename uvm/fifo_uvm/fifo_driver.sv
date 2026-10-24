// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: drive_item xử lý item.rst_req (kéo rst_n=0 một chu kỳ, ép
//             wr/rd=0) để sequence chèn reset giữa mô phỏng; mọi chu kỳ khác
//             lái rst_n=1. reset_dut lái qua drv_cb (cùng skew), vẫn giữ 5 chu kỳ.
// =============================================================================
class fifo_driver extends uvm_driver #(fifo_seq_item);

  `uvm_component_utils(fifo_driver)

  // handle to the inter face fifo_if
  virtual fifo_if vif; 

  // constructor
  function new(string name = "fifo_driver", uvm_component parent = null);
    super.new(name, parent); 
  endfunction

  // __________________________________________________________
  // build phase - get virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found in config_db")
    end
  endfunction


  // run phase
  virtual task run_phase(uvm_phase phase);
    fifo_seq_item item;

    // initial reset
    reset_dut();

    forever begin
      // St1: Get item from sequencer
      seq_item_port.get_next_item(item);

      // St2: Drive signals onto DUT
      drive_item(item);

      // St3: Tell sequencer we're done
      seq_item_port.item_done();
    end
  endtask

  // reset_dut()
  virtual task reset_dut();
    `uvm_info(get_type_name(), "Driving reset...", UVM_MEDIUM)
    vif.rst_n           = 1'b0;      // assert ngay tại t=0 (trước cạnh clock đầu tiên)
    vif.drv_cb.rst_n   <= 1'b0;
    vif.drv_cb.wr_en   <= 0;
    vif.drv_cb.rd_en   <= 0;
    vif.drv_cb.data_in <= 0;

    repeat (5) @(vif.drv_cb);       // hold reset for 5 cycles
    vif.drv_cb.rst_n   <= 1'b1;
    @(vif.drv_cb);                  // wait 1 cycle after release

    `uvm_info(get_type_name(), "Reset released.", UVM_MEDIUM)

  endtask

   // drive_item(item)
  virtual task drive_item(fifo_seq_item item);
    @(vif.drv_cb);                                 // sync to clock edge
    if (item.rst_req) begin                        // reset đồng bộ 1 chu kỳ
      vif.drv_cb.rst_n   <= 1'b0;
      vif.drv_cb.wr_en   <= 1'b0;
      vif.drv_cb.rd_en   <= 1'b0;
      vif.drv_cb.data_in <= item.data_in;
    end else begin
      vif.drv_cb.rst_n   <= 1'b1;
      vif.drv_cb.wr_en   <= item.wr_en;
      vif.drv_cb.rd_en   <= item.rd_en;
      vif.drv_cb.data_in <= item.data_in;
    end
  endtask
endclass