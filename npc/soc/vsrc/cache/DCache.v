`include "define.v"

/* verilator lint_off UNUSEDSIGNAL */

module DCache (
  input clk,
  input rst,
  input invalidate_i,
  input flush_i,
  output flush_done_o,

  input cpu_req_valid_i,
  output cpu_req_ready_o,
  input cpu_req_write_i,
  input [`XLEN-1:0] cpu_req_addr_i,
  input [`XLEN-1:0] cpu_req_wdata_i,
  input [3:0] cpu_req_wstrb_i,
  output cpu_rsp_valid_o,
  input cpu_rsp_ready_i,
  output [`XLEN-1:0] cpu_rsp_rdata_o,
  output cpu_rsp_error_o,

  output axi_arvalid_o,
  input axi_arready_i,
  output [`XLEN-1:0] axi_araddr_o,
  input axi_rvalid_i,
  output axi_rready_o,
  input [`XLEN-1:0] axi_rdata_i,
  input [1:0] axi_rresp_i,

  output axi_awvalid_o,
  input axi_awready_i,
  output [`XLEN-1:0] axi_awaddr_o,
  output axi_wvalid_o,
  input axi_wready_i,
  output [`XLEN-1:0] axi_wdata_o,
  output [3:0] axi_wstrb_o,
  input axi_bvalid_i,
  output axi_bready_o,
  input [1:0] axi_bresp_i
);

  localparam LINE_WORDS = `DCACHE_LINE_WORDS;
  localparam SET_COUNT = `DCACHE_LINE_COUNT;
  localparam WAY_COUNT = `DCACHE_WAY_COUNT;
  localparam OFFSET_BITS = `DCACHE_OFFSET_BITS;
  localparam INDEX_BITS = `DCACHE_INDEX_BITS;
  localparam WORD_BITS = `DCACHE_WORD_BITS;
  localparam WAY_BITS = `DCACHE_WAY_BITS;
  localparam TAG_BITS = `XLEN - OFFSET_BITS - INDEX_BITS;
  localparam DATA_WORDS = SET_COUNT * LINE_WORDS;
  localparam DATA_INDEX_BITS = INDEX_BITS + WORD_BITS;
  localparam WAY_TAG_BITS = WAY_COUNT * TAG_BITS;
  localparam WAY_DATA_BITS = WAY_COUNT * `XLEN;
  // flush 扫描步进随 index/way 宽度参数化，避免后续容量调整时留下硬编码常量。
  localparam [INDEX_BITS-1:0] INDEX_STEP = {{(INDEX_BITS-1){1'b0}}, 1'b1};
  localparam [WORD_BITS-1:0] WORD_STEP = {{(WORD_BITS-1){1'b0}}, 1'b1};

  localparam [4:0] S_IDLE = 5'd0;
  localparam [4:0] S_LOOKUP = 5'd1;
  localparam [4:0] S_WB_AW = 5'd2;
  localparam [4:0] S_WB_B = 5'd3;
  localparam [4:0] S_FILL_AR = 5'd4;
  localparam [4:0] S_FILL_R = 5'd5;
  localparam [4:0] S_REFILL_LOOKUP = 5'd6;
  localparam [4:0] S_STORE_ALLOC_READ = 5'd7;
  localparam [4:0] S_STORE_ALLOC_UPDATE = 5'd8;
  localparam [4:0] S_UNCACHED_AR = 5'd9;
  localparam [4:0] S_UNCACHED_R = 5'd10;
  localparam [4:0] S_UNCACHED_AW = 5'd11;
  localparam [4:0] S_UNCACHED_B = 5'd12;
  localparam [4:0] S_RESP = 5'd13;
  localparam [4:0] S_FLUSH_READ = 5'd14;
  localparam [4:0] S_FLUSH_SCAN = 5'd15;
  localparam [4:0] S_FLUSH_WB_AW = 5'd16;
  localparam [4:0] S_FLUSH_WB_B = 5'd17;
  localparam [4:0] S_FLUSH_DONE = 5'd18;

  reg [4:0] state_q;
  reg req_write_q;
  reg [`XLEN-1:0] req_addr_q;
  reg [`XLEN-1:0] req_wdata_q;
  reg [3:0] req_wstrb_q;
  reg [`XLEN-1:0] fill_base_q;
  reg [INDEX_BITS-1:0] fill_index_q;
  reg [TAG_BITS-1:0] fill_tag_q;
  reg [WAY_BITS-1:0] fill_way_q;
  reg [WORD_BITS-1:0] fill_word_q;
  reg [INDEX_BITS-1:0] victim_index_q;
  reg [TAG_BITS-1:0] victim_tag_q;
  reg [WAY_BITS-1:0] victim_way_q;
  reg [WORD_BITS-1:0] wb_word_q;
  reg [INDEX_BITS-1:0] flush_index_q;
  reg [WAY_BITS-1:0] flush_way_q;
  reg [WORD_BITS-1:0] flush_word_q;
  reg axi_aw_done_q;
  reg axi_w_done_q;
  reg [`XLEN-1:0] rsp_data_q;
  reg rsp_error_q;

  // 2-way 伪 LRU：记录每个 set 下一次冲突时优先替换哪个 way。
  reg [WAY_BITS-1:0] repl_q [0:SET_COUNT-1];

  function cacheable_word;
    input [`XLEN-1:0] addr;
    begin
      cacheable_word = (addr >= `CACHEABLE_BASE) && (addr <= `CACHEABLE_LAST);
    end
  endfunction

  function [INDEX_BITS-1:0] line_index;
    input [`XLEN-1:0] addr;
    begin
      line_index = addr[OFFSET_BITS + INDEX_BITS - 1:OFFSET_BITS];
    end
  endfunction

  function [TAG_BITS-1:0] line_tag;
    input [`XLEN-1:0] addr;
    begin
      line_tag = addr[`XLEN-1:OFFSET_BITS + INDEX_BITS];
    end
  endfunction

  function [WORD_BITS-1:0] word_offset;
    input [`XLEN-1:0] addr;
    begin
      word_offset = addr[OFFSET_BITS-1:2];
    end
  endfunction

  function [DATA_INDEX_BITS-1:0] data_index;
    input [INDEX_BITS-1:0] index;
    input [WORD_BITS-1:0] word;
    begin
      data_index = {index, word};
    end
  endfunction

  function [`XLEN-1:0] line_base;
    input [`XLEN-1:0] addr;
    begin
      line_base = {addr[`XLEN-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    end
  endfunction

  function [`XLEN-1:0] byte_mask32;
    input [3:0] wstrb;
    begin
      byte_mask32 = {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}};
    end
  endfunction

  function [WAY_COUNT-1:0] way_mask;
    input [WAY_BITS-1:0] way;
    begin
      way_mask = {{(WAY_COUNT-1){1'b0}}, 1'b1} << way;
    end
  endfunction

  function [WAY_TAG_BITS-1:0] way_tag_mask;
    input [WAY_BITS-1:0] way;
    begin
      way_tag_mask = {{(WAY_TAG_BITS-TAG_BITS){1'b0}}, {TAG_BITS{1'b1}}} << (way * TAG_BITS);
    end
  endfunction

  function [TAG_BITS-1:0] way_tag;
    input [WAY_TAG_BITS-1:0] tags;
    input [WAY_BITS-1:0] way;
    begin
      way_tag = tags[way * TAG_BITS +: TAG_BITS];
    end
  endfunction

  function [`XLEN-1:0] way_word;
    input [WAY_DATA_BITS-1:0] words;
    input [WAY_BITS-1:0] way;
    begin
      way_word = words[way * `XLEN +: `XLEN];
    end
  endfunction

  function [WAY_COUNT-1:0] tag_hit_vec;
    input [WAY_COUNT-1:0] valid;
    input [WAY_TAG_BITS-1:0] tags;
    input [TAG_BITS-1:0] tag;
    integer w;
    begin
      tag_hit_vec = {WAY_COUNT{1'b0}};
      for (w = 0; w < WAY_COUNT; w = w + 1) begin
        tag_hit_vec[w] = valid[w] && (tags[w * TAG_BITS +: TAG_BITS] == tag);
      end
    end
  endfunction

  function [WAY_BITS-1:0] hit_way;
    input [WAY_COUNT-1:0] hit_vec;
    begin
      hit_way = hit_vec[0] ? {WAY_BITS{1'b0}} : {{(WAY_BITS-1){1'b0}}, 1'b1};
    end
  endfunction

  function [WAY_BITS-1:0] victim_way;
    input [WAY_COUNT-1:0] valid;
    input [WAY_BITS-1:0] repl;
    begin
      victim_way = !valid[0] ? {WAY_BITS{1'b0}} :
                   !valid[1] ? {{(WAY_BITS-1){1'b0}}, 1'b1} :
                   repl;
    end
  endfunction

  function [WAY_TAG_BITS-1:0] tag_wr_data;
    input [WAY_BITS-1:0] way;
    input [TAG_BITS-1:0] tag;
    begin
      tag_wr_data = {{(WAY_TAG_BITS-TAG_BITS){1'b0}}, tag} << (way * TAG_BITS);
    end
  endfunction

  function [WAY_DATA_BITS-1:0] way_word_data;
    input [WAY_BITS-1:0] way;
    input [`XLEN-1:0] data;
    begin
      way_word_data = {{(WAY_DATA_BITS-`XLEN){1'b0}}, data} << (way * `XLEN);
    end
  endfunction

  function [WAY_DATA_BITS-1:0] way_word_mask;
    input [WAY_BITS-1:0] way;
    input [3:0] wstrb;
    begin
      way_word_mask = {{(WAY_DATA_BITS-`XLEN){1'b0}}, byte_mask32(wstrb)} << (way * `XLEN);
    end
  endfunction

  wire req_cacheable_w = cacheable_word(req_addr_q);
  wire [INDEX_BITS-1:0] req_index_w = line_index(req_addr_q);
  wire [TAG_BITS-1:0] req_tag_w = line_tag(req_addr_q);
  wire [WORD_BITS-1:0] req_word_w = word_offset(req_addr_q);
  wire [DATA_INDEX_BITS-1:0] req_data_index_w = data_index(req_index_w, req_word_w);

  wire idle_cpu_accept_w = (state_q == S_IDLE) && !flush_i;
  wire cpu_req_fire_w = cpu_req_valid_i && cpu_req_ready_o;
  wire refill_lookup_issue_w = (state_q == S_REFILL_LOOKUP);
  wire store_alloc_read_issue_w = (state_q == S_STORE_ALLOC_READ);
  wire flush_read_issue_w = (state_q == S_FLUSH_READ);
  wire [`XLEN-1:0] lookup_issue_addr_w = cpu_req_fire_w ? cpu_req_addr_i : req_addr_q;
  wire [INDEX_BITS-1:0] lookup_issue_index_w = line_index(lookup_issue_addr_w);
  wire [WORD_BITS-1:0] lookup_issue_word_w = word_offset(lookup_issue_addr_w);
  wire [DATA_INDEX_BITS-1:0] lookup_issue_data_index_w =
      data_index(lookup_issue_index_w, lookup_issue_word_w);
  wire lookup_issue_w = cpu_req_fire_w || refill_lookup_issue_w;

  wire [WAY_COUNT-1:0] valid_rd_w;
  wire [WAY_COUNT-1:0] dirty_rd_w;
  wire [WAY_TAG_BITS-1:0] tag_rd_w;
  wire [WAY_DATA_BITS-1:0] data_rd_w;

  wire [WAY_COUNT-1:0] lookup_hit_vec_w = tag_hit_vec(valid_rd_w, tag_rd_w, req_tag_w);
  wire lookup_hit_w = |lookup_hit_vec_w;
  wire [WAY_BITS-1:0] lookup_way_w = hit_way(lookup_hit_vec_w);
  wire [WAY_BITS-1:0] victim_way_w = victim_way(valid_rd_w, repl_q[req_index_w]);
  wire [TAG_BITS-1:0] victim_tag_w = way_tag(tag_rd_w, victim_way_w);
  wire victim_dirty_w = dirty_rd_w[victim_way_w];
  wire victim_valid_w = valid_rd_w[victim_way_w];

  wire [`XLEN-1:0] lookup_data_w = way_word(data_rd_w, lookup_way_w);
  wire lookup_miss_w = (state_q == S_LOOKUP) && req_cacheable_w && !lookup_hit_w;
  wire lookup_dirty_miss_w = lookup_miss_w && victim_valid_w && victim_dirty_w;
  wire store_lookup_hit_w = (state_q == S_LOOKUP) && req_write_q &&
                            (req_wstrb_q != 4'b0000) && req_cacheable_w && lookup_hit_w;
  wire lookup_zero_store_w = (state_q == S_LOOKUP) && req_write_q &&
                             (req_wstrb_q == 4'b0000);
  wire lookup_load_hit_w = (state_q == S_LOOKUP) && !req_write_q &&
                           req_cacheable_w && lookup_hit_w;
  wire lookup_rsp_valid_w = lookup_zero_store_w || lookup_load_hit_w || store_lookup_hit_w;
  wire lookup_rsp_fire_w = lookup_rsp_valid_w && cpu_rsp_ready_i;
  // DCache data SRAM 是 1RW；store hit 同拍要写 data array，不能再接下一次读请求。
  wire lookup_can_accept_next_w = lookup_rsp_fire_w && !store_lookup_hit_w && !flush_i;
  wire store_alloc_update_w = (state_q == S_STORE_ALLOC_UPDATE);
  wire store_alloc_rsp_valid_w = store_alloc_update_w;
  wire store_update_w = store_lookup_hit_w || store_alloc_update_w;
  wire [WAY_BITS-1:0] store_update_way_w = store_alloc_update_w ? fill_way_q :
                                           lookup_way_w;

  wire [`XLEN-1:0] store_update_old_data_w = store_alloc_update_w ? way_word(data_rd_w, fill_way_q) :
                                             lookup_data_w;
  wire [`XLEN-1:0] store_update_wdata_w = req_wdata_q;
  wire [3:0] store_update_wstrb_w = req_wstrb_q;
  wire [DATA_INDEX_BITS-1:0] store_update_index_w = req_data_index_w;
  wire [`XLEN-1:0] store_update_mask_w = byte_mask32(store_update_wstrb_w);
  wire [`XLEN-1:0] store_update_data_w =
      (store_update_old_data_w & ~store_update_mask_w) | (store_update_wdata_w & store_update_mask_w);

  wire [`XLEN-1:0] fill_req_addr_w =
      fill_base_q + {{(`XLEN-WORD_BITS-2){1'b0}}, fill_word_q, 2'b00};
  wire [`XLEN-1:0] wb_base_addr_w =
      {victim_tag_q, victim_index_q, {OFFSET_BITS{1'b0}}};
  wire [`XLEN-1:0] wb_req_addr_w =
      wb_base_addr_w + {{(`XLEN-WORD_BITS-2){1'b0}}, wb_word_q, 2'b00};
  wire [`XLEN-1:0] flush_base_addr_w =
      {way_tag(tag_rd_w, flush_way_q), flush_index_q, {OFFSET_BITS{1'b0}}};
  wire [`XLEN-1:0] flush_req_addr_w =
      flush_base_addr_w + {{(`XLEN-WORD_BITS-2){1'b0}}, flush_word_q, 2'b00};
  wire [`XLEN-1:0] wb_word_data_w = way_word(data_rd_w, victim_way_q);
  wire [`XLEN-1:0] flush_word_data_w = way_word(data_rd_w, flush_way_q);
  wire fill_rsp_fire_w = (state_q == S_FILL_R) && axi_rvalid_i && axi_rready_o;
  wire fill_rsp_ok_w = fill_rsp_fire_w && (axi_rresp_i == 2'b00);
  wire fill_last_word_w = (fill_word_q == {WORD_BITS{1'b1}});
  wire fill_done_w = fill_rsp_ok_w && fill_last_word_w;
  wire line_wb_state_w = (state_q == S_WB_B) || (state_q == S_FLUSH_WB_B);
  wire line_wb_b_fire_w = line_wb_state_w && axi_bvalid_i && axi_bready_o;
  wire line_wb_b_ok_w = line_wb_b_fire_w && (axi_bresp_i == 2'b00);
  wire wb_last_word_w = (wb_word_q == {WORD_BITS{1'b1}});
  wire flush_last_word_w = (flush_word_q == {WORD_BITS{1'b1}});
  wire flush_last_way_w = (flush_way_q == {{(WAY_BITS-1){1'b0}}, 1'b1});
  wire flush_last_index_w = (flush_index_q == {INDEX_BITS{1'b1}});
  wire wb_done_line_w = (state_q == S_WB_B) && line_wb_b_ok_w && wb_last_word_w;
  wire flush_wb_done_line_w = (state_q == S_FLUSH_WB_B) &&
                              line_wb_b_ok_w && flush_last_word_w;
  wire flush_dirty_line_w = valid_rd_w[flush_way_q] && dirty_rd_w[flush_way_q];
  wire [WORD_BITS-1:0] wb_next_word_w = wb_word_q + WORD_STEP;
  wire [WORD_BITS-1:0] flush_next_word_w = flush_word_q + WORD_STEP;
  wire lookup_wb_read_issue_w = lookup_dirty_miss_w;
  wire wb_next_read_issue_w = (state_q == S_WB_B) && line_wb_b_ok_w && !wb_last_word_w;
  wire flush_dirty_read_issue_w = (state_q == S_FLUSH_SCAN) && flush_dirty_line_w;
  wire flush_next_read_issue_w = (state_q == S_FLUSH_WB_B) &&
                                 line_wb_b_ok_w && !flush_last_word_w;
  wire meta_rd_en_w = lookup_issue_w || flush_read_issue_w;
  wire [INDEX_BITS-1:0] meta_rd_index_sel_w = flush_read_issue_w ?
                                              flush_index_q :
                                              lookup_issue_index_w;
  wire data_rd_en_w = lookup_issue_w || store_alloc_read_issue_w ||
                      lookup_wb_read_issue_w || wb_next_read_issue_w ||
                      flush_dirty_read_issue_w || flush_next_read_issue_w;
  wire [DATA_INDEX_BITS-1:0] data_rd_index_w =
      lookup_wb_read_issue_w ? data_index(req_index_w, {WORD_BITS{1'b0}}) :
      wb_next_read_issue_w ? data_index(victim_index_q, wb_next_word_w) :
      flush_dirty_read_issue_w ? data_index(flush_index_q, {WORD_BITS{1'b0}}) :
      flush_next_read_issue_w ? data_index(flush_index_q, flush_next_word_w) :
      store_alloc_read_issue_w ? req_data_index_w :
      lookup_issue_data_index_w;

  wire data_wr_en_w = fill_rsp_ok_w || store_update_w;
  wire [DATA_INDEX_BITS-1:0] data_wr_addr_w = fill_rsp_ok_w ?
                                               data_index(fill_index_q, fill_word_q) :
                                               store_update_index_w;
  wire [WAY_DATA_BITS-1:0] data_wr_data_w = fill_rsp_ok_w ?
                                            way_word_data(fill_way_q, axi_rdata_i) :
                                            way_word_data(store_update_way_w, store_update_data_w);
  wire [WAY_DATA_BITS-1:0] data_wr_mask_w = fill_rsp_ok_w ?
                                            way_word_mask(fill_way_q, 4'b1111) :
                                            way_word_mask(store_update_way_w, store_update_wstrb_w);

  wire valid_wr_en_w = fill_done_w;
  wire tag_wr_en_w = fill_done_w;
  wire dirty_wr_en_w = fill_done_w || wb_done_line_w ||
                       flush_wb_done_line_w || store_update_w;
  wire [INDEX_BITS-1:0] dirty_wr_addr_w = store_update_w ?
                                           req_index_w :
                                           (wb_done_line_w ? victim_index_q :
                                            (flush_wb_done_line_w ? flush_index_q : fill_index_q));
  wire [WAY_BITS-1:0] dirty_wr_way_w = store_update_w ? store_update_way_w :
                                       (wb_done_line_w ? victim_way_q :
                                        (flush_wb_done_line_w ? flush_way_q : fill_way_q));
  wire [WAY_COUNT-1:0] dirty_wr_data_w = store_update_w ? way_mask(store_update_way_w) :
                                         {WAY_COUNT{1'b0}};

  wire axi_write_state_w = (state_q == S_WB_AW) ||
                           (state_q == S_UNCACHED_AW) ||
                           (state_q == S_FLUSH_WB_AW);
  wire axi_aw_fire_w = axi_awvalid_o && axi_awready_i;
  wire axi_w_fire_w = axi_wvalid_o && axi_wready_i;
  wire axi_write_done_w = axi_write_state_w &&
                          (axi_aw_done_q || axi_aw_fire_w) &&
                          (axi_w_done_q || axi_w_fire_w);
  wire wb_axi_write_fire_w = ((state_q == S_WB_AW) ||
                              (state_q == S_FLUSH_WB_AW)) && axi_write_done_w;

  assign flush_done_o = (state_q == S_FLUSH_DONE);
  assign cpu_req_ready_o = idle_cpu_accept_w || lookup_can_accept_next_w;
  assign cpu_rsp_valid_o = (state_q == S_RESP) || lookup_rsp_valid_w ||
                           store_alloc_rsp_valid_w;
  assign cpu_rsp_rdata_o = (state_q == S_RESP) ? rsp_data_q :
                           (lookup_load_hit_w ? lookup_data_w : {`XLEN{1'b0}});
  assign cpu_rsp_error_o = (state_q == S_RESP) ? rsp_error_q : 1'b0;

  assign axi_arvalid_o = (state_q == S_FILL_AR) || (state_q == S_UNCACHED_AR);
  assign axi_araddr_o = (state_q == S_UNCACHED_AR) ? req_addr_q : fill_req_addr_w;
  assign axi_rready_o = (state_q == S_FILL_R) || (state_q == S_UNCACHED_R);

  assign axi_awvalid_o = axi_write_state_w && !axi_aw_done_q;
  assign axi_awaddr_o = (state_q == S_UNCACHED_AW) ? req_addr_q :
                         (state_q == S_FLUSH_WB_AW) ? flush_req_addr_w :
                         wb_req_addr_w;
  assign axi_wvalid_o = axi_write_state_w && !axi_w_done_q;
  assign axi_wdata_o = (state_q == S_UNCACHED_AW) ? req_wdata_q :
                       (state_q == S_FLUSH_WB_AW) ? flush_word_data_w :
                       wb_word_data_w;
  assign axi_wstrb_o = (state_q == S_UNCACHED_AW) ? req_wstrb_q : 4'b1111;
  assign axi_bready_o = (state_q == S_WB_B) ||
                        (state_q == S_UNCACHED_B) ||
                        (state_q == S_FLUSH_WB_B);

  Sram1Rw #(
    .DATA_WIDTH(WAY_COUNT),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(SET_COUNT)
  ) u_valid_sram (
    .clk(clk),
    .clear_i(rst | invalidate_i | flush_done_o),
    .rd_en_i(meta_rd_en_w),
    .rd_addr_i(meta_rd_index_sel_w),
    .rd_data_o(valid_rd_w),
    .wr_en_i(valid_wr_en_w),
    .wr_addr_i(fill_index_q),
    .wr_data_i(way_mask(fill_way_q)),
    .wr_mask_i(way_mask(fill_way_q))
  );

  Sram1Rw #(
    .DATA_WIDTH(WAY_COUNT),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(SET_COUNT)
  ) u_dirty_sram (
    .clk(clk),
    .clear_i(rst | invalidate_i | flush_done_o),
    .rd_en_i(meta_rd_en_w),
    .rd_addr_i(meta_rd_index_sel_w),
    .rd_data_o(dirty_rd_w),
    .wr_en_i(dirty_wr_en_w),
    .wr_addr_i(dirty_wr_addr_w),
    .wr_data_i(dirty_wr_data_w),
    .wr_mask_i(way_mask(dirty_wr_way_w))
  );

  Sram1Rw #(
    .DATA_WIDTH(WAY_TAG_BITS),
    .ADDR_WIDTH(INDEX_BITS),
    .DEPTH(SET_COUNT)
  ) u_tag_sram (
    .clk(clk),
    .clear_i(rst),
    .rd_en_i(meta_rd_en_w),
    .rd_addr_i(meta_rd_index_sel_w),
    .rd_data_o(tag_rd_w),
    .wr_en_i(tag_wr_en_w),
    .wr_addr_i(fill_index_q),
    .wr_data_i(tag_wr_data(fill_way_q, fill_tag_q)),
    .wr_mask_i(way_tag_mask(fill_way_q))
  );

  Sram1Rw #(
    .DATA_WIDTH(WAY_DATA_BITS),
    .ADDR_WIDTH(DATA_INDEX_BITS),
    .DEPTH(DATA_WORDS)
  ) u_data_sram (
    .clk(clk),
    .clear_i(rst),
    .rd_en_i(data_rd_en_w),
    .rd_addr_i(data_rd_index_w),
    .rd_data_o(data_rd_w),
    .wr_en_i(data_wr_en_w),
    .wr_addr_i(data_wr_addr_w),
    .wr_data_i(data_wr_data_w),
    .wr_mask_i(data_wr_mask_w)
  );

  integer repl_i;
  always @(posedge clk) begin
    if (rst) begin
      for (repl_i = 0; repl_i < SET_COUNT; repl_i = repl_i + 1) begin
        repl_q[repl_i] <= {WAY_BITS{1'b0}};
      end
      state_q <= S_IDLE;
      req_write_q <= 1'b0;
      req_addr_q <= {`XLEN{1'b0}};
      req_wdata_q <= {`XLEN{1'b0}};
      req_wstrb_q <= 4'b0000;
      fill_base_q <= {`XLEN{1'b0}};
      fill_index_q <= {INDEX_BITS{1'b0}};
      fill_tag_q <= {TAG_BITS{1'b0}};
      fill_way_q <= {WAY_BITS{1'b0}};
      fill_word_q <= {WORD_BITS{1'b0}};
      victim_index_q <= {INDEX_BITS{1'b0}};
      victim_tag_q <= {TAG_BITS{1'b0}};
      victim_way_q <= {WAY_BITS{1'b0}};
      wb_word_q <= {WORD_BITS{1'b0}};
      flush_index_q <= {INDEX_BITS{1'b0}};
      flush_way_q <= {WAY_BITS{1'b0}};
      flush_word_q <= {WORD_BITS{1'b0}};
      axi_aw_done_q <= 1'b0;
      axi_w_done_q <= 1'b0;
      rsp_data_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
    end else if (invalidate_i) begin
      state_q <= S_IDLE;
      fill_word_q <= {WORD_BITS{1'b0}};
      wb_word_q <= {WORD_BITS{1'b0}};
      flush_index_q <= {INDEX_BITS{1'b0}};
      flush_way_q <= {WAY_BITS{1'b0}};
      flush_word_q <= {WORD_BITS{1'b0}};
      axi_aw_done_q <= 1'b0;
      axi_w_done_q <= 1'b0;
      rsp_error_q <= 1'b0;
    end else begin
      if (fill_done_w) begin
        repl_q[fill_index_q] <= ~fill_way_q;
      end

      case (state_q)
        S_IDLE: begin
          if (flush_i) begin
            flush_index_q <= {INDEX_BITS{1'b0}};
            flush_way_q <= {WAY_BITS{1'b0}};
            flush_word_q <= {WORD_BITS{1'b0}};
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_FLUSH_READ;
          end else if (cpu_req_fire_w) begin
            req_write_q <= cpu_req_write_i;
            req_addr_q <= cpu_req_addr_i;
            req_wdata_q <= cpu_req_wdata_i;
            req_wstrb_q <= cpu_req_wstrb_i;
            state_q <= S_LOOKUP;
          end
        end

        S_LOOKUP: begin
          if (req_write_q) begin
            if (req_wstrb_q == 4'b0000) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b0;
              if (!cpu_rsp_ready_i) begin
                state_q <= S_RESP;
              end else if (cpu_req_fire_w) begin
                req_write_q <= cpu_req_write_i;
                req_addr_q <= cpu_req_addr_i;
                req_wdata_q <= cpu_req_wdata_i;
                req_wstrb_q <= cpu_req_wstrb_i;
                state_q <= S_LOOKUP;
              end else begin
                state_q <= S_IDLE;
              end
            end else if (!req_cacheable_w) begin
              axi_aw_done_q <= 1'b0;
              axi_w_done_q <= 1'b0;
              state_q <= S_UNCACHED_AW;
            end else if (lookup_hit_w) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b0;
              repl_q[req_index_w] <= ~lookup_way_w;
              if (!cpu_rsp_ready_i) begin
                state_q <= S_RESP;
              end else begin
                state_q <= S_IDLE;
              end
            end else begin
              fill_base_q <= line_base(req_addr_q);
              fill_index_q <= req_index_w;
              fill_tag_q <= req_tag_w;
              fill_way_q <= victim_way_w;
              fill_word_q <= {WORD_BITS{1'b0}};
              victim_index_q <= req_index_w;
              victim_tag_q <= victim_tag_w;
              victim_way_q <= victim_way_w;
              wb_word_q <= {WORD_BITS{1'b0}};
              axi_aw_done_q <= 1'b0;
              axi_w_done_q <= 1'b0;
              state_q <= (victim_valid_w && victim_dirty_w) ? S_WB_AW : S_FILL_AR;
            end
          end else if (!req_cacheable_w) begin
            state_q <= S_UNCACHED_AR;
          end else if (lookup_hit_w) begin
            rsp_data_q <= lookup_data_w;
            rsp_error_q <= 1'b0;
            repl_q[req_index_w] <= ~lookup_way_w;
            if (!cpu_rsp_ready_i) begin
              state_q <= S_RESP;
            end else if (cpu_req_fire_w) begin
              req_write_q <= cpu_req_write_i;
              req_addr_q <= cpu_req_addr_i;
              req_wdata_q <= cpu_req_wdata_i;
              req_wstrb_q <= cpu_req_wstrb_i;
              state_q <= S_LOOKUP;
            end else begin
              state_q <= S_IDLE;
            end
          end else begin
            fill_base_q <= line_base(req_addr_q);
            fill_index_q <= req_index_w;
            fill_tag_q <= req_tag_w;
            fill_way_q <= victim_way_w;
            fill_word_q <= {WORD_BITS{1'b0}};
            victim_index_q <= req_index_w;
            victim_tag_q <= victim_tag_w;
            victim_way_q <= victim_way_w;
            wb_word_q <= {WORD_BITS{1'b0}};
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= (victim_valid_w && victim_dirty_w) ? S_WB_AW : S_FILL_AR;
          end
        end

        S_REFILL_LOOKUP: begin
          state_q <= S_LOOKUP;
        end

        S_WB_AW: begin
          axi_aw_done_q <= axi_aw_done_q | axi_aw_fire_w;
          axi_w_done_q <= axi_w_done_q | axi_w_fire_w;
          if (axi_write_done_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_WB_B;
          end
        end

        S_WB_B: begin
          if (axi_bvalid_i) begin
            if (axi_bresp_i != 2'b00) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b1;
              state_q <= S_RESP;
            end else if (wb_last_word_w) begin
              wb_word_q <= {WORD_BITS{1'b0}};
              state_q <= S_FILL_AR;
            end else begin
              wb_word_q <= wb_next_word_w;
              state_q <= S_WB_AW;
            end
          end
        end

        S_FILL_AR: begin
          if (axi_arready_i) begin
            state_q <= S_FILL_R;
          end
        end

        S_FILL_R: begin
          if (axi_rvalid_i) begin
            if (axi_rresp_i != 2'b00) begin
              rsp_data_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b1;
              state_q <= S_RESP;
            end else if (fill_last_word_w) begin
              fill_word_q <= {WORD_BITS{1'b0}};
              state_q <= req_write_q ? S_STORE_ALLOC_READ : S_REFILL_LOOKUP;
            end else begin
              fill_word_q <= fill_word_q + WORD_STEP;
              state_q <= S_FILL_AR;
            end
          end
        end

        S_STORE_ALLOC_READ: begin
          state_q <= S_STORE_ALLOC_UPDATE;
        end

        S_STORE_ALLOC_UPDATE: begin
          rsp_data_q <= {`XLEN{1'b0}};
          rsp_error_q <= 1'b0;
          state_q <= cpu_rsp_ready_i ? S_IDLE : S_RESP;
        end

        S_UNCACHED_AR: begin
          if (axi_arready_i) begin
            state_q <= S_UNCACHED_R;
          end
        end

        S_UNCACHED_R: begin
          if (axi_rvalid_i) begin
            rsp_data_q <= axi_rdata_i;
            rsp_error_q <= (axi_rresp_i != 2'b00);
            state_q <= S_RESP;
          end
        end

        S_UNCACHED_AW: begin
          axi_aw_done_q <= axi_aw_done_q | axi_aw_fire_w;
          axi_w_done_q <= axi_w_done_q | axi_w_fire_w;
          if (axi_write_done_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_UNCACHED_B;
          end
        end

        S_UNCACHED_B: begin
          if (axi_bvalid_i) begin
            rsp_data_q <= {`XLEN{1'b0}};
            rsp_error_q <= (axi_bresp_i != 2'b00);
            state_q <= S_RESP;
          end
        end

        S_FLUSH_READ: begin
          flush_word_q <= {WORD_BITS{1'b0}};
          state_q <= S_FLUSH_SCAN;
        end

        S_FLUSH_SCAN: begin
          flush_word_q <= {WORD_BITS{1'b0}};
          if (flush_dirty_line_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_FLUSH_WB_AW;
          end else if (flush_last_way_w && flush_last_index_w) begin
            state_q <= S_FLUSH_DONE;
          end else if (flush_last_way_w) begin
            flush_way_q <= {WAY_BITS{1'b0}};
            flush_index_q <= flush_index_q + INDEX_STEP;
            state_q <= S_FLUSH_READ;
          end else begin
            flush_way_q <= flush_way_q + {{(WAY_BITS-1){1'b0}}, 1'b1};
          end
        end

        S_FLUSH_WB_AW: begin
          axi_aw_done_q <= axi_aw_done_q | axi_aw_fire_w;
          axi_w_done_q <= axi_w_done_q | axi_w_fire_w;
          if (axi_write_done_w) begin
            axi_aw_done_q <= 1'b0;
            axi_w_done_q <= 1'b0;
            state_q <= S_FLUSH_WB_B;
          end
        end

        S_FLUSH_WB_B: begin
          if (axi_bvalid_i) begin
            if (axi_bresp_i != 2'b00) begin
              state_q <= S_FLUSH_DONE;
            end else if (flush_last_word_w) begin
              flush_word_q <= {WORD_BITS{1'b0}};
              if (flush_last_way_w && flush_last_index_w) begin
                state_q <= S_FLUSH_DONE;
              end else if (flush_last_way_w) begin
                flush_way_q <= {WAY_BITS{1'b0}};
                flush_index_q <= flush_index_q + INDEX_STEP;
                state_q <= S_FLUSH_READ;
              end else begin
                flush_way_q <= flush_way_q + {{(WAY_BITS-1){1'b0}}, 1'b1};
                state_q <= S_FLUSH_SCAN;
              end
            end else begin
              flush_word_q <= flush_next_word_w;
              state_q <= S_FLUSH_WB_AW;
            end
          end
        end

        S_FLUSH_DONE: begin
          state_q <= flush_i ? S_FLUSH_DONE : S_IDLE;
        end

        S_RESP: begin
          if (cpu_rsp_ready_i) begin
            state_q <= S_IDLE;
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule
