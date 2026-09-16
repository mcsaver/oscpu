# 规范：分支方向预测器 OooBranchDirectionPredictor

> 模块：`vsrc/frontend/OooBranchDirectionPredictor.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
预测条件分支方向(taken/not-taken),双发射(2 lookup 口)。gshare(全局历史)+ local(局部历史)混合,
2-bit 饱和计数器。lookup 只接收 PC 与 1-bit `static_taken`；完整 branch immediate 留在前端
目标地址通路。只管方向;目标地址由 RAS 与前端直算(JAL=pc+imm、RET=RAS top;
JALR-BTB/BTC/pending jump sequencer 在 mode=1 下已判死,见 2026-07-03 RTL 重读基线)。

## 2. 结构
```
 gshare:  index = fn(PC, GHR)        → bht_q[idx] (2-bit 饱和)  [BPU_BHT_ENTRIES=1024]
 local :  lh = local_hist_q[PC_idx(256 项×8b)] → OooBranchLocalPht[{pc[4:1],lh}]
          OooBranchLocalPht = 16 banks × 256 rows × (valid+2-bit counter)
 GHR(ghr_q): 全局分支历史移位寄存器(BHT_INDEX_W 位)
 lookup → pred_taken / predict_strong / bht_idx(供 update 回写)
 update(resolve): 按实际 taken 更新计数器(±1 饱和)、移入 GHR、更新 local history
