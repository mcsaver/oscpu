RV64 RTL 结论｜对象=`OooLoadQueue.v` 中 alloc0/alloc1 lowest-onehot grant→同 index entry 写使能及 `.github/task-runs/2026-08-01-rv64-v13e-lq-onehot-write/evidence/{functional,ppa}`｜周期/配置=edge-old free、GEN_W=1/4、OOO_ASSERT on/off、5ns ideal-clock A/B｜TB/EDA 观测=focused assertion、raw-Q 四档及回退后 assertion PASS；coarse 缩小但 mapped area/cells 增加且 worst slack 退化；其余阶段 NOT_RUN｜范围=PASS

**判定：APPROVED_NOT_PROMOTION_ELIGIBLE。** PASS 仅批准负候选早停、证据留存和 production 回退，不批准候选 RTL 晋级。

- 周期等价仅在 `alloc0/1` grant 均为已知 `onehot0`、两 lane grant 互斥、accept/write gating 不变时成立：此时 `decode(encode(grant)) == grant`，edge-old free policy 与 lane1 prefix 足以保持分配集合和 entry payload。
- 不得扩展为无条件四态等价。multi-hot grant 会使直接写入多个 entry，而原编码路径只选一个；grant/free 含 X/Z 时，动态索引/解码与 procedural `if` 可能分别传播或吞掉 X；两 lane 命中同一 entry 时结果还会依赖 NBA/语句优先级。assert-on PASS 未给出 `$onehot0`/`$isunknown` 的具体 assertion 或原始 marker，因此只是定向观测，不是四态穷尽证明。
- A/B 结论一致且没有 PPA 假绿：coarse 从 `4568/1790/41922` 降至 `3189/528/28557`，但 mapped cells `18979→19888`（+909，约 +4.79%）、area `44073.68→45097.92`（+1024.24，约 +2.32%），5ns worst slack `+3.475173950ns→+3.370205879ns`（退化约 104.97ps）。sequential area 同为 `9264.64`，更符合 onehot 扇出/组合映射抵消 generic IR 缩减的解释。
- mapped area 与 timing 同时被 baseline 支配后早停合理。真实 `tb_ooo_int_backend`、DI-5、RTL style、31x2 mutation、`NpcTop` coarse、full-core mapped/STA、power、system 均只能记为 `NOT_RUN`，不能借 focused PASS 推断通过。
- 冻结材料中的 candidate SHA `a29819b5…bfd8` 与恢复后的 live RTL/spec SHA `5dc60f2f…c92f` / `e2d5f60d…6a6` 相互一致，且回退后 focused assertion 再次 PASS；候选快照和日志保留、`113782010` bytes/15 个可再生 runtime 文件删除并确认不存在，处置闭环成立。
- 未发现 `REJECTED_FAKE_GREEN_RISK` 或 `REJECTED_EVIDENCE_MISMATCH`。不过本节点未获得完整哈希、原始日志 marker、assertion 定义或 RTL diff，故对“负候选处置正确”置信度高，对“候选在所有四态输入下等价”不作声明。当前判定无需 `scope_extension_request`；任何重新晋级都必须补充形式等价/四态约束、完整 mapped/STA 配置及全部 NOT_RUN 阶段证据。
