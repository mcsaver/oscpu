`include "define.v"

// 【LSQ Phase2+3】数据 cache: 对齐 8B line 语义(重写)。
//
// 旧 byte-window 模型 entry 按「访问起始地址」精确匹配——同一 8B 数据的不同
// 访问偏移(0x1000 的 lw 与 0x1004 的 lw)是两个 entry, 短步进访问模式在直映
// 下互踢, CoreMark 实测 dcache load miss 47.6%(274k/576k), 且容量加大零收益
// (miss 全是窗口互踢, 非容量)。
//
// 新模型: entry = 对齐 8B line(index=addr[3+IW-1:3], tag=高位)。
// - 命中判定: 访问窗口落在单一 line 内(不跨线)且 tag 命中;
//   命中数据 = line >> (addr[2:0]*8)(给桥的窗口视图, 与旧接口语义一致——
//   下游 LSU 只消费低 size 字节)。
// - 跨线窗口(misaligned 跨 8B): req_line_cross_o=1, 桥按「窗口读、不 fill」
//   走 uncached 直读(正确性优先, 罕见路径)。
// - fill: 桥对不跨线 miss 发对齐 AR(addr&~7), fill_addr_i 须 8B 对齐。
// - store 合并: 不跨线 → line 内 wstrb<<off 精确合并(write-update, 保热);
//   跨线 store → 相关两线保守失效。write-no-allocate(miss 不建行)。
module OooDataWordCache #(
  parameter INDEX_W = 10,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,

  input [`XLEN-1:0] req_lookup_addr_i,
  // 本访问的字节窗口宽度(桥侧 wstrb popcount)
  input [3:0] req_nbytes_i,
  output req_cacheable_o,
  output req_hit_o,
  output req_line_cross_o,
  output [`XLEN-1:0] req_data_o,

  input [`XLEN-1:0] walk_lookup_addr_i,
  output walk_cacheable_o,
  output walk_hit_o,
  output [`XLEN-1:0] walk_data_o,

  input fill_valid_i,
  input [`XLEN-1:0] fill_addr_i,   // 须 8B 对齐(桥保证)
  input [`XLEN-1:0] fill_data_i,   // 对齐 line 数据

  input store_commit_i,
  input store_invalidate_all_i,
  input [`XLEN-1:0] store_addr_i,
  input [`XLEN-1:0] store_data_i,  // 窗口数据(低位起)
  input [`STRB_W-1:0] store_wstrb_i
);

  localparam TAG_W = `XLEN - 3 - INDEX_W;

  reg [ENTRY_COUNT-1:0] valid_q;
  reg [TAG_W-1:0] tag_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] data_q [0:ENTRY_COUNT-1];

  function [INDEX_W-1:0] line_index;
    input [`XLEN-1:0] addr;
    begin
      line_index = addr[INDEX_W+2:3];
    end
  endfunction

  function [TAG_W-1:0] line_tag;
    input [`XLEN-1:0] addr;
    begin
      line_tag = addr[`XLEN-1:INDEX_W+3];
    end
  endfunction

  function cacheable_addr;
    input [`XLEN-1:0] addr;
    begin
      cacheable_addr = ((addr & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
    end
  endfunction

  function [3:0] nbytes_from_wstrb;
    input [`STRB_W-1:0] wstrb;
    integer nb_i;
    begin
      nbytes_from_wstrb = 4'd0;
      for (nb_i = 0; nb_i < `STRB_W; nb_i = nb_i + 1)
        if (wstrb[nb_i])
          nbytes_from_wstrb = nbytes_from_wstrb + 4'd1;
      if (nbytes_from_wstrb == 4'd0)
        nbytes_from_wstrb = 4'd1;
    end
  endfunction

  function [`XLEN-1:0] merge_bytes;
    input [`XLEN-1:0] old_data;
    input [`XLEN-1:0] new_data;
    input [`STRB_W-1:0] mask;
    begin
      merge_bytes = {
          mask[7] ? new_data[63:56] : old_data[63:56],
          mask[6] ? new_data[55:48] : old_data[55:48],
          mask[5] ? new_data[47:40] : old_data[47:40],
          mask[4] ? new_data[39:32] : old_data[39:32],
          mask[3] ? new_data[31:24] : old_data[31:24],
          mask[2] ? new_data[23:16] : old_data[23:16],
          mask[1] ? new_data[15:8]  : old_data[15:8],
          mask[0] ? new_data[7:0]   : old_data[7:0]
      };
    end
  endfunction

  // ---- req(load/翻译后数据访问)----
  wire [2:0] req_off_w = req_lookup_addr_i[2:0];
  wire [INDEX_W-1:0] req_idx_w = line_index(req_lookup_addr_i);
  wire req_cross_w =
      ({1'b0, req_off_w} + req_nbytes_i) > 5'd8;
  assign req_cacheable_o = cacheable_addr(req_lookup_addr_i);
  assign req_line_cross_o = req_cross_w;
  assign req_hit_o =
      req_cacheable_o && !req_cross_w && valid_q[req_idx_w] &&
      (tag_q[req_idx_w] == line_tag(req_lookup_addr_i));
  // 窗口视图: line 右移 off 字节(下游只消费低 nbytes 字节)
  assign req_data_o = data_q[req_idx_w] >> {req_off_w, 3'b000};

  // ---- walk(PTW 8B 对齐读)----
  wire [INDEX_W-1:0] walk_idx_w = line_index(walk_lookup_addr_i);
  assign walk_cacheable_o = cacheable_addr(walk_lookup_addr_i);
  assign walk_hit_o =
      walk_cacheable_o && valid_q[walk_idx_w] &&
      (tag_q[walk_idx_w] == line_tag(walk_lookup_addr_i));
  assign walk_data_o = data_q[walk_idx_w];

  // ---- store 合并/失效 ----
  wire [2:0] st_off_w = store_addr_i[2:0];
  wire [3:0] st_nbytes_w = nbytes_from_wstrb(store_wstrb_i);
  wire st_cross_w = ({1'b0, st_off_w} + st_nbytes_w) > 5'd8;
  wire [INDEX_W-1:0] st_idx_w = line_index(store_addr_i);
  wire [INDEX_W-1:0] st_idx_p1_w = st_idx_w + {{(INDEX_W-1){1'b0}}, 1'b1};
  wire st_cacheable_w = cacheable_addr(store_addr_i);
  wire st_hit_w =
      st_cacheable_w && valid_q[st_idx_w] &&
      (tag_q[st_idx_w] == line_tag(store_addr_i));
  // line 视角的合并掩码/数据(窗口左移 off 字节)
  wire [`STRB_W-1:0] st_line_mask_w = store_wstrb_i << st_off_w;
  wire [`XLEN-1:0] st_line_data_w = store_data_i << {st_off_w, 3'b000};

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      if (fill_valid_i && cacheable_addr(fill_addr_i)) begin
        valid_q[line_index(fill_addr_i)] <= 1'b1;
        tag_q[line_index(fill_addr_i)] <= line_tag(fill_addr_i);
        data_q[line_index(fill_addr_i)] <= fill_data_i;
      end

      if (store_commit_i) begin
        if (store_invalidate_all_i) begin
          valid_q <= {ENTRY_COUNT{1'b0}};
        end else if (st_cacheable_w) begin
          if (!st_cross_w) begin
            if (st_hit_w) begin
              // write-update: 命中线内字节精确合并(短步进 store→load 保热)
              data_q[st_idx_w] <=
                  merge_bytes(data_q[st_idx_w], st_line_data_w,
                              st_line_mask_w);
            end
            // miss 不分配也无需失效: line 对齐模型下同 index 不同 tag 即
            // 不同物理行, 无窗口别名(旧模型的三邻域失效由此消灭)。
          end else begin
            // 跨线 store: 相关两线保守失效
            if (valid_q[st_idx_w] &&
                (tag_q[st_idx_w] == line_tag(store_addr_i)))
              valid_q[st_idx_w] <= 1'b0;
            if (valid_q[st_idx_p1_w] &&
                (tag_q[st_idx_p1_w] ==
                 line_tag(store_addr_i + {{(`XLEN-4){1'b0}}, 4'd8})))
              valid_q[st_idx_p1_w] <= 1'b0;
          end
        end
      end
    end
  end

endmodule
