// fifo_coverage: functional coverage, sampled on every monitor item.

class fifo_coverage extends uvm_subscriber #(fifo_seq_item);

  `uvm_component_utils(fifo_coverage)

  // Number of sampled items

  int num_samples = 0;

  covergroup fifo_cg with function sample(fifo_seq_item item);
    option.per_instance = 1;
    option.name         = "fifo_cg";
    option.comment      = "Functional coverage metrics for Synchronous FIFO";

    cp_wr_en: coverpoint item.wr_en {
      bins wr_deasserted = {1'b0};
      bins wr_asserted   = {1'b1};
    }

    cp_rd_en: coverpoint item.rd_en {
      bins rd_deasserted = {1'b0};
      bins rd_asserted   = {1'b1};
    }

    cx_wr_rd: cross cp_wr_en, cp_rd_en;

    cp_full: coverpoint item.full {
      bins not_full = {1'b0};
      bins is_full  = {1'b1};
    }

    cp_empty: coverpoint item.empty {
      bins not_empty = {1'b0};
      bins is_empty  = {1'b1};
    }

    cx_wr_full: cross cp_wr_en, cp_full;

    cx_rd_empty: cross cp_rd_en, cp_empty;

    cp_data_in: coverpoint item.data_in {
      bins zero = {0};
      bins low  = {[1:127]};
      bins high = {[128:254]};
      bins max  = {255};
    }

  endgroup : fifo_cg

  function new(string name = "fifo_coverage", uvm_component parent = null);
    super.new(name, parent);
    fifo_cg = new();
  endfunction : new

  virtual function void write(fifo_seq_item t);
    if (t != null) begin
      fifo_cg.sample(t);
      num_samples++;
      `uvm_info(get_type_name(),
        $sformatf("Sampled item #%0d for coverage: %s", num_samples, t.convert2string()),
        UVM_DEBUG)
    end
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "              FIFO COVERAGE SUMMARY               ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Transactions Sampled : %0d", num_samples), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Overall Instance Coverage  : %0.2f%%", fifo_cg.get_inst_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
  endfunction : report_phase

endclass : fifo_coverage
