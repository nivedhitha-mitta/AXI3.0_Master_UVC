enum bit[1:0] {FIXED, INCR, WRAP, BURST_RSVD} axi_burst_type;
enum bit[2:0] {AXI_READ, AXI_WRITE, AXI_WRITE_READ, AXI_READS, AXI_WRITES} axi_trnsfr_type;
enum bit {UVM_ACTIVE,UVM_PASSIVE} agent_type;
enum bit[1:0] {NORMAL_ACCESS, EX_ACCESS, LOCKED_ACCESS} lock_type;