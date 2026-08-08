# V15S f784 named timing path and e7da owner-set emptiness slice

## Outcome

保留设计 `sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308` 作为下一轮可回退 RV64 时序 engineering candidate。它保持 owner/holder 生命周期不变，仅把 `mem_idle_o` 的 owner-set emptiness 从 32-bit popcount 零比较改为同一 Q-only `live_mask` 的归约或。

本轮不声明 5ns timing closure、PPA qualification、canonical、Pareto、ARCH_STABLE 或 release。

## f784 named Top40

原始 `traceable-f784-a1.status` 保留 `FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`。综合、OpenSTA、parser 与清理事务均为 rc=0，唯一失败是旧名字 oracle 强制要求 `/` 层次分隔符；当前公开网表名是模块/信号锚定的 flattened 名称。

独立 replay 不改写原状态，重放冻结报告后得到 PASS：206 项 production manifest、14 项 artifact、40 个 startpoint/endpoint 均核验通过；Top40 为 1 个 unique launch、40 个 unique endpoint，其中 38 个 `jalr_prefetch_hit_available`、2 个 `redirect_valid`。40/40 均经过 owner `free0_ready_o` 相关锥、`mem_owner_live_count_w`、`mem_idle_o`、ROB `control_event_pregrant_w` 和 fetch outstanding 状态。

## RTL slice

- `OooMemOwnerTracker` 的默认参数为 `TOKEN_COUNT=32`、`TOKEN_W=5`、`COUNT_W=6`；`live_mask_o=live_q`，`live_count_o` 是同一 `live_q` 的组合 popcount。
- `OooIntBackend` 新增 `v15s_mem_owner_any_live_w=|mem_owner_live_mask_w`，`mem_idle_o` 使用其反相；计数继续用于守恒与观测。
- `OOO_ASSERT` 每拍检查 reduction 与 count-nonzero 的一致性。
- spec 固化为同拍 Q-only 二值投影，不改变 allocation/free/kill/flush/terminal authority。

## Verification

- focused：assert-off PASS、assert-on PASS。
- compile-success mutation：把 any-live 常量化为 0，由 HIST-QH younger-store oracle 以 `mem_idle got=1 expected=0` 检出；生产 RTL SHA 未漂移。
- L0：113/113 module PASS。
- L1：177/177 official、61/61 AM、DiffTest mismatch=0；CoreMark 10 iterations/CRC `0xfcaf` 与 Dhrystone 10000 runs 均 GOOD TRAP；11/11 schema-valid evidence mutations 被拒绝。
- 编译中间物 retained=0；L0/L1 task-run 总计约 17 MiB，其中冻结 simulator/reference 和 240 个小型 program image 是执行身份凭据，不是 build tree。

## Same-config PPA observation

| Metric | f784 | e7da | Delta |
|---|---:|---:|---:|
| WNS | -17.869169235 ns | -17.592411041 ns | +0.276758194 ns |
| TNS | -488025.46875 ns | -468716.46875 ns | +19309.0 ns |
| logic area proxy | 2181526.48 | 2181644.08 | +117.60 |
| cells incl. macros | 929441 | 929222 | -219 |
| combinational loops | 0 | 0 | 0 |

40/40 paths remain violating；power `0.136W` 仅为 fixed-toggle relative-only。候选因此只保留为可回退工程点。

## Review and scope

v4 独立限定材料复核确认二值等价、32/6 位宽和候选保留为 PASS；production 32-token 动态 full、全局 holder 完备性与四态 X-clean 保持 GAP。现有 4-token full 边界、参数约束、定向 mutation 和 L0/L1 足以支撑 engineering-candidate 弱声明；升级 canonical/signoff 时再补 production 参数 TB 或形式证明。

候选形成后的 current-design 复核发现一个启动环境边界：login shell 的 PATH 额外暴露 `riscv64-unknown-elf-gcc`，因此 verifier 正确拒绝两次与原执行不同的 toolchain 输入集合；两份 FAIL 日志原样保留。随后使用原 L0/L1 的 non-login WSL 启动上下文重放，得到 `[FULL-CORE-FUNCTIONAL-VERIFY][PASS]`，设计仍为 `e7da…7308`，分类为 `EXACT_ORIGINAL_NON_LOGIN_LAUNCH_CONTEXT`。这不是 RTL 漂移，也不改写先前失败。

本轮按风险不运行 L2/L3；没有特权级、MMU、设备模型或系统终端语义变化。Ubuntu 始终仅在用户明确要求时运行。
