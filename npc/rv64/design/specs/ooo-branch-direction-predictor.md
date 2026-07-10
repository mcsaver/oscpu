# 规范：分支方向预测器 OooBranchDirectionPredictor

> 模块：`vsrc/frontend/OooBranchDirectionPredictor.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
预测条件分支方向(taken/not-taken),双发射(2 lookup 口)。gshare(全局历史)+ local(局部历史)混合,
2-bit 饱和计数器。只管方向;目标地址由 RAS 与前端直算(JAL=pc+imm、RET=RAS top;
JALR-BTB/BTC/pending jump sequencer 在 mode=1 下已判死,见 2026-07-03 RTL 重读基线)。

## 2. 结构
```
 gshare:  index = fn(PC, GHR)        → bht_q[idx] (2-bit 饱和)  [BPU_BHT_ENTRIES≈4096]
 local :  lh = local_hist_q[PC_idx(256 项×8b)] → local_pht_q[{pc[4:1],lh}] (2-bit) [PHT 4096]
 GHR(ghr_q): 全局分支历史移位寄存器(BHT_INDEX_W 位)
 lookup → pred_taken / predict_strong / bht_idx(供 update 回写)
 update(resolve): 按实际 taken 更新计数器(±1 饱和)、移入 GHR、更新 local history
```
- 每项带 valid 位:未训练(valid=0)时回退**静态预测**(如 backward-taken/forward-not-taken)。
- 2-bit 计数器:`taken = valid ? (counter>=2) : static`;strong = 计数器在两端(00/11)。

## 3. 不变量
- **BP-I1 索引一致**:lookup 产出的 bht_idx 必须随 uop 传到 resolve,update 用同一 idx 回写(否则训错条目)。
- **BP-I2 更新顺序**:GHR/计数器在 resolve(真实方向已知)时更新;投机期不污染(误预测恢复走
  pred_npc 显式 mispredict redirect + ROB-walk;BranchSpecTracker 的 checkpoint 机制已判死)。
- **BP-I3 双发射**:lookup0/lookup1 同拍读同一表,需保证两口读不互相干扰(纯读)。
- 预测错不影响正确性(只影响性能):误预测由后端 resolve→精确 redirect 纠正。

## 4. 关键路径
Vivado OOC:13 逻辑级/logic ~3.4ns(local_hist→local_pht 索引+计数器),非 Fmax 瓶颈
(<DispatchBackend 39 级)。BHT/PHT 4096×2-bit 综合为分布式 RAM/BRAM。

## 5. debug/common 审核

当前审核层由两部分组成：

- `vsrc/common/OooBranchDirectionPredictorFacts.vh`：定义 lookup0/lookup1 的 BHT valid、
  pred taken、predict strong、update、clear 和静态 fallback 等外部观测 facts。该表只描述
  spec 语义，不规定 BHT/local history/local PHT 的物理编码。
- `vsrc/debug/OooBranchDirectionPredictorChecker.sv`：在 focused TB 中旁挂到真实端口，用独立
  参考模型跟踪 GHR、gshare BHT、local history 和 local PHT，并用立即断言审核 BP-I1、BP-I2、
  BP-I3 相关的 lookup/update 可见语义。它不进入 `RTL_CORE_SRCS`，不参与综合面积。

后续若把 BHT/local history/local PHT 换成 SRAM/macro/OOC module，必须先保持本 checker PASS，
或在本文件中记录被替代的不变量、替代检查和豁免理由。

## 6. Focused TB 覆盖

`tb_ooo_branch_direction_predictor` 当前覆盖：

- reset 后 GHR=0、BHT/local 表 invalid；
- 未训练 entry 的 forward-not-taken / backward-taken 静态 fallback；
- not-taken 训练对 BHT 2-bit 计数器的弱/强状态演进；
- clear 清 valid 与 GHR，payload 在 invalid entry 中无语义；
- taken update 移入 GHR，并影响 lookup0/lookup1 的 gshare index；
- 双 lookup 口同拍组合读，互不干扰。

建议命令：

```bash
make -C npc/rv64/testbench TESTS=tb_ooo_branch_direction_predictor \
  RESULT_DIR=/tmp/tb-bpu run
