//-------------------------------------------------------------------------
//						axi_master_seq_item 
//-------------------------------------------------------------------------

class axi_master_seq_item#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_sequence_item;
  //---------------------------------------
  //data and control fields
  //---------------------------------------
  //Write Address channel
  rand bit[3:0] awid;
  rand bit[ADDR_WIDTH-1:0] awaddr;
  rand bit[3:0] awlen;
  rand bit[2:0] awsize;
  rand bit[1:0] awburst; 
  rand bit[1:0] awlock;
  rand bit[3:0] awcache; 
  rand bit[2:0] awprot; 
//  bit awvalid;
//  logic awready;

  //Write data channel
  rand bit[3:0] wid;
  rand bit[DATA_WIDTH-1:0] wdata[];
//  rand bit[7:0] data[];//holds wdata for write & rdata during read
  rand bit[DATA_WIDTH/8 - 1:0] wstrb[];
//  logic wlast;
//  logic wvalid;
//  logic wready;

  //Write response channel
  bit[3:0] bid;
  bit[1:0] bresp;
//  logic bvalid;
//  logic bready;

  //Read address channel
  rand bit[3:0] arid;
  rand bit[ADDR_WIDTH-1:0] araddr;
  rand bit[3:0] arlen;
  rand bit[2:0] arsize;
  rand bit[1:0] arburst; 
  rand bit[1:0] arlock; 
  rand bit[3:0] arcache;
  rand bit[2:0] arprot; 
  bit arvalid;
//  logic arready;

  //Read data channel
  bit[3:0] rid;
  bit[DATA_WIDTH-1:0] rdata[];
  bit[1:0] rresp[];
  bit rlast;
  bit rvalid;
  bit rready;

  rand bit trnsfr_dir;//0--read trnsfr; 1-- write trnsfr
  rand int bready_delay_cycles;
  rand int rready_delay_cycles;
  rand bit wstrb_override;
