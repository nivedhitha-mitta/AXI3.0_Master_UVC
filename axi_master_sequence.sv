//-------------------------------------------------------------------------
//						axi_master_sequence's 
//-------------------------------------------------------------------------


//=========================================================================
// axi_base_seq - axi base sequence; implements tasks for write & read 
// which can be used in derived sequences
//=========================================================================
class axi_base_seq#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) extends uvm_sequence#(axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))); 

  `uvm_object_param_utils(axi_base_seq#(ADDR_WIDTH, DATA_WIDTH))
  
  typedef axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master_seq_item_t; 
  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_base_seq#(ADDR_WIDTH, DATA_WIDTH)");
    super.new(name);
  endfunction

  //---------------------------------------
  //wr_stimulus -- task to generate axi writes
  //---------------------------------------
  virtual task wr_stimulus (input bit[ADDR_WIDTH-1:0] awaddr_arg, input bit[3:0]awid_arg, input bit[3:0] awlen_arg, input bit[2:0] awsize_arg, input bit[1:0] awburst_arg, input bit[1:0] awlock_arg, input bit[3:0] awcache_arg, input bit[2:0] awprot_arg, input int bready_delay_cycles_arg = 0);
    req = axi_master_seq_item_t::type_id::create("req"); 
    wait_for_grant();
    req.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == awaddr_arg; awid == awid_arg; awlen == awlen_arg; awsize== awsize_arg; awburst==awburst_arg; awlock == awlock_arg; awcache == awcache_arg; awprot == awprot_arg; bready_delay_cycles == bready_delay_cycles_arg;}; 
    send_request(req);
    wait_for_item_done();
    get_response(req); 
    if ( req.bresp != 0 ) begin
      `uvm_error("WR_RESP_ERR",$sformatf("Observed bresp = %0d",req.bresp))
    end
//    req.print(); //temp debug
  endtask : wr_stimulus
  
  //---------------------------------------
  //rd_stimulus -- task to generate axi reads
  //---------------------------------------
  virtual task rd_stimulus ( input bit[ADDR_WIDTH-1:0] araddr_arg, input bit[3:0]arid_arg, input bit[3:0] arlen_arg, input bit[2:0] arsize_arg, input bit[1:0] arburst_arg, input bit[1:0] arlock_arg, input bit[3:0] arcache_arg, input bit[2:0] arprot_arg, input int rready_delay_cycles_arg = 0);
    req = axi_master_seq_item_t::type_id::create("req"); 
    wait_for_grant();
    req.randomize() with {trnsfr_dir == AXI_READ; araddr == araddr_arg; arid == arid_arg; arlen == arlen_arg; arsize== arsize_arg; arburst==arburst_arg; arlock == arlock_arg; arcache == arcache_arg; arprot == arprot_arg; rready_delay_cycles == rready_delay_cycles_arg; }; 
    send_request(req);
    wait_for_item_done();
    get_response(req);    
    for(int i = 0; i< req.rresp.size(); i++) begin
      if ( req.rresp [i] != 0 ) begin
        `uvm_error("RD_RESP_ERR",$sformatf("Observed rresp[%0d] = %0d", i, req.rresp[i]))
      end
    end
//    req.print(); //temp debug
  endtask : rd_stimulus
  
endclass
//=========================================================================

//=========================================================================
// incr_aligned_len_size_sweep_seq - exercises all possible combinations of
// aligned addr with all combinationations of axsize & axlen 
// for INCR type transfers
//=========================================================================
class incr_aligned_len_size_sweep_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(incr_aligned_len_size_sweep_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "incr_aligned_len_size_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<='hf ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        wr_stimulus(.awaddr_arg('h1000*i+'h100*j), .awid_arg(i), .awlen_arg(i), .awsize_arg(j), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
      end
    end
    
    for(int i=0; i<='hf ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        rd_stimulus(.araddr_arg('h1000*i+'h100*j), .arid_arg(i), .arlen_arg(i), .arsize_arg(j), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
      end
    end

//    wr_stimulus('h1000, 'ha, 'hf, 'h3, INCR, 'h0, 'h0, 'h0);
  endtask
endclass
//=========================================================================
// write_sequence - "write" type
//=========================================================================
class write_sequence extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));
  bit[ADDR_WIDTH-1:0] awaddr;
  bit[3:0] awid;
  bit[3:0] awlen;
  bit[2:0] awsize;
  bit[1:0] awburst;
  bit[3:0] awcache;
  bit[2:0] awprot;
  bit[1:0] awlock;

  `uvm_object_utils(write_sequence)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "write_sequence");
    super.new(name);
  endfunction

  virtual task body();
     wr_stimulus(.awaddr_arg(this.awaddr), .awid_arg(this.awid), .awlen_arg(this.awlen), .awsize_arg(this.awsize), .awburst_arg(this.awburst), .awlock_arg(this.awlock), .awcache_arg(this.awcache), .awprot_arg(this.awprot));
