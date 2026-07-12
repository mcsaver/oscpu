# RV64 F1a：BPU static-taken scalar ABI 与 placeholder 负载校正

## 基本信息

- `task_id`: 2026-07-12-rv64-f1a-bpu-static-taken
- `task_slug`: rv64-f1a-bpu-static-taken
- `graph_template`: architecture-refactor + timing-ab
- `graph_mode`: static+dynamic
- `status`: completed
- `owner`: root + bpu_lookup_iface + bpu_macro_timing + frontend_dirty_safe
- `started_at`: 2026-07-12 13:45:00 +0800
- `updated_at`: 2026-07-12 21:14:00 +0800

## 目标与范围

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `goal`: 把 BPU lookup fallback 从两路 64-bit immediate 收窄为两路 1-bit static-taken，
  同步 RTL/checker/TB/placeholder Liberty，并用相同 5ns 流程判断收益。
- `scope`: 不改变 predictor table、GHR、update 两拍流水、frontend redirect/fault gate、
  target address、fetch handshake 或流水级。
- `dirty-file boundary`: `OooFrontend.v` 有用户注释 hunk；只允许 partial-stage 391 行说明与
  1898 行 BPU 接口 hunk，用户 1139 行 hunk SHA256 必须保持
  `91fdf972d4395496f80fc0b24cf6caf77cb780508f99ec7c4a0b7c5435d79b46`。

## 根因

- RTL、checker 与 TB 的旧行为都只读 `imm[63]`；但旧 BPU macro ABI 暴露完整 immediate，
  B-imm sign extension 让每 lane 的 `imm[63:12]` 共 52 个 0.01pF placeholder pin 落在同一网。
- 这既制造约 0.51pF/lane 的无语义虚拟负载，也让 macro ABI 谎称 predictor 消费完整 immediate。
- 修复是收窄 owner 接口，不是插 buffer 或调 Liberty 数字；target adder 仍消费完整 B-imm。

## 六类合同与同拍优先级

1. lookup 仍为 0-cycle 纯组合 view，无握手/occupancy。
2. 无 stall/backpressure 状态，parent 冻结语义不变。
3. `reset/clear > update stage1/stage2` 不变，接口刀不新增状态。
4. exception/fault/invalid slot 的 prediction consume gate 仍只在 frontend。
5. 无 AXI/cache/访存 owner 变化。
6. 两路 `fetch_dec*_bimm_w[63]` 分别成为 static fallback 唯一真源；GHR/update/redirect
   单一真源不变。

## RED 与验收

- `BPU-ST1` structural RED：current predictor 仍暴露 `lookup*_imm_i[63:0]`，命令 rc=1。
- focused GREEN：双 lane forward/backward fallback、valid counter 覆盖 static bit、clear、GHR、
  update 与 checker 全绿。
- structural GREEN：active RTL/checker/generator/Liberty 无旧 imm port；两路 scalar pin 位宽为 1。
- timing gate：same HEAD/config/tool/standard-cell lib/其余三颗 macro lib；A 使用 wide-port BPU
  placeholder，B 使用端口匹配的 scalar BPU placeholder，两者 PIN_CAP/setup/hold/clk2q 常量相同。
  只在报告限制相同且 WNS/TNS/area 可解释时保留，不能把 placeholder 改口径越级称为 signoff。

## 当前边界

- `functional gates`: scalar macro checker PASS；错误 bit owner 负探针 rc=1；focused 2/2、
  module 87/87、Verilator 5.051 lint、RTL style、contract 38/38、Python compile 均 PASS。
- `core regress`: clean build PASS，AM 59/59，official p-mode 153/153 build + 153/153 run；
  current config 为 Difftest OFF，本轮未覆盖 privileged rv64mi/rv64si 或 Difftest。
- `timing state`: 有效 fresh pair 是 clean `5bd7a1546` A 与 F1a B；早先 c6b/B 混版报告已拒绝。
  WNS 均为 -12.90ns，TNS `-198649.61→-197335.64ns`（+0.661451%），两路目标 sign cone
  slack 改善 6.567661/6.021283ns；top40 完全相同且仍在后端。TNS 同时少了 126 个
  placeholder setup endpoint，只作辅助证据；candidate KEEP 的主因是 ABI 与目标 cone，不是 200MHz。
