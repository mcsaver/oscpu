`include "define.v"

module tb_ooo_mem_axi_bridge;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;
  reg mmu_flush;

  reg [1:0] priv_mode;
  reg [`XLEN-1:0] mstatus;
  reg [`XLEN-1:0] satp;
  reg svpbmt_en;

  reg mem0_req_valid;
  wire mem0_req_ready;
  reg mem0_req_write;
  reg mem0_req_probe;
  reg mem0_req_pretrans;
  reg mem0_req_nokill;
  reg [`XLEN-1:0] mem0_req_addr;
  reg [`XLEN-1:0] mem0_req_wdata;
  reg [`STRB_W-1:0] mem0_req_wstrb;
  wire mem0_rsp_valid;
  reg mem0_rsp_ready;
  wire [`XLEN-1:0] mem0_rsp_rdata;
  wire mem0_rsp_error;
  wire mem0_rsp_page_fault;
  wire mem_translate_active;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
  wire [2:0] lsu_axi_arsize;
  reg lsu_axi_rvalid;
  wire lsu_axi_rready;
  reg [`XLEN-1:0] lsu_axi_rdata;
  reg [1:0] lsu_axi_rresp;
  wire lsu_axi_awvalid;
  reg lsu_axi_awready;
  wire [`XLEN-1:0] lsu_axi_awaddr;
  wire lsu_axi_wvalid;
  reg lsu_axi_wready;
  wire [`XLEN-1:0] lsu_axi_wdata;
  wire [`STRB_W-1:0] lsu_axi_wstrb;
  reg lsu_axi_bvalid;
  wire lsu_axi_bready;
  reg [1:0] lsu_axi_bresp;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] DATA_VA = 64'h0000_0000_8000_3000;
  localparam [`XLEN-1:0] DATA_PA = 64'h0000_0000_8000_3000;
  // A/D 更新测试专用数据地址(同超页同 leaf PTE=ROOT_PT+16, 但不同 PA), 避免 store
  // 污染 DATA_PA 的物理 dcache(mmu_flush 不清物理索引 dcache)干扰后续 dtlb 测试。
  localparam [`XLEN-1:0] DATA_VA_AD = 64'h0000_0000_8000_a000;
  localparam [`XLEN-1:0] DATA_PA_AD = 64'h0000_0000_8000_a000;
  localparam [`XLEN-1:0] ROOT_PPN = ROOT_PT >> 12;
  localparam [`XLEN-1:0] SUPERPAGE_PPN =
      64'h0000_0000_8000_0000 >> 12;
  localparam [`XLEN-1:0] LEAF_FLAGS = 64'h0cf;
  localparam [`XLEN-1:0] LEAF_NO_ACCESS_FLAGS = 64'h08f;
  localparam [`XLEN-1:0] LEAF_NO_DIRTY_FLAGS = 64'h04f;
  localparam [`XLEN-1:0] SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | LEAF_FLAGS;
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR = {`PMP_ADDR_BUS_W{1'b1}};

  OooMemAxiBridge dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .mmu_flush_i(mmu_flush),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .satp_i(satp),
    .svpbmt_en_i(svpbmt_en),
    .pmpcfg_i(PMP_ALLOW_ALL_CFG),
    .pmpaddr_i(PMP_ALLOW_ALL_ADDR),
    .mem0_req_valid_i(mem0_req_valid),
    .mem0_req_ready_o(mem0_req_ready),
    .mem0_req_write_i(mem0_req_write),
    .mem0_req_probe_i(mem0_req_probe),
    .mem0_req_pretrans_i(mem0_req_pretrans),
    .mem0_req_nokill_i(mem0_req_nokill),
    .mem0_req_addr_i(mem0_req_addr),
    .mem0_req_wdata_i(mem0_req_wdata),
    .mem0_req_wstrb_i(mem0_req_wstrb),
    .mem0_rsp_valid_o(mem0_rsp_valid),
    .mem0_rsp_ready_i(mem0_rsp_ready),
    .mem0_rsp_rdata_o(mem0_rsp_rdata),
    .mem0_rsp_error_o(mem0_rsp_error),
    .mem0_rsp_page_fault_o(mem0_rsp_page_fault),
    .translate_active_o(mem_translate_active),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
    .lsu_axi_arsize_o(lsu_axi_arsize),
    .lsu_axi_rvalid_i(lsu_axi_rvalid),
    .lsu_axi_rready_o(lsu_axi_rready),
    .lsu_axi_rdata_i(lsu_axi_rdata),
    .lsu_axi_rresp_i(lsu_axi_rresp),
    .lsu_axi_awvalid_o(lsu_axi_awvalid),
    .lsu_axi_awready_i(lsu_axi_awready),
    .lsu_axi_awaddr_o(lsu_axi_awaddr),
    .lsu_axi_wvalid_o(lsu_axi_wvalid),
    .lsu_axi_wready_i(lsu_axi_wready),
    .lsu_axi_wdata_o(lsu_axi_wdata),
    .lsu_axi_wstrb_o(lsu_axi_wstrb),
    .lsu_axi_bvalid_i(lsu_axi_bvalid),
    .lsu_axi_bready_o(lsu_axi_bready),
    .lsu_axi_bresp_i(lsu_axi_bresp)
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
      flush = 1'b0;
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      mstatus = {`XLEN{1'b0}};
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      mem0_req_valid = 1'b0;
      mem0_req_write = 1'b0;
      mem0_req_probe = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_addr = {`XLEN{1'b0}};
      mem0_req_wdata = {`XLEN{1'b0}};
      mem0_req_wstrb = {`STRB_W{1'b0}};
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = {`XLEN{1'b0}};
      lsu_axi_rresp = 2'b00;
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      lsu_axi_bvalid = 1'b0;
      lsu_axi_bresp = 2'b00;
    end
  endtask

  task automatic check_svpbmt_pte_reserved_policy;
    reg [`XLEN-1:0] pbmt1_leaf;
    reg [`XLEN-1:0] pbmt2_leaf;
    reg [`XLEN-1:0] pbmt3_leaf;
    reg [`XLEN-1:0] pbmt1_nonleaf;
    reg [`XLEN-1:0] napot_leaf;
    reg [`XLEN-1:0] napot_bad_leaf;
    reg [`XLEN-1:0] napot_nonleaf;
    begin
      pbmt1_leaf = SUPERPAGE_PTE | (64'd1 << 61);
      pbmt2_leaf = SUPERPAGE_PTE | (64'd2 << 61);
      pbmt3_leaf = SUPERPAGE_PTE | (64'd3 << 61);
      pbmt1_nonleaf = ((ROOT_PT >> 12) << 10) | 64'h001 | (64'd1 << 61);
      napot_leaf =
          (SUPERPAGE_PTE & ~(64'hf << 10)) | (64'h8 << 10) | `SV39_PTE_N;
      napot_bad_leaf =
          (SUPERPAGE_PTE & ~(64'hf << 10)) | (64'h7 << 10) | `SV39_PTE_N;
      napot_nonleaf = ((ROOT_PT >> 12) << 10) | 64'h001 | `SV39_PTE_N;

      tb_check1("mem PBMT=1 leaf faults while Svpbmt disabled",
                dut.pte_reserved_fault(pbmt1_leaf, 1'b0, 2'd0), 1'b1);
      tb_check1("mem PBMT=1 leaf is legal when Svpbmt enabled",
                dut.pte_reserved_fault(pbmt1_leaf, 1'b1, 2'd0), 1'b0);
      tb_check1("mem PBMT=2 leaf is legal when Svpbmt enabled",
                dut.pte_reserved_fault(pbmt2_leaf, 1'b1, 2'd0), 1'b0);
      tb_check1("mem PBMT=3 leaf remains reserved",
                dut.pte_reserved_fault(pbmt3_leaf, 1'b1, 2'd0), 1'b1);
      tb_check1("mem non-leaf PBMT remains reserved",
                dut.pte_reserved_fault(pbmt1_nonleaf, 1'b1, 2'd1), 1'b1);
      tb_check1("mem Svnapot 64KiB leaf is legal",
                dut.pte_reserved_fault(napot_leaf, 1'b0, 2'd0), 1'b0);
      tb_check1("mem Svnapot bad ppn encoding faults",
                dut.pte_reserved_fault(napot_bad_leaf, 1'b0, 2'd0), 1'b1);
      tb_check1("mem Svnapot non-leaf faults",
                dut.pte_reserved_fault(napot_nonleaf, 1'b0, 2'd1), 1'b1);
      tb_check1("mem Svnapot level1 leaf faults",
                dut.pte_reserved_fault(napot_leaf, 1'b0, 2'd1), 1'b1);
      tb_check64("mem Svnapot PA uses VA low PPN bits",
                 dut.leaf_paddr(napot_leaf, DATA_VA, 2'd0), DATA_PA);
    end
  endtask

  task automatic issue_mem0_read;
    input [`XLEN-1:0] addr;
    begin
      issue_mem0_read_strb(addr, {`STRB_W{1'b1}});
    end
  endtask

  // 【line-dcache】读 miss 语义(AXI4 化 S3 后以 ARSIZE 表达): 不跨线 → 对齐
  // AR(addr&~7)+ARSIZE=8B(取整线); 跨线 → 原窗口 AR+ARSIZE=log2(访问宽度)。
  function automatic [3:0] strb_nbytes;
    input [`STRB_W-1:0] strb;
    integer bi;
    begin
      strb_nbytes = 4'd0;
      for (bi = 0; bi < `STRB_W; bi = bi + 1)
        if (strb[bi]) strb_nbytes = strb_nbytes + 4'd1;
      if (strb_nbytes == 4'd0) strb_nbytes = 4'd1;
    end
  endfunction

  function automatic [2:0] axsize_from_nbytes;
    input [3:0] nbytes;
    begin
      axsize_from_nbytes = (nbytes >= 4'd8) ? 3'd3 :
                           (nbytes >= 4'd4) ? 3'd2 :
                           (nbytes >= 4'd2) ? 3'd1 : 3'd0;
    end
  endfunction

  // 【刀 M·寄存站】读请求 fire 拍只进寄存站(零计算, 不发 lookup/AR); 次拍
  // stage_advance 发 dcache SRAM 读(不发 AR); 再次拍 S_LOOKUP 判决 miss 后才发
  // AR——本 task 只用于 miss 场景, AR 检查较 SRAM 同步读版再右移一拍, task 结束
  // 时桥已进 S_READ_DATA(对调用方等价)。
  task automatic issue_mem0_read_strb;
    input [`XLEN-1:0] addr;
    input [`STRB_W-1:0] strb;
    reg is_cross_r;
    begin
      is_cross_r = ({1'b0, addr[2:0]} + strb_nbytes(strb)) > 5'd8;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = addr;
      mem0_req_wstrb = strb;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("mem0 read request ready", mem0_req_ready, 1'b1);
      tb_check1("mem0 read no AR at fire", lsu_axi_arvalid, 1'b0);
      // 【刀 M·负测试锚点】fire 拍(寄存站空)不得出现 req 源 dcache lookup——
      // 对旧"fire 拍发 lookup"实现本检查必 FAIL(负测试证据存 task-runs)。
      tb_check1("mem0 read no req lookup at fire", dut.req_read_lookup_fire_w,
                1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      // advance 拍: 寄存站项进 FSM 并发 dcache lookup, AR 最早在判决拍。
      tb_check1("mem0 read advance no AR", lsu_axi_arvalid, 1'b0);
      tb_check1("mem0 read req lookup at advance", dut.req_read_lookup_fire_w,
                1'b1);
      tick();
      #1;
      tb_check1("mem0 read issues AR", lsu_axi_arvalid, 1'b1);
      tb_check64("mem0 read AR address", lsu_axi_araddr,
                 is_cross_r ? addr : {addr[`XLEN-1:3], 3'b000});
      tb_check64("mem0 read AR size", {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 is_cross_r ? {{(`XLEN-3){1'b0}}, axsize_from_nbytes(strb_nbytes(strb))}
                       : {{(`XLEN-3){1'b0}}, 3'd3});
      tick();
      lsu_axi_arready = 1'b0;
    end
  endtask

  task automatic read_arsize_tracks_load_mask;
    begin
      issue_mem0_read_strb(64'h0000_0000_8000_1005, 8'b0010_0000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0102_0304_0506_0708;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("masked read response valid", mem0_rsp_valid, 1'b1);
      // 窗口视图: 对齐 line 右移 paddr[2:0]*8(off=5)
      tb_check64("masked read window data", mem0_rsp_rdata,
                 64'h0000_0000_0001_0203);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // 【刀 M+SRAM 同步读】hit 路径统一在 S_LOOKUP 判决拍以锁存 paddr_q[2:0] 移位
  // (fire→advance→判决→S_RESP, 共 +1 拍); 本场景补两块原 cache 组合口负责、
  // SRAM 化后移到桥判决拍的语义审核:
  //   (a) unaligned hit 的窗口移位视图(接住 cache TB 里被移走的移位检查);
  //   (b) 跨线窗口即使 line 有效也必须 miss 走 AXI 原窗口读(read_cross_q 阻断
  //       hit——DWC-I2 的桥侧新落点)。
  task automatic cached_window_shift_and_cross_block;
    begin
      // (a) 前场景已 fill line 0x8000_1000=0x0102_0304_0506_0708; 同址 unaligned hit
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1005;
      mem0_req_wstrb = 8'b0010_0000;
      lsu_axi_arready = 1'b1;   // 陷阱: advance/判决拍均不得发 AR
      #1;
      tb_check1("cached window read ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("cached window advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("cached window hit no AR", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("cached window response valid", mem0_rsp_valid, 1'b1);
      tb_check64("cached window shifted data", mem0_rsp_rdata,
                 64'h0000_0000_0001_0203);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // (b) 跨线窗口(off=6, 4B): line 0x8000_1000 有效仍必须 miss(原窗口 AR,
      //     数据原样回传、不 fill)
      issue_mem0_read_strb(64'h0000_0000_8000_1006, 8'b0000_1111);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1a2b_3c4d_5e6f_7081;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("cross-line read response valid", mem0_rsp_valid, 1'b1);
      tb_check64("cross-line read data passthrough", mem0_rsp_rdata,
                 64'h1a2b_3c4d_5e6f_7081);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  task automatic held_response_flush_drop;
    begin
      // 【line-dcache】前一场景(1005 掩码读)已 fill 对齐 line 0x80001000,
      // 换未被 fill 的地址保持"miss→等 R"场景语义。
      issue_mem0_read(64'h0000_0000_8000_6000);
      #1;
      tb_check1("mem0 read waits for R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1122_3344_5566_7788;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("mem0 response is held", mem0_rsp_valid, 1'b1);
      tb_check64("mem0 held response data", mem0_rsp_rdata,
                 64'h1122_3344_5566_7788);

      flush = 1'b1;
      #1;
      tb_check1("flush hides held response", mem0_rsp_valid, 1'b0);
      tb_check1("flush blocks new request", mem0_req_ready, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("held response dropped", mem0_rsp_valid, 1'b0);
      tb_check1("bridge accepts request after held drop", mem0_req_ready, 1'b1);
    end
  endtask

  task automatic inflight_read_flush_abort;
    begin
      issue_mem0_read(64'h0000_0000_8000_3000);
      flush = 1'b1;
      #1;
      tb_check1("flush keeps current R channel ready", lsu_axi_rready, 1'b1);
      tb_check1("flush suppresses inflight response", mem0_rsp_valid, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      // 【AXI4 化 S1 契约反转】flush 后桥不再即刻空闲(旧=依赖 xbar abort 吞 R),
      // 改为本地持械等 R(drop_rsp_q)——rready 保持, 吞完残 R 才回 IDLE。
      tb_check1("flushed read keeps draining R", lsu_axi_rready, 1'b1);
      tb_check1("flushed read has no CPU response", mem0_rsp_valid, 1'b0);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hdead_dead_dead_dead;  // 残 R: 必须被吞掉不上交
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("stale R swallowed no response", mem0_rsp_valid, 1'b0);
      tb_check1("bridge idle after drain", mem0_req_ready, 1'b1);

      issue_mem0_read(64'h0000_0000_8000_3008);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'haaaa_bbbb_cccc_dddd;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("post-abort read response valid", mem0_rsp_valid, 1'b1);
      tb_check64("post-abort read response data", mem0_rsp_rdata,
                 64'haaaa_bbbb_cccc_dddd);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  task automatic partial_write_flush_drain;
    begin
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_4000;
      mem0_req_wdata = 64'h0102_0304_0506_0708;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("write request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;

      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b0;
      #1;
      // 【刀 M】advance 拍: 寄存站项进 FSM, AW/W 最早次拍可见。
      tb_check1("write advance no AW", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("write issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("write issues W", lsu_axi_wvalid, 1'b1);
      tb_check64("write AW address", lsu_axi_awaddr,
                 64'h0000_0000_8000_4000);
      tick();
      lsu_axi_awready = 1'b0;

      flush = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("flush drains remaining W", lsu_axi_wvalid, 1'b1);
      tb_check64("flush drain W data", lsu_axi_wdata,
                 64'h0102_0304_0506_0708);
      tick();
      flush = 1'b0;
      lsu_axi_wready = 1'b0;
      // 【刀 M·免费 skid】drop 窗口 ready=1: 在 B 等待拍把 correct-path load
      // 提前送进寄存站排队(旧契约此处 ready=0), advance 由 state 门挡住。
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_4100;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("write drain waits for B", lsu_axi_bready, 1'b1);
      tb_check1("write drain suppresses response", mem0_rsp_valid, 1'b0);
      tb_check1("drop window accepts into stage (skid)", mem0_req_ready, 1'b1);

      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      mem0_req_valid = 1'b0;
      #1;
      // 【store RMW×刀 M】drain store 的 B-ok 次拍是 RMW 判决拍(write-update
      // 合并落宏): bubble 观察点从旧 req_ready 压制改为寄存站保持——站内 load
      // 本拍不得 advance/发 lookup(bubble 数不变, 契约不弱化)。
      tb_check1("write drain rmw bubble holds staged load",
                dut.stage_advance_w, 1'b0);
      tb_check1("write drain rmw bubble no req lookup",
                dut.req_read_lookup_fire_w, 1'b0);
      tb_check1("write drain never exposes response", mem0_rsp_valid, 1'b0);
      tick();
      #1;
      // RMW 结束次拍: 站内 load 恢复 advance(发 lookup)。
      tb_check1("staged load advances after rmw bubble",
                dut.stage_advance_w, 1'b1);
      lsu_axi_arready = 1'b1;
      tick();
      #1;
      // 判决拍: 0x8000_4100 未 fill → miss 发 AR, 走通整条 skid load。
      tb_check1("post-drain skid load issues AR", lsu_axi_arvalid, 1'b1);
      tb_check64("post-drain skid load AR address", lsu_axi_araddr,
                 64'h0000_0000_8000_4100);
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h5a5a_a5a5_5a5a_a5a5;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("post-drain skid load response valid", mem0_rsp_valid, 1'b1);
      tb_check64("post-drain skid load response data", mem0_rsp_rdata,
                 64'h5a5a_a5a5_5a5a_a5a5);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      #1;
      tb_check1("bridge idle after write drain", mem0_req_ready, 1'b1);
    end
  endtask

  task automatic flushed_store_does_not_poison_dcache;
    begin
      issue_mem0_read(64'h0000_0000_8000_5000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1111_2222_3333_4444;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("dcache seed response valid", mem0_rsp_valid, 1'b1);
      tb_check64("dcache seed response data", mem0_rsp_rdata,
                 64'h1111_2222_3333_4444);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("aborted store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;

      flush = 1'b1;
      #1;
      tb_check1("aborted store hides response", mem0_rsp_valid, 1'b0);
      // 【刀 M】flush 拍站内 plain store 被当拍清除(未 advance 即止损, 比现状
      // 更早): 全程不得出现 AW。
      tb_check1("aborted store never issues AW", lsu_axi_awvalid, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("aborted store returns idle", mem0_req_ready, 1'b1);
      tb_check1("aborted store cleared from stage", dut.stg_valid_q, 1'b0);

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      #1;
      tb_check1("post-abort read no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【刀 M+1-cycle 同步读】hit 判定在 S_LOOKUP 判决拍(advance 次拍):
      // aborted store 未 commit 不失效 line, 判决拍命中、不发 AR。
      #1;
      tb_check1("post-abort read advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-abort read hits cache", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-abort cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("aborted store must not update dcache", mem0_rsp_rdata,
                 64'h1111_2222_3333_4444);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("committed store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("committed store advance no AW", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("committed store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("committed store issues W", lsu_axi_wvalid, 1'b1);
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("committed store waits B", lsu_axi_bready, 1'b1);
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("committed store response valid", mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("post-commit read no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【store RMW·write-update】committed store 在完成拍 2 拍 RMW 线内合并,
      // line 保持有效且已含新数据: 同址读判决拍命中, 不发 AR, 数据来自 cache
      // (与 PMEM 一致, MEM-I2 下 store 数据已落 PMEM)。
      #1;
      tb_check1("post-commit read advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-commit read hits updated line", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("post-commit cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("committed store data visible via cache hit", mem0_rsp_rdata,
                 64'haaaa_bbbb_cccc_dddd);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      mem0_req_wdata = 64'h1234_5678_9abc_def0;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("drained store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("drained store advance no AW", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("drained store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("drained store issues W", lsu_axi_wvalid, 1'b1);
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("drained store waits B", lsu_axi_bready, 1'b1);
      flush = 1'b1;
      lsu_axi_bvalid = 1'b1;
      tick();
      flush = 1'b0;
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("drained store hides response", mem0_rsp_valid, 1'b0);

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("post-drain read no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【store RMW·write-update】flush 下 drain 的 store 同样在完成拍 RMW
      // 合并进 line(untracked-over-flush 语义保持: 数据已落 PMEM, cache 与
      // PMEM 一致): 同址读命中新值, 不发 AR。
      #1;
      tb_check1("post-drain read advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-drain read hits updated line", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("post-drain cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("drained store data visible via cache hit", mem0_rsp_rdata,
                 64'h1234_5678_9abc_def0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // 【store RMW×刀 M 定向】write-update 的 2 拍 RMW 与读口仲裁:
  //   (a) store advance 拍站口即空出——back-to-back load 当拍进寄存站(免费 skid);
  //   (b) store 完成次拍(RMW 判决拍)rmw_busy 压 stage_advance——站内 load 被
  //       保持 1 bubble(观察点从旧 req_ready 压制改为寄存站保持, 契约不弱化);
  //   (c) bubble 后的同址 load 命中 RMW 合并后的 line(部分字节 wstrb 合并,
  //       数据来自 cache 而非 AXI——本场景 R 通道全程不驱动即为证明)。
  task automatic store_rmw_write_update_and_bubble;
    begin
      // 种子 fill: 读 0x8000_7000 → line = 0x1111_2222_3333_4444
      issue_mem0_read(64'h0000_0000_8000_7000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1111_2222_3333_4444;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("rmw seed response valid", mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // 低 4B 部分 store(PMEM 解耦: AW/W 完成拍即 commit=RMW 发射拍)
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_7000;
      mem0_req_wdata = 64'h0000_0000_dead_beef;
      mem0_req_wstrb = 8'b0000_1111;
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("rmw store request ready", mem0_req_ready, 1'b1);
      tick();
      // 同拍立即换上 back-to-back load 请求(考寄存站 back-to-back+RMW 保持)
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_7000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      #1;
      // store advance 拍: 站口腾出, back-to-back load 可当拍 fire 进站。
      tb_check1("rmw store advance accepts next (stage b2b)",
                mem0_req_ready, 1'b1);
      tb_check1("rmw store advance no AW yet", lsu_axi_awvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("rmw store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("rmw store issues W", lsu_axi_wvalid, 1'b1);
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      // RMW 判决拍: store 响应有效(S_RESP)且被消费, 但 rmw_busy 必须压住站内
      // load 的 advance(不发 lookup)——这就是 store 后 1 bubble 的新观察点。
      tb_check1("rmw decision cycle store response valid", mem0_rsp_valid,
                1'b1);
      tb_check1("rmw decision cycle holds staged load (1 bubble)",
                dut.stage_advance_w, 1'b0);
      tb_check1("rmw decision cycle no req lookup",
                dut.req_read_lookup_fire_w, 1'b0);
      tick();
      mem0_rsp_ready = 1'b0;
      #1;
      // bubble 之后站内 load 恢复 advance(发 lookup)。
      tb_check1("staged load advances after rmw bubble",
                dut.stage_advance_w, 1'b1);
      lsu_axi_arready = 1'b1;   // 陷阱: 命中不得发 AR
      tick();
      #1;
      tb_check1("post-rmw load hits merged line (no AR)", lsu_axi_arvalid,
                1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("post-rmw load response valid", mem0_rsp_valid, 1'b1);
      tb_check64("post-rmw load returns byte-merged data", mem0_rsp_rdata,
                 64'h1111_2222_dead_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // 解耦 store 的后台 B 由 bpend 吸收
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      tick();
    end
  endtask

  task automatic sv39_dtlb_and_paddr_cache_hit;
    begin
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("sv39 first request ready", mem0_req_ready, 1'b1);
      tb_check1("sv39 first request no direct data AR", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;

      #1;
      // 【刀 M】advance 拍才做 DTLB 判定并转 S_WALK_AR, walk AR 次拍可见。
      tb_check1("sv39 advance no walk AR yet", lsu_axi_arvalid, 1'b0);
      tick();

      #1;
      tb_check1("sv39 first walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 first walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      tb_check64("sv39 first walk AR size",
                 {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 {{(`XLEN-3){1'b0}}, 3'd3});
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 first walk waits R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SUPERPAGE_PTE;
      tick();
      lsu_axi_rvalid = 1'b0;

      #1;
      tb_check1("sv39 translated data AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 translated data AR physical", lsu_axi_araddr, DATA_PA);
      tb_check64("sv39 translated data AR size",
                 {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 {{(`XLEN-3){1'b0}}, 3'd3});
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 data waits R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hfeed_face_cafe_beef;
      tick();
      lsu_axi_rvalid = 1'b0;

      #1;
      tb_check1("sv39 first response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 first response data", mem0_rsp_rdata,
                 64'hfeed_face_cafe_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("sv39 repeat request ready", mem0_req_ready, 1'b1);
      tb_check1("sv39 repeat no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【刀 M+1-cycle 同步读】第二次同页同字访问由 DTLB + 物理 data cache 命中:
      // advance 拍 DTLB 命中发 lookup, hit 判定在 S_LOOKUP 判决拍, 全程不发
      // page-walk/data AR。
      #1;
      tb_check1("sv39 repeat advance no AXI AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("sv39 repeat request no AXI AR", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("sv39 repeat response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 repeat response data", mem0_rsp_rdata,
                 64'hfeed_face_cafe_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // 【新增·walk-hit 路径】mmu_flush 清 DTLB(物理索引 dcache 不清)后重访:
      // TLB miss → walk 读 PTE → leaf-ok 拍发 dcache 读 → S_LOOKUP 判决 hit,
      // 不发 data AR。该路径覆盖旧 walk 组合口(无移位/无跨线检查)错值 bug 的
      // 修复落点: 判决拍统一按锁存 paddr_q 移位。
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("sv39 walk-hit request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("sv39 walk-hit advance no AR yet", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("sv39 walk-hit walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 walk-hit walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("sv39 walk-hit waits PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SUPERPAGE_PTE;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("sv39 walk-hit no data AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("sv39 walk-hit response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 walk-hit response data", mem0_rsp_rdata,
                 64'hfeed_face_cafe_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
    end
  endtask

  // HW-managed A/D（Svadu，对齐 NEMU）：leaf 真权限过但 A=0(任意)/D=0(store) 不再 page fault，
  // 而是经 S_AD_UPDATE 写回 leaf PTE 置 A(D) 位、填 TLB 后续原访问：
  //   A=0 load  → 写 PTE|A → load miss 续 S_READ_ADDR(data AR) → 返回数据；
  //   D=0 store → 写 PTE|A|D → 续 S_WRITE_REQ(store AW/W→DATA_PA, PMEM decouple 提前完成)。
  // 两情形置位后 PTE 均 == SUPERPAGE_PTE(A=1,D=1)。
  task automatic sv39_leaf_ad_update;
    input [1023:0] what;
    input write_access;
    input [`XLEN-1:0] leaf_flags;
    reg [`XLEN-1:0] orig_pte;
    reg [`XLEN-1:0] ad_pte;
    begin
      orig_pte = (SUPERPAGE_PPN << 10) | leaf_flags;
      ad_pte = orig_pte | 64'h40 | (write_access ? 64'h80 : 64'h0);
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = write_access;
      mem0_req_addr = DATA_VA_AD;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1(what, mem0_req_ready, 1'b1);
      tb_check1("sv39 A/D update request no direct AXI", lsu_axi_arvalid,
                1'b0);
      tick();
      mem0_req_valid = 1'b0;

      #1;
      tb_check1("sv39 A/D update advance no AR yet", lsu_axi_arvalid, 1'b0);
      tick();

      #1;
      tb_check1("sv39 A/D update walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 A/D update walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 A/D update waits PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = orig_pte;
      tick();
      lsu_axi_rvalid = 1'b0;

      // S_AD_UPDATE：写回置位 PTE 到 leaf PTE 物理地址（全 8B），非 fault。
      #1;
      tb_check1("sv39 A/D update issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("sv39 A/D update issues W", lsu_axi_wvalid, 1'b1);
      tb_check64("sv39 A/D update write PTE address", lsu_axi_awaddr,
                 ROOT_PT + 64'd16);
      tb_check64("sv39 A/D update write PTE data", lsu_axi_wdata, ad_pte);
      tb_check1("sv39 A/D update write full strb", &lsu_axi_wstrb, 1'b1);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      lsu_axi_bvalid = 1'b1;
      lsu_axi_bresp = 2'b00;
      tick();
      lsu_axi_bvalid = 1'b0;

      if (write_access) begin
        // 续 store：AW/W 到 DATA_PA（store 数据），PMEM decouple 提前报完成。
        #1;
        tb_check1("sv39 A/D update store issues AW", lsu_axi_awvalid, 1'b1);
        tb_check64("sv39 A/D update store AW address", lsu_axi_awaddr,
                   DATA_PA_AD);
        tb_check64("sv39 A/D update store W data", lsu_axi_wdata,
                   64'haaaa_bbbb_cccc_dddd);
        lsu_axi_awready = 1'b1;
        lsu_axi_wready = 1'b1;
        tick();
        lsu_axi_awready = 1'b0;
        lsu_axi_wready = 1'b0;
        #1;
        tb_check1("sv39 A/D update store response valid", mem0_rsp_valid,
                  1'b1);
        tb_check1("sv39 A/D update store no error", mem0_rsp_error, 1'b0);
        tb_check1("sv39 A/D update store no page fault", mem0_rsp_page_fault,
                  1'b0);
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
        // decoupled PMEM store 的 B（bpend）吸收。
        lsu_axi_bvalid = 1'b1;
        tick();
        lsu_axi_bvalid = 1'b0;
      end else begin
        // 续 load miss：S_READ_ADDR → data AR(DATA_PA) → R → 返回数据。
        #1;
        tb_check1("sv39 A/D update load issues data AR", lsu_axi_arvalid,
                  1'b1);
        tb_check64("sv39 A/D update load data AR address", lsu_axi_araddr,
                   DATA_PA_AD);
        lsu_axi_arready = 1'b1;
        tick();
        lsu_axi_arready = 1'b0;
        #1;
        tb_check1("sv39 A/D update load waits R", lsu_axi_rready, 1'b1);
        lsu_axi_rvalid = 1'b1;
        lsu_axi_rdata = 64'hfeed_face_cafe_beef;
        tick();
        lsu_axi_rvalid = 1'b0;
        #1;
        tb_check1("sv39 A/D update load response valid", mem0_rsp_valid, 1'b1);
        tb_check1("sv39 A/D update load no error", mem0_rsp_error, 1'b0);
        tb_check64("sv39 A/D update load response data", mem0_rsp_rdata,
                   64'hfeed_face_cafe_beef);
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
      end

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
    end
  endtask

  // 【LSQ·SQ 切换】probe: write 探测走完翻译+PMP 后不写内存, PA 经 rsp_rdata 回传。
  task automatic probe_write_returns_pa;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_probe = 1'b1;
      mem0_req_addr = DATA_PA;
      mem0_req_wdata = 64'hdead_beef_0123_4567;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("probe request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_probe = 1'b0;
      #1;
      // 【刀 M】probe 短路判定在 advance 拍完成, rsp 次拍可见。
      tb_check1("probe advance no response yet", mem0_rsp_valid, 1'b0);
      tick();
      #1;
      tb_check1("probe response valid", mem0_rsp_valid, 1'b1);
      tb_check1("probe no error", mem0_rsp_error, 1'b0);
      tb_check1("probe no page fault", mem0_rsp_page_fault, 1'b0);
      tb_check64("probe returns PA in rdata", mem0_rsp_rdata, DATA_PA);
      tb_check1("probe does not issue AW", lsu_axi_awvalid, 1'b0);
      tb_check1("probe does not issue W", lsu_axi_wvalid, 1'b0);
      tb_check1("probe does not issue AR", lsu_axi_arvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // 【LSQ·SQ 切换×刀 M】pretrans+nokill(退休 store 落存): 跳过翻译直写 PA, 且
  // flush 期间事务照常推进(写必达)——寄存站项 flush 拍经 nokill 豁免照常
  // advance 进 FSM, 响应不被 kill 压制。
  task automatic pretrans_nokill_store_survives_flush;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_addr = DATA_PA;
      mem0_req_wdata = 64'h1122_3344_5566_7788;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("pretrans request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      // 立刻 flush: 站内 nokill 项必须在 flush 拍照常 advance 进 FSM(写必达)
      flush = 1'b1;
      #1;
      tb_check1("nokill staged item advances under flush",
                dut.stage_advance_w, 1'b1);
      tb_check1("nokill advance cycle no AW yet", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("nokill write still issues AW under flush",
                lsu_axi_awvalid, 1'b1);
      tb_check1("nokill write still issues W under flush",
                lsu_axi_wvalid, 1'b1);
      tb_check64("nokill write AW address", lsu_axi_awaddr, DATA_PA);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      // PMEM store 解耦: AW/W 落地即响应, flush 不得压制 nokill 事务的 rsp_valid
      tb_check1("nokill response valid under flush", mem0_rsp_valid, 1'b1);
      tb_check1("nokill response no error", mem0_rsp_error, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      flush = 1'b0;
      // 后台 B 由 bpend 吸收
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      tick();
    end
  endtask

  // 【刀 M·定向】寄存站 skid 保持(PSR-HOLD 型)与 flush 语义:
  //   (a) FSM 忙(等 R)期间 ready=1——plain load 提前进站排队并字段冻结
  //       (BRG-STG-HOLD 断言同拍在跑), 站满后 ready=0(单深度), flush 把未发射
  //       的 plain 项当拍清除(比现状更早止损: 全程不发任何 lookup/AR/rsp);
  //   (b) nokill(pretrans drain 落存)项 flush 拍原地存活(BRG-STG-NOKILL),
  //       flush 解除后照常 advance 完成写(写必达)。
  task automatic stage_skid_hold_and_flush_semantics;
    begin
      clear_inputs();
      tick();
      // (a) 底座: 慢读 A(miss, 不给 R)占住 FSM
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_8000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("skid base read ready", mem0_req_ready, 1'b1);
      tick();
      // A advance 拍立刻换上第二个 load B: back-to-back 进站
      mem0_req_addr = 64'h0000_0000_8000_8100;
      #1;
      tb_check1("skid back-to-back ready during advance",
                mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      // A 判决拍(miss→AR); B 在站保持: FSM 忙 → advance=0, 单深度 → ready=0
      tb_check1("skid holds while busy (no advance)",
                dut.stage_advance_w, 1'b0);
      tb_check1("skid full blocks ready", mem0_req_ready, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      // A 等 R; B 字段冻结检查(BRG-STG-HOLD 的 TB 对照)
      tb_check1("skid staged item persists", dut.stg_valid_q, 1'b1);
      tb_check64("skid staged addr frozen", dut.stg_addr_q,
                 64'h0000_0000_8000_8100);
      // flush: FSM 的 A 走读 abort(本地释放), 站内 plain B 被当拍清除
      flush = 1'b1;
      tick();
      flush = 1'b0;
      #1;
      tb_check1("flush clears staged plain load", dut.stg_valid_q, 1'b0);
      tb_check1("flushed staged load never ARs", lsu_axi_arvalid, 1'b0);
      tb_check1("bridge ready after skid flush", mem0_req_ready, 1'b1);
      tick();
      #1;
      tb_check1("no ghost AR after skid flush", lsu_axi_arvalid, 1'b0);
      tb_check1("no ghost response after skid flush", mem0_rsp_valid, 1'b0);
      // 【AXI4 化 S1】A 的残 R 排水(新契约: 桥自吞, 不再依赖 xbar abort)
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("skid flush drained back to idle", mem0_req_ready, 1'b1);

      // (b) nokill 项 flush 拍存活: 慢读 C 占 FSM, drain(nokill)进站, flush
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_8200;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("nokill-hold base read ready", mem0_req_ready, 1'b1);
      tick();
      // C advance 拍换上 drain 落存(pretrans+nokill write)进站
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_8300;
      mem0_req_wdata = 64'hc001_c0de_0000_ffff;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("nokill-hold drain enters stage", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_write = 1'b0;
      #1;
      tick();   // C 判决拍 miss→AR fire→S_READ_DATA
      lsu_axi_arready = 1'b0;
      // flush 拍: C(S_READ_DATA)本地释放; 站内 nokill 项不得被清除
      flush = 1'b1;
      #1;
      tb_check1("nokill staged survives flush cycle", dut.stg_valid_q, 1'b1);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("nokill staged still valid after flush",
                dut.stg_valid_q, 1'b1);
      // 【AXI4 化 S1】C 的残 R 先排水(drop_rsp_q 持械), 排完 nokill 才 advance
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("nokill staged advances after drain",
                dut.stage_advance_w, 1'b1);
      tick();
      #1;
      tb_check1("nokill staged store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check64("nokill staged store AW address", lsu_axi_awaddr,
                 64'h0000_0000_8000_8300);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("nokill staged store response valid", mem0_rsp_valid, 1'b1);
      tb_check1("nokill staged store no error", mem0_rsp_error, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      // 后台 B 由 bpend 吸收; 再空转一拍越过 RMW 判决拍
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      tick();
    end
  endtask

  // ===== 刀D 融合拍定向用例(load hit 流 1 拍/load 契约) =====
  // 【时序 T2】融合谓词已 tie-0(链头退回 FF), FUSION_EN=0 跳过融合契约用例;
  // 将来重新使能融合时改回 1。(c)(d) 的 flush 关断/miss 拍禁 advance 两用例
  // 与 tie-0 兼容, 保持常开。
  localparam FUSION_EN = 1'b0;
  task automatic dcache_hit_fusion_cases;
    begin
      if (FUSION_EN) begin
      // (a) 融合拍 back-to-back: 两个 hit load 连发, 稳态 1 拍/load
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;   // 陷阱: 全程不得发 AR
      #1;
      tb_check1("fusion load1 ready", mem0_req_ready, 1'b1);
      tick();                    // fire load1 进寄存站
      #1;
      tb_check1("fusion load1 advance lookup", dut.req_read_lookup_fire_w,
                1'b1);
      tick();                    // advance: load1 发 lookup, load2 fire 进站
      #1;
      // 判决拍=融合拍: load1 rsp 组合交付, 同拍 advance load2 发 lookup
      tb_check1("fusion beat rsp valid (1-cycle hit)", mem0_rsp_valid, 1'b1);
      tb_check64("fusion beat rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      tb_check1("fusion beat advances next", dut.stage_advance_w, 1'b1);
      tb_check1("fusion beat next lookup fires", dut.req_read_lookup_fire_w,
                1'b1);
      tick();                    // 融合拍结束: load2 进判决拍
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("fusion back-to-back second rsp", mem0_rsp_valid, 1'b1);
      tb_check64("fusion second rdata", mem0_rsp_rdata,
                 64'h0102_0304_0506_0708);
      tb_check1("fusion no AR throughout", lsu_axi_arvalid, 1'b0);
      tick();                    // load2 消费, 站空回 IDLE
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("fusion drain back to ready", mem0_req_ready, 1'b1);

      // (b) rsp 反压: hit 拍 rsp_ready=0 → 组合 rsp 不消费, 落寄存 S_RESP(skid)
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b0;
      #1;
      tick();                    // fire
      mem0_req_valid = 1'b0;
      #1;
      tick();                    // advance 发 lookup
      #1;
      tb_check1("stalled hit rsp valid", mem0_rsp_valid, 1'b1);
      tick();                    // 落寄存进 S_RESP
      #1;
      tb_check1("skid holds rsp", mem0_rsp_valid, 1'b1);
      tb_check64("skid holds rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      mem0_rsp_ready = 1'b1;
      tick();                    // 消费
      mem0_rsp_ready = 1'b0;

      end  // FUSION_EN (a)(b)

      // (d) miss 拍禁 advance: miss load 判决拍时站中已有下一项——advance 必须
      // 等 S_RESP 消费拍(mutation 杀手: advance 放宽到 miss 拍会覆写 paddr_q,
      // AR 地址错/事务丢失)
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_4000;  // 冷地址(miss), 与 0x8000_1000 不同 index
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;
      #1;
      tick();                    // fire miss-load 进寄存站
      mem0_req_addr = 64'h0000_0000_8000_1000;  // 下一项(hit 地址)排队
      #1;
      tick();                    // advance: miss-load 发 lookup, 下一项 fire 进站
      mem0_req_valid = 1'b0;
      #1;
      // miss 判决拍: 站有项但不得 advance(否则 paddr_q 被覆写)
      tb_check1("miss beat no advance", dut.stage_advance_w, 1'b0);
      tb_check1("miss beat no rsp", mem0_rsp_valid, 1'b0);
      tb_check1("miss beat AR fires", lsu_axi_arvalid, 1'b1);
      tb_check64("miss beat AR addr intact", lsu_axi_araddr,
                 64'h0000_0000_8000_4000);
      tick();                    // AR 握手 → S_READ_DATA
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hdead_beef_0000_4000;
      lsu_axi_rresp = 2'b00;
      #1;
      tick();                    // R beat → fill+S_RESP
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("miss resolved rsp", mem0_rsp_valid, 1'b1);
      tb_check64("miss resolved rdata", mem0_rsp_rdata,
                 64'hdead_beef_0000_4000);
      tick();                    // S_RESP 消费拍: 同拍 advance 下一项(hit)发 lookup
      #1;                        // 下一项判决拍
      if (FUSION_EN) begin
        tb_check1("queued hit rsp after miss", mem0_rsp_valid, 1'b1);
        tb_check64("queued hit rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      end else begin
        tick();                  // T2: 落寄存, S_RESP 拍交付
        #1;
        tb_check1("queued hit rsp after miss", mem0_rsp_valid, 1'b1);
        tb_check64("queued hit rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      end
      tick();
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      #1;

      // (c) flush(kill)拍融合关断: 判决拍撞 flush → 谓词含 !cpu_kill,
      // rsp 不得组合交付(p42 型污染防线), flush 分支释放 S_LOOKUP
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      #1;
      tick();                    // fire
      mem0_req_valid = 1'b0;
      #1;
      tick();                    // advance 发 lookup
      flush = 1'b1;
      #1;
      tb_check1("flush beat masks fusion rsp", mem0_rsp_valid, 1'b0);
      tick();                    // flush 分支释放 S_LOOKUP
      flush = 1'b0;
      mem0_rsp_ready = 1'b0;
      #1;
      tb_check1("flush drained back to ready", mem0_req_ready, 1'b1);
    end
  endtask

  wire unused_outputs =
      mem0_rsp_error | mem0_rsp_page_fault | (|lsu_axi_wstrb) |
      mem_translate_active;

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;
    check_svpbmt_pte_reserved_policy();

    held_response_flush_drop();
    inflight_read_flush_abort();
    read_arsize_tracks_load_mask();
    cached_window_shift_and_cross_block();
    dcache_hit_fusion_cases();
    partial_write_flush_drain();
    flushed_store_does_not_poison_dcache();
    store_rmw_write_update_and_bubble();
    sv39_leaf_ad_update("sv39 A=0 load triggers HW A update", 1'b0,
                       LEAF_NO_ACCESS_FLAGS);
    sv39_leaf_ad_update("sv39 D=0 store triggers HW D update", 1'b1,
                       LEAF_NO_DIRTY_FLAGS);
    sv39_dtlb_and_paddr_cache_hit();
    probe_write_returns_pa();
    pretrans_nokill_store_survives_flush();
    stage_skid_hold_and_flush_semantics();

    tb_check1("unused outputs settle", unused_outputs, unused_outputs);
    tb_finish("tb_ooo_mem_axi_bridge");
  end

endmodule
