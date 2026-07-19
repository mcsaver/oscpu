`include "define.v"

// 【SRAM 同步读】读口为单口两拍协议: 发射拍 lookup_en+lookup_addr, tick 后判决拍
// 观测 lookup_hit/lookup_line(针对锁存地址)。原 req/walk 双组合视图的 hit/data
// expect 全部改经 issue_lookup(插 tick); 纯地址组合视图(cacheable/line_cross)
// 仍同拍 #1 观测。窗口移位与跨线阻断职责移至桥判决拍, 由 tb_ooo_mem_axi_bridge
// 的 unaligned-hit/跨线读场景审核。
// 【store RMW·write-update 赎回】真 store commit(store_rmw_en=1)走 2 拍 RMW:
// commit 拍占宏口读, 次拍(rmw_busy=1)tag match 则线内字节合并写，并以
// 全 1 tag mask 幂等写回锁存 tag。
// commit_store 任务同步审核 rmw_busy 恰为发射次拍; 一期"无条件失效"预期全部
// 重写为 write-update 预期。A/D 维护路(store_rmw_en=0)与 PBMT NC/IO
// 路(store_cacheable=0)保持无条件失效，后者证明不 RMW 但会清理热别名。
// INDEX_W 固定 12(Sram4096x113 宏定死), TB 不再用小参数覆盖。
module tb_ooo_data_word_cache;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg dma_invalidate_all;

  reg [`XLEN-1:0] req_lookup_addr;
  reg [3:0] req_nbytes;
  wire req_cacheable;
  wire req_line_cross;

  reg [`XLEN-1:0] walk_lookup_addr;
  wire walk_cacheable;

  reg lookup_en;
  reg [`XLEN-1:0] lookup_addr;
  wire lookup_hit;
  wire [`XLEN-1:0] lookup_line;

  reg fill_valid;
  reg [`XLEN-1:0] fill_addr;
  reg [`XLEN-1:0] fill_data;

  reg store_commit;
  reg store_rmw_en;
  reg store_cacheable;
  reg [`XLEN-1:0] store_addr;
  reg [`XLEN-1:0] store_wdata;
  reg [`STRB_W-1:0] store_wstrb;
  wire rmw_busy;

  localparam [`XLEN-1:0] WORD0 = `NPC_AXI_PMEM_BASE + 64'h0000_1000;
  localparam [`XLEN-1:0] WORD1 = `NPC_AXI_PMEM_BASE + 64'h0000_1008;
  localparam [`XLEN-1:0] WORD2 = `NPC_AXI_PMEM_BASE + 64'h0000_1010;
  // 与 WORD0 同 index(addr[14:3])异 tag 的别名行(write-update 不误伤检查用)
  localparam [`XLEN-1:0] ALIAS0 = WORD0 + 64'h0000_8000;
  localparam [`XLEN-1:0] MMIO_WORD = 64'h0000_0000_1000_0000;

  OooDataWordCache dut (
    .clk(clk),
    .rst(rst),
    .dma_invalidate_all_i(dma_invalidate_all),
    .req_lookup_addr_i(req_lookup_addr),
    .req_nbytes_i(req_nbytes),
    .req_cacheable_o(req_cacheable),
    .req_line_cross_o(req_line_cross),
    .walk_lookup_addr_i(walk_lookup_addr),
    .walk_cacheable_o(walk_cacheable),
    .lookup_en_i(lookup_en),
    .lookup_addr_i(lookup_addr),
    .lookup_hit_o(lookup_hit),
    .lookup_line_o(lookup_line),
    .fill_valid_i(fill_valid),
    .fill_addr_i(fill_addr),
    .fill_data_i(fill_data),
    .store_commit_i(store_commit),
    .store_rmw_en_i(store_rmw_en),
    .store_cacheable_i(store_cacheable),
    .store_addr_i(store_addr),
    .store_wdata_i(store_wdata),
    .store_wstrb_i(store_wstrb),
    .rmw_busy_o(rmw_busy)
  );

  OooDataWordCacheChecker u_checker (
    .clk(clk),
    .rst(rst),
    .dma_invalidate_all_i(dma_invalidate_all),
    .req_lookup_addr_i(req_lookup_addr),
    .req_nbytes_i(req_nbytes),
    .req_cacheable_i(req_cacheable),
    .req_line_cross_i(req_line_cross),
    .walk_lookup_addr_i(walk_lookup_addr),
    .walk_cacheable_i(walk_cacheable),
    .lookup_en_i(lookup_en),
    .lookup_addr_i(lookup_addr),
    .lookup_hit_i(lookup_hit),
    .fill_valid_i(fill_valid),
    .fill_addr_i(fill_addr),
    .store_commit_i(store_commit),
    .store_rmw_en_i(store_rmw_en),
    .store_cacheable_i(store_cacheable),
    .store_addr_i(store_addr),
    .store_wdata_i(store_wdata),
    .store_wstrb_i(store_wstrb),
    .rmw_busy_i(rmw_busy)
  );

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic clear_inputs;
    begin
      req_lookup_addr = WORD0;
      dma_invalidate_all = 1'b0;
      req_nbytes = 4'd8;
      walk_lookup_addr = WORD0;
      lookup_en = 1'b0;
      lookup_addr = {`XLEN{1'b0}};
      fill_valid = 1'b0;
      fill_addr = {`XLEN{1'b0}};
      fill_data = {`XLEN{1'b0}};
      store_commit = 1'b0;
      store_rmw_en = 1'b0;
      store_cacheable = 1'b1;
      store_addr = {`XLEN{1'b0}};
      store_wdata = {`XLEN{1'b0}};
      store_wstrb = {`STRB_W{1'b0}};
    end
  endtask

  task automatic fill_word;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    begin
      fill_addr = addr;
      fill_data = data;
      fill_valid = 1'b1;
      tick();
      fill_valid = 1'b0;
      #1;
    end
  endtask

  // store commit: 发射拍拉 store_commit(RMW 路该拍占宏口读), tick 后判决拍
  // 审核 rmw_busy 恰位(cacheable RMW 路=1, A/D 维护路与 uncacheable=0),
  // 再 tick 走完判决拍(RMW 写落宏)并确认 busy 回落——两拍窗口内不发 lookup,
  // 与桥侧 req_ready 压制的合同一致(checker DWC-RMW-PORT 把关)。
  task automatic commit_store;
    input [`XLEN-1:0] addr;
    input [`STRB_W-1:0] strb;
    input [`XLEN-1:0] data;
    input rmw_en;
    input transaction_cacheable;
    reg busy_exp_r;
    begin
      busy_exp_r =
          rmw_en && transaction_cacheable &&
          ((addr & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
      store_addr = addr;
      store_wstrb = strb;
      store_wdata = data;
      store_rmw_en = rmw_en;
      store_cacheable = transaction_cacheable;
      store_commit = 1'b1;
      tick();
      store_commit = 1'b0;
      #1;
      tb_check1("rmw busy tracks decision cycle", rmw_busy, busy_exp_r);
      tick();
      #1;
      tb_check1("rmw busy deasserts after decision", rmw_busy, 1'b0);
    end
  endtask

  // 单读口两拍: 发射拍拉 en, tick 后即判决拍——调用方随后观测 lookup_hit/line。
  task automatic issue_lookup;
    input [`XLEN-1:0] addr;
    begin
      lookup_addr = addr;
      lookup_en = 1'b1;
      tick();
      lookup_en = 1'b0;
      #1;
    end
  endtask

  // T4P DMA coherence: full invalidate does not own the 1RW SRAM port, but it
  // has highest valid-bit priority and masks a lookup already in its decision
  // cycle.  Exercise every existing SRAM owner collision explicitly.
  task automatic dma_invalidate_conflicts;
    begin
      // Basic all-line clear and refill recovery.
      fill_word(WORD0, 64'h1111_2222_3333_4444);
      fill_word(WORD1, 64'h5555_6666_7777_8888);
      dma_invalidate_all = 1'b1;
      tick();
      dma_invalidate_all = 1'b0;
      #1;
      issue_lookup(WORD0);
      tb_check1("dma invalidate clears word0", lookup_hit, 1'b0);
      issue_lookup(WORD1);
      tb_check1("dma invalidate clears word1", lookup_hit, 1'b0);

      // Existing lookup decision and invalidate overlap: hit must be masked
      // before the clearing edge, so bridge hit-fusion cannot leak stale data.
      fill_word(WORD0, 64'haaaa_bbbb_cccc_dddd);
      lookup_addr = WORD0;
      lookup_en = 1'b1;
      tick();
      lookup_en = 1'b0;
      dma_invalidate_all = 1'b1;
      #1;
      tb_check1("dma masks lookup decision immediately", lookup_hit, 1'b0);
      tick();
      dma_invalidate_all = 1'b0;
      #1;

      // Lookup issue may still use the macro port; the same edge clears valid,
      // hence its following decision is a miss.
      fill_word(WORD0, 64'h0102_0304_0506_0708);
      lookup_addr = WORD0;
      lookup_en = 1'b1;
      dma_invalidate_all = 1'b1;
      tick();
      lookup_en = 1'b0;
      dma_invalidate_all = 1'b0;
      #1;
      tb_check1("dma plus lookup issue resolves miss", lookup_hit, 1'b0);
      tick();

      // Fill may write SRAM in the invalidate edge, but must not set valid.
      fill_addr = WORD0;
      fill_data = 64'hdead_beef_cafe_f00d;
      fill_valid = 1'b1;
      dma_invalidate_all = 1'b1;
      tick();
      fill_valid = 1'b0;
      dma_invalidate_all = 1'b0;
      #1;
      issue_lookup(WORD0);
      tb_check1("dma wins over same-cycle fill valid", lookup_hit, 1'b0);

      // RMW start keeps its busy cadence, but the cleared line makes its
      // decision miss/no-write.
      fill_word(WORD0, 64'h1111_2222_3333_4444);
      store_addr = WORD0;
      store_wstrb = 8'hff;
      store_wdata = 64'h9999_aaaa_bbbb_cccc;
      store_rmw_en = 1'b1;
      store_commit = 1'b1;
      dma_invalidate_all = 1'b1;
      tick();
      store_commit = 1'b0;
      dma_invalidate_all = 1'b0;
      #1;
      tb_check1("dma plus rmw-start preserves busy cadence", rmw_busy, 1'b1);
      tick();
      #1;
      tb_check1("dma plus rmw-start busy clears", rmw_busy, 1'b0);
      issue_lookup(WORD0);
      tb_check1("dma plus rmw-start leaves line invalid", lookup_hit, 1'b0);

      // Invalidate on the RMW decision edge also wins over the SRAM write.
      fill_word(WORD0, 64'h0123_4567_89ab_cdef);
      store_addr = WORD0;
      store_wstrb = 8'h0f;
      store_wdata = 64'h0000_0000_5566_7788;
      store_rmw_en = 1'b1;
      store_commit = 1'b1;
      tick();
      store_commit = 1'b0;
      dma_invalidate_all = 1'b1;
      #1;
      tb_check1("rmw decision active before dma edge", rmw_busy, 1'b1);
      tick();
      dma_invalidate_all = 1'b0;
      #1;
      tb_check1("dma plus rmw-decision busy clears", rmw_busy, 1'b0);
      issue_lookup(WORD0);
      tb_check1("dma wins over same-cycle rmw decision", lookup_hit, 1'b0);

      fill_word(WORD0, 64'hfeed_face_1234_5678);
      issue_lookup(WORD0);
      tb_check1("post-dma refill hits again", lookup_hit, 1'b1);
      tb_check64("post-dma refill data", lookup_line,
                 64'hfeed_face_1234_5678);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;

    // 纯地址组合视图: 同拍观测(0-cycle 合同保持)
    req_lookup_addr = WORD0;
    walk_lookup_addr = WORD0;
    #1;
    tb_check1("reset req cacheable", req_cacheable, 1'b1);
    tb_check1("reset walk cacheable", walk_cacheable, 1'b1);
    issue_lookup(WORD0);
    tb_check1("reset lookup miss", lookup_hit, 1'b0);

    fill_word(WORD0, 64'h0011_2233_4455_6677);
    issue_lookup(WORD0);
    tb_check1("fill lookup hit", lookup_hit, 1'b1);
    tb_check64("fill lookup line", lookup_line, 64'h0011_2233_4455_6677);
    // 原 walk 组合视图与 req 合并为同一单口: 再查一次代表 walk 用途
    issue_lookup(WORD0);
    tb_check1("fill second lookup hit (walk path shares port)", lookup_hit,
              1'b1);
    tb_check64("fill second lookup line", lookup_line,
               64'h0011_2233_4455_6677);
    // 判决拍之外 hit 必须为 0(两拍协议: hit 只在发射次拍有效)
    tick();
    tb_check1("hit deasserts outside decision cycle", lookup_hit, 1'b0);

    // 非对齐窗口: line_cross 组合视图 + 同 line 命中返回原始 line
    // (窗口右移已移至桥判决拍, 由 tb_ooo_mem_axi_bridge 审核移位值)
    req_lookup_addr = WORD0 + 64'd3;
    req_nbytes = 4'd4;
    #1;
    tb_check1("unaligned 4B not cross", req_line_cross, 1'b0);
    issue_lookup(WORD0 + 64'd3);
    tb_check1("unaligned lookup hits same line", lookup_hit, 1'b1);
    tb_check64("lookup returns raw line (shift moved to bridge)",
               lookup_line, 64'h0011_2233_4455_6677);

    // 跨线窗口组合检测(跨线阻断 hit 的职责在桥判决拍 read_cross_q,
    // 由 tb_ooo_mem_axi_bridge 的跨线读场景审核)
    req_lookup_addr = WORD0 + 64'd6;
    req_nbytes = 4'd4;
    #1;
    tb_check1("cross-line window detected", req_line_cross, 1'b1);
    req_lookup_addr = WORD0;
    req_nbytes = 4'd8;
    #1;

    // 【store RMW·write-update】命中线内字节合并: 低 4B 覆盖, 高 4B 保持,
    // line 依旧有效(一期无条件失效预期废止)。故意把当前无效的 fill_addr
    // 留在同 index 异 tag 的 ALIAS0，反证 RMW tag 幂等写回错误取 live fill
    // payload（正确 owner 必须是 commit 拍锁存的 rmw_tag_q）。
    fill_addr = ALIAS0;
    fill_data = 64'hface_cafe_dead_beef;
    fill_valid = 1'b0;
    commit_store(WORD0, 8'b0000_1111, 64'haabb_ccdd_1122_3344, 1'b1, 1'b1);
    issue_lookup(WORD0);
    tb_check1("rmw store keeps line valid", lookup_hit, 1'b1);
    tb_check64("rmw store merges low bytes", lookup_line,
               64'h0011_2233_1122_3344);
    issue_lookup(ALIAS0);
    tb_check1("rmw tag ignores inactive live fill payload", lookup_hit, 1'b0);

    // 偏移合并: off=4 的 2B store 只覆盖 byte4..5(窗口数据低位起)
    commit_store(WORD0 + 64'd4, 8'b0000_0011,
                 64'h0000_0000_0000_8899, 1'b1, 1'b1);
    issue_lookup(WORD0);
    tb_check1("offset rmw store keeps line valid", lookup_hit, 1'b1);
    tb_check64("offset rmw store merges bytes 4..5", lookup_line,
               64'h0011_8899_1122_3344);

    // write-no-allocate: miss 行(未 fill)store 不建行也不误动他行
    commit_store(WORD1, 8'b1111_1111, 64'hdead_dead_dead_dead, 1'b1, 1'b1);
    issue_lookup(WORD1);
    tb_check1("full store miss no allocate (line model)", lookup_hit, 1'b0);

    commit_store(WORD2, 8'b0000_1111, 64'hdead_dead_dead_dead, 1'b1, 1'b1);
    issue_lookup(WORD2);
    tb_check1("partial store miss no allocate", lookup_hit, 1'b0);

    // write-update 主收益: 同 index 异 tag 的 store miss 不再误清原行
    commit_store(ALIAS0, 8'b1111_1111,
                 64'h5a5a_5a5a_5a5a_5a5a, 1'b1, 1'b1);
    issue_lookup(WORD0);
    tb_check1("alias-index store miss keeps victim line", lookup_hit, 1'b1);
    tb_check64("alias-index store miss keeps victim data", lookup_line,
               64'h0011_8899_1122_3344);
    issue_lookup(ALIAS0);
    tb_check1("alias-index store no allocate", lookup_hit, 1'b0);

    // Fill 仍拥有完整 tag：同 index 换 tag 后新行命中、旧行必须失配。
    fill_word(ALIAS0, 64'h1357_9bdf_2468_ace0);
    issue_lookup(ALIAS0);
    tb_check1("alias replacement fill owns full tag", lookup_hit, 1'b1);
    tb_check64("alias replacement fill data", lookup_line,
               64'h1357_9bdf_2468_ace0);
    fill_word(WORD0, 64'h0f1e_2d3c_4b5a_6978);
    issue_lookup(WORD0);
    tb_check1("same-index replacement restores word0 tag", lookup_hit, 1'b1);
    issue_lookup(ALIAS0);
    tb_check1("same-index replacement evicts alias tag", lookup_hit, 1'b0);

    // 跨线 store: 本行照常线内合并(掩码截断=线内字节), 下一行保守失效
    fill_word(WORD0, 64'h1111_2222_3333_4444);
    fill_word(WORD1, 64'h5555_6666_7777_8888);
    issue_lookup(WORD0);
    tb_check1("cross-store setup word0 hit", lookup_hit, 1'b1);
    issue_lookup(WORD1);
    tb_check1("cross-store setup word1 hit", lookup_hit, 1'b1);
    commit_store(WORD0 + 64'd6, 8'b0000_1111,
                 64'h0000_0000_aabb_ccdd, 1'b1, 1'b1);
    issue_lookup(WORD0);
    tb_check1("cross-line store updates first line in-line bytes",
              lookup_hit, 1'b1);
    tb_check64("cross-line store merged bytes 6..7", lookup_line,
               64'hccdd_2222_3333_4444);
    issue_lookup(WORD1);
    tb_check1("cross-line store invalidates second line", lookup_hit, 1'b0);

    // A/D PTE 写回维护路(store_rmw_en=0): 保持一期无条件失效, 无 RMW 两拍窗口
    fill_word(WORD2, 64'h9999_8888_7777_6666);
    issue_lookup(WORD2);
    tb_check1("ad-maintenance setup hit", lookup_hit, 1'b1);
    commit_store(WORD2, 8'b1111_1111,
                 64'h0badc0de_0badc0de, 1'b0, 1'b1);
    issue_lookup(WORD2);
    tb_check1("ad-maintenance store invalidates unconditionally",
              lookup_hit, 1'b0);

    // A PMEM PA may be accessed through a PBMT NC/IO mapping after the same PA
    // was cached through a default-PBMT mapping.  The external store must not
    // RMW the cached line, but B completion must invalidate that stale alias.
    fill_word(WORD2, 64'hfeed_face_cafe_beef);
    issue_lookup(WORD2);
    tb_check1("pbmt-nc setup creates hot cacheable alias", lookup_hit, 1'b1);
    commit_store(WORD2, 8'b1111_1111,
                 64'h0123_4567_89ab_cdef, 1'b1, 1'b0);
    issue_lookup(WORD2);
    tb_check1("pbmt-nc store invalidates hot alias without rmw",
              lookup_hit, 1'b0);

    // The same conservative rule spans both lines for a cross-line NC/IO
    // store; neither line may remain as a stale cacheable alias.
    fill_word(WORD0, 64'h1111_2222_3333_4444);
    fill_word(WORD1, 64'h5555_6666_7777_8888);
    commit_store(WORD0 + 64'd6, 8'b0000_1111,
                 64'h0000_0000_aabb_ccdd, 1'b1, 1'b0);
    issue_lookup(WORD0);
    tb_check1("pbmt-nc cross-store invalidates first hot alias",
              lookup_hit, 1'b0);
    issue_lookup(WORD1);
    tb_check1("pbmt-nc cross-store invalidates second hot alias",
              lookup_hit, 1'b0);
    store_cacheable = 1'b1;

    dma_invalidate_conflicts();

    // MMIO: 组合视图不 cacheable, store commit 无 RMW(busy 恒 0), 判决必 miss
    commit_store(MMIO_WORD, 8'b1111_1111,
                 64'h1234_5678_9abc_def0, 1'b1, 1'b0);
    req_lookup_addr = MMIO_WORD;
    walk_lookup_addr = MMIO_WORD;
    #1;
    tb_check1("mmio req not cacheable", req_cacheable, 1'b0);
    tb_check1("mmio walk not cacheable", walk_cacheable, 1'b0);
    issue_lookup(MMIO_WORD);
    tb_check1("mmio lookup miss", lookup_hit, 1'b0);

    tb_finish("tb_ooo_data_word_cache");
  end
endmodule