//    wr_stimulus('h1000, 'ha, 'hf, 'h3, INCR, 'h0, 'h0, 'h0);
  endtask
endclass
//=========================================================================

//=========================================================================
// read_sequence - "read" type
//=========================================================================
class read_sequence extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));
  bit[ADDR_WIDTH-1:0] araddr;
  bit[3:0] arid;
  bit[3:0] arlen;
  bit[2:0] arsize;
  bit[1:0] arburst;
  bit[3:0] arcache;
  bit[2:0] arprot;
  bit[1:0] arlock;
  `uvm_object_utils(read_sequence)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "read_sequence");
    super.new(name);
  endfunction

  virtual task body();
    rd_stimulus(.araddr_arg(this.araddr), .arid_arg(this.arid), .arlen_arg(this.arlen), .arsize_arg(this.arsize), .arburst_arg(this.arburst), .arlock_arg(this.arlock), .arcache_arg(this.arcache), .arprot_arg(this.arprot));
  endtask
endclass
//=========================================================================

//=========================================================================
// write_read_sequence - "write" followed by "read"
//=========================================================================
class write_read_sequence extends uvm_sequence#(axi_master_seq_item#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)));

  `uvm_object_utils(write_read_sequence)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "write_read_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_do(req) //FIXME: Replace with `uvm_do_with to randomize and select write/read
    `uvm_do(req) //FIXME: Replace with `uvm_do_with to randomize and select write/read
  endtask
endclass
//=========================================================================

/*
//=========================================================================
// wr_rd_sequence - "write" followed by "read" (sequence's inside sequences)
//=========================================================================
class wr_rd_sequence extends uvm_sequence#(axi_master_seq_item);

  
  //---------------------------------------
  //Declaring sequences
  //---------------------------------------
  write_sequence wr_seq;
  read_sequence  rd_seq;

  //Declaring sequencer
  axi_master_sequencer axi_sqr;
  
  `uvm_object_utils(wr_rd_sequence)
  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "wr_rd_sequence");
    super.new(name);
    wr_seq = write_sequence::type_id::create("wr_seq");
    rd_seq = read_sequence::type_id::create("rd_seq");
  endfunction

  virtual task body();
    begin
      wr_seq.awaddr  = 'h1000;
      wr_seq.awid    = 'ha;
      wr_seq.awburst = INCR;
      wr_seq.awlen   = 'hf;
      wr_seq.awsize  = 'h3;
      wr_seq.start(axi_sqr);
      
      rd_seq.araddr  = 'h1000;
      rd_seq.arid    = 'h5;
      rd_seq.arburst = INCR;
      rd_seq.arlen   = 'hf;
      rd_seq.arsize  = 'h3;
      rd_seq.start(axi_sqr);
    end
  endtask
endclass
//=========================================================================
*/


