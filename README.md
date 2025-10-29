# AXI3.0_Master_UVC
This is an AXI3.0 Master UVC.
Supported features:
1. AXI3.0 protocol
2. Pipelined reads, pipelined writes, pipelined writes & reads
3. Different burst types(INCR, WRAP, FIXED)
4. Different data sizes
5. Exclusive access, Different axcache & axprot signals
6. Aligned and unaligned transfers
7. Narrow transfers
8. User defined wstrb
9. Configurable number of delay cycles between valid/ready signals for write response channel and read data channel
   
Limitations:
1. Doesn't support same(write-write/read-read) pipeline transfers for same awid/arid
2. Coverage and assertions are to be implemented yet.
3. Design doesn't support wrap transfers. But, UVC supports wrap transfers and has been verified.
4. Assertions and Coverage would be added in next versions.

**Design file reference:**
Copyright (c) 2018 Alex Forencich from github
