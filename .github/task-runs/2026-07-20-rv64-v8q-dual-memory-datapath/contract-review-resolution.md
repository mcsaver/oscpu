# F0 合同反例闭合

| reviewer GAP | 合同修订 | executable evidence |
| --- | --- | --- |
| F0-G01 reset 未定义 | 固定为上下游同域全系统同步 reset；组合接口静默、沿上冷启动清状态、共同放弃 reset 前事务 | 五态 + AW-only/W-only reset TB；`reset_owner_residue` mutation |
| F0-G02 公平缺 progress 假设 | 改为 transaction-bounded：持续双竞争且每个 owner 最终 terminal 时，等待 lane 在下一 IDLE 捕获点获选 | 双竞争 read/write terminal ledger；`fixed_lane0_priority`、`rr_update_on_capture` mutation |
| F0-G03 非法 dual-type 范围歧义 | 任一 lane 在任一非 reset 拍 dual-type 都是违例；IDLE 全局不捕获、不更新、不 fire | release fail-closed TB + assert-negative `ARB-REQ-CLASS-ONEHOT` |
| F0-G04 mutation 假绿 | 固定十二族；每项必须 compile/elaborate/activate/target-reject 且只有专属失败码 | mutation summary 四态与日志 oracle |
| F0-G05 freshness/claim 拼接 | 同次 runner pre/post 哈希 RTL/TB/checker/build/mutator/spec；唯一总 PASS 在全部子门后写出 | fresh run metadata、closure digest、未实例化/未发布架构 GREEN 的 claim checker |

reviewer 其余反例（R/B owner 隔离、错误 phase response、payload 逐位 scoreboarding、
terminal 邻接无 fall-through、locked transaction 不读 flush/ProducerId/token/class）均进入
F0 定向 TB 或 source checker。文本复核不作为 GREEN；上述 executable evidence 全部通过后
才允许 scoped leaf PASS。
