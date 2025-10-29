//-------------------------------------------------------------------------
//						axi_master_test
//-------------------------------------------------------------------------

`include "axi_master_env.sv"
class axi_master_base_test extends uvm_test;

  `uvm_component_utils(axi_master_base_test)
  typedef axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master_seq_item_t; 

  //---------------------------------------
  // env instance
  //---------------------------------------
  axi_master_env#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)) env;

  //---------------------------------------
  // constructor
  //---------------------------------------
  function new(string name = "axi_master_base_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  //---------------------------------------
  // build_phase
  //---------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Create the env
    env = axi_master_env#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))::type_id::create("env", this);
  endfunction : build_phase

  //---------------------------------------
  // end_of_elaboration phase
  //---------------------------------------
  virtual function void end_of_elaboration();
    //print's the topology
    print();
//    uvm_top.print_topology ();

  endfunction

  //---------------------------------------
  // report_phase
  //---------------------------------------
 function void report_phase(uvm_phase phase);
   uvm_report_server svr;
   super.report_phase(phase);

   svr = uvm_report_server::get_server();
   if(svr.get_severity_count(UVM_FATAL)+svr.get_severity_count(UVM_ERROR)>0) begin
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     `uvm_info(get_type_name(), "----            TEST FAIL          ----", UVM_NONE)
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    else begin
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
  endfunction

endclass : axi_master_base_test
