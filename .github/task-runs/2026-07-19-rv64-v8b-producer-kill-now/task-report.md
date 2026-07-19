# RV64 v8b-prep producer kill-now 任务报告

## 基本信息

- `task_id`: `2026-07-19-rv64-v8b-producer-kill-now`
- `status`: `completed (scoped)`
- `scope`: `OooClmulUnit + OooFpArithGate production producer-local kill-now`
- `verdict`: `two identified ambient kill dependencies GREEN / global identity and live Q1 RED`
- `parent_goal`: 持续优化 RV64 双发射完整 OoO 核及其 PPA，并把架构、验证、证据与协作规则固化成可发现、可执行、可审计工作流

## 根因与架构裁决

1. 旧 `OooClmulUnit` 与 `OooFpArithGate` 都在 Verilog function 内读取模块级
   `kill_valid_i`、`kill_rob_idx_i`、`rob_head_idx_i`，调用点只显式传入 held ROB index。
2. 在 Icarus 12.0 下，held index/state 不变而只切换 kill-valid、cut 或 head 时，连续赋值不会因
   function 的 ambient 自由变量变化而重新求值。修复前 CLMUL directed compile/elaborate 成功但出现
   10 个 failure，FP-arith compile/elaborate 成功但出现 3 个 failure；这关闭了“编译失败假红”，但只证明
   仿真语义反例，不能越级称 silicon bug。
3. kill 年龄统一冻结为等宽模减：`age(x)=x-rob_head`，仅当
   `kill_valid && age(x)>age(kill_boundary)` 时杀掉。严格 `>` 保留 recovery-causer；禁止 raw index 比较或
   inclusive boundary。
4. 这两个 producer 的 valid 进入 downstream 前已会触发 PRF write、wakeup、done FIFO 或共享 WB；不能期待
   ROB 在最后一跳拒绝错误 index 后替前面的副作用兜底。因此修复点必须在 producer holder/output valid。

## 实现与 production 调用链

- `npc/rv64/vsrc/execute/OooClmulUnit.v`
  - 删除 ambient `clmul_killed()`；显式计算 request、held response 与 kill boundary 的 circular age。
  - `reset/flush > matching inflight kill > normal state transition > hold`；matching request 同拍不进入 RUN，
    RUN/RESP victim 同拍组合屏蔽 `resp_valid_o`，同沿清 state/held ROB idx/pdest/data。
  - `req_ready_o` 只在 IDLE 为高，故 reviewer 指出的 `kill_inflight && req_fire` 在当前实现互斥；kill 后留下的
    acc/iter 属无效态 datapath 残值，下一请求在使用前完整覆盖，不增加清零 mux。
- `npc/rv64/vsrc/execute/OooFpArithGate.v`
  - helper 改成只读三个 formal 的纯 `fp_meta_younger(idx,boundary,head)`；launch、每级 meta 推进与 stage5
    output mask 都显式消费 kill-valid/cut/head。
  - `out_valid_o` 是 `OooFpBackend` arithmetic result 写 FP PRF、wakeup 与入 done FIFO 前的 valid；kill 在采样沿前
    稳定时，held stage5 victim 当拍为 0，旧 stage4 victim也因逐级 valid gate 不会在沿后形成延迟脉冲。
- production path 由结构 checker 锁定：

```text
OooClmulUnit.resp_valid
  -> OooIntBackend.clmul_rsp_to_wb{0,1}
  -> shared WB
  -> OooRob + BusyTable + IntIssueQueue + integer PRF

OooFpArithGate.out_valid
  -> OooFpBackend.fp_result_wb_valid
  -> FP PRF/wakeup + done FIFO
  -> fpwb
  -> OooIntBackend shared WB
```

`OooFpBackend` 的 done FIFO 另有 raw-index killed bit 与静默 pop，但它仍没有 generation/no-live-reuse 证明；
本报告不把 producer ingress 的 scoped 结论扩大为 FIFO 全生命周期或全局 stale completion 安全。

## 定向验证与防假绿

| Gate | 结果 | 权威证据 |
| --- | --- | --- |
| 修复前 CLMUL 动态反例 | compile/elaborate 成功，`10` failures | `evidence/pre-fix-clmul/logs/tb_ooo_clmul_unit.log` |
| 修复前 FP 动态反例 | compile/elaborate 成功，`3` failures | `evidence/pre-fix-fp/logs/tb_ooo_fp_arith_gate.log` |
| release/assert positive | PASS `2/2 + 2/2` | `evidence/focused-r2/summary.txt` |
| CLMUL circular-age model | PASS `4096/4096` | `evidence/focused-r2/positive/` |
| compile-success semantic mutation | PASS `13/13`，均由行为 oracle 杀死 | `evidence/focused-r2/mutations/` |
| checker/self-test | PASS / `3/3` | `evidence/focused-r2/gates/` |
| CLMUL strict Verilator | release/assert 均 PASS | `evidence/focused-r2/gates/clmul-verilator-*.log` |
| FP strict Verilator | RED，继承 `43` warnings | `evidence/focused-r2/gates/fp-verilator-strict.log` |
| FP nonfatal parse/elaboration | PASS | `evidence/focused-r2/gates/fp-verilator-nonfatal.log` |
| leaf style/Yosys | PASS / `2/2` | `evidence/focused-r2/gates/` |
| module aggregate | PASS `104/104` | `evidence/module-r2/summary.txt` |
| full RTL style / contract | PASS / PASS，当前 `289 >= 89` | `evidence/rtl-style-full-r1.log`、`evidence/check-contract-r1.log` |
| global strict/default build | RED / RED，继承 `115` warnings | `evidence/strict-lint-r1.log`、`evidence/full-build-r1.log` |
| nonfatal full parse/elaboration | PASS | `evidence/lint-nonfatal-r1.log` |
| broad source/evidence closure | PASS | `evidence/broad-gates-r1.sha256`、`evidence/broad-gates-r1.complete` |

