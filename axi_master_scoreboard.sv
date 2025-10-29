//-------------------------------------------------------------------------
//						axi_master_scoreboard 
//-------------------------------------------------------------------------

class axi_master_scoreboard#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_scoreboard;

  `uvm_analysis_imp_decl(_drv)
  `uvm_analysis_imp_decl(_mon)
  
  //---------------------------------------
  // typedefs
  //---------------------------------------
  typedef axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)) axi_master_seq_item_t;
  typedef axi_master_scoreboard#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)) axi_master_scoreboard_t;
  
  //---------------------------------------
  // declaring axi_pkt_q to store the pkt's recived from monitor
  //---------------------------------------
  axi_master_seq_item_t axi_pkt_q[$];
  axi_master_seq_item_t item;
  
  axi_master_seq_item_t axi_mon_wr_pkt_q[$]; //write packets received from monitor
  axi_master_seq_item_t axi_mon_rd_pkt_q[$]; //read packets received from monitor

//  axi_master_seq_item axi_drv_wr_rd_pkt_q[$]; //write packets received from driver

  axi_master_seq_item_t axi_drv_wr_pkt_q[$]; //write packets received from driver
  axi_master_seq_item_t axi_drv_rd_pkt_q[$]; //read packets received from driver
  
  
  //---------------------------------------
  // memory to store write transfers & to look for during read transfers
  //---------------------------------------
  bit[7:0] memory [/*'h10000000*/((2**ADDR_WIDTH)-1):0];
  
  int pass_cnt, fail_cnt;

  //---------------------------------------
  //port to recive packets from monitor
  //---------------------------------------
  uvm_analysis_imp_mon#(axi_master_seq_item_t, axi_master_scoreboard_t) mon_item_collected_export;
  uvm_analysis_imp_drv#(axi_master_seq_item_t, axi_master_scoreboard_t) drv_item_collected_export;
  `uvm_component_param_utils(axi_master_scoreboard#(ADDR_WIDTH, DATA_WIDTH))

  //---------------------------------------
  // new - constructor
  //---------------------------------------
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
  
  //---------------------------------------
  // build_phase - create port and initialize local memory
  //---------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_item_collected_export = new("mon_item_collected_export", this);
    drv_item_collected_export = new("drv_item_collected_export", this);
  endfunction: build_phase


  //---------------------------------------
  // run_phase - compare's the read data with the expected data(stored in local memory)
  // local memory will be updated on the write operation.
  //---------------------------------------
  virtual task run_phase(uvm_phase phase);
//    longint memory_size;
//    memory_size = 1<<(ADDR_WIDTH-1);
//    memory = new[memory_size];
    {pass_cnt, fail_cnt} = 'h0; 
    forever begin : forever_loop
      fork
        begin
          update_mem_compare_mem(); //update memory locations in case of write & compare read_data with content in memory in case of reads
        end
        begin
          driver_mon_cmp(); //compare tx_items of driver & monitor
        end
      join
    end : forever_loop
  endtask : run_phase
 
  
  //---------------------------------------
  // driver_mon_cmp -- verify the packets sent from driver & packets received at the monitor
  //---------------------------------------
  virtual task driver_mon_cmp();
    axi_master_seq_item_t mon_wr_pkt;
    axi_master_seq_item_t mon_rd_pkt;
    
    axi_master_seq_item_t drv_wr_pkt;
    axi_master_seq_item_t drv_rd_pkt;
    
    mon_wr_pkt = new();
    mon_rd_pkt = new();
    
    drv_wr_pkt = new();
    drv_rd_pkt = new();
    fork
    begin
      wait((axi_mon_wr_pkt_q.size!=0)&&(axi_drv_wr_pkt_q.size!=0));
      mon_wr_pkt = axi_mon_wr_pkt_q.pop_front();
      drv_wr_pkt = axi_drv_wr_pkt_q.pop_front();
      wr_cmp(drv_wr_pkt, mon_wr_pkt);
    end
    begin
      wait((axi_mon_rd_pkt_q.size!=0)&&(axi_drv_rd_pkt_q.size!=0));
      mon_rd_pkt = axi_mon_rd_pkt_q.pop_front();
      drv_rd_pkt = axi_drv_rd_pkt_q.pop_front();
      rd_cmp(drv_rd_pkt, mon_rd_pkt);
    end 
    join_any
  endtask: driver_mon_cmp
  
  //---------------------------------------
  // rd_cmp - verifies if read tx_items received from driver & monitor are same
  // i.e., read packets driven from driver are same as observed in monitor
  //---------------------------------------  
  virtual task rd_cmp(axi_master_seq_item_t drv_pkt, axi_master_seq_item_t mon_pkt);
    if(drv_pkt.araddr!=mon_pkt.araddr) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt araddr = %0x monitor araddr = %0x", drv_pkt.araddr, mon_pkt.araddr))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    if(drv_pkt.arcache!=mon_pkt.arcache) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt arcache = %0x monitor arcache = %0x", drv_pkt.arcache, mon_pkt.arcache))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    if(drv_pkt.arprot!=mon_pkt.arprot) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt arprot = %0x monitor arprot = %0x", drv_pkt.arprot, mon_pkt.arprot))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    if(drv_pkt.arlock!=mon_pkt.arlock) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt arlock = %0x monitor arlock = %0x", drv_pkt.arlock, mon_pkt.arlock))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    for(int i=0;i<drv_pkt.rdata.size();i++)
    begin
      if(drv_pkt.rdata[i]!=mon_pkt.rdata[i]) begin
        `uvm_error("SCB_MISMATCH",$sformatf("driver pkt rdata[%0d] = %0x monitor rdata[%0d] = %0x", i, drv_pkt.rdata[i], i, mon_pkt.rdata[i]))
        fail_cnt ++ ;
      end else begin
        pass_cnt ++ ;
      end
    end
  endtask : rd_cmp
  
  //---------------------------------------
  // wr_cmp - verifies if write tx_items received from driver & monitor are same
  // i.e., write packets driven from driver are same as observed in monitor
  //---------------------------------------

  virtual task wr_cmp(axi_master_seq_item_t drv_pkt, axi_master_seq_item_t mon_pkt);
    if(drv_pkt.awaddr!=mon_pkt.awaddr) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt awaddr = %0x monitor awaddr = %0x", drv_pkt.awaddr, mon_pkt.awaddr))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    if(drv_pkt.awcache!=mon_pkt.awcache) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt awcache = %0x monitor awcache = %0x", drv_pkt.awcache, mon_pkt.awcache))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    if(drv_pkt.awprot!=mon_pkt.awprot) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt awprot = %0x monitor awprot = %0x", drv_pkt.awprot, mon_pkt.awprot))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    if(drv_pkt.awlock!=mon_pkt.awlock) begin
      `uvm_error("SCB_MISMATCH",$sformatf("driver pkt awlock = %0x monitor awlock = %0x", drv_pkt.awlock, mon_pkt.awlock))
      fail_cnt ++;
    end else begin
      pass_cnt++;
    end
    for(int i=0;i<drv_pkt.wdata.size();i++)
      begin
        if(drv_pkt.wdata[i]!=mon_pkt.wdata[i]) begin
          `uvm_error("SCB_MISMATCH",$sformatf("driver pkt wdata[%0d] = %0x monitor wdata[%0d] = %0x", i, drv_pkt.wdata[i], i, mon_pkt.wdata[i]))
          fail_cnt ++ ;
        end else begin
          pass_cnt ++ ;
        end
        if(drv_pkt.wstrb[i]!=mon_pkt.wstrb[i]) begin
          `uvm_error("SCB_MISMATCH",$sformatf("driver pkt wstrb[%0d] = %0x monitor wstrb[%0d] = %0x", i, drv_pkt.wstrb[i], i, mon_pkt.wstrb[i]))
          fail_cnt ++ ;
        end else begin
          pass_cnt ++ ;
        end
      end
  endtask : wr_cmp
  
  //---------------------------------------
  // report_phase function - check for queues & report scoreboard_status
  //---------------------------------------
  virtual function void report_phase (uvm_phase phase);
    `uvm_info("REPORT_PHASE", $sformatf("pass_cnt = %0d; fail_cnt = %0d\n",pass_cnt, fail_cnt),UVM_LOW)
    if ( axi_mon_wr_pkt_q.size() != 0) begin
      `uvm_error("QUEUE_NOT_EMPTY", $sformatf("axi_mon_wr_pkt_q not empty; axi_mon_wr_pkt_q.size() = %0d\n",axi_mon_wr_pkt_q.size()))
    end
    if ( axi_mon_rd_pkt_q.size() != 0) begin
      `uvm_error("QUEUE_NOT_EMPTY", $sformatf("axi_mon_rd_pkt_q not empty; axi_mon_rd_pkt_q.size() = %0d\n",axi_mon_rd_pkt_q.size()))
    end
    if ( axi_drv_wr_pkt_q.size() != 0) begin
      `uvm_error("QUEUE_NOT_EMPTY", $sformatf("axi_drv_wr_pkt_q not empty; axi_drv_wr_pkt_q.size() = %0d\n",axi_drv_wr_pkt_q.size()))
    end
    if ( axi_drv_rd_pkt_q.size() != 0) begin
      `uvm_error("QUEUE_NOT_EMPTY", $sformatf("axi_drv_rd_pkt_q not empty; axi_drv_rd_pkt_q.size() = %0d\n",axi_drv_rd_pkt_q.size()))
    end
  endfunction : report_phase 
  
  //---------------------------------------
  // write_mon task - recives the pkt from monitor and pushes into queue
  //---------------------------------------
  virtual function void write_mon(axi_master_seq_item_t pkt);
