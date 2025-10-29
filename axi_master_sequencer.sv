//-------------------------------------------------------------------------
//						axi_master_sequencer 
//-------------------------------------------------------------------------

`ifdef VERILATOR
class axi_master_sequencer#parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_sequencer#(axi_master_seq_item#(ADDR_WIDTH, DATA_WIDTH),axi_master_seq_item#(ADDR_WIDTH, DATA_WIDTH));
`else
class axi_master_sequencer#(parameter ADDR_WIDTH=16, DATA_WIDTH=128) extends uvm_sequencer#(axi_master_seq_item#(ADDR_WIDTH, DATA_WIDTH));
`endif

    `uvm_component_utils(axi_master_sequencer#(ADDR_WIDTH, DATA_WIDTH))

  //---------------------------------------
  //constructor
  //---------------------------------------
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

endclass : axi_master_sequencer