//-------------------------------------------------------------------------
//						axi_master_env
//-------------------------------------------------------------------------

`include "axi_master_agent.sv"
`include "axi_master_scoreboard.sv"

class axi_master_env#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_env;

  //---------------------------------------
  // typedefs
  //---------------------------------------
  typedef axi_master_agent#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master_agent_t;
  typedef axi_master_scoreboard#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master_scoreboard_t;

  //---------------------------------------
  // agent and scoreboard instance
  //---------------------------------------
  axi_master_agent#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master_agnt;
  axi_master_scoreboard#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master_scb;

  //---------------------------------------
  //axi_config_class instance
  //---------------------------------------
  axi_config_class axi_cfg_class;
  
  `uvm_component_param_utils(axi_master_env#(ADDR_WIDTH, DATA_WIDTH))

  //---------------------------------------
  // constructor
  //---------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  //---------------------------------------
  // build_phase - crate the components
  //---------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //set axi_config_class in uvm_config_db
    axi_cfg_class = new();
    axi_cfg_class.axi_agent_type = UVM_ACTIVE;
    uvm_config_db#(axi_config_class)::set(uvm_root::get(),"*","axi_cfg_class",axi_cfg_class);
    axi_cfg_class.axi_agent_type = UVM_ACTIVE;

    axi_master_agnt = axi_master_agent_t::type_id::create("axi_master_agnt", this);
    axi_master_scb  = axi_master_scoreboard_t::type_id::create("axi_master_scb", this);
  endfunction : build_phase
  
  //---------------------------------------
  // connect_phase - connecting monitor and scoreboard port
  //---------------------------------------
  function void connect_phase(uvm_phase phase);
    axi_master_agnt.monitor.mon_item_collected_port.connect(axi_master_scb.mon_item_collected_export);    
    axi_master_agnt.driver.drv_item_collected_port.connect(axi_master_scb.drv_item_collected_export);    

  endfunction : connect_phase

endclass : axi_master_env