//    pkt.print();
    axi_pkt_q.push_back(pkt);
    if((pkt.trnsfr_dir== AXI_WRITE)||(pkt.trnsfr_dir== AXI_WRITE_READ))
    begin
      axi_mon_wr_pkt_q.push_back(pkt);
    end
    if((pkt.trnsfr_dir== AXI_READ)||(pkt.trnsfr_dir== AXI_WRITE_READ))
    begin
      axi_mon_rd_pkt_q.push_back(pkt);       
    end
    `uvm_info("SCOREBOARD_PKT",$sformatf("axi_pkt_received from monitor\n"),UVM_DEBUG)
//    pkt.print();
  endfunction : write_mon

  //---------------------------------------
  // write_drv task - recives the pkt from driver and pushes into queue
  //---------------------------------------
  virtual function void write_drv(axi_master_seq_item_t pkt);
//    pkt.print();
    if((pkt.trnsfr_dir== AXI_WRITE)||(pkt.trnsfr_dir== AXI_WRITE_READ))
    begin
      axi_drv_wr_pkt_q.push_back(pkt);
    end
    if((pkt.trnsfr_dir== AXI_READ)||(pkt.trnsfr_dir== AXI_WRITE_READ))
    begin
      axi_drv_rd_pkt_q.push_back(pkt);       
    end
    `uvm_info("SCOREBOARD_PKT",$sformatf("axi_pkt_received from driver\n"),UVM_DEBUG)
