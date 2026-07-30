# V11C memory tracker semantic coverage

## 结果

当前 design-id
`sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
下，`memory-tracker-producer-map` 与 `memory-tracker-live-set` 获得
current source-bound bounded PASS。production tracker RTL 未修改。

## 验证

- baseline：assert/release 2/2 PASS；
- X-known negative：4/4 精确拒绝；
- compile-success RTL variants：9/9 在关闭 checker 与 `OOO_ASSERT`
  后由 TB 独立 scoreboard 拒绝；
- evidence tool unit：5/5 PASS；
- semantic ledger unit：11/11 PASS；
- V11C 定向 Python 复核：16/16 PASS；
- ARCH_STABLE dependency self-test：51/53；V11C 新增路径的分组与
  fixture 全部通过，剩余两项是既有
  `CONTROL-EVENT-G1` V9R identity/status 漂移和旧 full-core
  candidate 未按当前 dynamic inventory 重绑；
- ledger：44 units、17 instances、50 bindings、5 PASS、39 GAP；
- independent final review：APPROVE，blocker=0；
- task-specific `npc-dev`：
  `.github/task-runs/2026-07-29-memory-tracker-semantic-revtag-v11c/`
  为 5/5 PASS、completed、DB publication 可召回；
- V11C 12 条 source/TB/tool/policy/spec 路径的 scoped strict guard PASS；
- V11C raw evidence 165 assets 已进入 `evidence_assets`，8 份 task-run
  Markdown 已同步 stored DB；`snapshot-stored`、DB-first audit 与全局
  runtime-artifact audit PASS。

## 边界

`tracker-next-token-cursor`、其它 holder、global no-live-reuse、whole
architecture 与 PPA 未晋级。无 production/elaboration/device-model/
simulator semantic 变化，因此不满足 A3 完整 rootfs 重跑条件。
上述两项 ARCH_STABLE current-workspace 失败继续 fail closed，不属于
本轮两个 tracker 语义单元的 PASS，也未被改写或豁免为架构完成。
全工作树 strict guard 已执行；`agent-system`、`rv64-systemd-contract`
与 `npc-dev` PASS，唯一全局 FAIL 是共享工作树中
`Linux/scripts/check-ubuntu-rootfs.sh` 缺 current `rv64-linux` evidence。
该 Linux 输入不在 V11C 范围，且本轮没有 production/elaboration/
device-model/simulator 语义变化，因此保留为显式范围外 GAP，不触发 A3
完整 rootfs 重跑。

技术 task-run 不声明 canonical e2e `run-manifest.json`；工作流 profile、
五节点 closure、publication 和 trace 由独立
`2026-07-29-memory-tracker-semantic-revtag-v11c` e2e run 承担。未为通过
run-scoped e2e artifact audit 而伪造技术节点清单。