```

## 7. Macro/OOC 待办

- [x] 建 `common` facts 与 `debug` checker，并接入 focused TB。
- [x] focused TB 覆盖 static fallback、counter training、clear、GHR index 与双 lookup。
- [x] 定义 table macro/OOC placeholder v0 的 lookup/update 端口、读写可见性和 reset/valid 初始化假设。
- [x] 给 Yosys-STA 报告提供 non-signoff timing/area placeholder v0，避免 unknown area 被误当闭合。
- [ ] 提供 iEDA/Yosys 可读的真实 Liberty/LEF macro model，或 OOC timing report + 顶层约束接入。
- [ ] 若接入仿真顶层 XMR checker，需登记非真空 evidence；若只保留 focused TB，macro-boundary
  task-run 必须说明边界为何足够局部。

## 8. Macro/OOC Contract v0

> 状态：ACTIVE placeholder。该节只给综合/STA 报告一个可审计的假设边界，不是面积/时序签核。

### 8.1 当前选择

v0 采用 **module-level OOC/blackbox boundary**：顶层 `NpcTop` synthesis 可以继续把
`OooBranchDirectionPredictor` 保留为边界单元；生产 RTL 仍使用当前 Verilog 实现。后续若替换为
SRAM wrapper 或多表 macro 组合，必须先证明 wrapper 对 §2/§3 的外部语义等价，或同步更新
前端/resolve update 载荷与 focused TB。

### 8.2 端口与时序假设

| 类别 | v0 假设 | 说明 |
| --- | --- | --- |
| lookup read latency | `0 cycle` | `lookup*_pc_i/lookup*_imm_i` 到 `lookup*_bht_idx_o/lookup*_bht_valid_o/lookup*_pred_taken_o/lookup*_predict_strong_o` 保持组合可见。 |
| read ports | two combinational views | lookup0/lookup1 当前同拍读同一组预测表，纯读互不干扰。单/双口 SRAM 化前必须证明仲裁、复制或延迟合同。 |
| update edge | `posedge clk` | `update_valid_i` 在 issue-resolve 拍训练 BHT/local PHT/local history，并移入 GHR。 |
| update visibility | `two cycles` | 【update 两拍流水(2026-07-10 时序债修复)】stage1 寄存输入+读老值(GHR 当拍更新)，stage2 训练写表——表项可见性从第 2 拍开始；back-to-back 同表项 RAW 丢一次训练增量(启发式可容忍)。OOC 实测 update in→reg 57ns→流水化后压半。 |
| reset/clear | valid-only table clear plus GHR zero | reset/clear 清 BHT/local valid 并把 GHR 置 0；counter/history payload 在 invalid entry 中无语义值。 |
| update source | issue-resolve only | 不做投机期污染；wrong-path 分支被 walk kill 后不 issue，不进入 update。 |

### 8.3 Area Placeholder

默认参数来自 `define.v`：`BPU_BHT_INDEX_W=12`、`BPU_LOCAL_HISTORY_INDEX_W=8`、
`BPU_LOCAL_HISTORY_W=8`、`BPU_LOCAL_PHT_INDEX_W=12`，因此：

| 项 | 数值 |
| --- | --- |
| gshare BHT valid bits | `4096` |
| gshare BHT counter bits | `4096 * 2 = 8192` |
| GHR bits | `12` |
| local history valid bits | `256` |
| local history bits | `256 * 8 = 2048` |
| local PHT valid bits | `4096` |
| local PHT counter bits | `4096 * 2 = 8192` |
| total state bits | `26892` |

该数字只是 state-capacity lower bound，不是 stdcell area、SRAM compiler area、leakage 或 timing closure。
在 Liberty/LEF 或 OOC timing report 接入前，`NpcTop` 报告必须继续把
`OooBranchDirectionPredictor` 面积标为未闭合。

### 8.4 STA 接入条件

- 若继续使用 blackbox：报告必须列出 lookup read latency、update visibility、双 lookup 读口、
  reset/clear/GHR 假设和 state bits，并声明 top area/timing 不含真实 predictor table macro。
- 若使用真实 SRAM/宏：必须提供 Liberty timing arcs 覆盖两路 lookup 组合输出或等价流水/旁路合同、
  update 写可见性、setup/hold、reset/valid 初始化假设，并同步 `sta.tcl`/PDK 读入。
- 若使用 OOC stdcell netlist：必须给出 OOC synthesis/STA evidence，并说明顶层如何约束 blackbox
  input/output delay；不能只用 `check_macro_contracts.py` PASS 作为 STA 证据。

## 9. 验证
- riscv-tests 分支测试(beq/bne/blt/...)、AM branch-resolve-loop(回边循环高可预测);
  方向错只降性能不破坏正确性。BPU 统计需 `CONFIG_NPC_BRANCH_STATS` 构建(默认 perf 关)。
- focused `tb_ooo_branch_direction_predictor` 审核 predictor table 本体。

## 10. 变更记录
- 2026-06-28：逆向文档化(gshare+local 混合/2-bit 饱和/双 lookup/静态回退/resolve 更新)。
- 2026-07-03：RTL 重读校正——目标预测引用改为现状(JALR-BTB/BTC 已死)、local PHT 索引精确化
  ({pc[4:1],hist})、BP-I2 恢复机制改为 mispredict+ROB-walk;update 单源=F2 issue-resolve。
- 2026-07-08：新增 debug/common checker、focused TB 和 Macro/OOC Contract v0，定义 BPU placeholder
  的 0-cycle lookup、next-cycle update visibility、valid-only table clear + GHR zero、26892 state-bit
  lower bound；真实 Liberty/LEF/OOC STA 仍未闭合。
