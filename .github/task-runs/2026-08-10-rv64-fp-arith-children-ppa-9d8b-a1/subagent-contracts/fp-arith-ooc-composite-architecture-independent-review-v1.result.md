# FP arithmetic OOC composite architecture independent review v1

RV64 RTL 结论｜对象=OooFpArithGate、五个 production child 及 OOC Liberty→NpcTop composite artifact graph｜周期/配置=launch-to-out 5 拍、每周期一发、live sha256:9d8bb6af、5.0ns typ_tt diagnostic｜TB/EDA 观测=功能 1/1 PASS、17/17 mutation rejected；既有 monolithic synthesis FAIL，未取得有效 mapped/OpenSTA/PPA｜范围=GAP

## 独立裁决

**FIX**。五个 production child 的 OOC 分解可行、可逆，不构成永久 BLOCK；但当前 Registry、runner、OpenSTA Tcl 与 parser 无法 fail-closed 表达“具有真实面积与时序弧的已知 OOC macro”。必须先新增一个版本化 `ooc_sta_abstraction` composite profile 及其负向门禁，再允许一个全新 run-id 的单次诊断实验。

## 五个 child 的真实边界

| Child | 真实流水边界 | OOC 内必须证明 | 顶层必须组合 |
|---|---|---|---|
| `OooFpAddSubPipe` | S1→S2→S3 | port→S1-D、S1→S2、S2→S3、S3-Q→port | S3 clk-to-Q→wrapper S4-D |
| `OooFpMulProductPipe` | 仅 S1 | port→S1-D、S1-Q→port；不存在 reg→reg path | S1-Q→`OooFpMulNormRoundPipe` S2-D |
| `OooFpMulNormRoundPipe` | S2→S3 | port→S2-D、S2→S3、S3-Q→port | S3-Q→wrapper S4-D |
| `OooFpFmaAlignAddPipe` | S1→S2→S3 | port→S1-D、S1→S2、S2→S3、S3-Q→port | S3-Q→`OooFpFmaNormRoundPipe` S4-D |
| `OooFpFmaNormRoundPipe` | S4→S5 | port→S4-D、S4→S5、S5-Q→port | S5-Q→wrapper result mux→backend completion/FIFO-D |

`OooFpArithGate` 保留 metadata、kill、valid、ProducerId、pdest、double、kind 的 S1–S5，以及 AddSub/Mul 的 S4/S5 对齐。五个 child 没有 ready/stall，寄存器每拍推进。`rst`、`flush_i` 是同步优先控制，必须建 setup/hold 并在 OOC 内证明控制扇出，不得建 recovery/removal。

五个 child 都没有真实 PI→PO 同周期组合通路，禁止添加虚假的 input-to-output Liberty arc。标准 sequential Liberty 也不编码“五拍功能关联”；五拍/吞吐由相同 design-id 的功能收据证明，Liberty 只承担首级输入约束、末级 clk-to-Q 及顶层跨边界 STA。所有 child 边界禁止 multicycle/false-path。

## 当前承重阻断

1. Registry 只有 `placeholder_blackbox` 与 `inline_rtl`；runner 又把 synthesis blackbox 直接当 parser 的 unknown placeholder，无法表达 `known_ooc_macro`。
2. 当前 OpenSTA 只报告 max，不报告 min/hold。
3. 当前 FP parser 强制 `negative_slack_pin_count > 0`，会误拒绝干净设计；同时依赖 `u_fp_arith` 名称可形成命名型假绿。
4. 当前 hierarchy census 要求 wrapper/五 child 都作为 inline module section 具有非零 cells/area，和顶层 known macro 语义冲突。
5. 当前 runner 没有逐 child OOC mapping、max/min STA、Liberty generator/validator 或 composite binding 阶段。
6. 缺少 pin capacitance、load/slew、min/max、同步控制与 corner 绑定的手写 Liberty 不得冒充 production characterization；当前最多只能产生 `OOC_STA_ABSTRACTION` typ_tt 诊断模型。

## 必须杀死的反例

- setup/hold/clk-to-Q arc 被删除、置零、错符号或错 `related_pin`。
- 虚假 PI→PO 组合弧，或 multicycle/false-path 隐藏真实跨 child 单周期路径。
- child 内部负 slack 而顶层抽象仍判完整 PASS。
- Liberty、RTL、helper、stdlib、工具、corner、SDC 或 profile 跨源码/跨 run-id 重放。
- 顶层同时保留 child stdcell 实现与 child macro，导致重复实现。
- NpcTop macro area 与 OOC area 双计，或 `cell_area=0` 漏计。
- 缺少 macro power model 时仍输出完整 power delta。
- 一条任意 `u_fp_arith` 路径冒充五个 child 的精确 boundary-class census。

## 进入实现合同的唯一最小修订

- 把 `inline_rtl`、`known_ooc_macro`、`unknown_placeholder` 三类边界分开；unknown 集合仍精确为 Sram4096x199×1、Sram4096x113×2、OooBranchDirectionPredictor×1。
- 五个 child 分别绑定 RTL/helper/filelist、mapped netlist、synth check/stat、max/min path、四类 arc census、area 与顺序 Liberty；MulProduct 使用 port→register 特例。
- 顶层只 inline wrapper，五个 child 各一个 known macro；拒绝 child RTL/stdcell 与 macro 重复存在。
- 顶层报告 max/min、跨 child、wrapper S4/S5、同步控制及 final completion 路径。
- 总面积仅计 Liberty macro area 一次，OOC area只用于核账；无 power model则明确 power incomplete。
- 所有 child artifact、generator/parser、stdlib、工具二进制、corner/units/load/slew/SDC 与同一新 run-id 的 composite manifest、summary、binding、cleanup 原子绑定。
- EDA 前先用定向负向测试攻击 arc、身份、重复实现、面积及路径反例。

最小 artifact graph：

```text
functional receipt/design-id
  → 5× exact child source closure
  → 5× OOC mapped/stat/max+min/internal inventory
  → 5× Liberty+arc/area receipt
  → composite manifest
  → NpcTop wrapper-inline/known-child-macro mapping
  → top max+min/boundary census/area reconciliation
  → parser summary
  → Registry binding
  → cleanup/status
```

即使实验成功，也只是非-placeholder composite diagnostic evidence；没有 LEF、P&R/寄生、多角落、完整 IO constraint 与 macro-inclusive qualified power，Registry 上限仍为 GAP、noncanonical、nonchampion。

## 身份和范围

- 功能收据 SHA：`f79726b683e602874164036083371669c8005d647eb529d3ef0d5facaaa50814`
- review contract SHA：`f2637ebe3c2b375e2e61698b52c35091ffce05ec1b6d9e33d0046a448fc9f54c`
- 当前 runner/OpenSTA/parser SHA 前缀：`295a8b13`、`b970c7a9`、`3269c7b8`。
- 精确 monolithic timeout owner、五 child OOC 可完成性、fast-corner hold、寄生与 macro power 仍未知。
- 本复核未运行 Python、测试、仿真、综合、OpenSTA 或 parser，未修改文件；WSL shell 已归还。
