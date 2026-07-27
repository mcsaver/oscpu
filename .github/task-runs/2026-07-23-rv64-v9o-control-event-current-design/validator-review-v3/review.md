# CONTROL-EVENT-G1 ledger validator review v3

## 结论

本地 RV64 CONTROL-EVENT-G1 控制事件流水事务证据的 current artifact 重放为局部 semantic_evidence=PASS，旧 full-core candidate 仍为 closed_binding=GAP。v2 的 mutation-summary 顶层 schema extension 与嵌套 downstream artifact reference 均由完整 validate_control_event_debt() 拒绝；canonical verify 和四项 CurrentWorkspaceTests 全部 PASS。

但验证器仍存在一项可实测的证据拓扑假绿：把当前 architecture hard-gates result 复制为另一 workspace-relative JSON artifact，向副本内嵌 architecture-debt-ledger artifact reference，再让 evidence index 指向该副本，完整 validator 返回空错误列表。该反例不改变 9/9 gate 字段、RTL source binding、index artifact count 或 canonical provenance hash，说明当前递归仅遍历 index 与 mutation summary 的内存对象，不递归审计被引用 JSON artifact 的内容。因此本 reviewer 总体裁决为 **GAP**；current artifact 局部闭合成立，但不能签发全局证据 DAG fail-closed。

## 逐项结果

| 项目 | 裁决 | 证据 |
| --- | --- | --- |
| 合同 JSON SHA-256 | PASS | d6dc3fc808fa859b97a6bc415ba3ac0fb0f98b40d92867479cf31f9616da368c，与派发值一致 |
| canonical evidence-index verify | PASS | [V9O-EVIDENCE-INDEX-VERIFY] design_id=sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a verification_id=sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1 artifacts=164 status=PASS |
| 四项 CurrentWorkspaceTests | PASS | 4/4；current evidence、false-green shapes、动态 inventory 与 require-stable GAP 均通过 |
| v2 mutation-summary schema extension | PASS | 完整 validator 拒绝：CONTROL-EVENT-G1 mutation-summary field set drifted; CONTROL-EVENT-G1 self-referential artifact is forbidden: .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/gates/arch-stable-audit.json |
| v2 nested downstream reference | PASS | 完整 validator 拒绝：CONTROL-EVENT-G1 self-referential artifact is forbidden: .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/gates/arch-stable-audit.json; CONTROL-EVENT-G1 compile-success RTL mutation semantics drifted |
| Makefile 动态 full-core inventory | PASS | 110 modules，parse errors=[]，与 index inventory 精确相等 |
| 精确 provenance | PASS | 23 paths，集合精确相等 |
| RTL mutation mapping | PASS | required/compile-success/rejected=11/11/11，11-name exact=true |
| live candidate binding | PASS | candidate=sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2，boundary identity 精确相等，且不同于 local design=sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a |
| full-core boundary | PASS | architecture freeze=GAP，blockers=59，PPA=UNQUALIFIED，promotion=false |
| 一层间接 JSON artifact topology | **GAP** | fixture accepted=true，完整 validator errors=[] |

## v2 反例复测

1. 顶层 downstream_artifact schema extension 被拒绝。错误同时包含 mutation-summary field set drifted 与 forbidden artifact，证明 exact top-level schema 生效。
2. 在首条 mutation result 的既有 purpose 字段内嵌 artifact object 被拒绝。错误包含 forbidden artifact，且 purpose 类型使 mutation semantics 同时 fail-closed，证明递归遍历 mutation summary 生效。

两项 fixture 都重新计算 mutation summary SHA、index summary record、index canonical provenance SHA 与模拟 ledger evidence SHA，并通过完整 validate_control_event_debt() 入口，而不是只调用浅层字段断言。

## 当前绑定

- RTL source identity：sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a，146 files，live recomputation 精确相等。
- verification source identity：sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1，133 files，live recomputation 精确相等。
- evidence index：164 unique artifacts；current 完整 validator errors=[]。
- current CONTROL-EVENT-G1：semantic_evidence=PASS；由于 full-core candidate design-id 仍是旧 cohort，closed_binding=GAP。
- full-core evaluation：59 blockers、PPA UNQUALIFIED、promotion false；9/9 directed architecture gate 不推导 full-core freeze 或 PPA qualification。

## 仍可构造的证据拓扑假绿

architecture_hard_gates.result 的 index record 未绑定固定 path。完整 validator 只核对该 record 的 hash/size，并在加载 JSON 后核对 overall_status、exit_code、RTL source set 与九个 gate 状态；它没有对加载后的 JSON 再执行 downstream-reference 递归。

v3 fixture 将原 result 复制到 reviewer 输出目录，加入指向 npc/rv64/design/arch/architecture-debt-ledger.json 的 path/sha256/size_bytes artifact object，更新 index result record 与 canonical provenance hash 后，完整 validator 接受。这个一层间接引用反例不否定 canonical builder 生成的 current artifact，但否定验证器对任意同形 ledger evidence 的全局 DAG 无环证明。

## 合同符合性

- 只读取合同枚举的 npc/rv64、当前 task-run 与两份规则文件。
- 新文件只写入 validator-review-v3 目录。
- 只使用合同列出的 sha256sum、sed、rg、git diff、python3；未使用网络或非工作区来源。
- contract JSON 哈希独立复核通过。

## unknowns

- 本节点重放既有 110-module、11-mutation 与 9-gate 证据，未重新运行这些生成型仿真任务。
- 未执行全空间 property-based JSON topology fuzz；除已实测的一层间接引用外，不能证明不存在其它未约束 artifact path 或内容替换。
- 当前输出目录中的 fixtures 是 validator 负向证据，不是可提升的 current-design evidence。

## scope_extension_request

若要关闭剩余假绿，请生成新版 implementation contract，至少授权 arch_stable_freeze.py、定向测试、build-evidence-index.py、evidence-index 与 ledger hash 刷新。建议把允许引用的 artifact path/role 绑定成精确表，并对所有 JSON artifact 进行有界递归 DAG 审计，或按 schema/role 明确禁止下游引用。当前 v3 verification 合同不授权修改这些共享文件。

## 实现者人格与审查者人格对抗

实现者证据支持 current design-id、146-file RTL、133-file verification、164 artifact、110 module、11 mutation 与旧 candidate GAP 一致；两条 v2 反例已关闭。

审查者的一层间接 artifact fixture 仍被完整 validator 接受，冲突未关闭。因此只能交付 current-design 局部闭合与 validator 总体 GAP，不能声明证据拓扑验证整体完成。

## 置信度

- v2 两条反例已关闭：高（0.99），由完整 validator fixture 实测拒绝。
- current 110-module、精确 provenance、11-mutation、live candidate 与 59-blocker 边界：高（0.99），由 canonical verify、四项工作区单测和 live recomputation 交叉验证。
- 间接 architecture result 拓扑假绿：高（0.99），由完整 validator 返回 errors=[] 实测。
- 未发现更多拓扑漏洞：中等偏低（0.65），未做全空间 property-based fuzz。