//Intermediate variables
  rand int total_strb_count_ones; //virtual field

  realtime start_time;//to store start time of transfer
  realtime end_time;//to store end time of transfer
  //---------------------------------------
  //Utility and Field macros
  //---------------------------------------
  `uvm_object_param_utils(axi_master_seq_item#(ADDR_WIDTH, DATA_WIDTH))
  constraint ar_signals {soft arlock == 1'h0; soft arcache == 4'h0; soft arprot == 3'h0; soft arburst == INCR; }
  constraint aw_signals {soft awlock == 1'h0; soft awcache == 4'h0; soft awprot == 3'h0; soft awburst == INCR; }

  constraint burst_vaild_types { awburst != BURST_RSVD; arburst != BURST_RSVD; }
  
  constraint write_id { wid == awid;}

  constraint axsize_valid {
    (1<<awsize)<= DATA_WIDTH/8;
    (1<<arsize)<= DATA_WIDTH/8;
                          }
  
  constraint wrap_transfer_constraints {
//    solve awsize before awaddr;
//    solve awburst before awaddr;
//    solve awburst before awlen;
    (awburst == WRAP) -> (awaddr % (1 << awsize) == 0);
    (awburst == WRAP) -> (awlen+1 inside {2, 4, 8, 16});
    (arburst == WRAP) -> (araddr % (1 << arsize) == 0);
    (arburst == WRAP) -> (arlen+1 inside {2, 4, 8, 16});
  }
  constraint wdata_con {
//    solve awlen before data;
//    solve awsize before data;
    solve awlen before wdata;
    if((trnsfr_dir==1)||(trnsfr_dir==2)) 
      wdata.size() == (awlen+1);
      /*
      if((2**awsize)*(awlen+1)<DATA_WIDTH/8) 
        data.size() == DATA_WIDTH/8;
      else
        data.size() == (2**awsize)*(awlen+1) ;
        */
    else
//      data.size() == 0;
      wdata.size() == 0;
  }
  
  constraint ready_delay_cycles {
    soft bready_delay_cycles == 0; soft rready_delay_cycles == 0;
  }
  
  constraint wstrb_override_con {
    soft wstrb_override == 0;
//    solve awlen before wstrb;
    wstrb.size() == wdata.size(); //for read transfer
/*    if(wstrb_override==1)
      wstrb.size() == awlen;    
  */                          }
  
  

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_master_seq_item");
    super.new(name);
  endfunction

  //---------------------------------------
  //post_randomize
  //---------------------------------------  
  function void post_randomize();
    int data_index=0; // used for data[] to wdata[] conversion
    bit[DATA_WIDTH-1:0] wdata_temp[];//Intermediate variable to calculate wdata from data
    int wdata_tmp_idx = 0;
    bit[DATA_WIDTH/8-1:0] wstrb_unaligned;
    //****wstrb calculation****
    if (wstrb_override == 0) begin : default_wstrb_gen
    wstrb = new[awlen+1];
    if(awburst==INCR || awburst == FIXED || awburst == WRAP) //wstrb calculation same for INCR aligned & WRAP aligned
      begin
	//Aligned address
        //wstrb calculation for beat0
        
          foreach(wstrb[0][i])
          begin
            if(i<2**awsize)
              wstrb[0][i] = 1'h1;
            else
              wstrb[0][i] = 1'h0;
          end
        //nmitta added begin
        if(awaddr%(2**awsize)==0) begin //if aligned address 
          wstrb[0] = wstrb[0] << (awaddr%(DATA_WIDTH/8));
//          `uvm_info("SEQ_ITEM_DEBUG",$sformatf("wstrb[0]=%0x",wstrb[0]),UVM_LOW)
        end
        //nmitta added end
          /*
        for(int i=0;i<DATA_WIDTH/8; i++) begin
          if((i>=(awaddr%(DATA_WIDTH/8)))&&(i<((awaddr%(DATA_WIDTH/8))+(2**awsize)))) begin
            wstrb[0][i] = 1'h1;
          end else begin
            wstrb[0][i] = 1'h0;
          end
        end
        for(int i=0; i<awlen;i++) begin
          wstrb[i+1] = (wstrb[i]<<(2**awsize))+(wstrb[i]>>((DATA_WIDTH/8)-(2**awsize)));
          `uvm_info("SEQ_ITEM_DEBUG",$sformatf("awaddr=%0x; awlen=%0x; awsize=%0d; wstrb[%0d+1]=%0x; wstrb[%0d]=%0x; (wstrb[i]<<(2**awsize)),(wstrb[i]>>((DATA_WIDTH/8)-(2**awsize))) = %0x",awaddr, awlen, awsize, i+1,wstrb[(i+1)],i,wstrb[i],((wstrb[i]<<(2**awsize))+(wstrb[i]>>((DATA_WIDTH/8)-(2**awsize))))),UVM_LOW)
          //rstrb[i+1] = {rstrb[i][((DATA_WIDTH/8)-1-(2**read_item.arsize)):0], rstrb[((DATA_WIDTH/8)-1):((DATA_WIDTH/8)-(2**read_item.arsize))]};
        end
        */
        
          wstrb_unaligned = wstrb[0];
        //wstrb[0] calculation update for unaligned address
        for(int i=0;i<awaddr%(2**awsize);i++)//gets executed only incase of unaligned address
        begin
          wstrb_unaligned[i] = 1'h0;
//          `uvm_info("DEBUG",$sformatf("wstrb_unaligned=%0x\n",wstrb_unaligned),UVM_LOW)
        end
        foreach(wstrb[i])//rstrb generation for beats other than 0th beat
        begin
          if(i+1 < awlen+1) begin
            wstrb[i+1] = ((wstrb[i]<<(2**awsize))+(wstrb[i]>>((DATA_WIDTH/8)-(2**awsize))));
          end
//          end
        end
        /*
        foreach(wstrb[i])//wstrb generation for beats other than 0th beat
        begin
          if((wstrb[i][DATA_WIDTH/8-1]==1'h1))
            wstrb[i+1] = wstrb[0];
          else
            wstrb[i+1] = wstrb[i]<<(2**awsize);
        end
*/
        wstrb[0] = wstrb_unaligned; //update wstrb[0] incase of unaligned address transfers

        if(awburst==FIXED) //For fixed transfers, wstrb is same as wstrb for beat0 i.e., wstrb[0] even incase of unaligned transfer
        begin
          for(int i=1;i<DATA_WIDTH/8;i++)//same wstrb value for all the beats
          begin
            wstrb[i] = wstrb[0];
          end
        end
      end 
    end : default_wstrb_gen
    
  //****wdata calculation from data dyn_array****
