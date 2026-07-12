# RV64 T3A current-top retry：dead cross-lane forward 删除候选再次否决

## 基本信息

- `task_id`: 2026-07-13-rv64-t3a-current-top-retry
- `status`: completed_rejected_candidate
- `profile`: npc-dev
- `supplementary_profile`: yosys-sta
- `base_commit`: 851049ecea559c79318c1be9604999427cd335e6
- `updated_at`: 2026-07-13 02:27:46 +0800
- `parent_goal`: active；完整功能与 physical 200 MHz 尚未闭合

## 为什么重做一次已拒绝的实验

2026-07-12 的第一次 A/B 中，full-chip top40 全部在 frontend，删除
`issue0 current result -> issue1 operand` mux 没有切中主路径，且 PPA 回退，所以候选已还原。
IFU-ACCESS-G1 的后续 fresh A 基线发生了路径族迁移：39/40 条 D-cache→MIQ 和唯一
D-cache→fetch 路径都明确经过这组旧 mux。RAW-I1 断言、负探针和“无 dispatch bypass / 无
early-result wakeup”证明 true arm 对合法状态不可达，因此有必要在新的 current top 上做一次
严格隔离的 retry，而不能机械沿用旧 top40 的结论。

## 候选与输入隔离

- 候选仅删除 `OooIntBackend` 中两路 current-result predicate/mux，lane1 operand 直连 PRF；
  不改状态、握手、kill、memory order 或正式 WB。
- A 是已校验归档 `tmp/2026-07-13-rv64-ifu-access-g1/NpcTop-200MHz-fresh.tar.zst`。
- 临时 Git index 把 B 的 `OooIntBackend.v` 单独还原到 parent blob 后，完整 `vsrc` binary
  diff SHA 精确回到 A provenance 的 `ade664147af14bd...`，证明 A/B 唯一 RTL 差异是候选；
  用户现有 frontend/debug/sim 未提交改动在两侧完全相同。
- B synth 命令、source/config hash 与非 signoff 边界冻结在
  `tmp/2026-07-13-t3a-retry/sta-provenance.md`。

## 功能与非真空证据

- focused IQ/Dispatch/IntBackend/AluCoreSlice/CoreTopGlue：5/5 PASS。
- 永久 module suite：93/93 PASS。
- RAW-I1 negative probe：只命中 `[INT-ISSUE-CONTRACT RAW-I1]`，runner 按预期非零。
- style PASS；Verilator 5.051 lint PASS；contract current=60 / baseline=59。
- CoreMark 10 iterations 与 A 逐项相同：`2,913,259 cycles / 3,218,573 commits / CPI 0.905`，
  CRC `0xfcaf`，GOOD TRAP，CoreMark/MHz `3.503`。

这些结果证明候选没有可见 cycle/功能差异，但不能替代 full-chip timing/PPA 门禁。

## Fresh synthesis / OpenSTA A/B

| 指标 | A（保留 mux） | B（删除 mux） | 裁决 |
| --- | ---: | ---: | --- |
| WNS | -10.001 ns | -10.182 ns | 恶化 181 ps |
| TNS | -120125.49 ns | -142389.47 ns | 恶化 22263.98 ns / 18.5% |
| 诊断频率 | ≈66.66 MHz | ≈65.87 MHz | 恶化约 1.19% |
| combinational loops | 109 | 142 | +33 / 30.3% |
| stdcell count | 656264 | 656390 | +126 |
| known stdcell area | 1570633.96 | 1571485.72 | +851.76 / 0.0542% |
| sequential area | 428920.80 | 428920.80 | 不变 |
| vectorless total power | 0.118 W | 0.120 W | 约 +1.7% |
| combinational power | 0.0150 W | 0.0167 W | 约 +11.3% |

结构删除本身是真实的：B `.sim` 中 `issue1_src{1,2}_value_w` 为 0 命中，旧
`issue0_wb_data -> issue1 operand` arcs 已消失；但 top40 从 A 的 `1 fetch + 39 MIQ` 迁移为
B 的 `1 fetch + 39 FP exec1`，且全局硬指标整体恶化。因此候选作为 200 MHz timing knife
被明确否决并用 `apply_patch` 还原；当前生产 `OooIntBackend.v` 与 parent HEAD SHA-256 均为
`89da54878c3ea1653795299e323cf1c84065925550aca43da53e17b059da6eda`。

## 独立审查与下一刀

审查者把 A 的 109 条 loop 还原为：108 条长运算 response→WB→PRF/IQ→branch-kill 反馈，
另 1 条 FP dual-lane free-list credit/ready 真环。下一刀选择低 CPI 的 long-op source-class
quarantine：正式 WB、BusyTable、IQ 状态吸收与 PRF 时序写保持完整；只有 IQ 同拍 select 和
PRF read0–3 write-through 改吃独立的 EX/MEM-only fast broadcast。这样 MulDiv/CLMUL 依赖只
晚一拍，ALU/load 快路不变，预计结构切掉 108 条环。FP admission SCC 另用 raw-intent / state-only
credit / actual-accept 分离，并看护 mandatory pair atomic fire；不能只改单个 FreeList comparator。

完整 branch packet 注册虽然也能切环，但会把 redirect/BPU/错误请求窗口整体推迟一拍；全 WB
注册会让所有 producer→consumer 增加一拍。两者均不作为首选。

## 实现者 / 审查者对抗结论

- 实现者证据：候选功能全绿、CoreMark cycle-exact、旧 arc 物理消失、fresh synth/OpenSTA 可复核。
- 审查者反例：full-chip WNS/TNS/loop/area/power 全部回退，top39 只迁移到更差的 FP 尾；
  142 个 loop 仍使绝对 STA 非 signoff。
- 冲突裁决：回退候选，保留失败证据；不得把本切片称为 200 MHz 完成。

## 留档与非声明

- B fresh build 已归档为
  `tmp/2026-07-13-t3a-retry/NpcTop-200MHz-rejected-b.tar.zst`，22,332,695 bytes，SHA-256
  `43d037aad2155e272f681eae0d135f7fab50153fd78aee815c2a384b9015c404`；`zstd --test`、
  `tar --list`、`SHA256SUMS --check` 全部 PASS。
- 该 STA 使用 ideal clock、无 SPEF/CTS/OCV/full IO constraint，并含四个 placeholder macro
  Liberty；它只用于同输入 A/B 和瓶颈排序，不是 physical 200 MHz signoff。
- parent goal 保持 active；功能债（IFU fault tval、PTW/PMP/PMA、LSU standard split、wrapper
  ARSIZE）和真实物理签核均未因本实验关闭。
