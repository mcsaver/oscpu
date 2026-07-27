# CONTROL-EVENT-G1 ledger validator review v2

## 结论

本地 RV64 `CONTROL-EVENT-G1` 控制事件流水事务证据验证器的 current artifact 集合可重放为局部 `semantic_evidence=PASS`，旧 full-core candidate 仍保持 `closed_binding=GAP`；但本节点总体裁决为 **GAP**，不能确认“五个 v1 缺口均 fail-closed”。

阻塞反例是：`validate_control_event_debt()` 只对 evidence-index 递归执行下游 artifact 禁入检查，未对独立的 `mutations/summary.json` 执行 exact 顶层字段检查或同等递归检查。一个哈希完全一致、11 项原有变异字段不变、仅额外内嵌 `gates/arch-stable-audit.json` artifact 的 mutation summary 被完整 validator 接受（返回空错误列表）。这可重新形成 mutation summary → downstream audit → ledger → mutation summary 的证据拓扑环。

因此：

- 当前精确 artifact 集合是干净且 source-bound 的；
- 当前 canonical verify 与两项定向单测是绿的；
- 验证器对 mutation-summary 形状仍存在可构造假绿，尚不能作为“所有下游产物均被 fail-closed 禁入”的硬证明；
- 9/9 directed architecture gates 不推导 full-core freeze，也不推导 PPA qualification。

## 实际执行结果

| 动作 | 结果 | 关键证据 |
| --- | --- | --- |
| 合同 JSON SHA-256 | PASS | `0bbc76666726d66ab1dd6224d4e2d7718f5e7e3231dd182ea2e83c5edb1248f8`，与派发值一致 |
| canonical evidence-index verify | PASS | `[V9O-EVIDENCE-INDEX-VERIFY] ... artifacts=164 status=PASS` |
| 两项 CONTROL-EVENT-G1 定向单测 | PASS，2/2 | `test_control_event_debt_evidence_is_current`、`test_control_event_payload_rejects_false_green_shapes` |
| full-core GAP 边界两项补充单测 | 1 PASS / 1 FAIL | `test_cli_require_stable_returns_two_for_current_gap` PASS；`test_current_candidate_is_honest_gap_with_dynamic_inventory` 因仍期望 109、live Makefile 已为 110 而 FAIL |
| 独立 reviewer 探针 | current binding PASS；1 个假绿被接受 | 详见 `replay-probes.json` |

canonical verify 重放得到：

- RTL design-id：`sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`
- RTL source set：146 files
- verification source-id：`sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1`
- verification source set：133 files
- indexed artifacts：164

## 五个 v1 缺口逐项复核

| v1 缺口 | 裁决 | 源码与 current artifact 交叉证据 |
| --- | --- | --- |
| 精确 provenance 集合 | PASS | `set(index.provenance) == CONTROL_EVENT_PROVENANCE_PATHS`；23 个 canonical path 精确相等，记录均为 `path/sha256/size_bytes`，canonical provenance SHA 也通过 verify |
| 下游产物禁入 | **GAP** | current index 的 164 个 artifact 中 forbidden 交集为空；把 downstream audit artifact 插入 index 会被拒绝。但同一 artifact 插入 mutation summary 顶层后，完整 `validate_control_event_debt()` 返回 `[]` |
| 11 项 RTL 变异映射 | PASS | 11 个 name 精确集合；逐项绑定 `source/test_name/make_variable/rejection_mode/make_returncode/lint_returncode/expected_markers/observed_markers/log path`；10 dynamic + 1 lint；source remap 探针被拒绝 |
| Makefile 模块清单 | PASS（验证逻辑）/ GAP（回归卫生） | live `TESTS :=` 动态解析无错误、110 项且顺序与 index inventory 完全一致；但现有 full-core workspace 单测仍硬编码 `109`，导致补充回归 FAIL |
| live full-core candidate 绑定 | PASS | live schema 为 `npc-rv64-arch-stable-candidate-v1`；candidate `sha256:2eff...c8b2` 与 index boundary 一致且不同于局部 RTL `sha256:08d3...8c6a`；实际 evaluate 为 `architecture_freeze=GAP`、`ppa=UNQUALIFIED`、`promotion_eligible=false`，并得到 `semantic_evidence=PASS` / `closed_binding=GAP` |

