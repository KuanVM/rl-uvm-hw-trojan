// =============================================================================
// LỊCH SỬ THAY ĐỔI (mới nhất ở trên)
// 2026-10-13: Thêm fifo_idle_seq (N chu kỳ wr=rd=0) để kết thúc test sạch:
//             driver không giữ wr/rd của item cuối trong lúc chờ hạ objection.
// =============================================================================
class fifo_base_sequence extends uvm_sequence #(fifo_seq_item);
  // registration
  `uvm_object_utils(fifo_base_sequence)

  //param config
  int unsigned num_transaction = 100;

  // constructor
  function new(string name = "fifo_base_sequence");
    super.new(name);
  endfunction

  // body() - the generator's core engine
  virtual task body();
    // the item (packet)
    fifo_seq_item item;

    // auto create random packets
    repeat (num_transaction) begin
      item = fifo_seq_item::type_id::create("item");

      start_item(item); // request the sequencer for permission to start, won't exe if sequencer don't allow

      // To create non-similiar items, randomize btw start | finish
      // if before start_item(item), could lead to miss state-dependent constraints
      if(!item.randomize()) begin
        `uvm_fatal("RAND", "Randomization failed!"); 
      end else begin
        finish_item(item); // wrapped & send to driver, won't finish until driver calls item_done()
      end
    end
  endtask
endclass : fifo_base_sequence
  
//___________________________________Tests Chamber________________________________

// test 1: fill to full sequence
class fifo_seq_fill_2_full extends fifo_base_sequence;
    `uvm_object_utils(fifo_seq_fill_2_full)

  function new(string name = "fifo_seq_fill_2_full");
    super.new(name);
  endfunction

  task body();
    repeat (32) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
        if (!req.randomize() with { wr_en == 1; rd_en == 0; }) begin
          `uvm_fatal("RAND", "Randomization failed")
        end
      finish_item(req);
    end
  endtask
endclass : fifo_seq_fill_2_full



// test 2: drain till empty
class fifo_seq_drain_2_empty extends fifo_base_sequence;
    `uvm_object_utils(fifo_seq_drain_2_empty)

  function new(string name = "fifo_seq_drain_2_empty");
    super.new(name);
  endfunction

  task body();
    repeat (32) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
        if (!req.randomize() with { wr_en == 0; rd_en == 1; }) begin
          `uvm_fatal("RAND", "Randomization failed")
        end
      finish_item(req);
    end
  endtask
endclass : fifo_seq_drain_2_empty


// idle: N chu kỳ wr_en = rd_en = 0 (dùng ở cuối test trước khi hạ objection)
class fifo_idle_seq extends fifo_base_sequence;
  `uvm_object_utils(fifo_idle_seq)

  function new(string name = "fifo_idle_seq");
    super.new(name);
    num_transaction = 2;
  endfunction

  task body();
    repeat (num_transaction) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      req.wr_en   = 1'b0;
      req.rd_en   = 1'b0;
      req.data_in = 8'h00;
      req.rst_req = 1'b0;
      finish_item(req);
    end
  endtask
endclass : fifo_idle_seq