```
- 每项带 valid 位:未训练(valid=0)时回退**静态预测**(如 backward-taken/forward-not-taken)。
- 2-bit 计数器:`taken = valid ? (counter>=2) : static`;strong = 计数器在两端(00/11)。

### 2.1 Production child ownership

`OooBranchDirectionPredictor` 继续拥有 GHR、1024-entry gshare BHT 和 256-entry
local-history；`vsrc/frontend/OooBranchLocalPht.v` 独占 local-PHT payload/valid 与
local-PHT update S1/S2。固定投影为 `BANKS=16`、`ROWS=256`：

- `index[11:8] = PC[4:1]` 只选 bank；
- `index[7:0] = local_history[7:0]` 只选 bank-local row；
- 每个 bank 只导出 256-bit valid 与 512-bit counter 的 state-Q read-only view；wrapper
  按 bank-major 拼成 4096-entry flat view，并用两条各自完整的 12-bit index 各作一次组合选择；
  同 bank/same row、同 bank/different row 与不同 bank 都保持无仲裁 0-cycle；
- update 只向匹配 bank 发出 valid，每个 bank 自己在 S1 捕获 row、taken 与 old counter，S2
  下一沿饱和写回。公共 `update_taken_i` 因而只负载 16 个 bank-local S1，而不是 4096-entry
  公共训练/写使能锥。

这个 child split 不改变容量、索引 ABI 或预测算法，也不新增 macro/blackbox；wrapper 与 16 个
`OooBranchLocalPhtBank` 在实验配置中全部 inline。wrapper 不拥有 local-PHT 寄存器、
`counter_train` 或时序写块；`update_old_ctr` 仍只在 bank 内从该 bank 的 Q 读取。

### 2.2 接口与六类合同（F1a scalar fallback ABI）

| 类别 | 合同 |
| --- | --- |
| 握手 | 两路 lookup 都是 0-cycle 纯组合 view，无 valid/ready；`lookup*_static_taken_i` 只在所选表项 invalid 时决定 fallback。 |
| stall/backpressure | 模块无 occupancy、无 stall 状态；parent stall 不在本模块捕获 lookup payload。 |
| flush/clear | `rst || clear_i` 清 valid、GHR 与 update 流水 valid；同拍 update 被丢弃，优先级保持 `reset/clear > update stage1/stage2`。 |
| 异常序 | predictor 不拥有异常、fault 或 redirect；非 branch/fault/invalid slot 是否消费预测仍由 frontend gate 单一决定。 |
| 访存序 | 无 AXI/cache/访存 owner，接口收窄不改变请求、响应或信用。 |
| 投机恢复/单一真源 | `fetch_dec*_bimm_w[12]` 是两路 static fallback 的唯一真源；其余 12 immediate bits 禁止进入 predictor/macro ABI，GHR/update 语义不变。 |

典型组合语义：`pred_taken = selected_valid ? selected_counter[1] : static_taken`。接口收窄
不新增寄存级、不改变 lookup latency，也不允许在 predictor 内重新解码 immediate。

## 3. 不变量
- **BP-I1 索引一致**:lookup 产出的 bht_idx 必须随 uop 传到 resolve,update 用同一 idx 回写(否则训错条目)。
- **BP-I2 更新顺序**:GHR/计数器在 resolve(真实方向已知)时更新;投机期不污染(误预测恢复走
  pred_npc 显式 mispredict redirect + ROB-walk;BranchSpecTracker 的 checkpoint 机制已判死)。
- **BP-I3 双发射**:lookup0/lookup1 同拍读同一表,需保证两口读不互相干扰(纯读)。
- **BP-I4 静态 fallback ABI (`BPU-ST1`)**:两路外部 ABI 各只有 1-bit
  `lookup*_static_taken_i`，且分别来自对应 slot B-imm 符号位。表项 valid 时 counter 必须覆盖
  static bit；表项 invalid 时该 bit 必须直接决定方向，lane0/1 不得串线。
- **BP-I5 decoder immediate ABI (`T3L`)**：frontend 内部 B-imm 总线宽度固定为 13，
  predictor 只取 bit12；branch target 由独立 split-target 模块消费完整 13 位，禁止恢复
  XLEN-wide sign-extension 作为跨模块接口。
- **BP-I6 local-PHT bank/index**：`index={PC[4:1],local_history[7:0]}` 必须严格投影为
  bank=`index[11:8]`、row=`index[7:0]`；read view 的 bit 序必须等于
  `bank*256+row`。不得交换位域、复用 lane0 地址、恢复 bank-local lane selector 或在同 bank
  两路间仲裁。
- **BP-I7 local-PHT update 可见性**：resolve 沿是 child S1，下一沿是 S2；lookup/S1 对同沿
  S2 保持 read-before-write，连续同 entry update 不做 forwarding，因而保留既有丢一次增量行为。
- **BP-I8 recovery**：`clear_i` 清每个 bank 的 valid 与 pending S2；mispredict 仍按 actual
  outcome 训练，且 redirect/ROB-walk 不 restore predictor。
- **BP-I9 local-PHT write ownership**：16 个 bank 是 4096-entry valid/counter 的唯一 owner；
  wrapper 只消费 Q 端 read-only view，禁止公共 flat valid/counter、trained-counter 或 variable-write
  owner。`update_taken_i` 最多进入 16 个 bank-local S1 捕获点。
- 预测错不影响正确性(只影响性能):误预测由后端 resolve→精确 redirect 纠正。

## 4. 关键路径

2026-08-10 的 current d3f3 inline mapped 证据显示 local-PHT 公共更新锥进入 BPU 内部负裕量
路径。旧 `mapped-5ns-bpu-local-pht-banked-child-inline-v1` 的 mapped execution receipt 为 PASS，
但冻结实验裁决是 `ROLLBACK/GAP`：公共 taken 已收窄到 16 个 bank-local S1，然而重复的 bank-local
lane read mux 使面积门失败；该点只保留为 noncanonical negative-knowledge archive。

`mapped-5ns-bpu-local-pht-write-banked-flat-read-view-inline-v1` 是唯一后继 development candidate：
write owner 与 S1/S2 继续分 bank，read 改成 bank Q flat view。当前 `UNMEASURED/GAP`，本切片明确
不运行综合/STA，不得声称 WNS/TNS/area/power 改善；唯一 next action 是另一个合同按新 live design-id
执行一次 traceable 5 ns PPA。新 RTL 使旧 d3f3/b279 elaboration/module/L3/mapped receipts 都不能
冒充 current-design evidence。

2026-07-12 fresh 5ns A/B 以同一 `5bd7a1546` RTL 基线、Yosys/TCL/PDK、其余三颗 macro
Liberty 与综合参数重跑；唯一有意差异是 BPU wide/static-scalar ABI 及匹配的 placeholder Liberty。
旧 ABI 把相同 B-imm 符号网复制接到每 lane 的 52 个 `imm[63:12]` pin；predictor 行为只消费
符号位。F1a 收窄为 1 个 `static_taken` pin，删除每 lane 51×0.01pF 的无语义 macro 输入负载。

| 指标 | A：wide immediate | B：scalar static bit | 变化 |
| --- | ---: | ---: | ---: |
| lane0 sign-driver output-net total cap（range max） | 0.731442 pF | 0.216994 pF | -0.514448 pF |
| lane1 sign-driver output-net total cap（range max） | 0.713429 pF | 0.220849 pF | -0.492580 pF |
| lane0 sign-driver cell delay | 8.030481 ns | 2.409060 ns | -5.621421 ns |
| lane1 sign-driver cell delay | 7.834482 ns | 2.454253 ns | -5.380229 ns |
| lane0 worst through-cone slack | -11.855756 ns | -5.288095 ns | +6.567661 ns |
| lane1 worst through-cone slack | -11.581460 ns | -5.560177 ns | +6.021283 ns |
| full-chip WNS @ 5ns | -12.90 ns | -12.90 ns | 0.00 ns |
| full-chip TNS @ 5ns | -198649.61 ns | -197335.64 ns | +1313.97 ns (+0.661451%) |
| stdcell area（四宏 unknown） | 1567145.72 | 1567234.20 | +88.48 (+0.005646%) |

两份 top40 路径逐字相同且都由后端瓶颈主导，只有全局 TNS 汇总不同。wide→scalar 同时删除
126 个 placeholder input setup endpoint，因此 TNS 变化混合了端点数与共享网减载，只能作辅助
证据；本刀按“ABI 真实化 + 目标 cone 明显减载”保留，不宣称 full-chip WNS 改善。面积差异远小于
0.01%，且 BPU/memory/FP macro 面积仍 unknown；OpenSTA 功耗两侧都四舍五入为 0.118W、macro
power 为 0，只能视为无可解释变化。placeholder 仍无真实 lookup input→output 组合弧，且无
SPEF/CTS/OCV，所以该结果不是 200MHz signoff；下一瓶颈必须按后端/前端流水级继续切分。

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
- 两个 scalar static bit 独立，且训练后翻转 static bit 不得覆盖有效 counter；
- not-taken 训练对 BHT 2-bit 计数器的弱/强状态演进；
- clear 清 valid 与 GHR，payload 在 invalid entry 中无语义；
- taken update 移入 GHR，并影响 lookup0/lookup1 的 gshare index；
- 双 lookup 口同拍组合读，互不干扰。
- parent→`OooBranchLocalPht` 的 bank-local S1 投影；prediction!=actual 的 mispredict 仍训练，
  随后的 recovery idle 不 restore local-PHT。

`tb_ooo_branch_local_pht` 定向覆盖 16×256 位域、双路 0-cycle、同 bank same/different row、
bank Q→flat view 位序、S1→S2、lookup/S2 read-before-write、饱和、背靠背同 entry 无 forwarding
与 clear pending-S2。`run_ooo_branch_local_pht_mutations.py` 先 fail-closed 审核 wrapper 无时序写 owner，
再要求原 11 项与新增 public-flat-write-owner 共 12 项负向 RTL 全部编译成功、各命中唯一预期动态
FAIL marker，且不得出现 `[RESULT] PASS`。

建议命令：

```bash
make -C npc/rv64/testbench TESTS=tb_ooo_branch_direction_predictor \
  RESULT_DIR=/tmp/tb-bpu run

