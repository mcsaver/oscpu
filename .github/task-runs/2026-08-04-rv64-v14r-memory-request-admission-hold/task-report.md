# V14R memory request admission hold — RTL 推导摘要

## 接口契约冻结（阶段 0）

- 规范真源：`npc/rv64/design/specs/ooo-memory-request-admission-hold.md`。
- 受影响边界：`OooIntBackend` bank0/bank1 request VALID/READY、217-bit payload、source fire与MIQ birth。
- 六类合同已冻结：端口/握手、stall DAG、flush/kill、异常与内存序、owner真源、reset/参数。
- flush/recovery：reset/flush/restore与授权source cancel先产生invalid bubble；cancel拍不fallback、不fire、
  不push MIQ。SQ/AMO exact older owner不被后到live priority替换。
- 同拍全序：`reset > cancellation/source-loss quarantine > held fire > held residency > stalled capture > idle`。
- 已实现立即断言：`V14R-H0..H7`；compile-success holder-bypass mutation与release TB形成双oracle。

## 阶段 1 — 需求

1. `valid&&!ready` 后保持bank-local source、owner tuple和完整payload到exact fire。
2. 后到高优先级source不得抢占held request；allowed cancel必须先显示VALID=0 bubble。
3. fire、source consume和MIQ birth同拍同源；保留SQ/AMO/buffer singleton与双bank ordinary并行。
4. 不修改bridge/AXI/B terminal、owner tracker、MIQ容量、cache或production workload语义。
5. 生产PPA目标是最小控制状态，不复制两份217-bit payload。

## 阶段 2a — 协议规则

- IDLE live winner若READY=1同拍fire；READY=0则捕获one-hot + kind/token/epoch。
- HELD selection覆盖live priority；READY只决定fire与时序clear，不进入VALID组合逻辑。
- source Q承载payload；`OOO_ASSERT` shadow逐位证明stall稳定。
- cancel/source-loss拍effective grant为零，下一拍才重新仲裁。

## 阶段 2b — 状态机

- 每bank两态：IDLE / HELD。
- bank0寄存`valid + sel[5:0] + kind[1:0] + token[4:0] + epoch[1:0]`共16bit。
- bank1寄存`valid + sel[2:0] + kind[1:0] + token[4:0] + epoch[1:0]`共13bit。
- transition与同拍优先级见规范§3.1/§2.3。

## 阶段 2c — 不变量

- effective grant/holder one-hot；stall后VALID/payload稳定；source exact resident；fire/consume/MIQ原子；
  cancel bubble；singleton cross-bank exclusion；无READY→VALID SCC。
- 任何意外source loss fail loud，不以collector去重、waiver或断言削弱收口。

## 阶段 2d — 数据通路约束

- 现有live priority改名为live grant；新增hold-source exact compare与effective grant层。
- 既有request/MIQ宽mux只替换选择信号，不新增production payload register或第二套mux。
- critical path是小tuple compare/hold Q到existing one-hot mux；READY不在该锥。

## 阶段 2e — RTL级拓扑自审

- module边界、两bank handshake、29bit状态、两态FSM、reset/cancel全序、singleton共享资源与关键路径
  均已列明。普通不同bank并行不被全局holder串行化。
- 备选full-payload skid约434 FF，仅在source Q稳定性不能闭合或STA证明更优时重新评估。
- 自审结论：29-bit控制holder进入production RTL；217-bit宽payload只在`OOO_ASSERT` shadow中保存。

## 阶段 3 — production RTL 与定向验证

- `OooIntBackend.v`：两bank均使用live/effective selector、source exact compare、stall capture、exact fire
  clear和cancel bubble；所有request、source consume与MIQ metadata改读effective selector。
- 单bank关联修复：older MIQ probe可能成为SQ physical head时，阻止younger plain-store probe先展示；
  保持reservation在SQ fire边沿缓冲的既有语义。
- focused结果：`holder_ff=29 payload_bits=217 banks=2 late_priority=2 exact_fire=2
  exact_source=2 independent_bank=1 late_sq_block=1 nonflush_cancel=1 capacity_isolation=2
  cancel_ready_race=1 PASS`。
