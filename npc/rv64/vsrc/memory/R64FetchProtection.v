// Minimum PMP granule is four bytes. Check each aligned word of a fetch
// sector independently, then mark its two halfwords. Alignment reports the
// first failed portion of a variable-length instruction.
module R64FetchProtection(
 input [63:0] address_i,input [1:0] privilege_i,
 input [15:0] pmp_active_i,input [895:0] pmp_lower_i,pmp_upper_i,
 input [63:0] pmp_permission_i,
 output [7:0] fault_mask_o,output uncached_o
);
 wire pma_fault_w;wire [1:0] class_w;
 R64Pma pma(.address_i(address_i),.size_i(5'd16),.fault_o(pma_fault_w),.class_o(class_w));
 assign uncached_o=class_w!=0;
 genvar lane;
 generate for(lane=0;lane<4;lane=lane+1)begin:g_word
  wire fault_w;
  R64PmpCheck pmp(.address_i({address_i[63:4],lane[1:0],2'b0}),.size_i(5'd4),
   .privilege_i(privilege_i),.access_i(3'b100),.active_i(pmp_active_i),
   .lower_i(pmp_lower_i),.upper_i(pmp_upper_i),.permission_i(pmp_permission_i),.fault_o(fault_w));
  assign fault_mask_o[lane*2+:2]={2{fault_w||pma_fault_w||class_w==2}};
 end endgenerate
endmodule

// Four fixed aligned word ranges share sector comparisons. No end-address
// carry belongs to this stage. Exact boundary low bits retain partial overlap.
module R64FetchProtectionPrepare(
 input [63:0] address_i,input [1:0] privilege_i,
 input [15:0] pmp_active_i,input [895:0] pmp_lower_i,pmp_upper_i,
 input [63:0] pmp_permission_i,
 output [129:0] facts_o,output uncached_o
);
 wire pma_fault_w;wire [1:0] class_w;
 R64FetchPma16 pma(.address_i(address_i),
  .fault_o(pma_fault_w),.class_o(class_w));
 assign uncached_o=class_w!=0;
 assign facts_o[129:128]={pma_fault_w||class_w==2,privilege_i!=3};
 genvar entry,word_index;
 generate for(entry=0;entry<16;entry=entry+1)begin:g_entry
  wire [55:0] lo_w=pmp_lower_i[entry*56+:56],hi_w=pmp_upper_i[entry*56+:56];
  wire [3:0] perm_w=pmp_permission_i[entry*4+:4];
  wire below_w=address_i[63:4]<{8'b0,lo_w[55:4]};
  wire above_w=address_i[63:4]>{8'b0,hi_w[55:4]};
  wire lo_equal_w=address_i[63:4]=={8'b0,lo_w[55:4]};
  wire hi_equal_w=address_i[63:4]=={8'b0,hi_w[55:4]};
  wire deny_mode_w=(privilege_i!=3||perm_w[3])&&!perm_w[2];
  for(word_index=0;word_index<4;word_index=word_index+1)begin:g_word
   localparam [3:0] FIRST=word_index*4,LAST=word_index*4+3;
   wire start_above_w,end_below_w;
   if(word_index==0)begin:g_low assign start_above_w=0;end
   else begin:g_start assign start_above_w=FIRST>hi_w[3:0];end
   if(word_index==3)begin:g_high assign end_below_w=0;end
   else begin:g_end assign end_below_w=LAST<lo_w[3:0];end
   assign facts_o[word_index*32+entry]=pmp_active_i[entry]&&
    !above_w&&!(hi_equal_w&&start_above_w)&&
    !below_w&&!(lo_equal_w&&end_below_w);
   assign facts_o[word_index*32+16+entry]=deny_mode_w||below_w||
    (lo_equal_w&&FIRST<lo_w[3:0])||above_w||(hi_equal_w&&LAST>hi_w[3:0]);
  end
 end endgenerate
endmodule

// Priority consumes immutable facts from the existing LOOKUP owner.
module R64FetchProtectionFinish(input [129:0] facts_i,output [7:0] fault_mask_o);
 genvar word_index,entry;
 generate for(word_index=0;word_index<4;word_index=word_index+1)begin:g_word
  wire [15:0] overlap_w=facts_i[word_index*32+:16];
  wire [15:0] deny_w=facts_i[word_index*32+16+:16];
  wire [15:0] selected_deny_w;
  for(entry=0;entry<16;entry=entry+1)begin:g_priority
   if(entry==0)begin:g_first
    assign selected_deny_w[entry]=overlap_w[entry]&&deny_w[entry];
   end else begin:g_later
    assign selected_deny_w[entry]=overlap_w[entry]&&deny_w[entry]&&!(|overlap_w[entry-1:0]);
   end
  end
  assign fault_mask_o[word_index*2+:2]={2{facts_i[129]||
   (facts_i[128]&&!(|overlap_w))||(|selected_deny_w)}};
 end endgenerate
endmodule

// Fetch transports always request 16 bytes. Compare the first address with
// the last legal first byte of each concrete platform window; this preserves
// the complete range check without a runtime 65-bit address+15 carry chain.
// Masks in R64PlatformMap describe naturally aligned power-of-two windows.
`include "R64PlatformMap.vh"
module R64FetchPma16(input [63:0] address_i,output fault_o,output [1:0] class_o);
 function covers_sector;
  input [63:0] first,base,mask;
  begin covers_sector=(first&mask)==base&&first<=((base|~mask)-64'd15);end
 endfunction
 wire pmem_w=covers_sector(address_i,`NPC_AXI_PMEM_BASE,`NPC_AXI_PMEM_MASK);
 wire psram_w=covers_sector(address_i,`NPC_AXI_PSRAM_BASE,`NPC_AXI_PSRAM_MASK);
 wire sdram_w=covers_sector(address_i,`NPC_AXI_SDRAM_BASE,`NPC_AXI_SDRAM_MASK);
 // Include a sector entering PMEM from below, as well as one starting in it.
 wire pmem_edge_w=(address_i&`NPC_AXI_PMEM_MASK)==`NPC_AXI_PMEM_BASE||
  (address_i>=(`NPC_AXI_PMEM_BASE-64'd15)&&address_i<`NPC_AXI_PMEM_BASE);
 wire nc_w=(psram_w&&!pmem_edge_w)||sdram_w;
 // CLINT, PLIC and Goldfish reject every 16-byte register transaction.
 wire io_w=
  covers_sector(address_i,`NPC_AXI_RESET_SYSCON_BASE,`NPC_AXI_RESET_SYSCON_MASK)||
  covers_sector(address_i,`NPC_AXI_UART_BASE,`NPC_AXI_UART_MASK)||
  covers_sector(address_i,`NPC_AXI_VIRTIO_BLK_BASE,`NPC_AXI_VIRTIO_BLK_MASK)||
  covers_sector(address_i,`NPC_AXI_LEGACY_MMIO_BASE,`NPC_AXI_LEGACY_MMIO_MASK);
 wire restricted_w=(address_i&`NPC_AXI_CLINT_MASK)==`NPC_AXI_CLINT_BASE||
  (address_i&`NPC_AXI_PLIC_MASK)==`NPC_AXI_PLIC_BASE||
  (address_i&`R64_RTC_MASK)==`R64_RTC_BASE;
 assign fault_o=restricted_w||!(pmem_w||nc_w||io_w);
 assign class_o=fault_o?2'd3:(pmem_w?2'd0:(nc_w?2'd1:2'd2));
endmodule