//    pkt.print();
  endfunction : write_drv
  
  
  
  //---------------------------------------
  // update_mem_compare_mem - update scb_memory on axi_writes &
  // verify memory contents with read_data on reads
  //---------------------------------------
  virtual task update_mem_compare_mem();
      item = new();
      wait(axi_pkt_q.size>0);
      item = axi_pkt_q.pop_front();
      //fork
        begin : write_operation
          //perform memory updates incase of writes
          if(item.trnsfr_dir==AXI_WRITE)
            update_memory(item);
        end : write_operation
        begin : read_operation
          //verify read_data with memory contents with rdata incase of reads
          if(item.trnsfr_dir==AXI_READ)
            verify_memory(item);
        end : read_operation
      //join
  endtask: update_mem_compare_mem
  
  //---------------------------------------
  // update_memory - update scb_memory on axi_writes
  //---------------------------------------
  virtual task update_memory(axi_master_seq_item_t write_item);
    logic[DATA_WIDTH-1:0] wstrb_mask[];
    logic[ADDR_WIDTH-1:0] awaddr_aligned;
    logic[ADDR_WIDTH-1:0] wr_addr;
    int wrap_trsfr_size;
    logic[ADDR_WIDTH-1:0] wrap_boundary;


    
    awaddr_aligned = write_item.awaddr - (write_item.awaddr % (2**write_item.awsize));
    case(write_item.awburst)
      FIXED   : begin
        for(int j=0;j<write_item.awlen+1;j++)//loop to loop around beat number
        begin
          wr_addr=write_item.awaddr;
          for(int i=0; i<DATA_WIDTH/8;i++) //loop to update memory for each beat
          begin
            if(write_item.wstrb[j][i]==1)
            begin
              memory[wr_addr] = write_item.wdata[j][8*i+:8];
              wr_addr++;

            end
          end
        end
        `uvm_info("SCBD_DEBUG",$sformatf("burst_type=%0d",write_item.awburst),UVM_LOW)
      		  	end
      INCR 	  : begin
//        `uvm_info("SCBD_DEBUG",$sformatf("burst_type=%0d",write_item.awburst),UVM_LOW)
        wr_addr=write_item.awaddr;
        for(int j=0;j<write_item.awlen+1;j++)//loop to loop around beat number
        begin

          for(int i=0; i<DATA_WIDTH/8;i++) //loop to update memory for each beat
          begin
            if(write_item.wstrb[j][i]==1)
            begin
              memory[wr_addr] = write_item.wdata[j][8*i+:8];
              //memory['h1002] = write_item.wdata[0][23:16];
