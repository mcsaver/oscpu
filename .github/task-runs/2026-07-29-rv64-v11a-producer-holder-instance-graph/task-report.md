# RV64 V11A ProducerId holder instance-graph report

## 状态

`BOUNDED_COMPLETE`。

本轮只闭合当前产品 `NpcTop` 配置下 ProducerId/owner-token holder 的
elaborated instance multiplicity 与证据发布链；未修改 production RTL。

当前 design ID：

`sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## NpcTop 层次观测

- Yosys 输入为固定顺序的 127 个 synthesizable RTL 文件。
- 配置为 `OOO_CSR_QUEUE_HEAD=1`、
  `OOO_TERMINAL_HOLDER_ASSERT=1`。
- reachable user-module instances：194。
- holder-bearing modules：15。
- exact holder instance paths：17。
- dual-instance modules：`OooMemInflightQueue` 2 个，
  `OooMemAxiBridge` 2 个。
- 未按 module name 去重，也未把 instance multiplicity 外推为 holder
  lifecycle 语义完备。

## 五件套证据

| 产物 | SHA-256 |
| --- | --- |
| `evidence/holder-instance-graph.json` | `865548ec4c7b466e2d0b69a2574cf0abb78d7dc1346518b6289775421ca361d7` |
| `evidence/yosys-instance-graph-receipt.json` | `5299822000292bfe6dd4729917899795e8b7663e1f2f8ad7810228809d31d3d2` |
| `evidence/yosys-instance-graph.full.json.gz` | `b3198345d9f55399c9f1fbac5fefa859f7a04e0deafc3cf5701b31a8ec2840fa` |
| `evidence/yosys-instance-graph.ys` | `be9ba9f96f7c4e4d90a0b6e1c910cdf6da27a91427fe7d956fe0ae8c4bfd7890` |
| `evidence/yosys-instance-graph.log` | `3869b0fe0ac8b00604b3e975b33475962afe3abc07a56e985ab891042f24ddde` |

完整 Yosys JSON 保留 creator、modules、cells 及其余文档内容。规范化只
作用于 map key 中的进程局部 `$0x<hex>:` token，并在碰撞时 fail closed；
values 与其它 keys 不变。两次独立 elaboration 的 canonical uncompressed
document 均为 197,075,777 bytes，SHA-256 为
`db0a066a1e7e23c1b118212095267eed72d51a0439e1b7c29d7bd5fe04cfc949`。
receipt 与 reachable graph 均直接从该完整文档重算。

## 分层验证

- instance-graph + runner 定向单测：23/23 PASS。
- holder-census 定向单测：15/15 PASS。
- shared task-status shell test：PASS。
- fresh result/receipt/full/script/log replay：byte-identical PASS。
- frozen audit 与 census audit：PASS。
- ARCH_STABLE workflow tests：50/50 PASS。
- V9N owner-residency refresh、V10C currentness 与 V9O index：PASS。
- closed currentness：
  `16 entries / 38 artifacts / 32 semantic checks / 0 failures`。
- postflight：`production_rtl_unchanged=true`。

runner 会先发布 RUNNING，任何 helper 缺失、unit failure、完整 JSON
不一致、source drift、cleanup signal 或 evidence incomplete 都会覆盖旧
PASS 为 stage-specific FAIL；只有 cleanup 与 evidence completion 后才发布
最终 PASS。

## 独立审查

- v1：GAP，发现同步删除、ARCH_STABLE 依赖、拓扑根、Yosys 输入/script
  与 stale-PASS 五类缺口。
- v2：GAP，要求完整 elaborator document、原始 ARCH_STABLE log、canonical
  evidence path、fresh predecessor 与动态 runner fixture。
- v3：`APPROVED_FOR_CURRENT_SCOPE`，确认两组双实例、五件套 hash、
  canonical full JSON 边界、23/23、15/15、50/50 与 16/38/32/0。

## 当前硬门

- `scope.instance_graph_complete=true` 只表示当前配置下 holder 实例枚举完整。
- `semantic_complete=false`。
- `global_no_live_reuse=SEMANTIC_COVERAGE_REQUIRED`。
- whole architecture：`RED`。
- PPA：`UNPROMOTED` / `UNQUALIFIED`。

本轮未执行 synthesis mapping、STA、power 或 Pareto 发布；没有
`npc/rv64/vsrc/**` production 文件变化，不能据此晋级完整 OoO 核或 PPA。

## AI workflow 证据

- DB-first project/NPC memory 已发布并生成 stored snapshot。
- 第一个 task slug 派生出过宽 focus，context recall 按合同失败；对应
  `.github/task-runs/2026-07-29-rv64-producerid-owner-token-holder-instance-graph-revtag-v11a/`
  保持 blocked，虽然其 5 个 profile 节点各自 PASS，也不追认为 completed。
- 最小独立 focus `producerid holder` 的 task-specific `npc-dev` run
  `.github/task-runs/2026-07-29-producerid-holder-revtag-v11a/` 已完成
  5/5，并发布 canonical report/manifest/index/dispatch/DB marker。
- V11A 的 13 个 raw evidence asset 已由
  `evidence-index.md` 记录路径、大小、SHA-256 与摘要；完整 payload 不写入
  长期 memory。
- 显式绑定该 completed run 的 12-path scoped strict guard PASS。
- 全工作树 strict guard 的 `agent-system`、`rv64-systemd-contract` 与
  `npc-dev` 均 PASS；唯一全局 FAIL 是 mixed-origin
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺新的 `rv64-linux` evidence。
  该路径不属于 V11A holder graph，本轮不把全局环境 GAP 改写为 PASS。
- DB-first audit 未发现本轮 memory hash mismatch；仍列出 8 个既有
  historical task-run `missing_backup`，保持为独立归档 GAP。

## 工作树边界

工作树含 mixed-origin 既有改动。本轮不执行 reset、restore、clean、stash、
commit 或 push；已由本地证据路径和精确哈希隔离本轮结论。
