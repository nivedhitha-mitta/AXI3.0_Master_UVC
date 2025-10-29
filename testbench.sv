//-------------------------------------------------------------------------
//               testbench.sv
//-------------------------------------------------------------------------

`include "uvm_pkg.sv"

import uvm_pkg::*;

`include "axi_defines.sv"
`include "axi_types.sv"
`include "axi_config_class.sv"
//`include "axi_assertions.sv"

//---------------------------------------------------------------
//including interface and testcase files
//---------------------------------------------------------------
`include "axi_master_interface.sv"
//`include "axi_master_coverage.sv"
`include "axi_master_testlist.svh"


module tbench_top;

  //---------------------------------------
  //clock and reset signal declaration
  //---------------------------------------
  bit aclk;
  bit areset_n;

  //---------------------------------------
  //clock generation
  //---------------------------------------

  initial begin
    forever begin
    #5 aclk = ~aclk;
    end
  end

  //---------------------------------------
  //reset Generation
  //---------------------------------------
  
  initial begin
    #1 areset_n = 0;
    #5 areset_n =1;
  end

  //---------------------------------------
  //interface instance
  //---------------------------------------

  axi_master_if#(
      // Width of data bus in bits
    .DATA_WIDTH(DATA_WIDTH), 
    // Width of address bus in bits
    .ADDR_WIDTH(ADDR_WIDTH))  intf 
  
  (.aclk(aclk),.areset_n(areset_n));
  
  //---------------------------------------
  //DUT instance -- axi_slave memory
  //---------------------------------------
  
  axi_ram #(
    
    // Width of data bus in bits
    .DATA_WIDTH(DATA_WIDTH), 
    // Width of address bus in bits 
    .ADDR_WIDTH(ADDR_WIDTH), 
    // Width of wstrb (width of data bus in words)
    .STRB_WIDTH(DATA_WIDTH/8), 
    // Width of ID signal
    .ID_WIDTH(4)
    
) DUT (
    
    .clk                (aclk),
    .rst                (!areset_n),

    .s_axi_awid         (intf.awid),
    .s_axi_awaddr       (intf.awaddr),
    .s_axi_awlen        ({4'h0,intf.awlen}),
    .s_axi_awsize       (intf.awsize),
    .s_axi_awburst      (intf.awburst),
    .s_axi_awlock       (intf.awlock[0]),
    .s_axi_awcache      (intf.awcache),
    .s_axi_awprot       (intf.awprot),
    .s_axi_awvalid      (intf.awvalid),
    .s_axi_awready      (intf.awready),
    .s_axi_wdata        (intf.wdata),
    .s_axi_wstrb        (intf.wstrb),
    .s_axi_wlast        (intf.wlast),
    .s_axi_wvalid       (intf.wvalid),
    .s_axi_wready       (intf.wready),
    .s_axi_bid          (intf.bid),
    .s_axi_bresp        (intf.bresp),
    .s_axi_bvalid       (intf.bvalid),
    .s_axi_bready       (intf.bready),
    .s_axi_arid         (intf.arid),
    .s_axi_araddr       (intf.araddr),
    .s_axi_arlen        ({4'h0,intf.arlen}),
    .s_axi_arsize       (intf.arsize),
    .s_axi_arburst      (intf.arburst),
    .s_axi_arlock       (intf.arlock[0]),
    .s_axi_arcache      (intf.arcache),
    .s_axi_arprot       (intf.arprot),
    .s_axi_arvalid      (intf.arvalid),
    .s_axi_arready      (intf.arready),
    .s_axi_rid          (intf.rid),
    .s_axi_rdata        (intf.rdata),
    .s_axi_rresp        (intf.rresp),
    .s_axi_rlast        (intf.rlast),
    .s_axi_rvalid       (intf.rvalid),
    .s_axi_rready       (intf.rready)
    
);

  /*
  //---------------------------------------
  // assertions
  //---------------------------------------

  bind DUT axi_assertions  axi_assertions_inst (
    .aclk         (clk),
    .aresetn      (!rst),

    .awid         (intf.awid),
    .awaddr       (intf.awaddr),
    .awlen        (intf.awlen),
    .awsize       (intf.awsize),
    .awburst      (intf.awburst),
    .awlock       (intf.awlock),
    .awcache      (intf.awcache),
    .awprot       (intf.awprot),
    .awvalid      (intf.awvalid),
    .awready      (intf.awready),
    .wdata        (intf.wdata),
    .wstrb        (intf.wstrb),
    .wlast        (intf.wlast),
    .wvalid       (intf.wvalid),
    .wready       (intf.wready),
    .bid          (intf.bid),
    .bresp        (intf.bresp),
    .bvalid       (intf.bvalid),
    .bready       (intf.bready),
    .arid         (intf.arid),
    .araddr       (intf.araddr),
    .arlen        (intf.arlen),
    .arsize       (intf.arsize),
    .arburst      (intf.arburst),
    .arlock       (intf.arlock),
    .arcache      (intf.arcache),
    .arprot       (intf.arprot),
    .arvalid      (intf.arvalid),
    .arready      (intf.arready),
    .rid          (intf.rid),
    .rdata        (intf.rdata),
    .rresp        (intf.rresp),
    .rlast        (intf.rlast),
    .rvalid       (intf.rvalid),
    .rready       (intf.rready)
);
*/
  //---------------------------------------
  //passing the interface handle to lower heirarchy using set method
  //and enabling the wave dump
  //---------------------------------------

  initial begin
    uvm_config_db#(virtual axi_master_if#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)))::set(uvm_root::get(),"*","vif",intf); 
  end

  //---------------------------------------
  //calling test
  //---------------------------------------
  initial begin
    run_test();
  end

//`ifdef VCD_DUMP  
  initial
  begin
    $dumpfile("axi_transfers.vcd");
    $dumpvars(0, tbench_top);
  end
//`endif //VCD_DUMP
 
  //TODO -- Add max runtime limit code
/*
initial
begin
      #500 $finish();
end
*/

endmodule : tbench_top