//              `uvm_info("SCBD_DEBUG_NEW",$sformatf("memory[%0x]=%0x;  write_item.wdata[0][7:0]=%0x\n",wr_addr,memory[wr_addr], write_item.wdata[j][8*i+:8]),UVM_LOW)
//              `uvm_info("SCBD_DEBUG",$sformatf("memory[%0x]=%0x\n",wr_addr,memory[wr_addr]),UVM_LOW)
//              `uvm_info("SCBD_DEBUG_memory_updated",$sformatf("write_item.awaddr=%0x; memory[%0x]=%0x\n", write_item.awaddr, wr_addr, memory[wr_addr]),UVM_LOW)
//              `uvm_info("SCBD_DEBUG_memory_updated",$sformatf("write_item.wdata[%0d][8*%0d+:8]=%0x\n",j,i,write_item.wdata[j][8*i+:8]),UVM_LOW)
//              `uvm_info("")
              wr_addr++;
            end
          end
        end
      		    end
      WRAP	  : begin
        wrap_trsfr_size = (write_item.awlen + 1)*(2**write_item.awsize);
        wr_addr=write_item.awaddr;
	    wrap_boundary = ((write_item.awaddr) - (write_item.awaddr % wrap_trsfr_size)+ wrap_trsfr_size - 1);
//        `uvm_info("SCBD_DEBUG",$sformatf("wrap_trsfr_size=%0d; wrap_boundary=%0x", wrap_trsfr_size, wrap_boundary),UVM_LOW)
        for(int j=0;j<write_item.awlen+1;j++)//loop to loop around beat number
        begin
          for(int i=0; i<DATA_WIDTH/8;i++) //loop to update memory for each beat
          begin
            if(write_item.wstrb[j][i]==1)
            begin
              memory[wr_addr] = write_item.wdata[j][8*i+:8];
//              `uvm_info("SCBD_DEBUG_NEW",$sformatf("write_item.awaddr=%0x; write_item.awlen=%0d; write_item.awsize=%0d; write_item.wstrb[%0d] = %0x; memory[%0x]=%0x;  write_item.wdata[%0d][8*%0d+:8]=%0x", write_item.awaddr, write_item.awlen, write_item.awsize, j, write_item.wstrb[j], wr_addr,memory[wr_addr], j,i,write_item.wdata[j][8*i+:8]),UVM_LOW)
              wr_addr++;
            end
