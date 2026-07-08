`include "define.v"

// 【B-FP 簇】FP 后端一体模块(spec ooo-fp-cluster-implementation-plan.md §7)。
// 收编: FP rename(map/freelist/busytable 第二套参数化实例) + FP 发射队列 +
// FP 物理寄存器堆(64, f0 真寄存器) + 架构 FPR(committed, 恒等恢复源) +
// FP 执行簇(arith 自流水/div·sqrt 迭代器/组合类 1 拍) + 完成 FIFO(统一出 ROB done)。
//
// 分工边界(与 OooIntBackend 协作):
//  - 纯 FP 算术与 FMV/FCVT 跨域 uop 经 disp_* 进本模块(FP IQ);
//  - FP load/store 走整数 IQ mem 通道, 本模块只提供 FP 目的 alloc(fpld_alloc)/
//    store 数据源查询与读(fpst_*)/load 写回(fpld_wb, 本模块 NaN-box);
//  - GPR 目的(FCMP/FCLASS/FMV.X/FCVT.to-int)的 pdest 来自整数 rename, 结果经
//    fpwb(rd_en=1)写整数 PRF; FPR 目的结果写本模块物理堆, fpwb 仅作 ROB done 载体
//    (rd_en=0, data=FP 值供 commit 写架构 FPR)。
//  - 恢复: trap flush=map 恒等+物理堆低 32 拷架构 FPR(单拍, 照抄整数模式);
//    mispredict=ROB-walk FP 分流(walk*_fp_* 还原 map/回收 preg)+IQ age-squash+
//    执行簇 meta kill。
/* verilator lint_off UNOPTFLAT */
// 【B-FP 簇】FP 交叉 wakeup/ready 菱形使 Verilator 跨实例保守判环
// (__Vcellinp__ 端口注入形态)。行为正确性由全量测试守; 真伪甄别与
// 结构化真修(交叉唤醒打拍)列为 FP 簇收尾项。
module OooFpBackend #(
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input flush_i,
  input [2:0] frm_i,

  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input recover_active_i,

  input walk0_fp_valid_i,
  input [`REG_ADDR_W-1:0] walk0_arch_i,
  input [PHY_REG_ADDR_W-1:0] walk0_old_pdest_i,
  input [PHY_REG_ADDR_W-1:0] walk0_new_pdest_i,
  input walk1_fp_valid_i,
  input [`REG_ADDR_W-1:0] walk1_arch_i,
  input [PHY_REG_ADDR_W-1:0] walk1_old_pdest_i,
  input [PHY_REG_ADDR_W-1:0] walk1_new_pdest_i,

  input disp_valid_i,
  output disp_ready_o,
  input [ROB_INDEX_W-1:0] disp_rob_idx_i,
  input [`INST_W-1:0] disp_inst_i,
  input disp_double_i,
  input disp_frd_en_i,
  input [`REG_ADDR_W-1:0] disp_frd_arch_i,
  input disp_dst_gpr_i,
  input [PHY_REG_ADDR_W-1:0] disp_gpr_pdest_i,
  input disp_fs1_en_i,
  input [`REG_ADDR_W-1:0] disp_fs1_arch_i,
  input disp_fs2_en_i,
  input [`REG_ADDR_W-1:0] disp_fs2_arch_i,
  input disp_fs3_en_i,
  input [`REG_ADDR_W-1:0] disp_fs3_arch_i,
  input disp_gpr_src_en_i,
  input [PHY_REG_ADDR_W-1:0] disp_gpr_src_preg_i,
  input disp_gpr_src_ready_i,
  output [PHY_REG_ADDR_W-1:0] disp_frd_new_pdest_o,
  output [PHY_REG_ADDR_W-1:0] disp_frd_old_pdest_o,

  // lane1 FP 算术(与 lane0 同构; 同拍双 FP 算术=FP IQ 双 alloc, FreeList alloc1)
  input disp1_valid_i,
  output disp1_ready_o,
  input [ROB_INDEX_W-1:0] disp1_rob_idx_i,
  input [`INST_W-1:0] disp1_inst_i,
  input disp1_double_i,
  input disp1_frd_en_i,
  input [`REG_ADDR_W-1:0] disp1_frd_arch_i,
  input disp1_dst_gpr_i,
  input [PHY_REG_ADDR_W-1:0] disp1_gpr_pdest_i,
  input disp1_fs1_en_i,
  input [`REG_ADDR_W-1:0] disp1_fs1_arch_i,
  input disp1_fs2_en_i,
  input [`REG_ADDR_W-1:0] disp1_fs2_arch_i,
  input disp1_fs3_en_i,
  input [`REG_ADDR_W-1:0] disp1_fs3_arch_i,
  input disp1_gpr_src_en_i,
  input [PHY_REG_ADDR_W-1:0] disp1_gpr_src_preg_i,
  input disp1_gpr_src_ready_i,
  output [PHY_REG_ADDR_W-1:0] disp1_frd_new_pdest_o,
  output [PHY_REG_ADDR_W-1:0] disp1_frd_old_pdest_o,

  input fpld0_alloc_valid_i,
  input [`REG_ADDR_W-1:0] fpld0_alloc_arch_i,
  output [PHY_REG_ADDR_W-1:0] fpld0_new_pdest_o,
  output [PHY_REG_ADDR_W-1:0] fpld0_old_pdest_o,
  input fpld1_alloc_valid_i,
  input [`REG_ADDR_W-1:0] fpld1_alloc_arch_i,
  output [PHY_REG_ADDR_W-1:0] fpld1_new_pdest_o,
  output [PHY_REG_ADDR_W-1:0] fpld1_old_pdest_o,
  output fp_alloc0_ready_o,
  output fp_alloc1_ready_o,

  input [`REG_ADDR_W-1:0] fpst0_query_arch_i,
  output [PHY_REG_ADDR_W-1:0] fpst0_query_preg_o,
  output fpst0_query_ready_o,
  input [`REG_ADDR_W-1:0] fpst1_query_arch_i,
  output [PHY_REG_ADDR_W-1:0] fpst1_query_preg_o,
  output fpst1_query_ready_o,

  output fp_wake0_valid_o,
  output [PHY_REG_ADDR_W-1:0] fp_wake0_preg_o,
  output fp_wake1_valid_o,
  output [PHY_REG_ADDR_W-1:0] fp_wake1_preg_o,

  input [PHY_REG_ADDR_W-1:0] fpst_read_preg_i,
  output [`XLEN-1:0] fpst_read_data_o,

  input fpld_wb_valid_i,
  input [PHY_REG_ADDR_W-1:0] fpld_wb_pdest_i,
  input [`XLEN-1:0] fpld_wb_data_i,
  input fpld_wb_double_i,

  input int_wake0_valid_i,
  input [PHY_REG_ADDR_W-1:0] int_wake0_preg_i,
  input int_wake1_valid_i,
  input [PHY_REG_ADDR_W-1:0] int_wake1_preg_i,

  output [PHY_REG_ADDR_W-1:0] gpr_read_addr_o,
  input [`XLEN-1:0] gpr_read_data_i,

  output fpwb_valid_o,
  output [ROB_INDEX_W-1:0] fpwb_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] fpwb_pdest_o,
  output fpwb_rd_en_o,
  output [`XLEN-1:0] fpwb_data_o,
  output [4:0] fpwb_fflags_o,
  input fpwb_ready_i,

  input commit0_fp_valid_i,
  input [`REG_ADDR_W-1:0] commit0_fp_arch_i,
  input [`XLEN-1:0] commit0_fp_data_i,
  input [PHY_REG_ADDR_W-1:0] commit0_fp_old_pdest_i,
  input commit1_fp_valid_i,
  input [`REG_ADDR_W-1:0] commit1_fp_arch_i,
  input [`XLEN-1:0] commit1_fp_data_i,
  input [PHY_REG_ADDR_W-1:0] commit1_fp_old_pdest_i
);

  // ===========================================================================
  // 架构 FPR(committed; 收编自 NpcCoreTop, 恢复源)
  // ===========================================================================
  wire [`XLEN * `REG_NUM - 1:0] arch_fprs_flat_w;
  wire [`XLEN-1:0] arch_fpr_read_unused0_w;
  wire [`XLEN-1:0] arch_fpr_read_unused1_w;
  wire [`XLEN-1:0] arch_fpr_read_unused2_w;
  OooFpRegFile u_arch_fpr (
    .clk(clk),
    .rst(rst),
    .read0_addr_i({`REG_ADDR_W{1'b0}}),
    .read0_data_o(arch_fpr_read_unused0_w),
    .read1_addr_i({`REG_ADDR_W{1'b0}}),
    .read1_data_o(arch_fpr_read_unused1_w),
    .read2_addr_i({`REG_ADDR_W{1'b0}}),
    .read2_data_o(arch_fpr_read_unused2_w),
    .load_write_valid_i(commit0_fp_valid_i),
    .load_write_addr_i(commit0_fp_arch_i),
    .load_write_data_i(commit0_fp_data_i),
    .result_write_valid_i(commit1_fp_valid_i),
    .result_write_addr_i(commit1_fp_arch_i),
    .result_write_data_i(commit1_fp_data_i),
    .fprs_o(arch_fprs_flat_w)
  );

  // ===========================================================================
  // FP rename: 轻量专用 map + FreeList(参数化) + 自建 busy 数组(口数自由,
  // 无同拍 alloc 前视——FP 源受 lane 序约束不需要, 也避免跨模块组合环)。
  // 双 lane: lane0=disp0(算术)或 fpld0(load); lane1=disp1(算术)或 fpld1(load)。
  // ===========================================================================
  wire disp_fire_w;
  wire disp1_fire_w;
  wire disp_frd_fire_w = disp_fire_w && disp_frd_en_i;
  wire disp1_frd_fire_w = disp1_fire_w && disp1_frd_en_i;

  wire freelist_alloc0_ready_w;
  wire freelist_alloc1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] freelist_alloc0_preg_w;
  wire [PHY_REG_ADDR_W-1:0] freelist_alloc1_preg_w;
  wire fpld0_fire_w = fpld0_alloc_valid_i && fp_alloc0_ready_o && !flush_i &&
                      !recover_active_i && !kill_valid_i;
  wire fpld1_fire_w = fpld1_alloc_valid_i && fp_alloc1_ready_o && !flush_i &&
                      !recover_active_i && !kill_valid_i;
  wire alloc0_valid_w = disp_frd_fire_w || fpld0_fire_w;
  wire alloc1_valid_w = disp1_frd_fire_w || fpld1_fire_w;
  assign fp_alloc0_ready_o = freelist_alloc0_ready_w && !recover_active_i &&
                             !kill_valid_i;
  assign fp_alloc1_ready_o = freelist_alloc1_ready_w && !recover_active_i &&
                             !kill_valid_i;

  reg [PHY_REG_ADDR_W-1:0] fp_map_q [0:`REG_NUM-1];
  integer mi;

  wire [`REG_ADDR_W-1:0] lane0_frd_arch_w =
      fpld0_alloc_valid_i ? fpld0_alloc_arch_i : disp_frd_arch_i;
  wire [`REG_ADDR_W-1:0] lane1_frd_arch_w =
      fpld1_alloc_valid_i ? fpld1_alloc_arch_i : disp1_frd_arch_i;

  // lane0→lane1 同拍前视: lane1 的源/old/store 查询若撞 lane0 的 frd arch,
  // 必须看到 lane0 的新映射(preg=alloc0)且 not-ready(结果未产生, 等 wakeup)。
  // 意图版条件(valid 而非 fire)避免 ready→fire→前视 的组合环; dispatch 对
  // 原子性(lane0 不 fire 则 lane1 必不 fire)保证保守无害。
  wire lane0_frd_intent_w =
      fpld0_alloc_valid_i || (disp_valid_i && disp_frd_en_i);
  wire [PHY_REG_ADDR_W-1:0] map_lane0_old_w = fp_map_q[lane0_frd_arch_w];
  wire lane1_old_hit0_w =
      lane0_frd_intent_w && (lane1_frd_arch_w == lane0_frd_arch_w);
  wire [PHY_REG_ADDR_W-1:0] map_lane1_old_w =
      lane1_old_hit0_w ? freelist_alloc0_preg_w : fp_map_q[lane1_frd_arch_w];
  assign disp_frd_new_pdest_o = freelist_alloc0_preg_w;
  assign disp_frd_old_pdest_o = map_lane0_old_w;
  assign disp1_frd_new_pdest_o = freelist_alloc1_preg_w;
  assign disp1_frd_old_pdest_o = map_lane1_old_w;
  assign fpld0_new_pdest_o = freelist_alloc0_preg_w;
  assign fpld0_old_pdest_o = map_lane0_old_w;
  assign fpld1_new_pdest_o = freelist_alloc1_preg_w;
  assign fpld1_old_pdest_o = map_lane1_old_w;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (mi = 0; mi < `REG_NUM; mi = mi + 1) begin
        fp_map_q[mi] <= mi[PHY_REG_ADDR_W-1:0];
      end
    end else if (recover_active_i) begin
      if (walk0_fp_valid_i)
        fp_map_q[walk0_arch_i] <= walk0_old_pdest_i;
      if (walk1_fp_valid_i)
        fp_map_q[walk1_arch_i] <= walk1_old_pdest_i;
    end else begin
      // lane1 为程序序更年轻, 后写胜(同拍同 arch WAW)
      if (alloc0_valid_w)
        fp_map_q[lane0_frd_arch_w] <= freelist_alloc0_preg_w;
      if (alloc1_valid_w)
        fp_map_q[lane1_frd_arch_w] <= freelist_alloc1_preg_w;
    end
  end

  wire free0_valid_w = recover_active_i ? walk0_fp_valid_i
                                        : commit0_fp_valid_i;
  wire [PHY_REG_ADDR_W-1:0] free0_preg_w =
      recover_active_i ? walk0_new_pdest_i : commit0_fp_old_pdest_i;
  wire free1_valid_w = recover_active_i ? walk1_fp_valid_i
                                        : commit1_fp_valid_i;
  wire [PHY_REG_ADDR_W-1:0] free1_preg_w =
      recover_active_i ? walk1_new_pdest_i : commit1_fp_old_pdest_i;

  // 声明前置，iverilog 14 拒绝前向引用(实例端口连接须先声明)
  wire [`OOO_FREE_COUNT_W-1:0] fp_free_count_unused_w;
  wire fp_free_empty_unused_w;
  wire fp_free_full_unused_w;

  OooFreeList #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_fp_free_list (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .alloc0_valid_i(alloc0_valid_w),
    .alloc0_ready_o(freelist_alloc0_ready_w),
    .alloc0_preg_o(freelist_alloc0_preg_w),
    .alloc1_valid_i(alloc1_valid_w),
    .alloc1_ready_o(freelist_alloc1_ready_w),
    .alloc1_preg_o(freelist_alloc1_preg_w),
    .free0_valid_i(free0_valid_w),
    .free0_preg_i(free0_preg_w),
    .free1_valid_i(free1_valid_w),
    .free1_preg_i(free1_preg_w),
    .free_count_o(fp_free_count_unused_w),
    .empty_o(fp_free_empty_unused_w),
    .full_o(fp_free_full_unused_w)
  );

  // 自建 FP busy 数组: alloc 拍置忙(时序), wakeup 拍清(时序);
  // 查询=裸读+wakeup 同拍前视(不含 alloc 前视——lane 序保证源非同拍 alloc)。
  reg fp_busy_q [0:`OOO_PHY_REG_COUNT-1];
  integer bi;
  wire fp_result_wb_valid_w;
  wire [PHY_REG_ADDR_W-1:0] fp_result_wb_preg_w;

  function fp_src_ready;
    input [PHY_REG_ADDR_W-1:0] preg;
    input wb0_v;
    input [PHY_REG_ADDR_W-1:0] wb0_p;
    input wb1_v;
    input [PHY_REG_ADDR_W-1:0] wb1_p;
    begin
      fp_src_ready = !fp_busy_q[preg] ||
                     (wb0_v && (wb0_p == preg)) ||
                     (wb1_v && (wb1_p == preg));
    end
  endfunction

  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (bi = 0; bi < `OOO_PHY_REG_COUNT; bi = bi + 1) begin
        fp_busy_q[bi] <= 1'b0;
      end
    end else begin
      if (fp_result_wb_valid_w)
        fp_busy_q[fp_result_wb_preg_w] <= 1'b0;
      if (fpld_wb_valid_i)
        fp_busy_q[fpld_wb_pdest_i] <= 1'b0;
      // alloc 置忙晚于 wakeup 清(同拍新 alloc 必忙, NBA 后写胜)
      if (alloc0_valid_w)
        fp_busy_q[freelist_alloc0_preg_w] <= 1'b1;
      if (alloc1_valid_w)
        fp_busy_q[freelist_alloc1_preg_w] <= 1'b1;
    end
  end

  // 查询面(disp0 三源 / disp1 三源 / fpst 双口)
  wire [PHY_REG_ADDR_W-1:0] map_read_fs1_preg_w = fp_map_q[disp_fs1_arch_i];
  wire [PHY_REG_ADDR_W-1:0] map_read_fs2_preg_w = fp_map_q[disp_fs2_arch_i];
  wire [PHY_REG_ADDR_W-1:0] map_read_fs3_preg_w = fp_map_q[disp_fs3_arch_i];
  wire lane1_fs1_hit0_w =
      lane0_frd_intent_w && (disp1_fs1_arch_i == lane0_frd_arch_w);
  wire lane1_fs2_hit0_w =
      lane0_frd_intent_w && (disp1_fs2_arch_i == lane0_frd_arch_w);
  wire lane1_fs3_hit0_w =
      lane0_frd_intent_w && (disp1_fs3_arch_i == lane0_frd_arch_w);
  wire [PHY_REG_ADDR_W-1:0] map_read1_fs1_preg_w =
      lane1_fs1_hit0_w ? freelist_alloc0_preg_w : fp_map_q[disp1_fs1_arch_i];
  wire [PHY_REG_ADDR_W-1:0] map_read1_fs2_preg_w =
      lane1_fs2_hit0_w ? freelist_alloc0_preg_w : fp_map_q[disp1_fs2_arch_i];
  wire [PHY_REG_ADDR_W-1:0] map_read1_fs3_preg_w =
      lane1_fs3_hit0_w ? freelist_alloc0_preg_w : fp_map_q[disp1_fs3_arch_i];
  wire busy_fs1_w = fp_src_ready(map_read_fs1_preg_w,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  wire busy_fs2_w = fp_src_ready(map_read_fs2_preg_w,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  wire busy_fs3_w = fp_src_ready(map_read_fs3_preg_w,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  wire busy1_fs1_w = !lane1_fs1_hit0_w && fp_src_ready(map_read1_fs1_preg_w,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  wire busy1_fs2_w = !lane1_fs2_hit0_w && fp_src_ready(map_read1_fs2_preg_w,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  wire busy1_fs3_w = !lane1_fs3_hit0_w && fp_src_ready(map_read1_fs3_preg_w,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  assign fpst0_query_preg_o = fp_map_q[fpst0_query_arch_i];
  assign fpst0_query_ready_o = fp_src_ready(fpst0_query_preg_o,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);
  wire fpst1_hit0_w =
      lane0_frd_intent_w && (fpst1_query_arch_i == lane0_frd_arch_w);
  assign fpst1_query_preg_o =
      fpst1_hit0_w ? freelist_alloc0_preg_w : fp_map_q[fpst1_query_arch_i];
  assign fpst1_query_ready_o = !fpst1_hit0_w && fp_src_ready(fpst1_query_preg_o,
      fp_result_wb_valid_w, fp_result_wb_preg_w, fpld_wb_valid_i, fpld_wb_pdest_i);

  assign fp_wake0_valid_o = fp_result_wb_valid_w;
  assign fp_wake0_preg_o = fp_result_wb_preg_w;
  assign fp_wake1_valid_o = fpld_wb_valid_i;
  assign fp_wake1_preg_o = fpld_wb_pdest_i;

  // ===========================================================================
  // FP 物理寄存器堆(64, f0 真寄存器; R0-2=IQ 发射三源, R3=FP store 数据;
  // W0=执行簇 FPR 结果, W1=load 写回)
  // ===========================================================================
  wire [PHY_REG_ADDR_W-1:0] issue_fs1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue_fs2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue_fs3_preg_w;
  wire [`XLEN-1:0] issue_fs1_data_w;
  wire [`XLEN-1:0] issue_fs2_data_w;
  wire [`XLEN-1:0] issue_fs3_data_w;
  wire fp_result_wb_frd_w;
  wire [`XLEN-1:0] fp_result_wb_value_w;
  // FLW 载入 NaN-box(高 32 全 1); FLD 直存
  wire [`XLEN-1:0] fpld_boxed_data_w =
      fpld_wb_double_i ? fpld_wb_data_i
                       : {32'hffff_ffff, fpld_wb_data_i[31:0]};

  OooFpPhysRegFile #(
    .PHY_REG_COUNT(`OOO_PHY_REG_COUNT),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_fp_phys_reg_file (
    .clk(clk),
    .rst(rst),
    .recover_i(flush_i),
    .recover_fprs_i(arch_fprs_flat_w),
    .read0_addr_i(issue_fs1_preg_w),
    .read0_data_o(issue_fs1_data_w),
    .read1_addr_i(issue_fs2_preg_w),
    .read1_data_o(issue_fs2_data_w),
    .read2_addr_i(issue_fs3_preg_w),
    .read2_data_o(issue_fs3_data_w),
    .read3_addr_i(fpst_read_preg_i),
    .read3_data_o(fpst_read_data_o),
    .write0_valid_i(fp_result_wb_valid_w && fp_result_wb_frd_w),
    .write0_addr_i(fp_result_wb_preg_w),
    .write0_data_i(fp_result_wb_value_w),
    .write1_valid_i(fpld_wb_valid_i),
    .write1_addr_i(fpld_wb_pdest_i),
    .write1_data_i(fpld_boxed_data_w)
  );

  // ===========================================================================
  // FP 发射队列
  // ===========================================================================
  wire iq_dispatch_ready_w;
  wire iq_dispatch1_ready_w;
  wire issue_valid_w;
  wire issue_ready_w;
  wire [ROB_INDEX_W-1:0] issue_rob_idx_w;
  wire [`INST_W-1:0] issue_inst_w;
  wire issue_double_w;
  wire [PHY_REG_ADDR_W-1:0] issue_pdest_w;
  wire issue_dst_gpr_w;
  wire issue_dst_en_w;
  wire [PHY_REG_ADDR_W-1:0] issue_gpr_preg_w;
  // 声明前置，iverilog 14 拒绝前向引用(实例端口连接须先声明)
  wire [3:0] fp_iq_count_unused_w;

  assign disp_ready_o = iq_dispatch_ready_w &&
                        (!disp_frd_en_i || fp_alloc0_ready_o) &&
                        !recover_active_i && !kill_valid_i;
  assign disp1_ready_o = iq_dispatch1_ready_w &&
                         (!disp1_frd_en_i || fp_alloc1_ready_o) &&
                         !recover_active_i && !kill_valid_i;
  assign disp_fire_w = disp_valid_i && disp_ready_o && !flush_i;
  assign disp1_fire_w = disp1_valid_i && disp1_ready_o && !flush_i;

  OooFpIssueQueue #(
    .ENTRY_INDEX_W(3),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_fp_issue_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_valid_i(kill_valid_i),
    .kill_rob_idx_i(kill_rob_idx_i),
    .rob_head_idx_i(rob_head_idx_i),
    .recover_active_i(recover_active_i),
    .dispatch_valid_i(disp_fire_w),
    .dispatch_ready_o(iq_dispatch_ready_w),
    .dispatch_rob_idx_i(disp_rob_idx_i),
    .dispatch_inst_i(disp_inst_i),
    .dispatch_double_i(disp_double_i),
    .dispatch_pdest_i(disp_frd_en_i ? freelist_alloc0_preg_w
                                    : disp_gpr_pdest_i),
    .dispatch_dst_gpr_i(disp_dst_gpr_i),
    .dispatch_dst_en_i(disp_frd_en_i || disp_dst_gpr_i),
    .dispatch_fs1_en_i(disp_fs1_en_i),
    .dispatch_fs1_preg_i(map_read_fs1_preg_w),
    .dispatch_fs1_ready_i(busy_fs1_w),
    .dispatch_fs2_en_i(disp_fs2_en_i),
    .dispatch_fs2_preg_i(map_read_fs2_preg_w),
    .dispatch_fs2_ready_i(busy_fs2_w),
    .dispatch_fs3_en_i(disp_fs3_en_i),
    .dispatch_fs3_preg_i(map_read_fs3_preg_w),
    .dispatch_fs3_ready_i(busy_fs3_w),
    .dispatch_gpr_en_i(disp_gpr_src_en_i),
    .dispatch_gpr_preg_i(disp_gpr_src_preg_i),
    .dispatch_gpr_ready_i(disp_gpr_src_ready_i),
    .dispatch1_valid_i(disp1_fire_w),
    .dispatch1_ready_o(iq_dispatch1_ready_w),
    .dispatch1_rob_idx_i(disp1_rob_idx_i),
    .dispatch1_inst_i(disp1_inst_i),
    .dispatch1_double_i(disp1_double_i),
    .dispatch1_pdest_i(disp1_frd_en_i ? freelist_alloc1_preg_w
                                      : disp1_gpr_pdest_i),
    .dispatch1_dst_gpr_i(disp1_dst_gpr_i),
    .dispatch1_dst_en_i(disp1_frd_en_i || disp1_dst_gpr_i),
    .dispatch1_fs1_en_i(disp1_fs1_en_i),
    .dispatch1_fs1_preg_i(map_read1_fs1_preg_w),
    .dispatch1_fs1_ready_i(busy1_fs1_w),
    .dispatch1_fs2_en_i(disp1_fs2_en_i),
    .dispatch1_fs2_preg_i(map_read1_fs2_preg_w),
    .dispatch1_fs2_ready_i(busy1_fs2_w),
    .dispatch1_fs3_en_i(disp1_fs3_en_i),
    .dispatch1_fs3_preg_i(map_read1_fs3_preg_w),
    .dispatch1_fs3_ready_i(busy1_fs3_w),
    .dispatch1_gpr_en_i(disp1_gpr_src_en_i),
    .dispatch1_gpr_preg_i(disp1_gpr_src_preg_i),
    .dispatch1_gpr_ready_i(disp1_gpr_src_ready_i),
    .fp_wake0_valid_i(fp_wake0_valid_o),
    .fp_wake0_preg_i(fp_wake0_preg_o),
    .fp_wake1_valid_i(fp_wake1_valid_o),
    .fp_wake1_preg_i(fp_wake1_preg_o),
    .int_wake0_valid_i(int_wake0_valid_i),
    .int_wake0_preg_i(int_wake0_preg_i),
    .int_wake1_valid_i(int_wake1_valid_i),
    .int_wake1_preg_i(int_wake1_preg_i),
    .issue_valid_o(issue_valid_w),
    .issue_ready_i(issue_ready_w),
    .issue_rob_idx_o(issue_rob_idx_w),
    .issue_inst_o(issue_inst_w),
    .issue_double_o(issue_double_w),
    .issue_pdest_o(issue_pdest_w),
    .issue_dst_gpr_o(issue_dst_gpr_w),
    .issue_dst_en_o(issue_dst_en_w),
    .issue_fs1_preg_o(issue_fs1_preg_w),
    .issue_fs2_preg_o(issue_fs2_preg_w),
    .issue_fs3_preg_o(issue_fs3_preg_w),
    .issue_gpr_preg_o(issue_gpr_preg_w),
    .count_o(fp_iq_count_unused_w)
  );

  assign gpr_read_addr_o = issue_gpr_preg_w;

  // ===========================================================================
  // 发射级 op-select(funct7 分类, 平移自 OooFpPendingExec)
  // ===========================================================================
  localparam [6:0] F7_FADD_S = 7'b0000000, F7_FADD_D = 7'b0000001;
  localparam [6:0] F7_FSUB_S = 7'b0000100, F7_FSUB_D = 7'b0000101;
  localparam [6:0] F7_FMUL_S = 7'b0001000, F7_FMUL_D = 7'b0001001;
  localparam [6:0] F7_FDIV_S = 7'b0001100, F7_FDIV_D = 7'b0001101;
  localparam [6:0] F7_FSQRT_S = 7'b0101100, F7_FSQRT_D = 7'b0101101;
  localparam [6:0] F7_FSGNJ_S = 7'b0010000, F7_FSGNJ_D = 7'b0010001;
  localparam [6:0] F7_FMINMAX_S = 7'b0010100, F7_FMINMAX_D = 7'b0010101;
  localparam [6:0] F7_FCVT_S_D = 7'b0100000, F7_FCVT_D_S = 7'b0100001;
  localparam [6:0] F7_FCMP_S = 7'b1010000, F7_FCMP_D = 7'b1010001;
  localparam [6:0] F7_FCVT_INT_S = 7'b1101000, F7_FCVT_INT_D = 7'b1101001;
  localparam [6:0] F7_FCVT_S_INT = 7'b1100000, F7_FCVT_D_INT = 7'b1100001;
  localparam [6:0] F7_FMV_X_W = 7'b1110000, F7_FMV_X_D = 7'b1110001;
  localparam [6:0] F7_FCLASS_S = 7'b1110000, F7_FCLASS_D = 7'b1110001;
  localparam [6:0] F7_FMV_W_X = 7'b1111000, F7_FMV_D_X = 7'b1111001;

  wire [6:0] is_f7_w = issue_inst_w[31:25];
  wire is_op_fp_w = issue_inst_w[6:0] == `OPCODE_OP_FP;
  wire [2:0] eff_rm_w =
      (issue_inst_w[14:12] == 3'b111) ? frm_i : issue_inst_w[14:12];

  wire op_fma_w = (issue_inst_w[6:0] == `OPCODE_MADD) ||
                  (issue_inst_w[6:0] == `OPCODE_MSUB) ||
                  (issue_inst_w[6:0] == `OPCODE_NMSUB) ||
                  (issue_inst_w[6:0] == `OPCODE_NMADD);
  wire op_addsub_w = is_op_fp_w &&
      ((is_f7_w == F7_FADD_S) || (is_f7_w == F7_FADD_D) ||
       (is_f7_w == F7_FSUB_S) || (is_f7_w == F7_FSUB_D));
  wire op_mul_w = is_op_fp_w &&
      ((is_f7_w == F7_FMUL_S) || (is_f7_w == F7_FMUL_D));
  wire op_div_w = is_op_fp_w &&
      ((is_f7_w == F7_FDIV_S) || (is_f7_w == F7_FDIV_D));
  wire op_sqrt_w = is_op_fp_w &&
      ((is_f7_w == F7_FSQRT_S) || (is_f7_w == F7_FSQRT_D));
  wire op_long_w = op_div_w || op_sqrt_w;
  wire op_arith_w = op_addsub_w || op_mul_w || op_fma_w;
  wire op_sgnj_w = is_op_fp_w &&
      ((is_f7_w == F7_FSGNJ_S) || (is_f7_w == F7_FSGNJ_D));
  wire op_minmax_w = is_op_fp_w &&
      ((is_f7_w == F7_FMINMAX_S) || (is_f7_w == F7_FMINMAX_D));
  wire op_cmp_w = is_op_fp_w &&
      ((is_f7_w == F7_FCMP_S) || (is_f7_w == F7_FCMP_D));
  wire op_class_w = is_op_fp_w && (issue_inst_w[14:12] == 3'b001) &&
      ((is_f7_w == F7_FCLASS_S) || (is_f7_w == F7_FCLASS_D));
  wire op_mv_to_gpr_w = is_op_fp_w && (issue_inst_w[14:12] == 3'b000) &&
      ((is_f7_w == F7_FMV_X_W) || (is_f7_w == F7_FMV_X_D));
  wire op_mv_to_fpr_w = is_op_fp_w &&
      ((is_f7_w == F7_FMV_W_X) || (is_f7_w == F7_FMV_D_X));
  wire op_cvt_to_gpr_w = is_op_fp_w &&
      ((is_f7_w == F7_FCVT_S_INT) || (is_f7_w == F7_FCVT_D_INT));
  wire op_cvt_int_to_fpr_w = is_op_fp_w &&
      ((is_f7_w == F7_FCVT_INT_S) || (is_f7_w == F7_FCVT_INT_D));
  wire op_cvt_fpr_to_fpr_w = is_op_fp_w &&
      (((is_f7_w == F7_FCVT_S_D) && (issue_inst_w[24:20] == 5'b00001)) ||
       ((is_f7_w == F7_FCVT_D_S) && (issue_inst_w[24:20] == 5'b00000)));

  wire [1:0] arith_kind_w = op_fma_w ? 2'd2 : (op_mul_w ? 2'd1 : 2'd0);
  wire arith_sub_op_w = (is_f7_w == F7_FSUB_S) || (is_f7_w == F7_FSUB_D);
  wire arith_neg_prod_w = (issue_inst_w[6:0] == `OPCODE_NMSUB) ||
                          (issue_inst_w[6:0] == `OPCODE_NMADD);
  wire arith_sub_add_w = (issue_inst_w[6:0] == `OPCODE_MSUB) ||
                         (issue_inst_w[6:0] == `OPCODE_NMADD);

  // ===========================================================================
  // 完成 FIFO(深 8; 统一出 fpwb → ROB done/int PRF)。发射预算: FIFO 余量必须
  // 覆盖"本拍入队+arith 在飞(最多 5)"——count<=2 才允许发射, arith out 恒有位。
  // ===========================================================================
  reg [3:0] done_fifo_count_q;
  wire done_fifo_room_w = (done_fifo_count_q <= 4'd2);

  // 执行资源 ready
  wire long_div_busy_w;
  wire long_sqrt_busy_w;
  // 组合类 1 拍寄存的 valid(占用时 IQ 不发组合类)——P2 提取后由 u_exec1_stage
  // 的 down_valid_o 驱动; 声明前置，iverilog 14 拒绝前向引用(issue_ready_w 引用)
  wire exec1_valid_q;
  reg long_meta_valid_q;
  wire long_busy_any_w = long_div_busy_w || long_sqrt_busy_w;
  wire issue_is_comb_w = op_sgnj_w || op_minmax_w || op_cmp_w || op_class_w ||
                         op_mv_to_gpr_w || op_mv_to_fpr_w || op_cvt_to_gpr_w ||
                         op_cvt_int_to_fpr_w || op_cvt_fpr_to_fpr_w;
  // long(div/sqrt)真正单在飞: 除 !busy 外还须 !long_meta_valid_q。busy 在 done 拍即掉, 但 completion
  // (long_done_hold)被更高优先级 arith/exec1 阻塞时 meta 尚未取——此窗口若发新 long op 会覆写旧 op 的
  // meta+清 done_hold → 旧 op 结果丢失永不退休(fp-difftest-probe: fdiv 完成被 arith 阻塞, fsqrt issue 覆写 fdiv)。
  // meta_valid 覆盖 issue→consume 全程, gate 它保证前一 long op 的完成被消费后才发下一条。
  assign issue_ready_w = done_fifo_room_w &&
                         (!op_long_w || (!long_busy_any_w && !long_meta_valid_q)) &&
                         (!issue_is_comb_w || !exec1_valid_q);
  wire issue_fire_w = issue_valid_w && issue_ready_w;

  // ===========================================================================
  // 执行簇: arith(自流水) / long(div·sqrt) / 组合类(1 拍寄存)
  // ===========================================================================
  wire [`XLEN-1:0] arith_addsub_unused_w;
  wire [4:0] arith_addsub_ff_unused_w;
  wire [`XLEN-1:0] arith_mul_unused_w;
  wire [4:0] arith_mul_ff_unused_w;
  wire [`XLEN-1:0] arith_fma_unused_w;
  wire [4:0] arith_fma_ff_unused_w;
  wire arith_done_unused_w;
  wire arith_out_valid_w;
  wire [ROB_INDEX_W-1:0] arith_out_rob_w;
  wire [PHY_REG_ADDR_W-1:0] arith_out_pdest_w;
  wire [`XLEN-1:0] arith_out_value_w;
  wire [4:0] arith_out_fflags_w;

  OooFpArithGate u_fp_arith (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .start_i(1'b0),
    .frs1_value_i(issue_fs1_data_w),
    .frs2_value_i(issue_fs2_data_w),
    .frs3_value_i(issue_fs3_data_w),
    .double_i(issue_double_w),
    .sub_op_i(arith_sub_op_w),
    .negate_product_i(arith_neg_prod_w),
    .subtract_addend_i(arith_sub_add_w),
    .rm_i(eff_rm_w),
    .addsub_value_o(arith_addsub_unused_w),
    .addsub_fflags_o(arith_addsub_ff_unused_w),
    .mul_value_o(arith_mul_unused_w),
    .mul_fflags_o(arith_mul_ff_unused_w),
    .fma_value_o(arith_fma_unused_w),
    .fma_fflags_o(arith_fma_ff_unused_w),
    .done_o(arith_done_unused_w),
    .launch_valid_i(issue_fire_w && op_arith_w),
    .launch_rob_idx_i(issue_rob_idx_w),
    .launch_pdest_i(issue_pdest_w),
    .launch_kind_i(arith_kind_w),
    .kill_valid_i(kill_valid_i),
    .kill_rob_idx_i(kill_rob_idx_i),
    .rob_head_idx_i(rob_head_idx_i),
    .out_valid_o(arith_out_valid_w),
    .out_rob_idx_o(arith_out_rob_w),
    .out_pdest_o(arith_out_pdest_w),
    .out_value_o(arith_out_value_w),
    .out_fflags_o(arith_out_fflags_w)
  );

  // div/sqrt: 单在飞(busy 背压); meta 在本层寄存(long_meta_valid_q 声明已前置)
  reg [ROB_INDEX_W-1:0] long_rob_q;
  reg [PHY_REG_ADDR_W-1:0] long_pdest_q;
  wire long_done_w;
  wire [`XLEN-1:0] long_result_w;
  wire [4:0] long_fflags_w;

  OooFpLongOpGate u_fp_long_op (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .frs1_value_i(issue_fs1_data_w),
    .frs2_value_i(issue_fs2_data_w),
    .double_i(issue_double_w),
    .rm_i(eff_rm_w),
    .long_start_i(issue_fire_w && op_long_w),
    .is_div_i(op_div_w),
    .is_sqrt_i(op_sqrt_w),
    .div_busy_o(long_div_busy_w),
    .sqrt_busy_o(long_sqrt_busy_w),
    .long_done_o(long_done_w),
    .long_done_result_o(long_result_w),
    .long_done_fflags_o(long_fflags_w)
  );

  // done 是单拍脉冲(DivIter/SqrtIter 每拍清 0): 用 hold 寄存承接,
  // 收取拍清 hold+meta; 新 op 发射拍作废旧 hold(wrong-path kill 后残留结果)。
  reg long_done_hold_q;
  reg [`XLEN-1:0] long_result_hold_q;
  reg [4:0] long_fflags_hold_q;
  wire long_take_pre_w;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      long_meta_valid_q <= 1'b0;
      long_rob_q <= {ROB_INDEX_W{1'b0}};
      long_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      long_done_hold_q <= 1'b0;
      long_result_hold_q <= {`XLEN{1'b0}};
      long_fflags_hold_q <= 5'b00000;
    end else begin
      if (issue_fire_w && op_long_w) begin
        long_meta_valid_q <= 1'b1;
        long_rob_q <= issue_rob_idx_w;
        long_pdest_q <= issue_pdest_w;
        long_done_hold_q <= 1'b0;
      end else if (long_done_w) begin
        long_done_hold_q <= 1'b1;
        long_result_hold_q <= long_result_w;
        long_fflags_hold_q <= long_fflags_w;
      end
      if (long_take_pre_w) begin
        long_meta_valid_q <= 1'b0;
        long_done_hold_q <= 1'b0;
      end
      if (kill_valid_i && long_meta_valid_q &&
          ((long_rob_q - rob_head_idx_i) >
           (kill_rob_idx_i - rob_head_idx_i))) begin
        long_meta_valid_q <= 1'b0;
      end
    end
  end

  // 组合类 gates(平移实例; 全组合, 结果发射拍算, 打 1 拍进 exec1)
  wire [`XLEN-1:0] cmp_value_w;
  wire [4:0] cmp_fflags_w;
  wire [`XLEN-1:0] minmax_value_w;
  wire [4:0] minmax_fflags_w;
  OooFpCompareGate u_fp_compare (
    .frs1_value_i(issue_fs1_data_w),
    .frs2_value_i(issue_fs2_data_w),
    .double_i(issue_double_w),
    .cmp_op_i(issue_inst_w[14:12]),
    .is_max_i(issue_inst_w[12]),
    .compare_value_o(cmp_value_w),
    .compare_fflags_o(cmp_fflags_w),
    .minmax_value_o(minmax_value_w),
    .minmax_fflags_o(minmax_fflags_w)
  );

  wire [`XLEN-1:0] sgnj_value_w;
  OooFpSgnjGate u_fp_sgnj (
    .frs1_value_i(issue_fs1_data_w),
    .frs2_value_i(issue_fs2_data_w),
    .double_i(issue_double_w),
    .op_i(issue_inst_w[14:12]),
    .sgnj_value_o(sgnj_value_w)
  );

  wire [`XLEN-1:0] class_value_w;
  OooFpClassifyGate u_fp_classify (
    .frs1_value_i(issue_fs1_data_w),
    .double_i(issue_double_w),
    .class_value_o(class_value_w)
  );

  wire cvt_src_double_w = (is_f7_w == F7_FCVT_D_INT) ||
                          (is_f7_w == F7_FCVT_S_D);
  wire cvt_dst_double_w = (is_f7_w == F7_FCVT_INT_D) ||
                          (is_f7_w == F7_FCVT_D_S);
  wire [`XLEN-1:0] cvt_to_gpr_value_w;
  wire [4:0] cvt_to_gpr_fflags_w;
  wire [`XLEN-1:0] cvt_to_fpr_value_w;
  wire [4:0] cvt_to_fpr_fflags_w;
  OooFpConvertGate u_fp_convert (
    .frs1_value_i(issue_fs1_data_w),
    .int_rs1_value_i(gpr_read_data_i),
    .src_double_i(cvt_src_double_w),
    .dst_double_i(cvt_dst_double_w),
    .fpr_to_fpr_i(op_cvt_fpr_to_fpr_w),
    .int_fmt_i(issue_inst_w[21:20]),
    .rm_i(eff_rm_w),
    .to_gpr_value_o(cvt_to_gpr_value_w),
    .to_gpr_fflags_o(cvt_to_gpr_fflags_w),
    .to_fpr_value_o(cvt_to_fpr_value_w),
    .to_fpr_fflags_o(cvt_to_fpr_fflags_w)
  );

  // FMV.X(FPR→GPR: W 符号扩展/D 直传); FMV.W/D.X(GPR→FPR: W NaN-box)
  wire [`XLEN-1:0] mv_to_gpr_value_w =
      issue_double_w ? issue_fs1_data_w
                     : {{32{issue_fs1_data_w[31]}}, issue_fs1_data_w[31:0]};
  wire [`XLEN-1:0] mv_to_fpr_value_w =
      issue_double_w ? gpr_read_data_i
                     : {32'hffff_ffff, gpr_read_data_i[31:0]};

  wire [`XLEN-1:0] comb_value_w =
      op_cmp_w ? cmp_value_w :
      op_minmax_w ? minmax_value_w :
      op_sgnj_w ? sgnj_value_w :
      op_class_w ? class_value_w :
      op_mv_to_gpr_w ? mv_to_gpr_value_w :
      op_mv_to_fpr_w ? mv_to_fpr_value_w :
      op_cvt_to_gpr_w ? cvt_to_gpr_value_w :
                        cvt_to_fpr_value_w;
  wire [4:0] comb_fflags_w =
      op_cmp_w ? cmp_fflags_w :
      op_minmax_w ? minmax_fflags_w :
      op_cvt_to_gpr_w ? cvt_to_gpr_fflags_w :
      (op_cvt_int_to_fpr_w || op_cvt_fpr_to_fpr_w) ? cvt_to_fpr_fflags_w :
                        5'b00000;

  // ===========================================================================
  // exec1 级间寄存(P2 提取刀): 组合类结果的 1 拍 stage 簇归一为 PipeStageReg。
  // payload 81b 布局 {rob[80:77],pdest[76:71],dst_gpr[70],dst_en[69],value[68:5],fflags[4:0]}。
  // flush 后 payload 留脏(原语惯例)——全部消费点经 exec1_take_w/exec1_valid_q 门控,
  // 无 valid=0 读 payload。位段别名 wire 使下游消费点零文本改动。
  // ===========================================================================
  wire [80:0] exec1_stage_payload_w;
  wire exec1_stage_up_ready_unused_w; // issue_ready_w 保留 !exec1_valid_q 项(语义中性), up_ready_o 悬空
  wire [ROB_INDEX_W-1:0] exec1_rob_q = exec1_stage_payload_w[80:77];
  wire [PHY_REG_ADDR_W-1:0] exec1_pdest_q = exec1_stage_payload_w[76:71];
  wire exec1_dst_gpr_q = exec1_stage_payload_w[70];
  wire exec1_dst_en_q = exec1_stage_payload_w[69];
  wire [`XLEN-1:0] exec1_value_q = exec1_stage_payload_w[68:5];
  wire [4:0] exec1_fflags_q = exec1_stage_payload_w[4:0];
  // kill 年龄判定留使用方(原语契约⑥): rob 从 down_payload 位段取, 环形 age 比较
  wire exec1_kill_w = kill_valid_i && exec1_valid_q &&
      ((exec1_rob_q - rob_head_idx_i) > (kill_rob_idx_i - rob_head_idx_i));

  PipeStageReg #(
    .WIDTH(81)
  ) u_exec1_stage (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),           // nuke 族; recover/checkpoint 不清 exec1(现状语义)
    .kill_i(exec1_kill_w),
    .up_valid_i(issue_fire_w && issue_is_comb_w),
    .up_ready_o(exec1_stage_up_ready_unused_w),
    .up_payload_i({issue_rob_idx_w, issue_pdest_w, issue_dst_gpr_w,
                   issue_dst_en_w, comb_value_w, comb_fflags_w}),
    .down_valid_o(exec1_valid_q),
    .down_ready_i(!arith_out_valid_w), // 唯一阻塞源=arith 完成仲裁优先
    .down_payload_o(exec1_stage_payload_w)
  );

  // ===========================================================================
  // 完成仲裁 + 完成 FIFO(优先: arith(无背压) > exec1(保持) > long(done 保持))
  // FPR 目的在入队拍写物理堆+唤醒(fp_result_wb_*); FIFO 只承载 ROB done 事务。
  // ===========================================================================
  wire exec1_take_w = exec1_valid_q && !arith_out_valid_w;
  wire long_take_w = long_done_hold_q && long_meta_valid_q &&
                     !arith_out_valid_w && !exec1_take_w;
  assign long_take_pre_w = long_take_w;

  assign fp_result_wb_valid_w =
      arith_out_valid_w || exec1_take_w || long_take_w;
  assign fp_result_wb_preg_w =
      arith_out_valid_w ? arith_out_pdest_w :
      exec1_take_w ? exec1_pdest_q : long_pdest_q;
  assign fp_result_wb_value_w =
      arith_out_valid_w ? arith_out_value_w :
      exec1_take_w ? exec1_value_q : long_result_hold_q;
  // arith/long 恒 FPR 目的; exec1 按 dst_gpr 区分
  assign fp_result_wb_frd_w =
      arith_out_valid_w ? 1'b1 :
      exec1_take_w ? (exec1_dst_en_q && !exec1_dst_gpr_q) : 1'b1;

  wire [ROB_INDEX_W-1:0] done_in_rob_w =
      arith_out_valid_w ? arith_out_rob_w :
      exec1_take_w ? exec1_rob_q : long_rob_q;
  wire [4:0] done_in_fflags_w =
      arith_out_valid_w ? arith_out_fflags_w :
      exec1_take_w ? exec1_fflags_q : long_fflags_hold_q;
  wire done_in_rd_en_w = exec1_take_w && exec1_dst_gpr_q && exec1_dst_en_q;
  wire [PHY_REG_ADDR_W-1:0] done_in_pdest_w = fp_result_wb_preg_w;
  wire [`XLEN-1:0] done_in_value_w = fp_result_wb_value_w;

  // FIFO(4 项×(rob+pdest+rd_en+value+fflags)); 深 8 计数上限但物理 8 项
  localparam DONE_FIFO_W = 3;
  localparam DONE_FIFO_N = (1 << DONE_FIFO_W);
  reg [ROB_INDEX_W-1:0] df_rob_q [0:DONE_FIFO_N-1];
  // kill 时 FIFO 存量 squash: 被 kill 指令的完成事务若滞留 FIFO, pop 后会把
  // 重放后同号新 ROB entry 标 done(撞号)→ 状态分叉。killed 项 pop 拍静默丢弃。
  reg df_killed_q [0:DONE_FIFO_N-1];
  reg [PHY_REG_ADDR_W-1:0] df_pdest_q [0:DONE_FIFO_N-1];
  reg df_rd_en_q [0:DONE_FIFO_N-1];
  reg [`XLEN-1:0] df_value_q [0:DONE_FIFO_N-1];
  reg [4:0] df_fflags_q [0:DONE_FIFO_N-1];
  reg [DONE_FIFO_W-1:0] df_head_q;
  reg [DONE_FIFO_W-1:0] df_tail_q;

  wire df_push_w = fp_result_wb_valid_w;
  wire df_empty_w = (done_fifo_count_q == 4'd0);
  wire df_head_killed_w = df_killed_q[df_head_q];
  // killed 项自弹(不需要下游 ready); 活项按下游 ready 弹
  wire df_pop_w = !df_empty_w && (df_head_killed_w || fpwb_ready_i);

  assign fpwb_valid_o = !df_empty_w && !df_head_killed_w;
  assign fpwb_rob_idx_o = df_rob_q[df_head_q];
  assign fpwb_pdest_o = df_pdest_q[df_head_q];
  assign fpwb_rd_en_o = df_rd_en_q[df_head_q];
  assign fpwb_data_o = df_value_q[df_head_q];
  assign fpwb_fflags_o = df_fflags_q[df_head_q];

  integer dfi;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      df_head_q <= {DONE_FIFO_W{1'b0}};
      df_tail_q <= {DONE_FIFO_W{1'b0}};
      done_fifo_count_q <= 4'd0;
      for (dfi = 0; dfi < DONE_FIFO_N; dfi = dfi + 1) begin
        df_rob_q[dfi] <= {ROB_INDEX_W{1'b0}};
        df_killed_q[dfi] <= 1'b0;
        df_pdest_q[dfi] <= {PHY_REG_ADDR_W{1'b0}};
        df_rd_en_q[dfi] <= 1'b0;
        df_value_q[dfi] <= {`XLEN{1'b0}};
        df_fflags_q[dfi] <= 5'b00000;
      end
    end else begin
      // exec1 装载/收取/kill 已提取进 u_exec1_stage(PipeStageReg), 本块只剩 done FIFO
      if (kill_valid_i) begin : df_kill_blk
        integer dk;
        for (dk = 0; dk < DONE_FIFO_N; dk = dk + 1) begin
          if (((df_rob_q[dk] - rob_head_idx_i) >
               (kill_rob_idx_i - rob_head_idx_i)))
            df_killed_q[dk] <= 1'b1;
        end
      end
      if (df_push_w) begin
        df_rob_q[df_tail_q] <= done_in_rob_w;
        df_killed_q[df_tail_q] <= kill_valid_i &&
            ((done_in_rob_w - rob_head_idx_i) >
             (kill_rob_idx_i - rob_head_idx_i));
        df_pdest_q[df_tail_q] <= done_in_pdest_w;
        df_rd_en_q[df_tail_q] <= done_in_rd_en_w;
        df_value_q[df_tail_q] <= done_in_value_w;
        df_fflags_q[df_tail_q] <= done_in_fflags_w;
        df_tail_q <= df_tail_q + {{(DONE_FIFO_W-1){1'b0}}, 1'b1};
      end
      if (df_pop_w) begin
        df_head_q <= df_head_q + {{(DONE_FIFO_W-1){1'b0}}, 1'b1};
      end
      done_fifo_count_q <= done_fifo_count_q +
                           {3'b000, df_push_w} - {3'b000, df_pop_w};
    end
  end


endmodule
/* verilator lint_on UNOPTFLAT */
