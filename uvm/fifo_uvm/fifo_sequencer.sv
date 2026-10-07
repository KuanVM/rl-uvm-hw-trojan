class fifo_sequencer extends uvm_sequencer #(fifo_seq_item);
  `uvm_component_utils(fifo_sequencer) // fifo_sequencer became a component_utils (lives in hierarchy)

  // constructor 
  function new(string name = "fifo_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass
