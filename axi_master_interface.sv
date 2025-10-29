//-------------------------------------------------------------------------
//						axi_master_interface 
//-------------------------------------------------------------------------

interface axi_master_if#(parameter ADDR_WIDTH=16, parameter DATA_WIDTH=128) (input logic aclk,areset_n);

  //---------------------------------------
  //declaring the signals
  //---------------------------------------
  //Write Address channel
  logic[3:0] awid;
  logic[ADDR_WIDTH-1:0] awaddr;
  logic[3:0] awlen;
  logic[2:0] awsize;
  logic[1:0] awburst;
  logic[1:0] awlock; 
  logic[3:0] awcache;
  logic[2:0] awprot; 
  logic awvalid;
  logic awready;

  //Write data channel
  logic[3:0] wid;
  logic[DATA_WIDTH-1:0] wdata;
  logic[DATA_WIDTH/8 - 1 :0] wstrb;
  logic wlast;
  logic wvalid;
  logic wready;

  //Write response channel
  logic[3:0] bid;
  logic[1:0] bresp;
  logic bvalid;
  logic bready;

  //Read address channel
  logic[3:0] arid;
  logic[ADDR_WIDTH-1:0] araddr;
  logic[3:0] arlen;
  logic[2:0] arsize;
  logic[1:0] arburst;
  logic[1:0] arlock; 
  logic[3:0] arcache;
  logic[2:0] arprot; 
  logic arvalid;
  logic arready;

  //Read data channel
  logic[3:0] rid;
  logic[DATA_WIDTH-1:0] rdata;
  logic[1:0] rresp;
  logic rlast;
  logic rvalid;
  logic rready;

endinterface : axi_master_if
