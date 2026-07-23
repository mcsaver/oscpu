# V9I 派发与状态日志

## 2026-07-22 recall / scope

- 精确 `rv64 IFU access footprint PMP RRESP lane1 owner` brief 因缺少独立 focus 正确失败；
  收敛到 `rv64 IFU access`、profile=`npc` 后 bounded non-history brief 完成。
- 历史 `2026-07-12-rv64-ifu-access-g1` 只作为合同与反例目录；当前 ledger 状态为
  `STALE_EVIDENCE`，必须重建 current-source 证据。
- V9H 已关闭相邻 `IFU-FETCH-G2`，V9I 不重复声明 decoder byte provenance，也不外推到
  `IFU-TVAL-G1`、`PTW-PMP-G1` 或正式 PPA。

## 2026-07-22 field-level wording workflow

- `prepare-rtl-task-contract` 的 canonical render 自动写明 AXI/PMP/IFU 字段、握手周期、2B EXEC
  access size、PMEM 读取边界和 lane0/lane1 fault owner；真实 RTL/TB/log 标识符保持原样。
- 没有新增关键词黑名单或能力降级；self-test 25/25、CLI self-test 20/20、wiring audit 与
  skill quick validation 均 PASS。

## 2026-07-22 canonical closure

- `make -C npc/rv64 check-ifu-access` PASS：focused 4/4、module aggregate 109/109、
  PMEM 尾界 2B 读取、负向 RTL 变体 19/19、证据单测 10/10。
- result SHA-256 为 `9776d139c4d9b406187b17008b6657b8094e59600487ad29ee018c283f3c3898`；
  raw log SHA-256 为 `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a`。
- 最终 no-tools 合同为
  `subagent-contracts/v9i-ifu-access-coverage-review-v2.json`，SHA-256
  `00a2e4db3475a6dec764404aca44095eaac88a8289dc2fae0268066b7de09991`；审查者返回高置信度
  PASS，且严格限定 `IFU-ACCESS-G1`。

## 2026-07-22 architecture integration

- 公共 `arch_stable_freeze.py` 加入 IFU-ACCESS 独立重构后，6 个既有 CLOSED 结果按各自 canonical
  命令重建；结果 JSON SHA 更新，raw logs 在适用条目上保持或重新绑定当前输出。
- 首次从 DI-1 启动 directed records 时，runner 在 RTL 仿真前因 DI-2 sibling inventory 仍存在而
  fail-closed；纠正为 DI-2 根入口后，依赖链完整重建，九个 architecture gates 全 GREEN。
- `architecture-current.json` SHA-256 为
  `f362898c079f5e599faab098940f22ce000995c7866eb34541c442db152ca695`；V9I hard-gates result
  SHA-256 为 `685b1ffdbc7da6c5d286baad3c570ca7c77bdf264e7ed39370794cc315aafb3d`。
- 最终 full-core audit 为 GAP、PPA UNQUALIFIED、promotion false、38 blockers；没有 CLOSED debt
  evidence drift。`IFU-ACCESS-G1` 从 `STALE_EVIDENCE` 重绑为 current-design `CLOSED`。

## 2026-07-22 DB/e2e/guard

- DB-owned updater 发布 project/NPC/agent-system memory；`rv64 IFU access current design` bounded
  non-history brief complete。
- `npc-dev`：`.github/task-runs/2026-07-22-rv64-ifu-access-current-v9i/` completed。
- agent-system probe 1 因 skill 源目录残留本轮生成 `.pyc` 而 blocked；删除该精确缓存文件后，probe 2
  的 10 个节点全部 PASS，但 slug 中 `fields v12` 缺少独立 focus，整体按规则继续 blocked。
- 使用已发布 NPC module memory 中的业务词后，正式 agent-system run
  `.github/task-runs/2026-07-22-rv64-ifu-access-current-v9i-2/` completed；github-index run
  `.github/task-runs/2026-07-22-rv64-ifu-access-current-v9i-3/` completed。
- strict guard 对 required profiles `agent-system`、`npc-dev`、`github-index` 全部 PASS。
