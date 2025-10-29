class axi_config_class;
  bit axi_agent_type; // To configure VIP as active/passive
  bit enable_coverage; //To enable coverage
  bit pipelined_access_enable; //To enable pipelined access in driver
  int pipeline_trnsfrs_cnt; //To configure number of pipelined transfers
endclass:axi_config_class
