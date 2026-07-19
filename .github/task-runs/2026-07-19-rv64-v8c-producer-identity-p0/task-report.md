# RV64 v8c producer identity P0 task report

## Census

- comment/string-stripped lexical scan：19 个 `ROB_INDEX_W` file/module carrier。
- mandatory derived-owner seed：9；declaration heuristic 命中：5；manifest：28 entries。
- 分类策略：file/module 单标签按 `strongest-live-authority`；MIQ、memory bridge 与 terminal
  collector 含 normal AUTH + drain 子态，整模块保守标 AUTH。
- mutation self-test：9/9，覆盖漏 carrier、漏 Q1 owner、伪字段完备、伪 global GREEN、擦除
  memory-local 边界、伪称 owner 开放世界完备，以及把 mixed AUTH 分别降格成
  TOMBSTONE/EXEMPT/DETACHED。
- 机器边界仍是 file/module；field、instance graph、semantic completeness 全为 false。
- runner 现持久化 `evidence/census/census.log`、checker/manifest/contract/runner hash，以及本次
  lexical scan 的 production source SHA 清单；不再用手写结论替代原始运行证据。

## Production current-RED

专用 TB 不使用层级 force，也不用 global flush 代替 recovery：15 次真实 allocate/WB/commit 把
ring 推到 `head/tail=15`；双分配 `branch@15 + old@0`；真实 reverse walk 回收 old；branch 退休后
new 重用 slot0；迟到 old WB 仅凭 raw idx 把 new 的 registered done/data 错误更新。完全相同序列
下的正常 new WB 正控成功。release 与 `OOO_ASSERT` 两构建均命中唯一 witness。

runner 的 PASS 是 expected-RED characterization；full-ID 修复后它应失败并由 GREEN regression
取代。

## 当前 ledger

```text
GLOBAL_NO_LIVE_REUSE=RED
GENERATION_SAFE_FULL_IDENTITY=RED
WRITEBACK_AUTHORIZATION=RED
Q1_CSR_LIVE_OWNER=RED
MEMORY_TOKEN_DOMAIN=LOCAL_GREEN
```

P1 应先在 ROB allocation 建立独立 `ProducerId` 真源；P2 才传播所有 AUTH carrier。active flip
必须再加 generation wrap/collision、edge-old no-reuse、所有 WB/PRF/wakeup exact-ID authorization，
不能把较宽 generation 当作安全证明。

本目录是 P0 census 与 current-RED 业务证据包，不冒充 canonical agent-e2e publication；AI 环境的
可发现/可执行/可审计状态由 task-specific profile 与 strict guard 独立签收。
