`include "define.v"

module OooSv39Tlb #(
  parameter INDEX_W = 6,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,
  input clear_i,

  input lookup_valid_i,
  input [`XLEN-1:0] lookup_vaddr_i,
  input [`XLEN-1:0] lookup_satp_i,
  output lookup_context_hit_o,
  output [`XLEN-1:0] lookup_pte_o,
  output [1:0] lookup_level_o,
  output [`XLEN-1:0] lookup_paddr_o,

  input fill_valid_i,
  input [`XLEN-1:0] fill_vaddr_i,
  input [`XLEN-1:0] fill_satp_i,
  input [`XLEN-1:0] fill_pte_i,
  input [1:0] fill_level_i
);

  reg [ENTRY_COUNT-1:0] valid_q;
  reg [26:0] vpn_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] satp_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pte_q [0:ENTRY_COUNT-1];
  reg [1:0] level_q [0:ENTRY_COUNT-1];

  function tlb_canonical_sv39;
    input [`XLEN-1:0] vaddr;
    begin
      tlb_canonical_sv39 = (vaddr[63:39] == {25{vaddr[38]}});
    end
  endfunction

  function [INDEX_W-1:0] tlb_index;
    input [`XLEN-1:0] vaddr;
    begin
      tlb_index = vaddr[INDEX_W+11:12];
    end
  endfunction

  function [26:0] vpn_tag;
    input [`XLEN-1:0] vaddr;
    begin
      vpn_tag = vaddr[38:12];
    end
  endfunction

  function vpn_match;
    input [26:0] req_vpn;
    input [26:0] ent_vpn;
    input [1:0] level;
    begin
      case (level)
        2'd2: vpn_match = (req_vpn[26:18] == ent_vpn[26:18]);
        2'd1: vpn_match = (req_vpn[26:9] == ent_vpn[26:9]);
        default: vpn_match = (req_vpn == ent_vpn);
      endcase
    end
  endfunction

  function [`XLEN-1:0] tlb_leaf_paddr;
    input [`XLEN-1:0] pte;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      // Svnapot 64KiB leaf 的 PPN[3:0] 来自 VA[15:12]；TLB 命中必须
      // 与 page walk 首次翻译同源，避免首访正确、后续命中错译。
      tlb_leaf_paddr = {8'b0,
                    (level == 2'd2) ?
                    {pte[53:28], vaddr[29:21], vaddr[20:12]} :
                    (level == 2'd1) ?
                    {pte[53:28], pte[27:19], vaddr[20:12]} :
                    (((pte & `SV39_PTE_N) != {`XLEN{1'b0}}) ?
                     {pte[53:14], vaddr[15:12]} :
                     pte[53:10]),
                    vaddr[11:0]};
    end
  endfunction

  wire [INDEX_W-1:0] lookup_idx_w = tlb_index(lookup_vaddr_i);
  wire [INDEX_W-1:0] fill_idx_w = tlb_index(fill_vaddr_i);
  wire [26:0] lookup_vpn_w = vpn_tag(lookup_vaddr_i);

  assign lookup_context_hit_o =
      lookup_valid_i && !clear_i && tlb_canonical_sv39(lookup_vaddr_i) &&
      valid_q[lookup_idx_w] &&
      (satp_q[lookup_idx_w] == lookup_satp_i) &&
      vpn_match(lookup_vpn_w, vpn_q[lookup_idx_w], level_q[lookup_idx_w]);
  assign lookup_pte_o = pte_q[lookup_idx_w];
  assign lookup_level_o = level_q[lookup_idx_w];
  assign lookup_paddr_o =
      tlb_leaf_paddr(
          pte_q[lookup_idx_w], lookup_vaddr_i, level_q[lookup_idx_w]);

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      if (clear_i) begin
        valid_q <= {ENTRY_COUNT{1'b0}};
      end

      if (fill_valid_i) begin
        valid_q[fill_idx_w] <= 1'b1;
        vpn_q[fill_idx_w] <= vpn_tag(fill_vaddr_i);
        satp_q[fill_idx_w] <= fill_satp_i;
        pte_q[fill_idx_w] <= fill_pte_i;
        level_q[fill_idx_w] <= fill_level_i;
      end
    end
  end

endmodule