## 可构造假绿与负向探针

reviewer fixture 只写入本输出目录；它重定向 fixture path 常量，但不修改验证器函数或判断逻辑，并为 fixture 重新计算 mutation 文件 SHA、index summary SHA、index provenance SHA 与模拟 ledger evidence SHA。

1. **index 内嵌 downstream audit artifact**：被拒绝，错误为  
   `CONTROL-EVENT-G1 self-referential artifact is forbidden: .../gates/arch-stable-audit.json`。

2. **mutation summary 内嵌同一 downstream audit artifact**：**被接受**，`errors=[]`。  
   根因位于验证分层：`validate_indexed_artifacts(index)` 只遍历 `index`；随后对 `mutations` 只检查选定语义字段和 11 条 result mapping，既不拒绝额外顶层字段，也不递归应用 `CONTROL_EVENT_FORBIDDEN_ARTIFACT_PATHS`。

3. **把首条 mutation 的 `source` 重映射为 `OooCoreTopGlue.v`**：被拒绝，错误为  
   `CONTROL-EVENT-G1 compile-success RTL mutation semantics drifted`。

现有定向单测还证明以下 payload 形状被拒绝：缺 strict-younger variant、缺 8-class matrix、从局部闭合提升 PPA、错误 design identity、provenance 自指、focused log 复用、mutation source remap。

## 审查者人格复核

实现者视角的交付证据支持：current RTL/verification source identity、exact provenance、164 artifact、110 module、11 mutation mapping 与旧 candidate GAP 均一致，canonical replay 为 PASS。

审查者视角找到两个不能忽略的反例：

- mutation summary 可内嵌 downstream artifact 而完整 validator 假绿；
- workspace full-core boundary 单测仍含 109 项旧期望，整份 `test_arch_stable_freeze.py` 不能宣称全绿。

冲突未关闭，因此只能交付“current artifact 局部一致 + validator fail-closed 仍有 GAP”，不能签发全 PASS。

## 合同符合性

- 合同 JSON 哈希已独立核对。
- 只读取合同枚举的 `npc/rv64`、本 task-run 与规则文件。
- 仅运行合同枚举的 `sha256sum`、`sed`、`rg`、`git diff`、`python3`。
- 网络、账户、凭据、外部服务均未使用。
- 写入仅位于 `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/validator-review-v2`。

## unknowns 与范围扩展请求

- 本节点验证的是已生成 evidence 的重放与 validator 负向形状；未重新生成 110 个 module TB、11 个 RTL mutation 或 9 个 architecture gate。
- 未在本 verification 合同内修改共享 validator 或测试。
- 若要关闭 blocker，需要新版 implementation contract 至少授权写入：
  - `npc/rv64/eval/ppa/tools/arch_stable_freeze.py`
  - `npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py`
  - 如在构造侧同步 exact schema，则包括 task-run `build-evidence-index.py`
  - 因 validator 位于 provenance，修复后还需重建 `evidence-index.json` 并刷新 ledger 中对应 artifact SHA
- 建议新增 full-validator 单测：mutation summary 额外 downstream artifact 必须被拒绝；同时把 live inventory 断言由硬编码 109 更新为动态 110 或直接与 `parse_required_tests()` 结果绑定。

## 置信度

- mutation-summary downstream 假绿：高（0.99），由完整 validator fixture 实际返回 `[]` 证明。
- 五项 current binding 数值：高（0.98），由独立 source recomputation、canonical verify 与 reviewer JSON 交叉证明。
- 未发现其它 validator 形状漏洞：中等（0.75）；本节点未运行全量 fuzz/property-based schema 探索。
