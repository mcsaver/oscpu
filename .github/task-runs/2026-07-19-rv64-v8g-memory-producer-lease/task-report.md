# RV64 v8g async-memory ProducerId lease 闭合报告

## 基本信息

- `task_id`: `2026-07-19-rv64-v8g-memory-producer-lease`
- `task_class`: `architecture_closure_without_ppa_promotion`
- `slice_status`: `scoped_completed`
- `parent_goal_state`: `active`
- `promotion_eligible`: `false`

本报告只签收 async-memory active-owner 的 ProducerId 租约、完成资格、不可逆 STORE/AMO
launch 与 response-credit 单向 DAG。MulDiv、CLMUL、FP、branch、global no-live-reuse、完整
DI/OOO hard gate、Linux、200 MHz 与 PPA 均不在本 GREEN 内。

## 实现者结论

- `OooMemOwnerTracker` 保存不可变 full ProducerId，导出 edge-old live bitmap/table；duplicate
  PID 与 death/birth 同沿重用 fail closed。
- ROB 增加 memory completion2 exact-open query、head full PID/launch-open 和 Q-only pair
  candidate；dispatch lane0、mandatory lane1 pair、optional lane1 都由 registered lease mask 门控。
- SQ allocation/bind/request/release 全程比较 full PID；physical STORE 在 exact B 前保持
  `request_sent && !terminal` owner。AMO write 同样重新证明 exact capability、head PID、
  launch-open 与 one-shot；post-launch ROB `!done` 由最终 response 唯一终结。
- backend 把 tracker mismatch、合法 speculative closed 和 irreversible fatal closed 分成互斥
  类别；只有 exact-open completion 可以进入 ROB/WB/PRF/Busy/IQ/public side effect。
- response-credit 断环不靠降吞吐：bridge raw drop 不读 advance，station query 读 Q；local
  terminal 做布尔等价因式分解；younger-killed buffer 禁止 request grant；六路 terminal mask
  直接取 scalar source，避免 packed-vector 粗粒度假环。

## 功能与静态硬门

| gate | 结果 | 证据 |
|---|---:|---|
| focused release | 7/7 PASS | `evidence/focused/summary.txt` |
| focused `OOO_ASSERT` | 7/7 PASS | `evidence/focused/summary.txt` |
| compile-success mutation | 29/29 命中；25 dynamic + 4 structural | `evidence/focused/mutation-summary.log` |
| source pre/post hash | byte-equal | `evidence/focused/sources.pre.sha256`、`sources.post.sha256` |
| module aggregate | 105/105 PASS | `evidence/full-module-aggregate-final/summary.txt` |
| structural audit | PASS | `evidence/static/structural-audit.log` |
| RTL style / contract | PASS；assertions 320 >= 89 | `evidence/static/check-rtl-style.log`、`check-contract.log` |
| architecture checker self-test | 15/15 PASS | `evidence/static/architecture-hard-gates.log` |
| real architecture inventory | `OVERALL: RED` | `evidence/static/architecture-hard-gates.json` |
| strict lint regression | inherited rc=2、115 warnings；normalized byte-equal v8d | `evidence/static/full-lint.status` |

lint 的非零状态未被豁免：它保留 115 条继承 warning；本切片只证明没有新增 warning signature，
并且最初暴露的 `core_mem_rsp_ready_w` SCC 已从 116 恢复为 115。

## 审查者反例与纠偏

1. reviewer 的四轮合同复核先后发现 launch/B terminal、open/closed 分类、tracker exact-tag、
   post-launch done、terminal credit 和 bounded grant 缺口；三份 amendment 在改 RTL 前冻结。
2. scoped-green 后的 no-tool 复核再提出 early done/release、连续 WB contention、kind/epoch
   mutation；全部转成定向测试和 mutation，而非把文字结论当证据。
3. runner 首版有两个假锚点：fatal-normal-final 只测 LOAD、STORE early-terminal mutation 先撞到
   更早 collector tuple mismatch。补 AMO closed-final 窗口并把 expected consequence 锚到真实最早
   失败后重跑，避免“mutation 失败了就算检出”的假绿。
4. static runner 首版把预期的 global architecture RED 当脚本错误；现要求 make rc=2、self-test
   精确 `OK`、inventory 精确 `OVERALL: RED` 三者同时成立，scoped green 不再遮住 parent RED。
5. full lint 真实发现 response-ready SCC。逐段切除四类结构回边后，以 4 个功能仿真仍 PASS、
   静态审计必须 FAIL 的 compile-success structural mutants 证明规则非文本装饰。

## AI 开发环境实战固化

- 子 agent 合同为 `subagent-contracts/v8g-memory-lease-contract-review.json`，SHA-256
  `de5814ab05adf13e0d966e5963b1b948dea5fa4c287fd5938e27bddd79b1b0a2`；哈希只绑定该 JSON。
- 实际 reviewer 边界比 JSON 上限更窄：no tools、no shell、no file access、no network，只消费
  自包含冻结摘要。Windows→WSL 工程命令由主 agent single-flight 执行。
- 常驻 instruction、`prepare-rtl-task-contract` skill 与 `agent-system/rtl-task-contract` e2e 已新增
  fail-closed 规则：文本反例必须转成 spec + TB/mutation/static audit，或显式记录剩余风险。
- 平台 review 只隔离当前子节点为 `review_pending`；禁止重复提交同一请求、改变 RTL 语义或把
  单节点状态传播成长期目标 global blocked。准确领域措辞用于消歧，不以改变平台分类为目标。

## 剩余 RED / UNKNOWN

- MulDiv、CLMUL、FP、branch 与其它 async holder 的 full ProducerId propagation/authorization；
- finite generation wrap 下的 global live collision fence 与完整 holder census；
- DI-1..5、OOO-1..4 当前 inventory 仍 RED；
- strict lint 的 115 条继承 warning、DiffTest/Linux/系统级恢复；
- arch-stable freeze、fresh synthesis/STA、qualified macro area/power、200 MHz 与 Pareto promotion。

## 最终裁决

v8g async-memory scoped slice 完成，父目标继续 `active`。本轮没有运行或授权 PPA promotion；
下一主序应继续剩余 holder/global collision fence，并在完整架构硬门闭合后才生成正式 PPA A/B。
