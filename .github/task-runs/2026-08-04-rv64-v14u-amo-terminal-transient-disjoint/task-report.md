# RV64 V14U AMO terminal/transient holder closure

## 结论

当前设计 `sha256:f69e7fd726dad68d48e88881b0bca73152d1102d482d46a4798e9a61f3dd8add`
中，AMO pending token 与 reservation0、reservation1、legacy buffer 的 raw-Q holder
互斥合同已由 assertion-only RTL、自然 lane9 周期和三类 compile-success alias 反例闭合。
`OooMemOwnerTerminalCollector` 的 12 个 ingress 共 66 个 source pair 当前均具有
producer-side gate 或立即断言，`precollector_pair_status=CLOSED`。

该结论不改变历史 V9P 失败的 exact-pair 边界：历史 pair 仍为 UNKNOWN，原始 FAIL 保留，
不得据此把历史 defect ledger 改写为 BACKFILLED。此轮未运行全系统回放、综合、STA 或 PPA，
也不提升 `ARCH_STABLE`。

## 接口契约冻结

| 契约类 | 本轮冻结内容 |
| --- | --- |
| 握手 | `issue0_mem_request_fire_w && issue0_is_excl_kind_w` 是 reservation0 到 AMO pending 的唯一 owner handoff；同沿清 reservation0、捕获相同 exact tuple。 |
| 反压 | 新增 mask 只读取 edge-old raw-Q valid/token，不进入 request、ready、collector 或 recovery 组合锥。 |
| flush/restore | lane9 与 lane6/7/8 可同拍结束不同 token；同一 token 重复必须在 holder 断言处 `$fatal`，不得由 collector 去重。 |
| 异常序 | 不改变 AMO read fault、final response 或 ROB retirement 语义。 |
| 访存序 | 不改变 AMO 独占窗口、request grant、MIQ push 或 physical write 时序。 |
| 单一真源 | pending token 来自 reservation0 exact handoff；reservation1 从准入侧排除 AMO，legacy buffer 只承载 plain memory。 |

对应稳定规范：`npc/rv64/design/specs/ooo-dual-memory-terminal-owners.md` §2.4、§3.2、§3.3。

## 最小实现

- `OooIntBackend.v` 在 `OOO_TERMINAL_HOLDER_ASSERT` 域增加
  `v14u_amo_pending_owner_mask_w` 与 `v14u_amo_transient_overlap_mask_w`。
- `[V14U-AMO-TRANSIENT-HOLDER-DISJOINT]` 使用四态非零比较，独立扫描 AMO pending、
  reservation0、reservation1 与 legacy buffer 的 raw-Q valid/token。
- `tb_ooo_int_backend.sv` 在自然 AMO read→write-phase→checkpoint restore 周期观察
  lane9=1、lane6/7/8=0，并保留 lane9 exact tuple 检查。
- V11N runner 增加 reservation0、reservation1、legacy buffer 三类 alias mutation；
  每类在 generation width 1/4 下均要求编译成功、仿真非零退出、专用 marker 恰好一次，
  并解析 marker 中实际激活的 holder，防止三个 profile 误打同一反例。
- 静态 lane 工具精确匹配 AMO pending mask、三个 transient operand 和专用断言体；
  不能仅凭 marker 名称宣称覆盖。

## 分层证据

- 静态合同与 runner 单测：19/19 PASS。
- V11N profile：36/36 PASS；4 个 production assert/release 基线，26 个既有 release-oracle
  mutation profile，6 个 V14U assertion mutation profile。
- 邻近回归：3/3 PASS。
- runner source-before/source-after：MATCH。
- 静态 terminal matrix：66/66 source-guarded-or-asserted，collector-only=0，CLOSED。
- runner 与 matrix design ID：完全一致。
- PASS 后二级产物清理：55 项，包含 39 个 Icarus compile image 与 16 个生成式负向 RTL；
  `retained_compile_images=0`，留档由约 464 MiB 降至约 2.3 MiB，仅保留结果、日志、哈希与 receipts。

核心指针：

- `evidence/terminal-lane-pair-current.json`
- `rtl-verification/v11n-amo-pending-holder-evidence/summary.json`
- `rtl-verification/v11n-amo-pending-holder-evidence/artifact-cleanup.json`
- `rtl-verification/v11n-amo-pending-holder-evidence/runner.status`

## 审查与范围

隔离 reviewer 合同已通过 validate，SHA-256 为
`cf9a73a38e8d92cbcdf73292afedb26ead9523cdcc19e162abf96026ab9b234f`。
平台返回 `agent thread limit reached`，因此 `dispatch-log.md` 保持 `review_pending`；本报告不声称
独立 reviewer PASS。正式 finish、历史 defect 晋级和全架构晋级均等待新隔离节点复核。

## 候选门禁

`agent-flow finish --candidate` 返回 `CANDIDATE_PASS`：6/6 固定门禁 PASS，包含
`flow-self-test`、`rv64-soc-delivery-gates`、`rv64-terminal-collector-lane-contract`、
`rv64-historical-defect-ledger-audit`、`rv64-historical-defect-current-contract` 与依赖自动选择的
`rv64-memory-request-hold-fast`。门禁累计 8.016 s，占本轮登记工作时间 0.52%；40% 仍只是
非阻断复盘目标，没有引入时间门禁。
