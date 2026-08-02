# V13D pre-implementation review

RV64 RTL 结论｜对象=`OooLoadQueue` release ready/fire/entry-clear 方程｜周期/配置=同拍
completion/commit，SYNTHESIS 二态与仿真四态｜TB/EDA 观测=冻结方程独立代数复核，未运行工具｜
范围=`APPROVED_FOR_IMPLEMENTATION`

- live `ProducerId` 唯一时，`global ready × local match × commit` 与
  `local ready-hit × commit` 二态逐 entry 等价；同拍 completion bypass 保留。
- duplicate-PID 非法状态中，旧方程会让已完成 entry 的 ready 跨清未完成 duplicate，候选只清
  本地 ready-hit entry；断言存在不能替代生产组合逻辑检查。
- unknown-only local hit 在 procedural `if(X)` 下不清，exact-1 加无关 X 只清 exact entry。
- reviewer 指出：若把外部 fire 改为 exact-1 fire-bitmap reduction，`commit=X` 的可见值会由 X
  收紧为 0。因此实际实现进一步收窄为“外部 fire 方程不变、仅 entry clear 局部化”。
- 该批准仅允许实现与测试，不支持 PPA、full-core timing 或 promotion 结论；最终候选随后因
  mapped area 与 STA 同时回退而被拒。

合同：`subagent-contracts/v13d-lq-release-localization-pre-review-v1.json`，SHA-256
`e052e34d1a36589532def0501f0b47d1a13d21360c571a046de7b4d1e525845b`。
