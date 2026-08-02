# RV64 V13G `OooIntIssueQueue` onehot pop-mask checkpoint

Status: DEVELOPMENT CHECKPOINT PASS / independent review APPROVED / local PPA PASS /
full-core coarse PASS / full-core mapped, STA, power and system GAP

## RTL 机制

`OooIntIssueSelect8` 原本已经产生 issue0/issue1 owner onehot，但 packed compaction 又把 owner 编成
3-bit index，再对 8 个 entry 逐项比较。V13G 直接用 `issue*_onehot_w & {8{issue*_fire_w}}`，并把
memory-pair accepted edge 映射为 `8'b0000_0011`，形成 `compact_remove_w`。survivor `write_i`、
payload copy、dispatch append、sticky wake、kill/flush/reset、端口和所有时序边界不变。

等价范围是正常硬件合同下的 known onehot、两 lane owner 互斥及 memory-pair 原子 pop2；不声称在
内部 owner multi-hot 或 X/Z 违约态下与旧 binary encode/decode 四态行为完全相同。既有 onehot、
packed-age 与 lane 合同断言未修改、未削弱。

## 身份与功能证据

- 父 design-id：`sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`。
- 候选 design-id：`sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44`；
  full-core coarse 前后 JSON 完全一致。
- 与父 binding 比较的 146 份 RTL 中只改变 `OooIntIssueQueue.v`。最终 RTL SHA-256：
  `08b32e2c69690f8dcd66aa69d1cd3001acdb343319f55348379c273ec7aab012`。
- G1/G4 stimulus-owned V11F edge model PASS；G4 全量 IQ TB PASS。
- `tb_ooo_dispatch_backend`、`tb_ooo_int_backend`、`tb_ooo_alu_decode_backend` 3/3 PASS；
  `check-rtl-style` PASS。
- 通用 TB 与 G1 的 12 个 mismatch 在父/候选同配复现，属于旧 V8O generation-nonzero oracle
  不适配宽度 1；原始 FAIL 与有效替代 oracle 都保留在 `evidence/functional/`。

## 局部 PPA

配置均为 `OooIntIssueQueue`、200 MHz、flatten=1、share=0；OpenSTA 使用同一 icsprout55 liberty、
5 ns ideal clock、zero I/O delay。

| Metric | V13F parent | V13G candidate | Delta |
| --- | ---: | ---: | ---: |
| coarse cells | 4,430 | 4,385 | -45 |
| coarse `$eq` | 198 | 184 | -14 |
| coarse `$logic_and` | 379 | 353 | -26 |
| coarse `$mux` / `$pmux` | 1,614 / 1,481 | 1,614 / 1,481 | unchanged |
| mapped cells | 34,468 | 33,284 | -1,184 |
| mapped area | 75,205.48 | 74,917.64 | -287.84 (-0.383%) |
| sequential area | 19,293.12 | 19,293.12 | unchanged |
| worst slack | +2.233862638 ns | +2.406632185 ns | +0.172769547 ns |

两次 `synth_check` 均为 0 problems，TNS/WNS 均为 0/0。父 top40 全部为
`valid_q[0]→entry0 payload D`；候选该族退出，新的 worst 是
`valid_q[5]→bht_idx_q[1] D`，仍属于 packed compaction，但不再经过原 binary owner 回译瓶颈。

PPA 运行后只更新了解释性 RTL 注释与 spec；`evidence/source/ppa-input-reconstructed/` 的文件哈希
精确复现运行时 byte stream，`ppa-input-to-final.diff` 证明最终 RTL 仅有注释差异。

## Full-core coarse 传播

父基线来自同一 146-file binding 的 V13B current-design checkpoint；配置为 `NpcTop`、200 MHz、
flatten=0、share=0、stop-after-coarse=1。候选在 235.22 s 内 fail-closed PASS：

| Metric | Parent | Candidate | Delta |
| --- | ---: | ---: | ---: |
| total cells | 51,129 | 51,084 | -45 |
| wire bits | 1,690,602 | 1,690,585 | -17 |
| `$eq` | 3,631 | 3,617 | -14 |
| `$logic_and` | 7,828 | 7,802 | -26 |
| `$mux` / `$pmux` | 15,471 / 2,659 | 15,471 / 2,659 | unchanged |

delta 与局部 coarse 精确一致，没有观察到 parent 层结构成本转移；这仍不是 full-core mapped/STA
或 power 结论。

## 裁决与清理

V13G 可保留为 current RTL 的开发检查点：功能合同通过，局部 mapped area/slack 同时正向，且
full-core coarse 精确传播。由于没有 full-core mapped/STA、qualified power、完整架构 cohort 或
新 system transaction，不把它描述为最终 PPA/signoff promotion。

独立审查裁决为 `APPROVED_DEVELOPMENT_CHECKPOINT`。批准范围严格限定于 control known 0/1、
firing owner exact-onehot、双 regular lane owner 互斥，以及 Q-only memory-pair 单握手原子 pop2。
既有 onehot 断言对 X 不是 fail-closed knownness 证明，且本轮未注入 selector X/Z；普通双 memory
lane 的两个 downstream READY 也未在本轮证明原子耦合。这两项与全部未运行阶段继续记 GAP，
详见 `review-result.md`。

审查指出 spec 首页 R3.3 状态文字滞后；shell 归还后只修正文档状态句，RTL 与 design-id 未变。
冻结审查输入和修正后 spec 哈希见 `evidence/source/post-review-spec-status.md`。

full-core runner 已删除 228,079,766 bytes / 7 files；其余 local PPA 与 VVP runtime 又删除
230,104,813 bytes / 19 files，总计 458,184,579 bytes / 26 个可再生产物。它们不能直接恢复，
但可由冻结源码、配置和保留日志重建。task-run 只保留源码身份、功能日志、stat/check、STA top40、
full-core coarse 结果与裁决。

归档后又按已解析的三个精确路径删除 compact agent-flow 与 DB materialize staging：
21,158 bytes / 18 files。该 staging 不能直接恢复，但稳定记忆可从 stored DB 重新 materialize，
agent-flow 结论已固化在本报告、`summary.json` 与 `review-result.md`。
