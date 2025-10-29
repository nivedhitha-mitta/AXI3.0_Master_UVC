//-------------------------------------------------------------------------
//						axi_master_driver 
//-------------------------------------------------------------------------

`define DRIV_IF vif

class axi_master_driver#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_driver #(axi_master_seq_item#(ADDR_WIDTH, DATA_WIDTH));

  //---------------------------------------
  // Virtual Interface
  //---------------------------------------
  virtual axi_master_if#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) vif;
  
  //---------------------------------------
  // typedefs
  //---------------------------------------
  typedef axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)) axi_master_seq_item_t;
  
  //---------------------------------------
  // Config class
  //---------------------------------------
  axi_config_class axi_cfg_class;
  
  //---------------------------------------
  // queues for pipelined access
  //---------------------------------------
  axi_master_seq_item_t pipelined_addr_writes_asc_arr[bit[3:0]];
  axi_master_seq_item_t pipelined_data_writes_asc_arr[bit[3:0]];
  axi_master_seq_item_t pipelined_rsp_writes_asc_arr[bit[3:0]];
  axi_master_seq_item_t pipelined_addr_reads_asc_arr[bit[3:0]];
  axi_master_seq_item_t pipelined_data_reads_asc_arr[bit[3:0]];
  int wr_addr_ch_index_q[$]; //used for pipelined transfers
  int wr_data_ch_index_q[$];
  int wr_rsp_ch_index_q[$];
  int rd_addr_ch_index_q[$]; //used for pipelined transfers
  int rd_data_ch_index_q[$];

  
  //---------------------------------------
  // analysis port, to send the transaction to scoreboard
  //---------------------------------------
  uvm_analysis_port #(axi_master_seq_item_t) drv_item_collected_port;
  
  `uvm_component_param_utils(axi_master_driver#(ADDR_WIDTH, DATA_WIDTH))

  //---------------------------------------
  // Constructor
  //---------------------------------------
  function new (string name, uvm_component parent);
    super.new(name, parent);
    drv_item_collected_port = new("drv_item_collected_port", this);
    axi_cfg_class = new();
  endfunction : new

  //---------------------------------------
  // build phase
  //---------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_master_if#(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
       `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
     if(!uvm_config_db#(axi_config_class)::get(this, "", "axi_cfg_class", axi_cfg_class))
     begin
       `uvm_fatal("NO_CFG","Unable to get axi_cfg_class in driver")
     end
  endfunction: build_phase

  //---------------------------------------
  // run phase
  //---------------------------------------
  virtual task run_phase(uvm_phase phase);

    forever begin : run_phase_main
      perform_reset(); //Perform reset
        fork //Perform drive operation (or) Exit if reset
          begin
            wait(vif.areset_n==1);
            drive();
          end
          @(negedge vif.areset_n);
        join_any
    end : run_phase_main
  endtask : run_phase

  //---------------------------------------
  // perform_reset - drives all the output signals 
  // of axi_master interface to 0's
  //---------------------------------------

  virtual task perform_reset;
    if(`DRIV_IF.areset_n==0) begin
      {vif.awaddr, vif.awid, vif.awlen, vif.awsize, vif.awburst, vif.awlock, vif.awcache, vif.awprot, vif.awvalid, vif.wid, vif.wdata, vif.wstrb, vif.wlast, vif.wvalid, vif.bready, vif.arid, vif.araddr, vif.arlen, vif.arsize, vif.arburst, vif.arlock, vif.arcache, vif.arprot, vif.arvalid, vif.rid, vif.rready} <= 'h0;
    end
  endtask: perform_reset

  //---------------------------------------
  // drive_address_read_ch - drives
  // read address channel of axi_master interface
  //---------------------------------------
  virtual task automatic drive_address_read_ch ( ref axi_master_seq_item_t axi_item_ar );
//    phase.raise_objection(this);
    @(posedge `DRIV_IF.aclk);
    `DRIV_IF.araddr	<= axi_item_ar.araddr;
    `DRIV_IF.arid	<= axi_item_ar.arid;
    `DRIV_IF.arsize 	<= axi_item_ar.arsize;
    `DRIV_IF.arlen 	<= axi_item_ar.arlen;
    `DRIV_IF.arburst	<= axi_item_ar.arburst;
    `DRIV_IF.arcache	<= axi_item_ar.arcache;
    `DRIV_IF.arprot 	<= axi_item_ar.arprot;
    `DRIV_IF.arlock 	<= axi_item_ar.arlock;
    `DRIV_IF.arvalid	<= 'h1;
     wait(`DRIV_IF.arready==1);//Make arvalid low when arready==1 is observed
     @(posedge `DRIV_IF.aclk);
     `DRIV_IF.arvalid 	<=  'h0;
     `DRIV_IF.araddr 	<=  'h0;
     `DRIV_IF.arlen 	<=  'h0;
     `DRIV_IF.arburst	<=  'h0;
     `DRIV_IF.arcache 	<=  'h0;
     `DRIV_IF.arprot 	<=  'h0;
  endtask:drive_address_read_ch
  
  //---------------------------------------
  // drive_read_ch - drives & collects
  // read data channel of axi_master interface
  //---------------------------------------
  
  virtual task automatic drive_read_ch ( ref axi_master_seq_item_t axi_item_r );
    axi_item_r.rdata = new[axi_item_r.arlen+1];
    axi_item_r.rresp = new[axi_item_r.arlen+1];
    axi_item_r.rid   = `DRIV_IF.rid;
    for(int i=0; i<axi_item_r.rready_delay_cycles;i++) begin
      @(posedge `DRIV_IF.aclk);
    end
    `DRIV_IF.rready <= 1;
    for(int i=0;i<axi_item_r.arlen+1;i++)
    begin
      wait(`DRIV_IF.rvalid&&`DRIV_IF.rready);
      @(posedge `DRIV_IF.aclk);
      axi_item_r.rdata[i] = `DRIV_IF.rdata;
      axi_item_r.rresp[i] = `DRIV_IF.rresp;
    end
//    phase.drop_objection(this);
  endtask:drive_read_ch
  
  //---------------------------------------
  // drive_address_write_ch - drives
  // write address channel of axi_master interface
  //---------------------------------------
  
  virtual task automatic drive_address_write_ch ( ref axi_master_seq_item_t axi_item_aw );
//    axi_item_aw.print();
//    phase.raise_objection(this);
    @(posedge `DRIV_IF.aclk);
    `DRIV_IF.awaddr  <= axi_item_aw.awaddr;
    `DRIV_IF.awsize  <= axi_item_aw.awsize;
    `DRIV_IF.awlen   <= axi_item_aw.awlen;
    `DRIV_IF.awburst <= axi_item_aw.awburst;
    `DRIV_IF.awcache <= axi_item_aw.awcache;
    `DRIV_IF.awprot  <= axi_item_aw.awprot;
    `DRIV_IF.awlock  <= axi_item_aw.awlock;
    `DRIV_IF.awvalid <= 1'h1;
    `DRIV_IF.awid    <= axi_item_aw.awid;
    //@(posedge `DRIV_IF.aclk)
    wait(`DRIV_IF.awready==1);//Make awvalid low when awready==1 is observed
    @(posedge `DRIV_IF.aclk);
    `DRIV_IF.awvalid <= 1'h0;
    `DRIV_IF.awaddr  <= 'h0;
  endtask:drive_address_write_ch
  
  //---------------------------------------
  // drive_write_ch - drives
  // write data channel of axi_master interface
  //---------------------------------------
  
  virtual task automatic drive_write_ch ( ref axi_master_seq_item_t axi_item_w );
    for(int i=0;i<axi_item_w.awlen+1;i++)
    begin
      if(i!=0) begin
        @(posedge `DRIV_IF.aclk);
      end
      `DRIV_IF.wid    <= axi_item_w.wid;
      `DRIV_IF.wdata  <= axi_item_w.wdata[i];
      `DRIV_IF.wstrb  <= axi_item_w.wstrb[i];
      `DRIV_IF.wvalid <= 1'b1;
      if(i==axi_item_w.awlen) begin
        `DRIV_IF.wlast <= 1'b1;
      end
    end
    @(posedge `DRIV_IF.aclk);
    `DRIV_IF.wlast  <= 1'h0;
    `DRIV_IF.wvalid <= 1'h0;
    `DRIV_IF.wdata  <= 'h0;
    `DRIV_IF.wstrb  <= 'h0;
  endtask:drive_write_ch
  
  //---------------------------------------
  // drive_write_resp_ch - drives & collects
  // write resp channel of axi_master interface
  //---------------------------------------
  
  virtual task automatic drive_write_resp_ch ( ref axi_master_seq_item_t axi_item_b );
    for(int i=0; i<axi_item_b.bready_delay_cycles;i++) begin
      @(posedge `DRIV_IF.aclk);
    end
    `DRIV_IF.bready <= 1'h1;
    wait(`DRIV_IF.bvalid&&`DRIV_IF.bready);
    @(posedge `DRIV_IF.aclk);
    axi_item_b.bid    = `DRIV_IF.bid;
    axi_item_b.bresp  = `DRIV_IF.bresp;
//    phase.drop_objection(this);
  endtask:drive_write_resp_ch

  //---------------------------------------
  // drive - drives write & read channels
  //---------------------------------------

  virtual task automatic drive();

    fork
      forever
      begin : store_tx_items
        seq_item_port.get(req);
//        req.print();
        if(req.trnsfr_dir==1) begin          
          pipelined_addr_writes_asc_arr[req.awid] = req;
          wr_addr_ch_index_q.push_back(req.awid);
 //         req.print();
        end else if(req.trnsfr_dir==0) begin  //TODO -- Implement similar things for read
          pipelined_addr_reads_asc_arr[req.arid] = req;
          rd_addr_ch_index_q.push_back(req.arid);
        end
      end : store_tx_items

      forever begin : drive_aw_ch
        drive_pipelined_addr_wr_ch();
//      `uvm_info("DEBUG_DRIVER",$sformatf("write_address_channel driven"), UVM_LOW)
      end : drive_aw_ch
      
      forever begin : drive_w_ch
        drive_pipelined_data_wr_ch();
//      `uvm_info("DEBUG_DRIVER",$sformatf("write_data_channel driven"), UVM_LOW)
      end : drive_w_ch
      
      forever begin : drive_b_ch
        drive_pipelined_resp_wr_ch(); 
//        `uvm_info("DEBUG_DRIVER",$sformatf("write_rsp_channel driven"), UVM_LOW)
      end      
      
      forever begin : drive_ar_ch
        drive_pipelined_addr_rd_ch();
//              `uvm_info("DEBUG_DRIVER",$sformatf("read_address_channel driven"), UVM_LOW)
      end : drive_ar_ch
      
      forever begin : drive_r_ch
        drive_pipelined_data_rd_ch();
//        `uvm_info("DEBUG_DRIVER",$sformatf("read_data_channel driven"), UVM_LOW)
      end : drive_r_ch
      
    join
  endtask : drive
  
  //---------------------------------------
  // drive_pipelined_addr_wr_ch
  //---------------------------------------
  virtual task automatic drive_pipelined_addr_wr_ch;
    int awid;
//    `uvm_info("DEBUG_DRIVER",$sformatf("Inside drive_pipelined_addr_wr_ch"),UVM_LOW)
    wait(wr_addr_ch_index_q.size() > 0) //begin : drv_pipelined_aw_ch
    awid = wr_addr_ch_index_q.pop_front();
//    `uvm_info("DEBUG_DRIVER",$sformatf("awid=%0d",awid),UVM_LOW)
//    pipelined_addr_writes_asc_arr[awid].print(); //DEBUG temp
    drive_address_write_ch(pipelined_addr_writes_asc_arr[awid]);
    wr_data_ch_index_q.push_back(awid);
    pipelined_data_writes_asc_arr[awid] = pipelined_addr_writes_asc_arr[awid];
    pipelined_addr_writes_asc_arr.delete(awid);

  endtask : drive_pipelined_addr_wr_ch
  
  //---------------------------------------
  // drive_pipelined_data_wr_ch
  //---------------------------------------
  virtual task automatic drive_pipelined_data_wr_ch;
    int wid;
    wait(wr_data_ch_index_q.size() > 0);
    wid = wr_data_ch_index_q.pop_front();
    drive_write_ch(pipelined_data_writes_asc_arr[wid]);
    wr_rsp_ch_index_q.push_back(wid);
    pipelined_rsp_writes_asc_arr[wid] = pipelined_data_writes_asc_arr[wid];

  endtask : drive_pipelined_data_wr_ch
    
  //---------------------------------------
  // drive_pipelined_resp_wr_ch
  //---------------------------------------
  virtual task automatic drive_pipelined_resp_wr_ch;
    int bid;
    wait(wr_rsp_ch_index_q.size() > 0);
    bid = wr_rsp_ch_index_q.pop_front();
    drive_write_resp_ch(pipelined_rsp_writes_asc_arr[bid]);
    #1;
    seq_item_port.put(pipelined_rsp_writes_asc_arr[bid]);
//    #1;
    drv_item_collected_port.write(pipelined_rsp_writes_asc_arr[bid]);
  endtask : drive_pipelined_resp_wr_ch

  //---------------------------------------
  // drive_pipelined_addr_rd_ch
  //---------------------------------------
  virtual task automatic drive_pipelined_addr_rd_ch;
    int arid;
//    `uvm_info("DEBUG_DRIVER",$sformatf("Inside drive_pipelined_addr_rd_ch"),UVM_LOW)
    wait(rd_addr_ch_index_q.size() > 0) //begin : drv_pipelined_aw_ch
    arid = rd_addr_ch_index_q.pop_front();
//    `uvm_info("DEBUG_DRIVER",$sformatf("arid=%0d",arid),UVM_LOW)
    drive_address_read_ch(pipelined_addr_reads_asc_arr[arid]);
    rd_data_ch_index_q.push_back(arid);
    pipelined_data_reads_asc_arr[arid] = pipelined_addr_reads_asc_arr[arid];
    pipelined_addr_reads_asc_arr.delete(arid);

  endtask : drive_pipelined_addr_rd_ch

  //---------------------------------------
  // drive_pipelined_data_rd_ch
  //---------------------------------------
   virtual task automatic drive_pipelined_data_rd_ch;
     int rid;
     wait(rd_data_ch_index_q.size() > 0);
     rid = rd_data_ch_index_q.pop_front();
     drive_read_ch(pipelined_data_reads_asc_arr[rid]);
     #1;
     seq_item_port.put(pipelined_data_reads_asc_arr[rid]);

//    #1;
     drv_item_collected_port.write(pipelined_data_reads_asc_arr[rid]);
//      end : drv_pipelined_b_ch
  endtask : drive_pipelined_data_rd_ch
  
  //---------------------------------------
  // drive_write - drives write channels
  //---------------------------------------

  task automatic drive_write (axi_master_seq_item_t axi_item);
    begin
      drive_address_write_ch(axi_item);
      drive_write_ch(axi_item);
      drive_write_resp_ch(axi_item);    
    end
  endtask: drive_write

  //---------------------------------------
  // drive_read - drives read channels
  //---------------------------------------
  
  task automatic drive_read (axi_master_seq_item_t axi_item);
    begin
      drive_address_read_ch(axi_item);
      drive_read_ch(axi_item);
    end
  endtask: drive_read

endclass : axi_master_driver