//=========================================================================
// incr_unaligned_addr_seq - exercises all possible combinations of
// unaligned addr with all combinationations of axsize & axlen 
// for INCR type transfers
//=========================================================================
class incr_unaligned_addr_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(incr_unaligned_addr_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "incr_unaligned_addr_seq");
    super.new(name);
  endfunction

  virtual task body();
    int beat_size=1;
    for(int i=4; i>'h0 ; i--) begin //i--equivalent to axsize
      for(int k=(1<<i); k >'h0; k--) begin
        if(k%(1<<i)!=0) begin
          wr_stimulus(.awaddr_arg('h1000*(1<<i) + 'h100*k + k), .awid_arg(k), .awlen_arg('h8), .awsize_arg(i), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
        end
      end
    end
    
    for(int i=4; i>'h0 ; i--) begin
      for(int k=(1<<i); k >'h0; k--) begin
        if(k%(1<<i)!=0) begin
          rd_stimulus(.araddr_arg('h1000*(1<<i) + 'h100*k + k), .arid_arg(k), .arlen_arg('h8), .arsize_arg(i), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
        end
      end
    end
  endtask
endclass

//=========================================================================
// fixed_aligned_len_size_sweep_seq - exercises all possible combinations of
// aligned addr with all combinationations of axsize & axlen 
// for FIXED type transfers
//=========================================================================
class fixed_aligned_len_size_sweep_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(fixed_aligned_len_size_sweep_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "fixed_aligned_len_size_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<='hf ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        wr_stimulus(.awaddr_arg('h1000*i+'h100*j), .awid_arg(i), .awlen_arg(i), .awsize_arg(j), .awburst_arg(FIXED), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
      end
    end
    
    for(int i=0; i<='hf ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        rd_stimulus(.araddr_arg('h1000*i+'h100*j), .arid_arg(i), .arlen_arg(i), .arsize_arg(j), .arburst_arg(FIXED), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
      end
    end
  endtask
endclass : fixed_aligned_len_size_sweep_seq

//=========================================================================
// fixed_unaligned_addr_seq - exercises all possible combinations of
// unaligned addr with all combinationations of axsize & axlen 
// for FIXED type transfers
//=========================================================================
class fixed_unaligned_addr_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(fixed_unaligned_addr_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "fixed_unaligned_addr_seq");
    super.new(name);
  endfunction

  virtual task body();
    int beat_size=1;
    for(int i=4; i>'h0 ; i--) begin //i--equivalent to axsize
      for(int k=(1<<i); k >'h0; k--) begin
        if(k%(1<<i)!=0) begin
          wr_stimulus(.awaddr_arg('h1000*(1<<i) + 'h100*k + k), .awid_arg(k), .awlen_arg('h8), .awsize_arg(i), .awburst_arg(FIXED), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
        end
      end
    end
    
    for(int i=4; i>'h0 ; i--) begin
      for(int k=(1<<i); k >'h0; k--) begin
        if(k%(1<<i)!=0) begin
          rd_stimulus(.araddr_arg('h1000*(1<<i) + 'h100*k + k), .arid_arg(k), .arlen_arg('h8), .arsize_arg(i), .arburst_arg(FIXED), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
        end
      end
    end
  endtask
endclass : fixed_unaligned_addr_seq
/*
//=========================================================================
// pipelined_wr_rd_sequence - pipelined write & read sequence
//=========================================================================
class pipelined_wr_rd_sequence extends axi_base_seq;

  `uvm_object_utils(pipelined_wr_rd_sequence)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "wr_rd_sequence");
    super.new(name);
  endfunction

  virtual task body();
    wr_stimulus(.awaddr_arg( 'h2000 ), .awid_arg(1), .awlen_arg('hf), .awsize_arg(4), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
    fork
      wr_stimulus(.awaddr_arg( 'h1000 ), .awid_arg(1), .awlen_arg('hf), .awsize_arg(4), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
      rd_stimulus(.araddr_arg( 'h2000 ), .arid_arg(2), .arlen_arg('hf), .arsize_arg(4), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
    join

  endtask
endclass : pipelined_wr_rd_sequence
//=========================================================================

//=========================================================================
// pipelined_wr_sequence - pipelined writes sequence
//=========================================================================
class pipelined_wr_sequence extends uvm_sequence#(axi_master_seq_item);

  //---------------------------------------
  //Declaring sequences
  //---------------------------------------
  write_sequence wr_seq1;
  write_sequence wr_seq2;

  `uvm_object_utils(pipelined_wr_sequence)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "wr_rd_sequence");
    super.new(name);
  endfunction

  virtual task body();
    fork
    begin
    //write transfer
      req = axi_master_seq_item::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == 1; awaddr == 'h1000; awlen == 'hf; awsize== 4; awburst==INCR;}; //nmitta temp;
      finish_item(req);
     // get_response(req);
//      `uvm_info("DEBUG",$sformatf("time=%0d",$time),UVM_LOW)
//      req.print();
    end
    begin
   //write transfer
      req = axi_master_seq_item::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == 1; awaddr == 'h2000; awlen == 'hf; awsize== 4; awburst==INCR;}; //nmitta temp;
      finish_item(req);
      //get_response(req);

    end
    join
 //   `uvm_do_with(wr_seq,{wr_seq.trnsfr_dir==1; wr_seq.awlen==3; wr_seq.awsize=2;}) 
 //   `uvm_do_with(rd_seq,{rd_seq.trnsfr_dir==0; rd_seq.awlen==3; rd_seq.awsize=2;}) 

  endtask
endclass
//=========================================================================


//=========================================================================
// pipelined_rd_sequence - pipelined reads sequence
//=========================================================================
class pipelined_rd_sequence extends uvm_sequence#(axi_master_seq_item);

  `uvm_object_utils(pipelined_rd_sequence)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "wr_rd_sequence");
    super.new(name);
  endfunction

  virtual task body();
        begin
    //write transfer
      req = axi_master_seq_item::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == 1; awaddr == 'h1000; awlen == 'hf; awsize== 4; awburst==INCR;}; //nmitta temp;
      finish_item(req);
     // get_response(req);
//      `uvm_info("DEBUG",$sformatf("time=%0d",$time),UVM_LOW)
//      req.print();
    end
    begin
   //write transfer
      req = axi_master_seq_item::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == 1; awaddr == 'h2000; awlen == 'hf; awsize== 4; awburst==INCR;}; //nmitta temp;
      finish_item(req);
      //get_response(req);

    end
    
    fork
    begin
    //write transfer
      req = axi_master_seq_item::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == 0; araddr == 'h1000; arlen == 'hf; arsize== 4; arburst==INCR;}; //nmitta temp;
      finish_item(req);
     // get_response(req);
//      `uvm_info("DEBUG",$sformatf("time=%0d",$time),UVM_LOW)
//      req.print();
    end
    begin
   //write transfer
      req = axi_master_seq_item::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == 0; araddr == 'h2000; arlen == 'hf; arsize== 4; arburst==INCR;}; //nmitta temp;
      finish_item(req);
      //get_response(req);

    end
    join


  endtask
endclass
*/

//=========================================================================
// axi_bready_rready_delayed_seq – delays bready for write transfer &
//  rready for read for mentioned number of aclk cycles
//=========================================================================
class axi_bready_rready_delayed_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(axi_bready_rready_delayed_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_bready_rready_delayed_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_stimulus(.awaddr_arg('h1000), .awid_arg('ha), .awlen_arg('h8), .awsize_arg('h4), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0), .bready_delay_cycles_arg('h5));
    rd_stimulus(.araddr_arg('h1000), .arid_arg('h5), .arlen_arg('h8), .arsize_arg('h4), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0), .rready_delay_cycles_arg('h4));
  endtask : body
endclass : axi_bready_rready_delayed_seq

//=========================================================================
// axcache_signals_toggle - exercises all possible combinations of axcache signals
//=========================================================================
class axcache_signals_toggle extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(axcache_signals_toggle)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "incr_aligned_len_size_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit[3:0] awcache_arg[10] = {'h0, 'h1, 'h2, 'h3, 'h6, 'h7, 'ha, 'hb, 'he, 'hf};
    bit[3:0] arcache_arg[10]   = {'h0, 'h1, 'h2, 'h3, 'h6, 'h7, 'ha, 'hb, 'he, 'hf};
    for(int i=0; i<10 ; i++) begin
        wr_stimulus(.awaddr_arg('h1000*i), .awid_arg(i), .awlen_arg(i), .awsize_arg(4), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg(awcache_arg[i]), .awprot_arg('h0));
    end
    
    for(int i=0; i< 10; i++) begin
        rd_stimulus(.araddr_arg('h1000*i), .arid_arg(i), .arlen_arg(i), .arsize_arg(4), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg(arcache_arg[i]), .arprot_arg('h0));
    end

  endtask
endclass : axcache_signals_toggle

//=========================================================================
// axprot_signals_toggle - exercises all possible combinations of axcache signals
//=========================================================================
class axprot_signals_toggle extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(axprot_signals_toggle)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "incr_aligned_len_size_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<8 ; i++) begin
        wr_stimulus(.awaddr_arg('h1000*i), .awid_arg(i), .awlen_arg(i), .awsize_arg(4), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg(i));
    end
    
    for(int i=0; i<8; i++) begin
        rd_stimulus(.araddr_arg('h1000*i), .arid_arg(i), .arlen_arg(i), .arsize_arg(4), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg(i));
    end

  endtask
endclass : axprot_signals_toggle

//=========================================================================
// axlock_signals_toggle - exercises all possible combinations of axcache signals
//=========================================================================
class axlock_signals_toggle extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(axlock_signals_toggle)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "incr_aligned_len_size_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<3 ; i++) begin
        wr_stimulus(.awaddr_arg('h1000*i), .awid_arg(i), .awlen_arg(i), .awsize_arg(4), .awburst_arg(INCR), .awprot_arg('h0), .awcache_arg('h0), .awlock_arg(i));
    end
    
    for(int i=0; i<3; i++) begin
        rd_stimulus(.araddr_arg('h1000*i), .arid_arg(i), .arlen_arg(i), .arsize_arg(4), .arburst_arg(INCR), .arprot_arg('h0), .arcache_arg('h0), .arlock_arg(i));
    end

  endtask
endclass : axlock_signals_toggle

//=========================================================================
// ex_access_seq - perform exclusive access
//=========================================================================
class ex_access_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(ex_access_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "incr_aligned_len_size_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    rd_stimulus(.araddr_arg('h1000), .arid_arg('ha), .arlen_arg(0), .arsize_arg(4), .arburst_arg(INCR), .arlock_arg('h1), .arcache_arg('h0), .arprot_arg('h0)); //perform ex_read
    wr_stimulus(.awaddr_arg('h1000), .awid_arg('ha), .awlen_arg(0), .awsize_arg(4), .awburst_arg(INCR), .awlock_arg('h1), .awcache_arg('h0), .awprot_arg('h0)); //perform ex_write
    if(req.bresp!='h1)
      `uvm_error("EX_ACCESS_FAILURE",$sformatf("Expected response: 'h1; Observed response : 'h%0x\n",req.bresp))
  endtask
endclass : ex_access_seq
      
//=========================================================================
// axi_wstrb_override_seq - sequence in which wstrb is provided 
// using inline args instead of default generation for corner cases
//=========================================================================
class axi_wstrb_override_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(axi_wstrb_override_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_wstrb_override_seq");
    super.new(name);
  endfunction

  virtual task body();
    req = axi_master_seq_item_t::type_id::create("req");
    wait_for_grant();
    req.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == 'h1013; awid == 'ha; awlen == 0; awsize== 4; awburst == INCR; wstrb_override == 1; wstrb[0]=='hfff8;}; 
    send_request(req);
    wait_for_item_done();
    get_response(req);

    req = axi_master_seq_item_t::type_id::create("req");
    wait_for_grant();
    req.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == 'h1020; awid == 'h5; awlen == 0; awsize== 4; awburst == INCR; wstrb_override == 1; wstrb[0]=='h7;}; 
    send_request(req);
    wait_for_item_done();
    get_response(req);


    rd_stimulus(.araddr_arg('h1013), .arid_arg('h5), .arlen_arg(2), .arsize_arg(4), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));

  endtask : body
endclass : axi_wstrb_override_seq      
    
//=========================================================================
// wrap_transfer_seq - Exercise wrap transfers
//=========================================================================
class wrap_transfer_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(wrap_transfer_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "wrap_transfer_seq");
    super.new(name);
  endfunction

  virtual task body();
//    repeat(50) begin
    repeat(10) begin
      wrap_wr_stimulus;
    end
//    repeat(50) begin
    repeat(10) begin
      wrap_rd_stimulus;
    end
  endtask

  //---------------------------------------
  //wrap_wr_stimulus -- task to generate axi writes for wrap transfers
  //---------------------------------------
  virtual task wrap_wr_stimulus;
      req = axi_master_seq_item_t::type_id::create("req");
      wait_for_grant();
    req.randomize() with {trnsfr_dir == AXI_WRITE; awburst == WRAP; awaddr inside {['h0:'h2000]};}; 
      send_request(req);
      wait_for_item_done();
      get_response(req);
  endtask : wrap_wr_stimulus
  
  //---------------------------------------
  //wrap_rd_stimulus -- task to generate axi reads for wrap transfers
  //---------------------------------------
  virtual task wrap_rd_stimulus;
      req = axi_master_seq_item_t::type_id::create("req");
      wait_for_grant();
      req.randomize() with {trnsfr_dir == AXI_READ; arburst == WRAP; araddr inside {['h0:'h2000]}; }; 
      send_request(req);
      wait_for_item_done();
      get_response(req);
  endtask : wrap_rd_stimulus

endclass : wrap_transfer_seq
    
//=========================================================================
// axi_excess_writes_limited_reads_seq
//=========================================================================
class axi_excess_writes_limited_reads_seq extends axi_base_seq#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH));

  `uvm_object_utils(axi_excess_writes_limited_reads_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_excess_writes_limited_reads_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<='h7 ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        wr_stimulus(.awaddr_arg('h1000*i+'h100*j), .awid_arg(i), .awlen_arg(i), .awsize_arg(j), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
      end
    end
    for(int i=0; i<='h2 ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        rd_stimulus(.araddr_arg('h1000*i+'h100*j), .arid_arg(i), .arlen_arg(i), .arsize_arg(j), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
      end
    end
  endtask
endclass

    //=========================================================================
// pipelined_wr_rd_sequence - Performs pipelined writes & reads
//=========================================================================
class pipelined_wr_rd_sequence extends axi_base_seq#(ADDR_WIDTH, DATA_WIDTH);
  
  axi_master_seq_item_t req1, req2;

  `uvm_object_utils(pipelined_wr_rd_sequence)

  //---------------------------------------
  // Constructor
  //---------------------------------------
  function new(string name = "axi_base_seq");
    super.new(name);
  endfunction

  //---------------------------------------
  // body task
  //---------------------------------------
  task body();
    for(int i = 0; i < 3; i++) begin
      req = axi_master_seq_item_t::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == i*'h1000; awid == i; awlen == 'h8; awsize== 'h4; awburst==INCR; awlock == 'h0; awcache == 'h0; awprot == 'h0; bready_delay_cycles == 0;};    
      finish_item(req);
    end
    
    for(int i = 0; i < 3; i++) begin
      get_response(req);    
      req.print();
    end
    
    fork
      begin
        for(int i = 0; i < 3; i++) begin
          req1 = axi_master_seq_item_t::type_id::create("req1");
          start_item(req1);
          req1.randomize() with {trnsfr_dir == AXI_READ; araddr == i*'h1000; arid == i; arlen == 'h8; arsize== 'h4; arburst==INCR; arlock == 'h0; arcache == 'h0; arprot == 'h0; bready_delay_cycles == 0;};    
          finish_item(req1);
          /*
        end
        for(int i = 0; i < 3; i++) begin
        */
          get_response(req1);    
          req1.print();
        end
      end
      begin
        for(int i = 0; i < 3; i++) begin
          req2 = axi_master_seq_item_t::type_id::create("req2");
          start_item(req2);
          req2.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == i*'h1000 + 'h4000 ; awid == i; awlen == 'h8; awsize== 'h4; awburst==INCR; awlock == 'h0; awcache == 'h0; awprot == 'h0; bready_delay_cycles == 0;};    
          finish_item(req2);
          get_response(req2);    
          req2.print();
        end
/*
        for(int i = 0; i < 3; i++) begin
          get_response(req2);    
          req2.print();
        end
*/      end
    join
  endtask : body
  
endclass : pipelined_wr_rd_sequence
//=========================================================================
// pipelined_rd_sequence - Performs pipelined reads
//=========================================================================
class pipelined_rd_sequence extends axi_base_seq#(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_utils(pipelined_rd_sequence)

  //---------------------------------------
  // Constructor
  //---------------------------------------
  function new(string name = "axi_base_seq");
    super.new(name);
  endfunction

  //---------------------------------------
  // body task
  //---------------------------------------
  task body();
    for(int i = 0; i < 3; i++) begin
      req = axi_master_seq_item_t::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == i*'h1000; awid == i; awlen == 'h8; awsize== 'h4; awburst==INCR; awlock == 'h0; awcache == 'h0; awprot == 'h0; bready_delay_cycles == 0;};    
      finish_item(req);
    end
    for(int i = 0; i < 3; i++) begin
      get_response(req);    
      req.print();
    end
    for(int i = 0; i < 3; i++) begin
      req = axi_master_seq_item_t::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == AXI_READ; araddr == i*'h1000; arid == i; arlen == 'h8; arsize== 'h4; arburst==INCR; arlock == 'h0; arcache == 'h0; arprot == 'h0; bready_delay_cycles == 0;};    
      finish_item(req);
    end
    for(int i = 0; i < 3; i++) begin
      get_response(req);    
      req.print();
    end
  endtask : body
  
endclass : pipelined_rd_sequence

//=========================================================================
// axi_incr_fixed_wrap_transfers_seq
//=========================================================================
class axi_incr_fixed_wrap_transfers_seq extends axi_base_seq#(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_utils(axi_incr_fixed_wrap_transfers_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_incr_fixed_wrap_transfers_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<='h2 ; i++) begin
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        wr_stimulus(.awaddr_arg('h0*i+'h100*j), .awid_arg(i), .awlen_arg(i), .awsize_arg(j), .awburst_arg(INCR), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
        rd_stimulus(.araddr_arg('h0*i+'h100*j), .arid_arg(i), .arlen_arg(i), .arsize_arg(j), .arburst_arg(INCR), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
        wr_stimulus(.awaddr_arg('h20000*i+'h100*j), .awid_arg(i), .awlen_arg(i), .awsize_arg(j), .awburst_arg(FIXED), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
        rd_stimulus(.araddr_arg('h20000*i+'h100*j), .arid_arg(i), .arlen_arg(i), .arsize_arg(j), .arburst_arg(FIXED), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
        wr_stimulus(.awaddr_arg('h40000*i+'h1000*j), .awid_arg(i), .awlen_arg(2<<i), .awsize_arg(j), .awburst_arg(WRAP), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
        rd_stimulus(.araddr_arg('h40000*i+'h1000*j), .arid_arg(i), .arlen_arg(2<<i), .arsize_arg(j), .arburst_arg(WRAP), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
      end
    end
    

  endtask
endclass
//=========================================================================
// pipelined_wr_sequence 
//=========================================================================
class pipelined_wr_sequence extends axi_base_seq#(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_utils(pipelined_wr_sequence)

  //---------------------------------------
  // Constructor
  //---------------------------------------
  function new(string name = "pipelined_wr_sequence");
    super.new(name);
  endfunction

  //---------------------------------------
  // body task
  //---------------------------------------
  task body();
    for(int i = 0; i < 3; i++) begin
      req = axi_master_seq_item_t::type_id::create("req");
      start_item(req);
      req.randomize() with {trnsfr_dir == AXI_WRITE; awaddr == i*'h1000; awid == i; awlen == 'h8; awsize== 'h4; awburst==INCR; awlock == 'h0; awcache == 'h0; awprot == 'h0; bready_delay_cycles == 0;};    
      finish_item(req);
    end
    for(int i = 0; i < 3; i++) begin
      get_response(req);    
      req.print();
    end
  endtask : body
  
  
  //---------------------------------------
  //rd_stimulus -- task to generate axi reads
  //---------------------------------------
  virtual task rd_stimulus ( input bit[ADDR_WIDTH-1:0] araddr_arg, input bit[3:0]arid_arg, input bit[3:0] arlen_arg, input bit[2:0] arsize_arg, input bit[1:0] arburst_arg, input bit[1:0] arlock_arg, input bit[3:0] arcache_arg, input bit[2:0] arprot_arg, input int rready_delay_cycles_arg = 0);
    req = axi_master_seq_item_t::type_id::create("req");
    wait_for_grant();
    req.randomize() with {trnsfr_dir == AXI_READ; araddr == araddr_arg; arid == arid_arg; arlen == arlen_arg; arsize== arsize_arg; arburst==arburst_arg; arlock == arlock_arg; arcache == arcache_arg; arprot == arprot_arg; rready_delay_cycles == rready_delay_cycles_arg; }; 
    send_request(req);
    wait_for_item_done();
    get_response(req);    
  endtask : rd_stimulus
  
endclass : pipelined_wr_sequence
    
//=========================================================================
// axi_wrap_transfers_scbd_seq
//=========================================================================
 class axi_wrap_transfers_scbd_seq extends axi_base_seq#(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_utils(axi_wrap_transfers_scbd_seq)

  //---------------------------------------
  //Constructor
  //---------------------------------------
  function new(string name = "axi_wrap_transfers_scbd_seq");
    super.new(name);
  endfunction

  virtual task body();
    for(int i=0; i<='h2 ; i++) begin
//    int i = 2;
      for(int j=0; (1<<j)<= (DATA_WIDTH/8); j++) begin
        wr_stimulus(.awaddr_arg('h40000*i+'h1000*j), .awid_arg(i), .awlen_arg(2<<i), .awsize_arg(j), .awburst_arg(WRAP), .awlock_arg('h0), .awcache_arg('h0), .awprot_arg('h0));
        rd_stimulus(.araddr_arg('h40000*i+'h1000*j), .arid_arg(i), .arlen_arg(2<<i), .arsize_arg(j), .arburst_arg(WRAP), .arlock_arg('h0), .arcache_arg('h0), .arprot_arg('h0));
      end
    end
    

  endtask
endclass    