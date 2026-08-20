RV64 RTL 结论｜对象=`OooBranchDirectionPredictor.local_pht_valid_q/local_pht_q`、候选 `OooBranchLocalPht/OooBranchLocalPhtBank[0:15]`、`opensta-top40.rpt`｜周期/配置=双路 0-cycle lookup、resolve S1→下一沿 S2、d3f3、5.000 ns `mapped-5ns-bpu-inline-v1`｜TB/EDA 观测=current TB 仅有 predecessor PASS；sealed whole-inline WNS=-50.241458893 ns、TNS=-719693.1875 ns、Top40=40/40 BPU internal；candidate RTL/TB/mutation/synth/STA/OOC 均不存在且本轮未运行｜范围=GAP

独立裁决：`FIX`。16×256 banking 是语义可行、根因方向合理的候选，但当前不能 `APPROVE`、不能登记 production retain/Pareto，更不能声明 OOC/PPA 闭合。只允许修订门禁后做一次可逆、全 inline 的因果实验。

## 身份与当前事实

- 合同 SHA-256 已匹配：`b0e52bcd58eda350ea0524a288870a4956663fd8e53a6a75cc2fc9ee7354d85b`。
- current RTL：`OooBranchDirectionPredictor.v=698b45f4...8997`，`OooFrontend.v=7a16f069...14f7f`，与 sealed d3f3 inline summary 的 synthesis source identity 一致。
- `bpu-child-split-architect-route-v1.json` 明示 `candidate_exists=false`。
- workspace 中无 `OooBranchLocalPht.v`、`OooBranchLocalPht.lib` 或 `mapped-5ns-bpu-local-pht-banked-child-*` 工件；定向 `rg` 返回码 1、无匹配。
- registry 目前只有 `mapped-5ns-four-placeholder-v1` 和 `mapped-5ns-bpu-inline-v1`，没有 child inline/OOC 配置。
- scoped diff 没有 BPU candidate 变更；仅看到与本对象无关的 V16A Makefile 改动，未将其纳入结论。

## Architecture IR 攻击结论

当前索引为：

```text
local-history index = PC[8:1]
local-PHT index     = {PC[4:1], local_history[7:0]}
bank                = index[11:8] = PC[4:1]
row                 = index[7:0]  = local history
```

该映射正确，但必须在 registry/config 或 elaboration assertion 中固定 `PC_BITS=4`、`HISTORY_W=8`、`INDEX_W=12`、`ENTRIES=4096`、`BANKS=16`、`ROWS=256`，否则未来参数变化可能静默产生 alias。

周期语义必须保持：

1. 两路 lookup 均为组合 0-cycle；same-bank/same-row、same-bank/different-row 均不得仲裁、stall 或复制 architected state。
2. resolve 沿为 S1：捕获 index、taken、写前 counter；GHR 同沿更新。
3. 下一沿为 S2：local-PHT、BHT、local history 同拍写回。
4. lookup 与 S2 write 同沿时，FIFO 采样写前值；沿后组合输出才可反映新值。
5. 背靠背同 entry：后一个 S1 读取前一个 S2 写前值，允许丢一次增量；禁止隐式 forwarding。
6. `rst || clear_i` 为同步优先级，清 valid、GHR 和所有 bank-local `upd_valid`；pending S2 不得在 clear 后复活 entry。
7. `OooBranchBpuUpdateGate` 的 issue-resolve 单源在预测正确和 mispredict 时都训练；mispredict 只走 redirect/ROB squash，不 checkpoint/restore predictor。

## Fanout 是否真实切断

结构推理支持候选，但尚未得到网表证明。只有下列形态才算真实切断：

- raw `update_taken_i` 只驱动 parent 的既有更新状态、4-bit bank decode，以及至多 16 个 bank-local S1 taken 寄存器；
- 每个 bank 的本地 `upd_taken_q/old_ctr_q` 只进入本 bank 至多 256-entry 的写锥；
- `counter_train()` 必须在 bank-local S1 寄存器之后计算。

反例是 wrapper 在 bank 上方先生成公共 `trained_counter`，或保留一个全局 `upd_taken_q` 再送入全部 4096 entry；这种实现即使层级名变成 child，也没有切断根因。另一个反例是综合重新 merge/share 16 个 bank 的公共逻辑。