- single-bank结果：`older_probe=1 younger_store_block=1 valid_lease=0 mutation_anchor=2 PASS`。
- mutation matrix：holder bypass、cancel fallback、consume/MIQ live split、single-bank probe-order
  bypass四个版本均编译成功，并分别命中专属拒绝marker及最终`[RESULT] FAIL`；aggregate 4/4，
  mutation前后production SHA一致。领域PASS marker只在`tb_errors==0`时输出。
- link regressions：V8S双memory、default legacy、V11L retry、V11M reservation均PASS；style、Verilator
  lint和`check-contract` PASS。

固定入口：

```text
npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh --tier fast
npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh --tier link
```

## 阶段 4 — 当前设计身份与 workload 诊断

- production RTL design-id：`sha256:5a6895c8b2ec27cb45aec8bb935dcb2e415cc8935a1eff53686b03cdf981f9f4`。
- 新Yosys instance graph：15个holder module、17个实例、2个合法重复实例；producer-holder census为
  `direct=20 packed=5 token_q=17 generation=1`，37项graph/census单测PASS。
- 当前CoreMark：5,380,028 cycles、3,183,617 retired、CoreMark PASS、GOOD TRAP、完整ROI；
  `invalid_events=0`且13类invalid reason全零。相比旧参考少12,159 cycles，但这是跨设计诊断，不能直接
  声称性能收益。
- 原始run保持`FAIL rc=1 stage=receipt-build`，因为旧oracle要求与旧设计counter bit-exact；修正后的
  checker只重放冻结manifest/simulator/cleanup/log，独立run为PASS并声明`dut_rerun=0`、
  `observer_noninterference_qualified=false`、`PPA=UNQUALIFIED`。

证据指针：

- 当前graph：`evidence/current-holder-instance-graph/`。
- 当前focused/mutation/regression：本task-run的`verification-v3/`；仅保留result/log/diff/manifest，
  无build/VVP/mutant工作副本。`verification-v2/`保留终审前一版原始输入，供反例复盘。
- 原始workload：`.github/task-runs/2026-08-04-rv64-v14r-owner-timing-invalid-probe-v1/`。
- checker replay：`.github/task-runs/2026-08-04-rv64-v14r-owner-timing-checker-replay-v1/`。
- 独立审查：`evidence/independent-review-v2.md`与`evidence/oracle-followup-review-v3.md`。

## 阶段 5 — 当前边界

V14R request admission合同与目标workload invalid-event根因已经闭合；完整ARCH_STABLE功能cohort、
同设计stats-off/stats-on三次A/B、综合/STA/Power与PPA promotion尚未重建，继续保持GAP/UNQUALIFIED。

## 阶段 6 — 公开 SoC 方法论与轻量工作流固化

- 方法论基于公开可核验的RISC-V、AXI、OpenTitan/lowRISC、OpenHW以及公开EDA signoff实践；不声称
  复制任何厂商内部流程。任务分类、执行tier与设计maturity保持正交。
- `review/analysis`保持零自动门；普通RTL只映射domain fast。显式
  `rv64-memory-request-hold-link`会正规化掉auto-fast，避免重复运行。
- 固定wheel支持`--evidence-dir`，且只允许写入`.github/task-runs/`的显式空子目录；编译物始终进入
  `.github/runtime-artifacts/`并在结束清理。task-run只留marker、bounded log、diff、manifest与审查结论。
- 本轮C指针自测PASS；开发期不设置精确40%时间硬门，候选交付点才集中运行固定gate与独立审查。

## 阶段 7 — 交付前 strict guard 与 scoped GAP

- strict guard只消费agent-flow记录的58个显式路径，不扫描Git工作树；结果保持
  `FAIL rc=1`，缺少的宽泛profile为`npc-dev`与`agent-system`，原始输出见
  `strict-guard-v14r.log`和`strict-guard-v14r.status`。
- 本轮不为满足宽泛profile重复启动DUT/EDA：实际RTL surface已由V14R dual-bank/single-bank focused、
  四个专属marker的compile-success mutation、V8S/default/V11L/V11M link、RTL style、Verilator lint、
  contract check与两次独立审查覆盖；agent-system surface由C planner自测和delivery-gate配置检查覆盖。
- 该scoped豁免不改写guard FAIL，也不授权current ARCH_STABLE、同设计性能、综合、STA、power或PPA。
  production RTL、elaboration/config、simulator/device model或本轮oracle语义后续变化时，必须按对应
  maturity stage重新生成证据，不能继承本豁免。
