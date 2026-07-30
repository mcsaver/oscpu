# V11D memory tracker cursor semantic coverage

## 当前结果

在 design-id
`sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
下，`tracker-next-token-cursor` 已取得 current source-bound bounded PASS。
production `OooMemOwnerTracker.v` 未修改，SHA-256 仍为
`fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`。

## RTL 推导摘要

- 需求：双 lane memory-owner token 必须按沿前 FREE 集合从 cursor
  圆环选择，且只有真正出生才能推进。
- 协议：lane0 取第一 FREE；lane1 仅排除合法 lane0 claim 后取第二 FREE；
  原子 pair 单 credit 零出生；同沿 death 不参与 scan。
- 状态：lane1 fire 优先令 cursor=`token1+1`，否则 lane0 fire 令
  cursor=`token0+1`，零 fire 保持，reset 为 0。
- 不变量：双出生 token 不同；idle/full/blocked/atomic-scarcity 保持；
  exact/bulk death 下一沿才可复用；4/32-token 均自然回绕。
- 数据通路：verification-only TB 用 stimulus、沿前 expected live/PID/
  metadata/cursor 独立计算 ready/token/fire；DUT token 不作为 expected
  输入；hierarchical `dut.next_token_q` 比较是第二个 oracle，并非仅作
  补充诊断。

## canonical attempt-2

- baseline：`assert-t4`、`release-t4`、`assert-t32`、
  `release-t32`，4/4 PASS；
- marker：lane selection、ring scan、death visibility、atomic hold 在
  4/32-token 每个 profile 各恰一次；
- compile-success RTL variants：9/9 均生成 vvp，在 32-token、
  `OOO_ASSERT` 关闭配置下由独立 TB 拒绝；
- evidence summary SHA-256：
  `21a209961c55f4036af32c716701ed52803caf2dd61889a9dfe662c1105d3a50`；
- Python：V11C compatibility + V11D evidence + semantic ledger
  24/24 PASS；
- semantic ledger：44 units、17 instances、50 bindings，
  6 PASS / 38 GAP，整体仍 `GAP`；
- independent final review：bounded APPROVE，blocker=0，仅覆盖
  `tracker-next-token-cursor`；
- ARCH_STABLE：53 项中 51 PASS；V11D workflow/test-source 接线无新增
  failure，剩余两项是既有 current-workspace 漂移；
  `evidence/arch-stable-unittest.log` 已保存 53 项原始输出与
  `EXPECTED_GAP pass=51 fail=2 v11d_new_failures=0` 分类。

## attempt-1

attempt-1 同样取得 4/4 + 9/9，但复读发现 lane1 变体的首个拒绝点可能
落在 invalid lane token 输出，强于 valid/ready 握手合同。原始产物保留，
不作 ledger 晋级依据；attempt-2 收紧 oracle 并重新绑定。

## 工作流收口

- task-specific `npc-dev`：
  `.github/task-runs/2026-07-30-memory-tracker-cursor-semantic-revtag-v11d/`
  为 completed、5/5 PASS，且 `runs/evidence` 可从 DB 召回；
- V11D 10-path scoped strict guard PASS；
- 全工作树 strict guard 中 `agent-system`、`rv64-systemd-contract`、
  `npc-dev` PASS，唯一 FAIL 是共享工作树
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence；
- V11D raw evidence 141 assets 已进入 `evidence_assets`；final identity
  helper 重算 146-file RTL binding、核对 canonical 12-file manifest 与
  production tracker SHA 后 PASS。技术 task-run
  的 8 份 Markdown 使用 `update-stored` 同步；技术 task-run 不伪造
  `complete.marker` 或 e2e `run-manifest.json`，五节点 publication 由上面的
  独立 task-specific run 承担；
- `snapshot-stored`、DB-first audit、Markdown coverage audit 与
  runtime-artifact audit 均 PASS。
- commit gate：branch `ai`、HEAD `af027d1bce085bace474b748dcd89113145f8772`；
  共享工作树有 249 个 tracked 修改、1,564 个 untracked 文件，且已有一个
  与 V11D 无关的 staged profile。未执行 stage/commit，避免把 mixed-origin
  改动并入本轮。

## 边界

本轮不闭合其余 38 个 holder 单元、global no-live-reuse、whole
architecture、系统事务、综合、STA、功耗或 PPA。没有 production core RTL、
elaborated RTL、设备模型或 simulator 语义变化，因此不满足 A3 完整系统重跑条件。
全工作树 `rv64-linux` 缺证据来自 mixed-origin 的共享 Linux 路径，不属于
本轮 cursor RTL/verification 范围，也不产生 A3 完整系统重跑义务。
V11D cursor 子范围已收口；全局 architecture/PPA 状态继续为 RED/GAP。
