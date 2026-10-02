class fifo_coverage extends uvm_subscriber #(fifo_seq_item);
  `uvm_component_utils(fifo_coverage)
  // transaction handle for covergroup sampling
  fifo_seq_item item;

  // covergroup definition
  covergroup fifo_cg;
    // Individual coverpoints
    cp_wr_en: coverpoint item.wr_en {
      bins active   = {1};
      bins inactive = {0};
    }

    cp_rd_en: coverpoint item.rd_en {
      bins active   = {1};
      bins inactive = {0};
    }

    // transition coverage
    cp_full_trans: coverpoint item.full {
      bins rise = (0 => 1);
      bins fall = (1 => 0);
    }

    cp_empty_trans: coverpoint item.empty  {
      bins rise = (0 => 1);
      bins fall = (1 => 0);
    }

    // Invalid bins
    cp_full_empty: coverpoint {item.full, item.empty} {
      invalid_bins both_high  = {2'b11}; // full && empty simultaneously
    }
  endgroup

  // constructor, instantiate covergroup
  function new(string name = "fifo_coverage", uvm_component parent = null);
    super.new(name, parent);
    fifo_cg = new();
  endfunction

  // write()
  virtual function void write(fifo_seq_item t);
    item = t;         // store handle for covergroup sampling
    fifo_cg.sample(); // sample all coverpoints
  endfunction

  // report phase - coverage summary
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Coverage: %.1f%%", fifo_cg.get_coverage()), UVM_LOW)
  endfunction
endclass