//            wr_addr++;
	        if(wr_addr==(wrap_boundary+1)) begin
	          wr_addr = write_item.awaddr - (write_item.awaddr % wrap_trsfr_size);
	        end
          end
        end
//        `uvm_info("SCBD_DEBUG",$sformatf("burst_type=%0d",write_item.awburst),UVM_LOW)
      		    end
      default : begin
        `uvm_error("BURST_TYPE_ERR",$sformatf("Unknown Write burst type awburst=%0d",write_item.awburst))
      			end
    endcase
    
  endtask
 
   
  //---------------------------------------
  // verify_memory - verify memory contents with read_data on reads
  //---------------------------------------
  virtual task verify_memory(axi_master_seq_item_t read_item);
    bit[DATA_WIDTH-1:0] rdata_expected[], rdata_expected_temp[], rdata_mask[];
    bit[DATA_WIDTH/8-1:0] rstrb[];
    bit[ADDR_WIDTH-1:0] DW_aligned_rd_start_addr;
    bit[DATA_WIDTH/8-1:0] rstrb_unaligned;
    bit[ADDR_WIDTH-1:0] rd_idx;
    int wrap_rd_trnsfr_size;
    bit[ADDR_WIDTH-1:0] wrap_boundary;
    bit[ADDR_WIDTH-1:0] rd_addr;

    //integer temp;
    
    rdata_expected_temp = new[read_item.arlen + 1];//[$ceil(((read_item.arlen+1)*(2**read_item.arsize))/(DATA_WIDTH/8))];
    rdata_expected = new[read_item.arlen + 1];
    rstrb = new[read_item.arlen + 1];
    rdata_mask = new[read_item.arlen + 1];
    
      begin : default_rstrb_gen
        rstrb = new[read_item.arlen+1];
        if(read_item.arburst==INCR || read_item.arburst == FIXED || read_item.arburst == WRAP) //rstrb calculation same for INCR aligned & WRAP aligned
      begin
	//Aligned address
        //rstrb calculation for beat0
        
          foreach(rstrb[0][i])
          begin
            if(i<2**read_item.arsize)
              rstrb[0][i] = 1'h1;
            else
              rstrb[0][i] = 1'h0;
          end
        //nmitta added 10_06_25 begin
        if(read_item.araddr%(2**read_item.arsize)==0) begin //if aligned address 
          rstrb[0] = (rstrb[0] << (read_item.araddr%(DATA_WIDTH/8)));
//          `uvm_info("RSTRB_DEBUG",$sformatf("rstrb[0]=%0x",rstrb[0]),UVM_LOW)
        end
        //nmitta added end
        /*
        for(int i=0;i<DATA_WIDTH/8; i++) begin
          if((i>=(read_item.araddr%(DATA_WIDTH/8)))&&(i<((read_item.araddr%(DATA_WIDTH/8))+(2**read_item.arsize)))) begin
            rstrb[0][i] = 1'h1;
          end else begin
            rstrb[0][i] = 1'h0;
          end
        end
        
        for(int i=0; i<read_item.arlen;i++) begin
          rstrb[i+1] = (rstrb[i]<<(2**read_item.arsize))+(rstrb[i]>>((DATA_WIDTH/8)-(2**read_item.arsize)));
          //rstrb[i+1] = {rstrb[i][((DATA_WIDTH/8)-1-(2**read_item.arsize)):0], rstrb[((DATA_WIDTH/8)-1):((DATA_WIDTH/8)-(2**read_item.arsize))]};
        end*/
        
          rstrb_unaligned = rstrb[0];
        //rstrb[0] calculation update for unaligned address
        for(int i=0;i<read_item.araddr%(2**read_item.arsize);i++)//gets executed only incase of unaligned address
        begin
          rstrb_unaligned[i] = 1'h0;
