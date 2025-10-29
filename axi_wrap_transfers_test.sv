//-------------------------------------------------------------------------
//						axi_wrap_transfers_test 
//-------------------------------------------------------------------------
class axi_wrap_transfers_test extends axi_master_base_test;

  `uvm_component_utils(axi_wrap_transfers_test)

  //---------------------------------------
  // sequence instance
  //---------------------------------------
  wrap_transfer_seq seq;

  //---------------------------------------
  // constructor
  //---------------------------------------
  function new(string name = "axi_wrap_transfers_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  //---------------------------------------
  // build_phase
  //---------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the sequence
    seq = wrap_transfer_seq::type_id::create("seq");

  endfunction : build_phase

  //---------------------------------------
  // run_phase - starting the test
  //---------------------------------------
  virtual function void end_of_elaboration_phase (uvm_phase phase);
//         uvm_top.print_topology ();
    print();
  endfunction

  //---------------------------------------
  // run_phase - starting the test
  //---------------------------------------
  task run_phase(uvm_phase phase);

    phase.raise_objection(this,"starting test");

    seq.start(env.axi_master_agnt.sequencer);
    #100;
    phase.drop_objection(this);

  endtask : run_phase

endclass : axi_wrap_transfers_test