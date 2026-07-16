# T3M — integer EX sticky wakeup barrier

- task_id: `2026-07-13-rv64-t3m-ex-fast-wake-barrier`
- baseline commit: `31e90c679`，其上叠加尚未提交但已完成裁决的 T3L source/evidence
- comparison netlist: T3L SHA-256
  `a13614447e599104d2925687a9a14e8e17080d4481eb5993ddfc283ab157f9df`
- status: interface/topology frozen；RTL 与验证进行中
- parent goal: 完整功能 + fresh 5.000 ns `WNS>=0 && TNS>=0 && loops=0`

## 根因与裁决

T3L 将旧 fetch branch-target 家族移出 top40，WNS 从 T3K `-8.720 ns` 改善到
`-8.390 ns`，但 TNS 从 `-199154.36 ns` 轻微恶化到 `-199224.19 ns`，父目标未闭合。
T3L top40 的 40 条路径都从 `u_ex0_stage.down_valid_o` 起，经 EX fast wake、IntIQ
same-cycle select、PRF fast bypass、ALU0/ALU1、ROB/CSR request，终止于 CsrFile DFF。

本轮选择真实流水边界：删除 integer EX fast select 与 PRF fast bypass；正式 WB 在 N 沿
原子写 PRF 并置 IQ sticky，dependent N+1 最早发射。没有 false/multicycle 约束。

## 实现前拓扑审查

- producer：`OooIntBackend.ex0/1_*_q` 经五源仲裁形成正式 `wb0/1`。
- state consumers：IQ `src*_ready_q`、BusyTable、PRF `regs_q`、ROB done；均在沿上吸收正式 WB。
- removed combinational consumers：IQ resident select 的 `select_wakeup*` 与 PRF read0-3 的
  `bypass*`。
- collision proof points：IQ compaction、dispatch insertion、kill survivor 都已显式 OR
  `wakeup_match(wb0/1)`；flush 清 IQ 且 PRF recover 的优先级高于 write。
- unchanged risk：跨 lane result mux 继续保留，由 `RAW-I1` 证明合法 true arm 不可达；待
  T3M fresh 结果后再独立 A/B。

接口、owner、周期、flush/kill/stall 与六类合同见
`npc/rv64/design/specs/ooo-ex-sticky-wakeup-barrier.md`。Topology review 通过，可以进入 RTL。

## 预注册证据门槛

1. source checker：fast ABI 全消失且 formal WB state consumers 非空。
2. focused IQ/PRF/backend：N 不 issue/read-new，N+1 issue/read-new；覆盖双 lane/双源、
   dispatch/compaction/kill/flush/backpressure collision。
3. 三个可编译 mutation 与两个 assertion negative，禁止编译失败/空场景假绿。
4. lint/style/contract/module、protected `177/177`、CoreMark iter10、OS smoke。
5. canonical fresh synthesis；T3L 对照与 T3M focused STA；全局 5 ns WNS/TNS/loops/top40。

## 审查者预置反例

- 新 consumer 与 WB 同拍入队时丢唯一 wake pulse。
- IQ ready 与 PRF payload 错开一沿导致 stale operand。
- kill survivor 未吸收 WB，或 flush 后旧 wake 复活 preg。
- 删除 bypass 后 `RAW-I1` 漏洞使 issue1 读取 issue0 尚未落账的数据。
- focused `NO_TIMING_PATH` 来自空对象/旧网表，而非真实边界。
- WNS 改善但 TNS/功能恶化，被错误写成 200 MHz 达成。

## 当前定向结果

- source contract PASS：四个 production RTL 无 `fast_wb`、`select_wakeup`、PRF
  `bypass*`；formal WB→IQ/PRF/ROB 边界完整，IQ 八个 collision capture site 均在。
- focused 4/4 PASS：PRF、IntIQ、DispatchBackend、IntBackend；集成三 uop 用例证明
  WB N 拍不 select，N+1 双 lane 从 stored PRF 读取 64-bit 正确值。
- 两个 assertion negative 各只有一个目标 `ERROR:`；三个可编译 source mutant 均以
  `compile_rc=0/sim_rc=1` 被杀死。
- `check-contract` 初跑按预期发现计数 `89 -> 85`：删除 7 个旧 fast 身份/子集 `$error`
  （IntBackend 2、IQ 2、PRF 3），新增 3 个 sticky/stored 消费边界 `$error`（IQ 2、PRF 1），
  净减 4。旧接口已物理不存在，保留身份断言只会制造僵尸合同，因此 baseline 合法 ratchet
  到 85；必须以新 negative/mutation 牙齿而不是数量补丁证明不回退。

后续章节将在每一层证据生成后追加；当前不声明局部完成或 200 MHz 达标。
