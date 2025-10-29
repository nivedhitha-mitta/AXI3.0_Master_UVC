//-------------------------------------------------------------------------
//						axi_master_monitor 
//-------------------------------------------------------------------------

`define DRIV_IF vif
//Doesn't support same(write-write/read-read) pipeline transfers for same awid/arid
class axi_master_monitor#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_monitor;

  //---------------------------------------
  // Virtual Interface
  //---------------------------------------
  virtual axi_master_if#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) vif;
  
  //---------------------------------------
  // typedefs
  //---------------------------------------
  typedef axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)) axi_master_seq_item_t;
  
  //---------------------------------------
  // analysis port, to send the transaction to scoreboard
  //---------------------------------------
  uvm_analysis_port #(axi_master_seq_item_t) mon_item_collected_port;

  //---------------------------------------
  // To store transfers collected
  //---------------------------------------
  axi_master_seq_item_t trans_collected_rd_arr[*]; //associative array
  axi_master_seq_item_t trans_collected_wr_arr[*]; //associative array

  `uvm_component_utils(axi_master_monitor#(ADDR_WIDTH, DATA_WIDTH))

  //---------------------------------------
  // new - constructor
  //---------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_item_collected_port = new("mon_item_collected_port", this);
  endfunction : new

  //---------------------------------------
  // build_phase - getting the interface handle
  //---------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_master_if#(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction : build_phase

  //---------------------------------------
  // run_phase - convert the signal level activity to transaction level.
  // i.e, sample the values on interface signal and assign to transaction class fields
  //---------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin : run_phase_main
      fork //Collect pin level transfers (or) Exit if reset
        begin
          wait(vif.areset_n==1);
          @(posedge `DRIV_IF.aclk);
          if(`DRIV_IF.awvalid && `DRIV_IF.awready) begin : collect_aw
            collect_aw_ch;
            phase.raise_objection(this);
          end:collect_aw
          if(`DRIV_IF.wvalid && `DRIV_IF.wready) begin : collect_w
            collect_w_ch;
          end : collect_w
          if(`DRIV_IF.bvalid && `DRIV_IF.bready) begin : collect_b
            collect_b_ch;
            phase.drop_objection(this);
          end : collect_b
          if(`DRIV_IF.arvalid && `DRIV_IF.arready) begin : collect_ar
            collect_ar_ch;
            phase.raise_objection(this);
          end:collect_ar
          if(`DRIV_IF.rvalid && `DRIV_IF.rready) begin : collect_r
            collect_r_ch;
            if(`DRIV_IF.rlast) begin
              phase.drop_objection(this);
            end
          end : collect_r
        end
        @(negedge vif.areset_n);
      join_any
    end : run_phase_main
  endtask : run_phase
  //---------------------------------------
  // collect_aw_ch - collect aw channel signals to transaction_item
  //---------------------------------------
  virtual task collect_aw_ch;
    int wr_trnsfr_size;//beat_size*burst_length
      trans_collected_wr_arr[`DRIV_IF.awid] = new();
      trans_collected_wr_arr[`DRIV_IF.awid].awaddr = `DRIV_IF.awaddr;
      trans_collected_wr_arr[`DRIV_IF.awid].awlen = `DRIV_IF.awlen;
      trans_collected_wr_arr[`DRIV_IF.awid].awsize = `DRIV_IF.awsize;
      trans_collected_wr_arr[`DRIV_IF.awid].awburst = `DRIV_IF.awburst;
      trans_collected_wr_arr[`DRIV_IF.awid].awprot = `DRIV_IF.awprot;
      trans_collected_wr_arr[`DRIV_IF.awid].awlock = `DRIV_IF.awlock;
      trans_collected_wr_arr[`DRIV_IF.awid].awcache = `DRIV_IF.awcache;
      trans_collected_wr_arr[`DRIV_IF.awid].awid = `DRIV_IF.awid;
      wr_trnsfr_size = (2**trans_collected_wr_arr[`DRIV_IF.awid].awburst)*(trans_collected_wr_arr[`DRIV_IF.awid].awlen+1);
      trans_collected_wr_arr[`DRIV_IF.awid].wdata = new[/*trans_collected_wr_arr[`DRIV_IF.awid].awlen+*/1];
      trans_collected_wr_arr[`DRIV_IF.awid].wstrb = new[/*trans_collected_wr_arr[`DRIV_IF.awid].awlen+*/1];
//      trans_collected_wr_arr[`DRIV_IF.awid].data = new[wr_trnsfr_size];
      trans_collected_wr_arr[`DRIV_IF.awid].trnsfr_dir = AXI_WRITE;
      trans_collected_wr_arr[`DRIV_IF.awid].start_time = $realtime;//save start_time_stamp of transfer
  endtask:collect_aw_ch

  //---------------------------------------
  // collect_w_ch - collect w channel signals to transaction_item
  //---------------------------------------

  virtual task collect_w_ch;

//	array = new [array.size() + 1] (array);
//        trans_collected_wr_arr[`DRIV_IF.wid].wdata.push_back(`DRIV_IF.wdata);
    trans_collected_wr_arr[`DRIV_IF.wid].wid = `DRIV_IF.wid;
    trans_collected_wr_arr[`DRIV_IF.wid].wdata[(trans_collected_wr_arr[`DRIV_IF.wid].wdata.size()-1)] = `DRIV_IF.wdata; //store wdata value
    if(trans_collected_wr_arr[`DRIV_IF.wid].wdata.size < trans_collected_wr_arr[`DRIV_IF.wid].awlen + 1) //create 1 new entry in dyn_arr retaining it's contents till wdata size equals awlen + 1
    begin
      trans_collected_wr_arr[`DRIV_IF.wid].wdata = new[trans_collected_wr_arr[`DRIV_IF.wid].wdata.size()+1] (trans_collected_wr_arr[`DRIV_IF.wid].wdata); //create 1 new entry in dyn_arr retaining it's contents
    end