//nmitta temp          `uvm_info("DEBUG",$sformatf("rstrb_unaligned=%0x\n",rstrb_unaligned),UVM_LOW)
        end
        foreach(rstrb[i])//rstrb generation for beats other than 0th beat
        begin
/*          if((rstrb[i][DATA_WIDTH/8-1]==1'h1)) begin
            rstrb[i+1] = rstrb[0];
          end else begin */
//            rstrb[i+1] = (rstrb[i]<<(2**read_item.arsize));
          if(i+1 < read_item.arlen+1) begin
            rstrb[i+1] = ((rstrb[i]<<(2**read_item.arsize))+(rstrb[i]>>((DATA_WIDTH/8)-(2**read_item.arsize))));
//            `uvm_info("SCBD_DEBUG",$sformatf("rstrb[%0d+1]=%0x; (rstrb[i]<<(2**read_item.arsize)=%0x + (rstrb[i]>>((DATA_WIDTH/8)-(2**read_item.arsize)) =%0x; (DATA_WIDTH/8)-(2**read_item.arsize)=%0x ",i,rstrb[i+1],(rstrb[i]<<(2**read_item.arsize)),(rstrb[i]>>((DATA_WIDTH/8)-(2**read_item.arsize))),((DATA_WIDTH/8)-(2**read_item.arsize))),UVM_LOW)
          end
//          end
        end

        rstrb[0] = rstrb_unaligned; //update rstrb[0] incase of unaligned address transfers

        if(read_item.arburst==FIXED) //For fixed transfers, rstrb is same as rstrb for beat0 i.e., rstrb[0] even incase of unaligned transfer
        begin
          for(int i=1;i<DATA_WIDTH/8;i++)//same rstrb value for all the beats
          begin
            rstrb[i] = rstrb[0];
          end
        end
      end 
        for(int i=0; i < read_item.arlen+1; i++) begin //to loop around beats
          for(int j=0; j < DATA_WIDTH/8; j++) begin //to loop around in single beat
            rdata_mask[i][8*j+:8] = {8{rstrb[i][j]}};
//            `uvm_info("DEBUG_rdata_mask",$sformatf("rstrb[%0d]=%0x; rdata_mask[%0d]=%0x", i, rstrb[i], i, rdata_mask[i]),UVM_LOW)
          end
        end
  end : default_rstrb_gen
    
    DW_aligned_rd_start_addr = read_item.araddr - (read_item.araddr%(DATA_WIDTH/8));
    case(read_item.arburst) //TODO
      FIXED   : begin
                for(int j = 0; j < read_item.arlen + 1; j++) begin //loop to loop around each beat
          for(int i = 0; i < DATA_WIDTH/8; i++) begin //loop to loop around each byte in a beat
            rdata_expected_temp[j][8*i+:8] = memory[DW_aligned_rd_start_addr + (j*DATA_WIDTH/8) + i];
          end
        end
        for(int idx = 0, j=0; idx < read_item.arlen+1; j++) begin //expected_rdata same for all beats
          for(int k=0; k < ((DATA_WIDTH/8)/(2**read_item.arsize)) ; k++ ) begin
            rdata_expected[idx] = rdata_expected_temp[0];
            idx++;
          end
        end

/*
        for(int j=0;j<read_item.arlen + 1; j++) begin
          if((rdata_expected[j]&rdata_mask[j]) == (read_item.rdata[j]&rdata_mask[j])) begin
            `uvm_info("DEBUG_RDATA_MATCH", $sformatf("rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x; rstrb[%0d]=%0x; rdata_mask[%0d] = %0x", j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]), UVM_LOW)
            pass_cnt++;
          end else begin
            `uvm_error("RDATA_MISMATCH", $sformatf("read_item.araddr=%0x; read_item.arlen=%0d; read_item.arsize=%0d; rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x\n", read_item.araddr, read_item.arlen, read_item.arsize, j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]))
            fail_cnt++;
          end
        end
*/
//        `uvm_info("SCBD_DEBUG",$sformatf("burst_type=%0d",read_item.arburst),UVM_LOW)
      		  	end
      INCR 	  : begin
        
        for(int j = 0; j < read_item.arlen + 1; j++) begin //loop to loop around each beat
          for(int i = 0; i < DATA_WIDTH/8; i++) begin //loop to loop around each byte in a beat
