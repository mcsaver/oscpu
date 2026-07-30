# V11F `OooIntIssueQueue` full-ProducerId holder 推导

## production 数据流

`dispatch0_fire_w` / `dispatch1_fire_w` 形成 accepted birth。组合 next-state
先按 issue/pair fire 和 selective kill 过滤 edge-old valid entries，再按原
顺序把 survivor 的 payload 与 `producer_id_q[compact_i]` 压缩到
`write_i`，最后按 lane0/lane1 顺序追加 accepted dispatch ProducerId。

regular issue payload 由 selector index 读取对应 edge-old
`producer_id_q`；memory pair payload读取 entry0/1。`producer_live_mask_o`
扫描登记的 edge-old Q，因此 fire 或 kill 当拍仍保留旧 holder，下一拍才
反映死亡。这与全局 no-live-reuse 的 edge-old owner 生命周期一致。

## 独立 expected model

V11F focused mode 使用 testbench-owned：

- `v11f_expected_valid[0:7]`
- `v11f_expected_pid[0:7]`

model 只消费 testbench stimulus、沿前 ready/fire、selector 观测和显式
kill/flush/reset 日程；它不读取 `producer_live_mask_o`、DUT `valid_q` 或
`producer_id_q` 来推进 expected。每个 directed edge 后比较：

- 全部八槽 raw valid/full ProducerId；
- full-P live mask 与 count；
- regular issue0/1 和 memory pair carrier；
- raw ProducerId 的 case-equality 与 reduction-X knownness。

正向配置为 assert/release × `PRODUCER_GEN_W=1/4`，两种断言配置复用同一
scoreboard。

## 定向周期矩阵

1. dirty reset 后八槽 invalid；
2. 双 dispatch birth；
3. full queue rejection；
4. READY-low 与 recover hold；
5. nonzero-index overtaking；
6. single fire + 同沿 dual append；
7. dual fire；
8. memory pair READY-low、atomic pop2 与 append；
9. `head=14`、boundary=15 的 selective wrap kill；
10. nonempty flush 与 reset；
11. raw PID X injection negative。

正向日志必须出现：

- `[V11F-INT-IQ-BIRTH-HOLD]`
- `[V11F-INT-IQ-ISSUE-COMPACTION]`
- `[V11F-INT-IQ-PAIR-DEATH]`
- `[V11F-INT-IQ-KILL-FLUSH-RESET]`
- `[V11F-INT-IQ-ALL]`
- `[PASS] tb_ooo_int_issue_queue_v11f_producer_lifecycle`

## compile-success 变异矩阵

关闭 `OOO_ASSERT` 后仍必须由 `[V11F-INT-IQ-ORACLE][FAIL]` 拒绝：

1. dispatch0 generation 清零；
2. dispatch1 错取 lane0 PID；
3. compaction 错取 write index PID；
4. compaction generation 清零；
5–6. issue0/1 generation 清零；
7–8. issue0/1 raw index 错源；
9–10. issue0/1 fire 不删除；
11. pair pop 只删除 entry0；
12. kill boundary 错改为 inclusive；
13–14. 忽略 flush/reset；
15–16. regular/pair fire 当拍提前从 live mask 死亡；
17. live mask 按 raw ROB index 解码；
18–20. dispatch0、dispatch1、compaction PID 注入 X。

## 生产修改判定

独立预审未找到合法 IQ-I6 输入下的 production 反例，因此 production
`OooIntIssueQueue.v` 保持字节不变，本轮实现仅进入 testbench、evidence
builder/tests、semantic policy/tool/tests、spec 与 task-run。

无约束端口下 `kill_valid_i && dispatch*_valid_i` 可表现为 ready/fire 为 1
但 kill 分支不追加；该组合违反冻结的 IQ-I6 transaction barrier。验证该
barrier 的自然可达性需要扩展到 `OooDispatchBackend`/`OooIntBackend`
集成范围，本轮保持 GAP，不把它伪装成 IQ 局部 PASS 或 RTL bug。
