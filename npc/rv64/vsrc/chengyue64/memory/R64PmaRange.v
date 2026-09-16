`include "R64PlatformMap.vh"
// Concrete platform address map, checked over the complete requested range.
// PMEM is a cached subwindow of PSRAM. Attribute crossings cannot silently use
// the wider region's policy. Output class: cached=0, noncacheable=1, IO=2, fault=3.
module R64PmaRange(
 input [63:0] address_i,input [64:0] last_i,input [4:0] size_i,
 output fault_o,output [1:0] class_o
);
 wire [64:0] last_w=last_i;
 function region_covers;
  input [63:0] first,last,base,mask;
  begin region_covers=(first&mask)==base&&(last&mask)==base;end
 endfunction
 wire pmem_w=region_covers(address_i,last_w[63:0],`NPC_AXI_PMEM_BASE,`NPC_AXI_PMEM_MASK);
 wire psram_w=region_covers(address_i,last_w[63:0],`NPC_AXI_PSRAM_BASE,`NPC_AXI_PSRAM_MASK);
 wire sdram_w=region_covers(address_i,last_w[63:0],`NPC_AXI_SDRAM_BASE,`NPC_AXI_SDRAM_MASK);
 wire pmem_edge_w=(address_i&`NPC_AXI_PMEM_MASK)==`NPC_AXI_PMEM_BASE||
                    (last_w[63:0]&`NPC_AXI_PMEM_MASK)==`NPC_AXI_PMEM_BASE;
 wire nc_w=(psram_w&&!pmem_edge_w)||sdram_w;
 wire io_w=
  region_covers(address_i,last_w[63:0],`R64_RTC_BASE,`R64_RTC_MASK)||
  region_covers(address_i,last_w[63:0],`NPC_AXI_RESET_SYSCON_BASE,`NPC_AXI_RESET_SYSCON_MASK)||
  region_covers(address_i,last_w[63:0],`NPC_AXI_CLINT_BASE,`NPC_AXI_CLINT_MASK)||
  region_covers(address_i,last_w[63:0],`NPC_AXI_PLIC_BASE,`NPC_AXI_PLIC_MASK)||
  region_covers(address_i,last_w[63:0],`NPC_AXI_UART_BASE,`NPC_AXI_UART_MASK)||
  region_covers(address_i,last_w[63:0],`NPC_AXI_VIRTIO_BLK_BASE,`NPC_AXI_VIRTIO_BLK_MASK)||
  region_covers(address_i,last_w[63:0],`NPC_AXI_LEGACY_MMIO_BASE,`NPC_AXI_LEGACY_MMIO_MASK);
 // Register transaction restrictions take precedence over generic alignment.
 // CLINT implements only MSIP32, MTIME/CMP32 halves and aligned64 pairs;
 // PLIC and Goldfish registers accept naturally aligned 32-bit accesses.
 wire clint_w=(address_i&`NPC_AXI_CLINT_MASK)==`NPC_AXI_CLINT_BASE;
 wire plic_w=(address_i&`NPC_AXI_PLIC_MASK)==`NPC_AXI_PLIC_BASE;
 wire rtc_w=(address_i&`R64_RTC_MASK)==`R64_RTC_BASE;
 wire timer_pair_w=address_i[15:0]==16'h4000||address_i[15:0]==16'hbff8;
 wire timer_half_w=timer_pair_w||address_i[15:0]==16'h4004||address_i[15:0]==16'hbffc;
 wire clint_valid_w=(size_i==4&&(address_i[15:0]==0||timer_half_w))||(size_i==8&&timer_pair_w);
 wire device_invalid_w=(clint_w&&!clint_valid_w)||((plic_w||rtc_w)&&(size_i!=4||address_i[1:0]!=0));
 assign fault_o=size_i==0||last_w[64]||device_invalid_w||!(pmem_w||nc_w||io_w);
 assign class_o=fault_o?2'd3:(pmem_w?2'd0:(nc_w?2'd1:2'd2));
endmodule