make -C npc/rv64/testbench TESTS=tb_ooo_branch_local_pht \
  RESULT_DIR=/tmp/tb-bpu-local-pht run

make -C npc/rv64/testbench bpu-local-pht-flat-read-view-mutations \
  BPU_LOCAL_PHT_MUTATION_RESULT=/tmp/tb-bpu-local-pht-mutations
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
| lookup read latency | `0 cycle` | `lookup*_pc_i/lookup*_static_taken_i` 到 `lookup*_bht_idx_o/lookup*_bht_valid_o/lookup*_pred_taken_o/lookup*_predict_strong_o` 保持组合可见；每路 static fallback 仅 1 bit。 |
| read ports | two combinational views | lookup0/lookup1 当前同拍读同一组预测表，纯读互不干扰。单/双口 SRAM 化前必须证明仲裁、复制或延迟合同。 |
| update edge | `posedge clk` | `update_valid_i` 在 issue-resolve 拍训练 BHT/local PHT/local history，并移入 GHR。 |
| update visibility | `two cycles` | 【update 两拍流水(2026-07-10 时序债修复)】stage1 寄存输入+读老值(GHR 当拍更新)，stage2 训练写表——表项可见性从第 2 拍开始；back-to-back 同表项 RAW 丢一次训练增量(启发式可容忍)。OOC 实测 update in→reg 57ns→流水化后压半。 |
| reset/clear | valid-only table clear plus GHR zero | reset/clear 清 BHT/local valid 并把 GHR 置 0；counter/history payload 在 invalid entry 中无语义值。 |
| update source | issue-resolve only | 不做投机期污染；wrong-path 分支被 walk kill 后不 issue，不进入 update。 |

### 8.3 Area Placeholder

默认参数来自 `define.v`：`BPU_BHT_INDEX_W=10`、`BPU_LOCAL_HISTORY_INDEX_W=8`、
`BPU_LOCAL_HISTORY_W=8`、`BPU_LOCAL_PHT_INDEX_W=12`，因此：

| 项 | 数值 |
| --- | --- |
| gshare BHT valid bits | `1024` |
| gshare BHT counter bits | `1024 * 2 = 2048` |
| GHR bits | `10` |
| local history valid bits | `256` |
| local history bits | `256 * 8 = 2048` |
| local PHT valid bits | `16 * 256 = 4096` |
| local PHT counter bits | `16 * 256 * 2 = 8192` |
| total state bits | `17674` |

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
- 2026-07-12：F1a 冻结 `lookup*_imm_i[63:0]`→`lookup*_static_taken_i` 单 bit ABI；同步
  placeholder Liberty/checker/TB，并按当前 1024-entry BHT 校正 state lower bound 为 17674 bit。
- 2026-08-10：把 local-PHT state/read/update 从 parent 移入 production child
  `OooBranchLocalPht`，固定 16×256 bank-local S1/S2；保留双路 0-cycle、read-before-write、clear、
  mispredict train/no-restore 与背靠背无 forwarding 语义。配置仅为 non-canonical/non-champion
  engineering proxy archive，尚无新身份综合/STA 结论。
- 2026-08-10：冻结旧 banked-child mapped execution PASS 为 `ROLLBACK/GAP` archive；唯一后继
  保持 bank-local write owner，把每 bank lane-specific row selector 改为 Q 端 read-only view，
  wrapper 对两条完整 index各作一次 flat select。新配置为 development/unmeasured/noncanonical，
  本刀未运行综合/STA。