因此必须以 mapped netlist fail-closed 检查：

- 恰有 16 个 bank instance；
- public `update_taken_i` 不再直接成为跨 bank PHT-entry endpoint family 的 startpoint；
- 每个 bank-local taken startpoint 的 PHT endpoint 集不超过该 bank 256 entries；
- 旧 `update_taken_i→local_pht_q[*]` Top40 family 消失，且无等价跨 bank replacement；
- bank read mux/local-history→PHT lookup 路径仍在 Top40/STA 可见。

## 当前 TB 与 mutation GAP

`tb_ooo_branch_direction_predictor.sv` 虽旁挂完整 reference checker，但刺激不足：PHT 无效时的碰撞不能证明两个已训练 read view 独立；无显式 bank/row 位域及不同 bank 测试；update task 插入空拍，无 back-to-back same-entry RAW；无 lookup/S2-write 同沿；clear 时没有 pending S2；饱和边界不完整；无 child 级 mispredict-train/no-restore 集成观测。

candidate 必须增加 directed TB：

- same-bank/same-row、same-bank/different-row、different-bank 双读；
- bank/row swap 可观测序列；
- taken/NT 两端饱和；
- S1/S2 精确 visibility；
- same-entry back-to-back RAW；
- lookup/S2-write read-before-write；
- reset、idle clear、pending-S2 clear；
- predicted-correct 与 mispredict 都训练；
- mispredict 不 restore；
- 两路输出及 `lookup*_bht_valid_o` ABI 不变。

mutation 必须先编译成功，再由指定 marker/断言失败检出，不能把编译失败算 RED。至少覆盖：lane1 复用 lane0 地址、bank/row 交换、插入 lookup pipeline、counter wrap/taken 反相、update 改成一拍或三拍、添加 RAW forwarding、clear 不清 bank-local update、same-bank read 仲裁、mispredict 抑制训练或触发 restore、综合 merge 后重新形成跨 bank fanout，以及 Liberty 删除 lookup arc、隐藏 state-Q arc、area/power 置零或缺 internal STA。

## Registry 与一次可逆 inline 实验

允许一次实验的边界：

- 只新增 local-PHT child/banks，并替换 parent 的 local-PHT state；
- 不改 `OooFrontend` 端口、FIFO sampling edge、BPU selector、GHR/BHT/local-history周期；
- child 与全部 banks inline；SRAM199、SRAM113、FP 仍保持同样三类 placeholder；
- comparison parent 固定为 `mapped-5ns-bpu-inline-v1`；
- 配置可使用 `mapped-5ns-bpu-local-pht-banked-child-inline-v1`，但必须先进入 registry，绑定 source manifest/design-id、filelist、elaboration reachability、owner=`rv64-bpu` 和 exact unknown-macro inventory；
- 结果只能登记为 `engineering_proxy_archive`，保持 `front_accepted=false`、`canonical=false`、`ppa_champion=false`。

功能门应包括 focused checker、上述 directed/mutation、同身份回归及系统层；由于只是物理重排，冻结 workload 的 prediction trace、branch accuracy、cycles/retired 应 bit-exact。不一致即视为语义失败，而不是允许的 CPI trade-off。

## PPA、retain 与 rollback

sealed whole-inline 当前值：logic-area proxy=`2465601.32`，sequential area=`679275.52`，BPU mapped area=`283823.40`，WNS/TNS=`-50.241458893/-719693.1875 ns`，40/40 violated，`target_200mhz_met=false`，fixed-toggle power=`0.162 W` 且仅 relative/unqualified。

四宏 comparison parent：logic-area proxy=`2181777.92`，WNS/TNS=`-11.550187111/-287464.78125 ns`，power=`0.136 W`，同样 unqualified。

raw marker `status=PASS` 只证明 synthesis/OpenSTA/parser/trace/binding/cleanup 收据闭合，不是 timing PASS。最坏路径原文为 `update_taken_i` DFF/Q 经 AOI21 到 `local_pht_q[0][0]` DFF/D，关键 arc=`54.784690857 ns`，slack marker=`slack (VIOLATED)`。

