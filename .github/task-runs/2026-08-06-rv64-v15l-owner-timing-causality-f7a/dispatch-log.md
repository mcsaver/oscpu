# RV64 owner-timing causality dispatch log

## v15l-arch-stable-independent-review-f7a-v4

- 工程对象：本地 RV64 双发射 OoO 核 exact ARCH_STABLE candidate v4 的只读独立反例复核。
- 合同：`.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/subagent-contracts/v15l-arch-stable-independent-review-f7a-v4.json`
- 合同 SHA-256：`2bb555a48971e1efb053366c869592f523da63fe503dce63da31f0a3c70d7793`
- candidate SHA-256：`08cb6b8ef87995428f6eb1306c78313984feff235bcf404fb49fbf51e1f39b74`
- 权限：`read-only-review`；命令仅 `rg`、`sed`、`sha256sum`；无写路径。
- 结论：`PASS`；`unknowns=[]`、`scope_extension_request=none`，exact approval marker 恰好一次。
- 报告：`.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/arch-stable-independent-review-f7a-v4.md`
- 技术边界：v3→v4 仅重绑定 RV64 PPA 优化规范哈希；production RTL、配置、工具与 L0–L3 证据不变；PPA 仍为 `UNQUALIFIED`。
- 调度注记：reviewer 曾让一对冗余的 workflow-segment 只读哈希命令短暂重叠；该结果未进入结论，随后由串行整候选归一化哈希完整替代。全部命令已停止，无写入或残留进程，WSL ownership 已归还。

## v15l-owner-timing-independent-review-f7a-a2

- 工程对象：同一 RV64 design-id 下 CoreMark/Dhrystone owner-timing A2 receipt、H1–H4 计数关系与 selector next-action 的独立复核。
- v1 合同：`.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/subagent-contracts/v15l-owner-timing-independent-review-f7a-a2.json`
- v1 合同 SHA-256：`824d17ad905006d6939873d42e895b9d3bff4317ee74126ec1e9ab7f715907fd`
- v1 结论：`GAP`；A2 receipt rebuild、18 项 owner-timing 单测与 selector canonical verify 已 PASS，但 selector 的 25 项单测实际读取的 schema、policy、authority 与 RTL binding 传递输入未全部列入合同。节点未越过 `allowed_paths`，未输出 approval marker。
- v1 报告：`.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/owner-timing-independent-review-f7a-a2-v1-gap.md`
- v2 合同：`.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/subagent-contracts/v15l-owner-timing-independent-review-f7a-a2-v2.json`
- v2 合同 SHA-256：`6c41e89f5f91e0ec0317145bd28fdfbc91935c48eb1b993f7b7f6d8bfde8a7f9`
- v2 范围纠偏：只补充 selector 单测真实读取的 `npc/rv64/vsrc`、architecture policy/authority、PPA schema/policy/baseline、blueprint 与 PPA README；不扩展到整个工作区。
- v2 结论：`PASS`；receipt rebuild/verify、owner-timing 18 项、selector 25 项及 canonical verify 全部通过；exact approval marker 恰好一次。
- A2 result SHA-256：`1a99bd6ae38d4b672c20d263834ccddc13203d377777888203b935698ce2afef`
- selector SHA-256：`51841c120668a264ddba2b8b3a89ad46f147ca9e6ba5aa669bc24c8c897fcd0b`
- v2 报告：`.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/owner-timing-independent-review-f7a-a2.md`
- 技术边界：H1–H4 排序为 `H1 ≈ H3 > H4 > H2`，但因果仍未唯一闭合；`hypothesis_selection_authorized=false`、`optimization_candidate_authorized=false`、PPA `UNQUALIFIED`。
- 调度状态：所有工程命令已停止，unittest 临时目录已清理，WSL single-flight ownership 已归还主节点。
