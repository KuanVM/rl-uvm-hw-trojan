class fifo_seq_item extends uvm_sequence_item;


  // random stimulus fieldz
  rand bit wr_en;
  rand bit rd_en;
  rand bit [7:0] data_in;

  // observation fieldz
  bit [7:0] data_out;
  bit full;
  bit empty;

  // UVM: register with the original factory
  // case 1: Not manually write do_copy(), do_compare(), do_print()
  // not recommend bec sim's perf will largely be nerfed when scaled up
  /*
  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(wr_en,    UVM_ALL_ON)
    `uvm_field_int(rd_en,    UVM_ALL_ON)
    `uvm_field_int(data_in,  UVM_ALL_ON)
    `uvm_field_int(data_out, UVM_ALL_ON)
    `uvm_field_int(full,     UVM_ALL_ON)
    `uvm_field_int(empty,    UVM_ALL_ON)
  `uvm_object_utils_end // fifo_seq_item
  */

  
  // case 2: manually write do_copy(), do_compare(), do_print()
  `uvm_object_utils(fifo_seq_item)
  

  //default constraints
  constraint c_default_dist {
    wr_en dist {1 := 60, 0 := 40}; // write-biased for faster filling
    rd_en dist {1 := 40, 0 := 60};
  }

  constraint c_valid_data {
    //example: soft constraint, easily overriden, in case wanna try error injection in the future- ex: data_in == 300
    soft data_in inside {[0:255]};
  }

  //constructor 
  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction

  // convert_2_string() - for a more peaceful debug experience, evrythangs have been organized beautifully, for visuali
  virtual function string convert2string();
    return $sformatf("wr = %0b, rd = %0b, d_in = %0b, d_out = %0b, full = %0b, empty = %0b", wr_en, rd_en, data_in, data_out, full, empty);
  endfunction

  
  // case 2: manual do_copy(), do_compare(), do_print()

  // manual do_copy 
  // use do_copy (so that 2 uvc (mon & sco) can't affect each other's memory), 2 indepedent mem fields
    // required if pass items through analysis ports (monitors ---> scoreboard)
    // without do_copy, " aliased handles " - scoreboard sees stale data
  virtual function void do_copy(uvm_object rhs);
    fifo_seq_item rhs_;
    // if cast failed,...
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("CAST", "do_copy cast failed")
    end

    super.do_copy(rhs);
    
    //manually copying from source (rhs_) to destination (this)
    this.wr_en    = rhs_.wr_en;
    this.rd_en    = rhs_.rd_en;
    this.data_in  = rhs_.data_in;
    this.data_out = rhs_.data_out;
    this.full     = rhs_.full;
    this.empty    = rhs_.empty;
  endfunction  

  // manual do_compare
  // field by field comparison (rhs >< uvm_comparer) 
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    fifo_seq_item rhs_;
    if (!$cast(rhs_, rhs)) begin
      return 0;
    end 
    else
    return ( // this: actual signal from DUT (-> "actual_item".compare trong scoreboard), rhs: from the golden model
      super.do_compare(rhs, comparer) &&
      this.data_out == rhs_.data_out && 
      this.full     == rhs_.full &&
      this.empty    == rhs_.empty 
    ); // if all theses're similiar then return 1
  endfunction

  // manual do_print
  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("wr_en",   wr_en,   1, UVM_BIN);
    printer.print_field_int("rd_en",   rd_en,   1, UVM_BIN);
    printer.print_field_int("data_in", data_in, 8, UVM_HEX);
    printer.print_field_int("data_out",data_out, 8, UVM_HEX);
    printer.print_field_int("full",    full,    1, UVM_BIN);
    printer.print_field_int("empty",   empty,   1, UVM_BIN);
  endfunction
  
endclass