//            rdata_expected[j][8*i+:8] = memory[DW_aligned_rd_start_addr + (j*DATA_WIDTH/8) + i];
            rdata_expected_temp[j][8*i+:8] = memory[DW_aligned_rd_start_addr + (j*DATA_WIDTH/8) + i];
//            `uvm_info("DEBUG",$sformatf("(read_item.arlen+1)/((DATA_WIDTH/8)/(2**read_item.arsize))= %0d; rdata_expected_temp[%0d][8*%0d+:8]=%0x; memory=%0x", $ceil((read_item.arlen+1)/((DATA_WIDTH/8)/(2**read_item.arsize))), j, i, rdata_expected_temp[j][8*i+:8],memory[DW_aligned_rd_start_addr + (j*DATA_WIDTH/8) + i]),UVM_LOW)
          end
//          `uvm_info("DEBUG",$sformatf("rdata_expected_temp[%0d]=%0x; ", j, rdata_expected_temp[j]),UVM_LOW)
        end
        for(int idx = 0, j=0; idx < read_item.arlen+1; j++) begin
          rdata_expected[idx] = rdata_expected_temp[j];
          idx++;
        end

/*
        for(int j=0;j<read_item.arlen + 1; j++) begin
          if((rdata_expected[j]&rdata_mask[j]) == (read_item.rdata[j]&rdata_mask[j])) begin
            `uvm_info("DEBUG_RDATA_MATCH", $sformatf("arburst=%0x; araddr=%0x; arlen=%0x; arsize=%0x; rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x; rstrb[%0d]=%0x; rdata_mask[%0d] = %0x", read_item.arburst, read_item.araddr, read_item.arlen, read_item.arsize, j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]), UVM_LOW)
            pass_cnt++;
          end else begin
//            `uvm_error("RDATA_MISMATCH", $sformatf("rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x\n", j, rdata_expected[j]&rdata_mask[j], j, read_item.rdata[j]&rdata_mask[j], j, rstrb[j], j, rdata_mask[j]))
            `uvm_error("RDATA_MISMATCH", $sformatf("arburst=%0x; araddr=%0x; arlen=%0x; arsize=%0x; rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x", read_item.arburst, read_item.araddr, read_item.arlen, read_item.arsize, j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]))
            fail_cnt++;
          end
        end
	*/
//        `uvm_info("SCBD_DEBUG",$sformatf("burst_type=%0d",read_item.arburst),UVM_LOW)
      		    end
      WRAP	  : begin
        
        rd_idx = DW_aligned_rd_start_addr;
        wrap_rd_trnsfr_size = (read_item.arlen + 1)*(2**read_item.arsize);
        rd_addr = read_item.araddr;

        
        wrap_boundary = ((read_item.araddr) - (read_item.araddr % wrap_rd_trnsfr_size)+ wrap_rd_trnsfr_size - 1);
