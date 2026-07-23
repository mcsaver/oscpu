# OOO-3 v3 独立审查：GAP (P1)

- 合同：`subagent-contracts/v8v-ooo3-final-review-v3.json`
- 合同 SHA-256：`016de2d3302a4c7f26717fb1827c43b21a0ff8988d7da37ec2812145ecf163c5`
- 审查边界：只读 RTL、testbench、checker、mutation 与 evidence provenance
- 裁决：`OOO-3 = GAP (P1)`；overall architecture 仍为 `RED`；PPA 仍为 `UNQUALIFIED`

## 阻断反例

已发出 physical write、尚未收到 B 的 store 遇到 `checkpoint_restore_i`：

1. SQ 已置 `request_sent_q`，physical write 不可撤销。
2. restore 同拍清空 ROB/MIQ/rename owner。
3. SQ 因 `request_sent_q` 保留该 entry。
4. SQ entry 只能由同一 ROB owner 的 commit release 释放；bridge terminal 不替代精确 commit。
5. 因原 ROB owner 已消失，SQ tombstone、`sq_count` 与 `mem_retire_quiet_o` 永久无法闭合。

B 与 restore 同拍时，ROB completion query 被 flush 关断，DRAIN response 进入 fatal irrevocable 分类；无 B 同拍时，保留的 SQ physical owner 失去 exact-open ROB head。两条路径都违反 owner conservation。

## 修复约束

- restore 请求在存在已发射、尚未完成精确退休的 physical store 时必须进入 pending，而不能执行破坏性全域恢复。
- pending 期间停止接收新的 dispatch/issue/request，但必须允许既有 B response、formal WB、ROB commit 与 SQ release 继续推进。
- 仅在 `B -> formal WB -> ROB commit -> SQ release` 闭合后执行一次 backend-wide restore。
- 不得用 bridge drop 后直接清 SQ 代替该序列，否则会丢失 B error 的精确异常语义。

## 必补验证

- delayed-B store + restore；
- B 与 restore 同拍；
- OKAY 与 error B response；
- request/B/WB/commit/SQ free exactly once；
- 无 reset 的 restore 后 redispatch/retire；
- 切断 store-drain restore guard 的 compile-success mutation。

低优先级 11 metric、9 LQ mutation、15 F2 mutation 与 28/41 inventory 审计在 P1 确认后停止，必须在修复并刷新证据后重新执行。