- `parent_goal`: active；本刀只提高时序模型与接口真实性，不宣称完整功能或 200 MHz 已闭合。
- `functional blockers`: IFU-AXI-G1、IFU-FETCH-G2、PTW-PMP-G1 仍开放。

## RTL 推导摘要

- **需求要点**：predictor 只拥有 branch direction fallback，不拥有完整 immediate 或 target
  address；因此外部 lookup ABI 必须只表达 `static_taken`。
- **协议/状态机**：lookup 仍是 0-cycle 无握手组合 view；update 两拍流水、GHR、table valid、
  `rst/clear` 优先级与可见拍均保持原样，没有新增 FSM、credit 或 backpressure。
- **关键不变量**：lane0/1 分别来自 `fetch_dec0/1_bimm_w[XLEN-1]`；invalid entry 由 static bit
  决定，valid counter 覆盖 static bit；完整 B-imm target adder、fault/redirect consume gate 不变。
- **数据通路骨架**：PacketDecode B-imm sign → scalar BPU lookup fallback；PacketDecode full B-imm
  → frontend target adder。debug checker/TB/generator/Liberty 使用同一 ABI，旧宽口由 checker 禁止。

## 验证与 A/B 结论

- TDD/反例：structural RED、合同 checker RED、错误 owner-bit 负探针，以及 mixed-selector
  ticked RED 都精确命中目标；settle-only selector 尝试因未触发 posedge assertion 被拒绝为假绿。
- 新鲜功能证据见 `evidence/final-validation/summary.txt`；core 证据见
  `evidence/core-regress/20260712-210142-1697127/audit-summary.txt`。
- fresh timing 输入身份、报告与结论见 `evidence/timing/input-identity.txt`、
  `A5bd-top40.rpt`、`B-final-top40.rpt`、`timing-comparison-summary.txt`。两侧 post-map 都是
  0 problems；check_setup 同为 303 inputs 无 input delay、1849 outputs 无 output delay、
  1851 unconstrained endpoints、204 combinational loops。
- BPU/其余 macro 面积仍 unknown；BPU placeholder 不含 lookup input→output 组合弧，vectorless
  macro power=0，且无 SPEF/CTS/OCV。当前约束关键路径约 17.895ns（约 55.88MHz），远未到
  200MHz；此外 wide→scalar 少了 126 个 macro input setup endpoint，TNS 改善不能全部归因于
  共享网减载。F1a 只能判为局部减载/ABI 修正成功。

## 实现者 / 审查者对抗

- **实现者人格**：接口全链收窄，target owner 保持，focused/module/core 与同输入 full synth/STA
  给出完整 GREEN；目标 sign cone 的 cap、driver delay、slack 均大幅改善，因此保留 candidate。
- **审查者人格**：发现并修复 checker selector typo；拒绝未跨采样沿的假绿；拒绝 c6b/B 混版
  A/B；核对 top40 仅 TNS 行不同、WNS 无改善、面积微增、power 无解释力，并确认 placeholder
  限制。最终对 F1a 功能与 KEEP 决策 `NO BLOCKER`，但明确反对“200MHz 已完成”结论。
- **未解决冲突**：parent 目标仍受功能三项与后端/前端 mandatory registered boundary 阻塞；
  本 task 只可标记 slice completed，不能标记 parent complete。

## 收尾结论

- `final_result`: F1a scalar static-fallback ABI 功能闭合，candidate KEEP；full-chip 200MHz 未闭合。
- `workflow evidence`: fresh `npc-dev`、`yosys-sta` 与 `agent-system` profile 均 completed/PASS；
  前两者分别位于
  `.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken-npc-final/` 与
  `.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken-yosys-final/`，后者位于
  `.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken-agent-final/`。最终 strict guard
  对三个 required profile 全部 PASS。
- `next slice`: 先关闭 IFU-AXI-G1（flush 不得取消已呈现的 A-update AXI write owner；必须补齐
  AW/W 并消费 B 后 drop），再做 IFU-FETCH-G2、PTW-PMP-G1，最后进入 mandatory repipeline。