//        trans_collected_wr_arr[`DRIV_IF.wid].wstrb.push_back(`DRIV_IF.wstrb);
    trans_collected_wr_arr[`DRIV_IF.wid].wstrb[trans_collected_wr_arr[`DRIV_IF.wid].wstrb.size()-1] = `DRIV_IF.wstrb;
    if(trans_collected_wr_arr[`DRIV_IF.wid].wstrb.size < trans_collected_wr_arr[`DRIV_IF.wid].awlen + 1)
    begin
      trans_collected_wr_arr[`DRIV_IF.wid].wstrb = new[trans_collected_wr_arr[`DRIV_IF.wid].wstrb.size()+1] (trans_collected_wr_arr[`DRIV_IF.wid].wstrb); //push_back(`DRIV_IF.wstrb);
    end
        //end
   endtask : collect_w_ch

  //---------------------------------------
  // collect_b_ch - collect b channel signals to transaction_item
  //---------------------------------------

   virtual task collect_b_ch;
     trans_collected_wr_arr[`DRIV_IF.bid].bid = `DRIV_IF.bid;
     trans_collected_wr_arr[`DRIV_IF.bid].bresp = `DRIV_IF.bresp;
     trans_collected_wr_arr[`DRIV_IF.bid].end_time = $realtime;//save end_time_stamp of transfer
     mon_item_collected_port.write(trans_collected_wr_arr[`DRIV_IF.bid]);
   endtask : collect_b_ch

  //---------------------------------------
  // collect_ar_ch - collect ar channel signals to transaction_item
  //---------------------------------------

   virtual task collect_ar_ch;
     int rd_trnsfr_size;//beat_size*burst_length
     trans_collected_rd_arr[`DRIV_IF.arid] = new();
     trans_collected_rd_arr[`DRIV_IF.arid].araddr = `DRIV_IF.araddr;
     trans_collected_rd_arr[`DRIV_IF.arid].arlen = `DRIV_IF.arlen;
     trans_collected_rd_arr[`DRIV_IF.arid].arsize = `DRIV_IF.arsize;
     trans_collected_rd_arr[`DRIV_IF.arid].arburst = `DRIV_IF.arburst;
     trans_collected_rd_arr[`DRIV_IF.arid].arprot = `DRIV_IF.arprot;
     trans_collected_rd_arr[`DRIV_IF.arid].arlock = `DRIV_IF.arlock;
     trans_collected_rd_arr[`DRIV_IF.arid].arcache = `DRIV_IF.arcache;
     trans_collected_rd_arr[`DRIV_IF.arid].arid = `DRIV_IF.arid;
     rd_trnsfr_size = (2**trans_collected_rd_arr[`DRIV_IF.arid].arburst)*(trans_collected_rd_arr[`DRIV_IF.arid].arlen+1);
     trans_collected_rd_arr[`DRIV_IF.arid].rdata = new[/*trans_collected_rd_arr[`DRIV_IF.arid].awlen+1*/1];
     trans_collected_rd_arr[`DRIV_IF.arid].rresp = new[/*trans_collected_rd_arr[`DRIV_IF.arid].arlen+1*/1];
//     trans_collected_rd_arr[`DRIV_IF.arid].data = new[rd_trnsfr_size];
     trans_collected_rd_arr[`DRIV_IF.arid].trnsfr_dir = AXI_READ;
     trans_collected_rd_arr[`DRIV_IF.arid].start_time = $realtime;//save start_time_stamp of transfer
   endtask : collect_ar_ch


  //---------------------------------------
  // collect_r_ch - collect r channel signals to transaction_item
  //---------------------------------------

   virtual task collect_r_ch;
     if(`DRIV_IF.rvalid && `DRIV_IF.rready) begin
       trans_collected_rd_arr[`DRIV_IF.rid].rid = `DRIV_IF.rid;
       trans_collected_rd_arr[`DRIV_IF.rid].rdata[trans_collected_rd_arr[`DRIV_IF.rid].rdata.size()-1] = `DRIV_IF.rdata;
       if(trans_collected_rd_arr[`DRIV_IF.rid].rdata.size < trans_collected_rd_arr[`DRIV_IF.rid].arlen + 1)
       begin
         trans_collected_rd_arr[`DRIV_IF.rid].rdata = new[trans_collected_rd_arr[`DRIV_IF.rid].rdata.size()+1] (trans_collected_rd_arr[`DRIV_IF.rid].rdata); //push_back(`DRIV_IF.wdata);
       end

       trans_collected_rd_arr[`DRIV_IF.rid].rresp[trans_collected_rd_arr[`DRIV_IF.rid].rresp.size()-1] = `DRIV_IF.rresp;
       if(trans_collected_rd_arr[`DRIV_IF.rid].rresp.size < trans_collected_rd_arr[`DRIV_IF.rid].arlen + 1)
       begin
         trans_collected_rd_arr[`DRIV_IF.rid].rresp = new[trans_collected_rd_arr[`DRIV_IF.rid].rresp.size()+1] (trans_collected_rd_arr[`DRIV_IF.rid].rresp); //push_back(`DRIV_IF.wdata);
       end

       if(`DRIV_IF.rlast) begin
         trans_collected_rd_arr[`DRIV_IF.arid].end_time = $realtime;//save end_time_stamp of transfer
         mon_item_collected_port.write(trans_collected_rd_arr[`DRIV_IF.rid]);
       end
     end
   endtask : collect_r_ch

endclass : axi_master_monitor