//        `uvm_info("SCBD_DEBUG",$sformatf("wrap_rd_trnsfr_size=%0d; wrap_boundary=%0x", wrap_rd_trnsfr_size, wrap_boundary),UVM_LOW)
/*
        for(int j = 0; j < read_item.arlen + 1; j++) begin //loop to loop around each beat
          for(int i = 0; i < DATA_WIDTH/8; i++) begin //loop to loop around each byte in a beat
            rdata_expected_temp[j][8*i+:8] = memory[(rd_idx + (j*DATA_WIDTH/8) + i)];
            `uvm_info("RD_DATA_SCBD_DEBUG",$sformatf("memory[%0x]=%0x",(rd_idx + (j*DATA_WIDTH/8) + i),memory[(rd_idx + (j*DATA_WIDTH/8) + i)]),UVM_LOW)
            if((rd_idx + (j*DATA_WIDTH/8) + i)== (wrap_boundary+1)) begin
	          rd_idx = read_item.araddr - (read_item.araddr%rd_trnsfr_size);
	        end
          end
        end
        for(int idx = 0, j=0; idx < read_item.arlen+1; j++) begin
          for(int k=0; k < ((DATA_WIDTH/8)/(2**read_item.arsize)) ; k++ ) begin
            rdata_expected[idx] = rdata_expected_temp[j];
            idx++;
          end
        end
        */
        for(int j=0;j<read_item.arlen+1;j++)//loop to loop around beat number
        begin
          for(int i=0; i<DATA_WIDTH/8;i++) //loop to update memory for each beat
          begin
            if(rstrb[j][i]==1)
            begin
              rdata_expected[j][8*i+:8] = memory[rd_addr];
//              `uvm_info("SCBD_DEBUG_NEW",$sformatf("read_item.araddr=%0x; memory[%0x]=%0x;  rdata_expected[%0d][8*%0d+:8]=%0x",read_item.araddr, rd_addr,memory[rd_addr], j, i, rdata_expected[j][8*i+:8]),UVM_LOW)
              rd_addr++;
            end
//            rd_addr++;
	        if(rd_addr==(wrap_boundary+1)) begin
	          rd_addr = read_item.araddr - (read_item.araddr % wrap_rd_trnsfr_size);
	        end
          end
        end

/*
        for(int j=0;j<read_item.arlen + 1; j++) begin
          if((rdata_expected[j]&rdata_mask[j]) == (read_item.rdata[j]&rdata_mask[j])) begin
            `uvm_info("DEBUG_RDATA_MATCH", $sformatf("rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x; rstrb[%0d]=%0x; rdata_mask[%0d] = %0x", j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]), UVM_LOW)
            pass_cnt++;
          end else begin
//            `uvm_error("RDATA_MISMATCH", $sformatf("rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x\n", j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]))
              `uvm_error("RDATA_MISMATCH", $sformatf("read_item.araddr=%0x; read_item.arlen=%0d; read_item.arsize=%0d; rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x\n", read_item.araddr, read_item.arlen, read_item.arsize, j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]))

            fail_cnt++;
          end
        end
	*/
 //       `uvm_info("SCBD_DEBUG",$sformatf("burst_type=%0d",read_item.arburst),UVM_LOW)
      		    end
      default : begin
        `uvm_error("BURST_TYPE_ERR",$sformatf("Unknown Read burst type awburst=%0d",read_item.arburst))
      			end            
    endcase
    //expected_data Vs acutal_data comparision
    for(int j=0;j<read_item.arlen + 1; j++) begin
      if((rdata_expected[j]&rdata_mask[j]) == (read_item.rdata[j]&rdata_mask[j])) begin
        `uvm_info("DEBUG_RDATA_MATCH", $sformatf("arburst=%0x; araddr=%0x; rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x; rstrb[%0d]=%0x; rdata_mask[%0d] = %0x", read_item.arburst, read_item.araddr, j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]), UVM_LOW)
        pass_cnt++;
      end else begin
//        `uvm_error("RDATA_MISMATCH", $sformatf("rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x\n", j, rdata_expected[j]&rdata_mask[j], j, read_item.rdata[j]&rdata_mask[j], j, rstrb[j], j, rdata_mask[j]))
        `uvm_error("RDATA_MISMATCH", $sformatf("arburst=%0x; araddr=%0x; rdata_expected[%0d] = %0x; rdata_observed[%0d] = %0x;  rstrb[%0d]=%0x; rdata_mask[%0d] = %0x", read_item.arburst, read_item.araddr, j, (rdata_expected[j]&rdata_mask[j]), j, (read_item.rdata[j]&rdata_mask[j]), j, rstrb[j], j, rdata_mask[j]))
        fail_cnt++;
      end
    end
   
  endtask



endclass : axi_master_scoreboard