13 个 mutation 覆盖 CLMUL ambient function、漏 request/inflight kill-valid、`>=` boundary、raw index、漏 request
kill、漏 response mask、漏 holder clear，以及 FP ambient function、raw/reversed age、漏 output mask、漏 pipeline
propagation kill。正例还覆盖 only-input-change、request/RUN/backpressured RESP、equal/older/wrap、kill 后同 ROB idx
换 pdest/data 重发和 no-delayed-pulse。

全局 strict/default 的 `115` 项精确分布为 `TIMESCALEMOD:108`、`PINCONNECTEMPTY:2`、`LATCH:4`、
`UNOPTFLAT:1`；三份归一化输出与 frozen pre-v8a baseline byte-match，故只能报告 inherited RED，不能用
nonfatal parse 或局部 lint 冒充全局 GREEN。

最终裁决只采用修复前两组日志、`focused-r2`、`module-r2` 与 broad `*-r1`。`clmul-r1`、`fp-r1`、
`mutations-r1`、`module-r1` 是 canonical rerun 前现场，保留追溯但已 superseded。

## 独立审查与剩余风险

独立 reviewer 从 FP 同拍 sink push、CLMUL partial-state 清理、idx-only identity、FIFO 内旧条目和覆盖假绿寻找
P0/P1；最终未发现阻断 scoped GREEN 的 P0。审查确认：

- CLMUL `req_ready_o == IDLE` 关闭 kill-inflight 与新 request 同拍冲突；state/identity/output-valid 已清且下一请求
  完整重写 acc/iter，因此无需为无效态残值增加 PPA mux。
- FP sink enable 唯一来自 masked stage5 valid，合同要求 kill 在采样沿前稳定；若 kill 只在同一沿后的 NBA 才产生，
  该沿已经发生的 push 不属于本切片可追溯范围。
- 已经进入任意 downstream queue 的引用、其他 producer 与复用后同 idx completion 都不能由本地 mask 证明安全。
- FP 每个 resident stage 的位置扫描、独立 equal/older exhaustive model 与 production sink assertion 可继续作为 P1
  加固；当前 pure helper、逐级结构锁、propagation mutation 与 delayed-pulse witness 足以支持本轮窄结论，不能外推。

## 可宣称边界

- **GREEN**：两个已识别 production producer 的 ambient kill dependency 已消除；当前 CLMUL holder 与 FP-arith
  pipeline/output 对沿前稳定的 matching kill 具有显式 modular-age 同拍抑制。
- **RED**：all producer/holder census、downstream full identity、ROB reuse/generation/no-live-reuse、kill 窗口外的迟到
  completion、全局 stale-WB closure。
- **RED**：live Q1 owner、mismatch-cycle `kill_now`、下一拍 registered shared abort、Q1/CsrFile 同事件取消、完整
  selective squash/full quiet/FENCE.I lifecycle。
- **NOT MEASURED**：Linux、综合后面积/功耗、STA、频率与任何 PPA 收益。

本切片与 Q1 shared abort 没有直接协议事件关系；它只关闭同一 lifecycle invariant 下的两个 producer-local 前置
缺口。父目标继续 active。

## AI e2e 与 retained DB 实战

- 先将 project/npc 的当前工程事实用 `update-stored` 写入 retained DB，执行 `snapshot-stored` 与
  `audit-db-first`；显式 `brief rv64 producer kill now --profile npc-dev --focus-scope non-history` 随后从当前
  `.github/memory/modules/npc.md` 选中 independent primary，预算 `2041/2400`。
- 首轮 task-specific `2026-07-19-rv64-producer-kill-now` (`npc-dev`) 5/5 completed/publication-valid；把本轮
  e2e 使用结论写回 project/npc/agent-system memory 后，再次同步/snapshot/audit，避免用早于最终 memory 的证据
  交付。
- 最终新鲜证据为 `2026-07-19-rv64-producer-kill-now-2` (`agent-system`, 9/9) 与
  `2026-07-19-rv64-producer-kill-now-3` (`npc-dev`, 5/5)，两者均 completed 且由 DB `runs` 查询可恢复。
- `audit-db-first` PASS；`audit-markdown-coverage --fail-on-live-evidence` PASS
  (`live_evidence=0`)；`doctor --fail-on-drift` PASS (`blocking_drift=0`)。
- 最终 `scripts/agent-e2e.sh --guard --guard-mode strict` 要求三个 profile 并全部 PASS：本轮新鲜
  `agent-system ...-2`、`npc-dev ...-3`，以及语义仍新鲜的既有 `github-index 2026-07-19-slug-recall-3`。

这条 e2e 证据只证明 retained memory、bounded recall、profile 调度与事务式 publication 链路；它不替代前述
RTL directed/module/broad gate，也不构成 Linux、full identity、live Q1 或 PPA 结论。

## 后续原子切片

1. 完成 global still-live holder census，冻结 last-reference release、collision-stall 与 no-live-reuse，再选择 full
   identity/generation 编码。
2. 用 stale WB→PRF/wakeup 与 reused-index completion 反例驱动 identity 贯通，而不是只扩大位宽。
3. 在 active wrapper 实现 mismatch-cycle `kill_now` + next-cycle registered shared abort，并让 Q1/CsrFile 消费同一事件。
4. 追加 FP per-stage resident-victim/equal/older/wrap model 与 production sink assertions，进一步缩小 producer proof 假设。
