//-------------------------------------------------------------------------
//						axi_master_agent 
//-------------------------------------------------------------------------

`include "axi_master_seq_item.sv"
`include "axi_master_sequencer.sv"
`include "axi_master_sequence.sv"
`include "axi_master_driver.sv"
`include "axi_master_monitor.sv"

class axi_master_agent#(parameter ADDR_WIDTH=16, DATA_WIDTH=128) extends uvm_agent;

  //---------------------------------------
  // component instances
  //---------------------------------------
  axi_master_driver#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))    driver;
  axi_master_sequencer#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) sequencer;
  axi_master_monitor#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))   monitor;
  axi_config_class     axi_cfg_class;
//  axi_master_coverage  axi_cov;
  
  `uvm_component_param_utils(axi_master_agent#(ADDR_WIDTH, DATA_WIDTH))

  //---------------------------------------
  // constructor
  //---------------------------------------
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  //---------------------------------------
  // build_phase
  //---------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_cfg_class = new();
    monitor = axi_master_monitor#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))::type_id::create("monitor", this);

    if(!uvm_config_db#(axi_config_class)::get(this, "", "axi_cfg_class", axi_cfg_class)) begin
      `uvm_fatal("NO_CFG","Unable to get axi_cfg_class")
    end

    //creating driver and sequencer only for ACTIVE agent
    if(axi_cfg_class.axi_agent_type == UVM_ACTIVE) begin
      driver    = axi_master_driver#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))::type_id::create("driver", this);
      sequencer = axi_master_sequencer#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))::type_id::create("sequencer", this);
    end
    /*
    //creating coverage class instance only if coverage_enable is equal to 1
    if(axi_cfg_class.coverage_enable == 1) begin
      driver    = axi_master_driver::type_id::create("driver", this);
      sequencer = axi_master_sequencer::type_id::create("sequencer", this);
    end
    */
  endfunction : build_phase

  //---------------------------------------
  // connect_phase - connecting the driver and sequencer port
  //---------------------------------------
  function void connect_phase(uvm_phase phase);
    if(axi_cfg_class.axi_agent_type == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : axi_master_agent