/*    
    wdata = new[awlen+1];
    wdata_temp = new[((awlen+1)*(2**awsize))/(DATA_WIDTH/8)];

    for(int i=0;i<awlen+1;i++)
    begin
      wdata_temp[i] = 'h0;
      for(int j=0;j<DATA_WIDTH/8;j++)
      begin
        //wdata[i][j*8+:8] = data[data_index];
//        if(data_index<(1<<awsize))
          wdata_temp[i][j*8+:8] = data[data_index];
//        else
//          wdata_temp[i][j*8+:8] = 8'h0;

        `uvm_info("SEQ_ITEM_DEBUG",$sformatf("wdata_temp[%0d][%0d*8+:8]=%0x; data[%0d]=%0x; data.size()=%0d\n",i,j,wdata_temp[i][j*8+:8],data_index,data[data_index],data.size()),UVM_LOW)

        data_index++;
      end
    end
    
    for(int i=0;i<(awlen+1);i++)
    begin
      if(i%(wdata.size()/wdata_temp.size()) == 0)
      begin
        wdata[i] = wdata_temp[wdata_tmp_idx];
        wdata_tmp_idx++;
      end
      else
      begin
        wdata[i] = wdata[i-1];
      end
    end
    */
//    `uvm_info("DEBUG",$sformatf("wdata[0]=%0x data[0]=%0x",wdata[0],data[0]),UVM_LOW)     
  endfunction : post_randomize

  //------------------------------
  //do_print method
  //------------------------------
  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("trnsfr_dir", trnsfr_dir, $bits(trnsfr_dir), UVM_HEX);

    if ( trnsfr_dir == 1 ) begin
      printer.print_field_int("awaddr", awaddr, $bits(awaddr), UVM_HEX);
      printer.print_field_int("awid", awid, $bits(awid), UVM_HEX);
      printer.print_field_int("awlen", awlen, $bits(awlen), UVM_HEX);
      printer.print_field_int("awsize", awsize, $bits(awsize), UVM_HEX);
      printer.print_field_int("awburst", awburst, $bits(awburst), UVM_HEX);
      printer.print_field_int("awlock", awlock, $bits(awlock), UVM_HEX);
      printer.print_field_int("awcache", awcache, $bits(awcache), UVM_HEX);
      printer.print_field_int("awprot", awprot, $bits(awprot), UVM_HEX);
      printer.print_field_int("wid", wid, $bits(wid), UVM_HEX);
      for ( int i=0; i < wdata.size(); i++ )
      begin   
        printer.print_field($sformatf("wdata[%0d]",i), wdata[i], $bits(wdata[i]), UVM_HEX);
      end
      for ( int i=0; i < wstrb.size(); i++ )
      begin   
        printer.print_field($sformatf("wstrb[%0d]",i), wstrb[i], $bits(wstrb[i]), UVM_HEX);
      end
      /*
      for(int i=0;i<data.size();i++)
      begin   
        printer.print_field($sformatf("data[%0d]",i), data[i], $bits(data[i]), UVM_HEX);
      end
      */
      printer.print_field_int("bid", bid, $bits(bid), UVM_HEX);
      printer.print_field_int("bresp", bresp, $bits(bresp), UVM_HEX);
    end else if ( trnsfr_dir == 0 ) begin
      printer.print_field_int("araddr", araddr, $bits(araddr), UVM_HEX);
      printer.print_field_int("arid", arid, $bits(arid), UVM_HEX);
      printer.print_field_int("arlen", arlen, $bits(arlen), UVM_HEX);
      printer.print_field_int("arsize", arsize, $bits(arsize), UVM_HEX);
      printer.print_field_int("arburst", arburst, $bits(arburst), UVM_HEX);
      printer.print_field_int("arlock", arlock, $bits(arlock), UVM_HEX);
      printer.print_field_int("arcache", arcache, $bits(arcache), UVM_HEX);
      printer.print_field_int("arprot", arprot, $bits(arprot), UVM_HEX);
      printer.print_field_int("rid", rid, $bits(rid), UVM_HEX);
      for(int i=0;i<rdata.size();i++)
      begin   
        printer.print_field($sformatf("rdata[%0d]",i), rdata[i], $bits(rdata[i]), UVM_HEX);
      end
      for(int i=0;i<rresp.size();i++)
      begin   
        printer.print_field($sformatf("rresp[%0d]",i), rresp[i], $bits(rresp[i]), UVM_HEX);
      end
      printer.print_real($sformatf("start_time"), start_time);
      printer.print_real($sformatf("end_time"), end_time);
    end
 endfunction : do_print

endclass : axi_master_seq_item
