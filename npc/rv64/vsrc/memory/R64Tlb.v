// Shared TLB storage primitive for Sv39 I/D translation. One lookup port and
// one fill port; page sizes are 4 KiB, Svnapot 64 KiB, 2 MiB, and 1 GiB.
// Permission/A-D decisions belong to the translation stage using flags_o.
// SFENCE with an ASID preserves global entries; address-selective invalidation
// matches the entire leaf mapping, including superpages and NAPOT.
module R64Tlb #(
  parameter integer INDEX_W=4,
  parameter integer ENTRIES=(1<<INDEX_W)
) (
  input clk_i,input rst_i,
  input [63:0] vaddr_i,input [15:0] asid_i,
  output reg hit_o,
  output reg [55:0] paddr_o,
  output reg [7:0] flags_o,
  output reg [1:0] pbmt_o,
  input fill_i,input [26:0] fill_vpn_i,
  input [43:0] fill_ppn_i,input [15:0] fill_asid_i,
  input fill_global_i,input [1:0] fill_level_i,input fill_napot_i,
  input [7:0] fill_flags_i,input [1:0] fill_pbmt_i,
  input invalidate_i,input invalidate_all_vaddr_i,input invalidate_all_asid_i,
  input [26:0] invalidate_vpn_i,input [15:0] invalidate_asid_i
);
  reg [ENTRIES-1:0] valid_q,global_q,napot_q;
  reg [26:0] vpn_q[0:ENTRIES-1];
  reg [43:0] ppn_q[0:ENTRIES-1];
  reg [15:0] asid_q[0:ENTRIES-1];
  reg [1:0] level_q[0:ENTRIES-1],pbmt_q[0:ENTRIES-1];
  reg [7:0] flags_q[0:ENTRIES-1];
  reg [INDEX_W-1:0] next_q;
  wire [26:0] vpn_w=vaddr_i[38:12];
  wire [26:0] fill_vpn_w=fill_vpn_i;
  wire [26:0] invalidate_vpn_w=invalidate_vpn_i;

  function vpn_match;
    input [26:0] first,second;
    input [1:0] level;
    input napot;
    begin
      case(level)
        2'd2: vpn_match=first[26:18]==second[26:18];
        2'd1: vpn_match=first[26:9]==second[26:9];
        default: vpn_match=napot?(first[26:4]==second[26:4]):first==second;
      endcase
    end
  endfunction

  function [55:0] physical_address;
    input [43:0] ppn;
    input [1:0] level;
    input napot;
    input [29:0] offset;
    begin
      case(level)
        2'd2: physical_address={ppn[43:18],offset[29:0]};
        2'd1: physical_address={ppn[43:9],offset[20:0]};
        default: physical_address=napot?{ppn[43:4],offset[15:0]}:{ppn,offset[11:0]};
      endcase
    end
  endfunction

  wire canonical_w=vaddr_i[63:39]=={25{vaddr_i[38]}};
  wire [ENTRIES-1:0] matches_w;
  wire [ENTRIES-1:0] invalidate_w,overlap_w;
  genvar entry;
  generate for(entry=0;entry<ENTRIES;entry=entry+1) begin : gen_entry
    assign matches_w[entry]=valid_q[entry]&&canonical_w&&
      (global_q[entry]||asid_q[entry]==asid_i)&&
      vpn_match(vpn_q[entry],vpn_w,level_q[entry],napot_q[entry]);
    assign invalidate_w[entry]=invalidate_i&&
      (invalidate_all_asid_i||(!global_q[entry]&&asid_q[entry]==invalidate_asid_i))&&
      (invalidate_all_vaddr_i||vpn_match(vpn_q[entry],invalidate_vpn_w,level_q[entry],napot_q[entry]));
    assign overlap_w[entry]=(global_q[entry]||fill_global_i||asid_q[entry]==fill_asid_i)&&
      (vpn_match(vpn_q[entry],fill_vpn_w,level_q[entry],napot_q[entry])||
       vpn_match(vpn_q[entry],fill_vpn_w,fill_level_i,fill_napot_i));
  end endgenerate

  integer k;
  wire [ENTRIES-1:0] first_free_w;
  wire free_found_w;
  R64FreeSelect #(.N(ENTRIES)) free_select(.free_i(~valid_q),
    .first_o(first_free_w),.second_o(),.any_o(free_found_w),.two_o());
  reg [INDEX_W-1:0] victim_r;
  always @(*) begin
    hit_o=|matches_w;paddr_o=0;flags_o=0;pbmt_o=0;
    victim_r=free_found_w ? {INDEX_W{1'b0}}:next_q;
    for(k=0;k<ENTRIES;k=k+1) begin
      // One-hot mux rather than priority over complete physical addresses.
      paddr_o=paddr_o|({56{matches_w[k]}}&
        physical_address(ppn_q[k],level_q[k],napot_q[k],vaddr_i[29:0]));
      flags_o=flags_o|({8{matches_w[k]}}&flags_q[k]);
      pbmt_o=pbmt_o|({2{matches_w[k]}}&pbmt_q[k]);
      victim_r=victim_r|(k[INDEX_W-1:0]&{INDEX_W{first_free_w[k]}});
    end
  end

  integer n;
  always @(posedge clk_i) begin
    if(rst_i) begin valid_q<=0;next_q<=0;end
    else begin
      for(n=0;n<ENTRIES;n=n+1)
        if(invalidate_w[n]||(fill_i&&!invalidate_i&&overlap_w[n])) valid_q[n]<=0;
      // A concurrent invalidate wins over fill, including a stale walker.
      if(fill_i&&!invalidate_i) begin
        valid_q[victim_r]<=1;vpn_q[victim_r]<=fill_vpn_w;
        ppn_q[victim_r]<=fill_ppn_i;asid_q[victim_r]<=fill_asid_i;
        global_q[victim_r]<=fill_global_i;level_q[victim_r]<=fill_level_i;
        napot_q[victim_r]<=fill_napot_i;flags_q[victim_r]<=fill_flags_i;
        pbmt_q[victim_r]<=fill_pbmt_i;next_q<=victim_r+1'b1;
      end
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if(!rst_i) begin
    if((matches_w&(matches_w-1'b1))!=0) $fatal(1,"TLB overlapping matches");
    if(fill_i&&!invalidate_i&&
       (fill_level_i==3||
        (fill_level_i==2&&fill_ppn_i[17:0]!=0)||
        (fill_level_i==1&&fill_ppn_i[8:0]!=0)||
        (fill_napot_i&&(fill_level_i!=0||fill_ppn_i[3:0]!=4'b1000))))
      $fatal(1,"TLB invalid leaf alignment");
  end
`endif
endmodule
