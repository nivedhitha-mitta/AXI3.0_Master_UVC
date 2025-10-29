//-------------------------------------------------------------------------
//						axi_master_pipelined_reads_test 
//-------------------------------------------------------------------------
class axi_master_pipelined_reads_test extends axi_master_base_test;

  `uvm_component_utils(axi_master_pipelined_reads_test)

  //---------------------------------------
  // sequence instance
  //---------------------------------------
  pipelined_rd_sequence seq;

  axi_config_class axi_cfg_class;
  //---------------------------------------
  // constructor
  //---------------------------------------
  function new(string name = "axi_master_pipelined_reads_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  //---------------------------------------
  // build_phase
  //---------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_cfg_class = new();
/*     if(!uvm_config_db#(axi_config_class)::get(this, "", "axi_cfg_class", axi_cfg_class))
     begin
       `uvm_fatal("NO_CFG","Unable to get axi_cfg_class in test")
     end
*/
    // Create the sequence
    seq = pipelined_rd_sequence::type_id::create("seq");
  endfunction : build_phase

  //---------------------------------------
  // run_phase - starting the test
  //---------------------------------------
  virtual function void end_of_elaboration_phase (uvm_phase phase);
//         uvm_top.print_topology ();
    if(!uvm_config_db#(axi_config_class)::get(this, "", "axi_cfg_class", axi_cfg_class))
    begin
      `uvm_fatal("NO_CFG","Unable to get axi_cfg_class in test")
    end
    print();
  endfunction

  //---------------------------------------
  // run_phase - starting the test
  //---------------------------------------
  task run_phase(uvm_phase phase);

    phase.raise_objection(this,"starting test");
//    axi_cfg_class.pipelined_access_enable = 1;
//    axi_cfg_class.pipeline_trnsfrs_cnt = 2;
    seq.start(env.axi_master_agnt.sequencer);
    #100;
    phase.drop_objection(this);

  endtask : run_phase
  
endclass : axi_master_pipelined_reads_test
