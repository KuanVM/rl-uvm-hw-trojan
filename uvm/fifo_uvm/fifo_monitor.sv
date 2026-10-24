// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Bỏ dòng @(posedge vif.clk) thừa trước khi đọc data_out (vấn đề 2):
//             mỗi mẫu giờ đúng 1 chu kỳ, data_out lấy cùng cạnh qua mon_cb;
//             scoreboard tự xử lý trễ 1 chu kỳ qua pending_read. rst_n lấy qua
//             mon_cb để cùng thời điểm lấy mẫu với các tín hiệu khác.
// =============================================================================
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
      `uvm_fatal("NO VIF", "Virtual interface not found")
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

    item.wr_en    = vif.mon_cb.wr_en;
    item.rst_n    = vif.mon_cb.rst_n;
    item.rd_en    = vif.mon_cb.rd_en;
    item.data_in  = vif.mon_cb.data_in;
    item.full     = vif.mon_cb.full;
    item.empty    = vif.mon_cb.empty;
    item.data_out = vif.mon_cb.data_out; // kết quả của lần đọc ở cạnh TRƯỚC
    
  endtask
endclass