rollback 条件：

- 任一语义、cycle、mutation 或 state-count 失败；
- public update fanout 未被限定，或综合恢复等价跨 bank family；
- WNS、TNS、logic area任一不优于 whole-inline，或 bank read mux形成等价灾难路径；
- child 内部路径不可见；
- CPI/accuracy/trace 非 bit-exact。

提案中的“只要 WNS/TNS 严格更好、area delta 略低于 283823.40”最多支持继续研究，不能构成 Pareto retain；微小但仍灾难性的改善不得写成 production closure。正式 promotion 仍需 WNS/slack≥`+0.10 ns`、TNS=0、violations=0、loops=0、per-workload performance floor 与全局 Pareto checker、同口径 total area，以及 activity coverage≥95% 的 macro-inclusive qualified power。

## OOC fail-closed 条件

当前 `OooBranchDirectionPredictor.lib` SHA=`ddbd7ba1...1699c`，`area: 0`，把实际组合 lookup 错写为固定 `clk→output` placeholder；只可作历史 plumbing 锚。

未来 `OooBranchLocalPht.lib` 除两路 index→valid/counter 组合 arc、同步 update/reset/clear setup/hold、非零真实 area/power外，还必须覆盖隐藏 storage-Q 在 S2 沿变化后到 lookup output 的路径。可采用真实 `clk→lookup*_valid/ctr` characterization，或可审计的等价 memory timing abstraction；只有 address→output arc 会隐藏内部 state-Q→hybrid-select→FIFO-D 路径。

OOC 必须合取 exact child RTL/netlist/design-id 的 internal S1→S2 write STA、hidden storage-Q/read-mux→child-output STA、双路 same-bank 2R1W/read-before-write 功能模型、real min/max Liberty arcs/slew/load tables、top lookup-index→child→hybrid/FIFO 路径、top child-output→hybrid/FIFO 边界路径，以及 child 加 outside-child 的真实 area/internal/leakage power。任一缺失都只能判“路径隐藏”，不得 OOC PASS。

## Unknowns

- Yosys 是否保持 16-bank 层级并避免重新 sharing；
- public/bank-local fanout、capacitance 和 buffer tree 的真实数量；
- 54.78 ns 有多少来自 Liberty overload/ideal-clock proxy；
- 0-cycle async same-bank 2R1W 的可实现宏；
- bank mux 是否成为新关键路径；
- CTS、routing、多 corner、read-during-write 物理行为；
- qualified power、macro-inclusive total area；
- candidate 的 CPI、accuracy 和完整回归结果。

## Alternative hypotheses

- 高扇出可通过物理 buffering、drive-strength/fanout constraint 缓解，未必必须改 RTL banking。
- 54.78 ns 可能主要是 stdcell Liberty 在极端负载下外推失真。
- write fanout 修复后，`local_hist_q→PHT read mux→hybrid/FIFO` 可能立即成为主瓶颈。
- 采用 history bits 作 bank 的另一种 12-bit bijective physical permutation在语义上也可行；`PC[4:1]` 映射正确，但尚未被证明是唯一或 PPA 最优选择。
- 真正的多端口 SRAM/OOC macro 可能优于 flop banking，但目前没有可信 2R1W、read-first 和 PPA characterization。

`scope_extension_request=无`：合同内材料已足以判定 current candidate 未实现、证据不闭合；缺失工件本身就是 fail-closed 结论。再次评审需新增 candidate RTL、registry/filelist、directed TB、compile-success mutation、inline mapped receipt，以及后续 real OOC Liberty/internal+top STA，但这属于下一实现节点，不是本轮扩域。

`confidence_and_basis`：bank/row 与现有周期语义为高置信度，依据 current RTL/spec/source hash；whole-inline 数值与身份为高置信度，依据 sealed summary/Top40/synth-stat；banking 能改善 fanout 为中等置信度；最终 timing/area/power/OOC 可行性为低置信度，尚无 candidate EDA 工件。

shell ownership 已归还；全部工程命令已停止。本轮未修改文件，未运行仿真、综合、STA、parser 或测试。
