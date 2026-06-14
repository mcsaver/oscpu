# npc/single CPI 1.174 归因分析

## 结论

`npc/single` 当前 5 级流水乘法接入方式仍是阻塞式长延迟 EX：乘法请求发出后，`ex_muldiv_wait_w` 会阻塞 `PipelineControl.ex_fire_o`，直到 `Rv32Multiplier.rsp_valid_o` 为 1。同一条 ID/EX 乘法等待期间由 `mul_req_issued_q` 防止重复发射。

因此，在同一个 CoreMark 二进制、同一 cache/BPU/config、同一动态指令流上，把组合乘法换成当前 5 级阻塞流水乘法不会减少 guest cycles；理论上只会按动态乘法次数增加等待周期。当前 CPI 下降不能归因于乘法器流水本身。

分析过程中发现并修复了一个长延迟请求边界：mul/div 请求原先可在 `ex_fire` 之前发出，如果源寄存器依赖 EX/MEM 中尚未返回的 load miss，就可能提前捕获旧操作数。现已用 `ex_operand_load_wait_w` 门控 mul/div 请求，等 `mem_response` 后再发起。

## 证据

- 当前 CoreMark ELF attribute：`rv32i_m_c_zicsr_zifencei_zmmul_zba_zbb_zbc_zbs`。
- 当前反汇编有 24 个静态乘法类指令，无 `__mulsi3`。
- 复跑命令：
  - `make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc run NPC_RUN_ARGS="--no-progress -m 0"`
- 修补后复跑结果：
  - `cycles=356772397`
  - `commits=303899926`
  - `CPI=1.174`
  - branch miss `2181807`
  - ICache miss `30844`
  - DCache miss `70`
  - DCache writeback `240`

## 归因

1. 相对旧 `rv32i_zicsr` CoreMark 镜像，主要原因是 guest 程序变短：旧镜像走 libgcc `__mulsi3` 软件乘法，约 746M commits；当前镜像走硬件 `mul/mulhu`，约 304M commits。
2. 相对 2026-05-22 的硬件乘法基线 `cycles=389956180/CPI=1.283`，当前 commits 基本仍是 304M 量级，但 cycles 降到 356.8M；主要差异是后续 2-way cache 消除了 CoreMark direct-mapped DCache 冲突，历史画像 DCache miss/writeback 约 `944k/771k`，当前为 `70/240`。分支 miss 只从 `2196215` 到 `2181807`，不足以解释约 33M cycles 差距。
3. 当前乘法器流水化主要改善 Verilator/综合组合路径压力；它可能提升 host 仿真 `eval()` 成本或时序收敛表现，但不会让这个 in-order 阻塞核心中的单条乘法在 guest cycle 上更快。

## 修复与验证

- `NpcCore` 新增 `ex_rs1_load_wait_w/ex_rs2_load_wait_w/ex_operand_load_wait_w`，mul/div 请求在源操作数等待 load miss 时保持不发。
- `tb_npc_core_smoke` 改成覆盖 `lui; addi; lw miss; mul; ebreak`，检查 x10 写回 `42`。
- 验证：
  - `make -C npc/single lint` PASS。
  - `make -C npc/single/testbench BUILD_DIR=/tmp/npc-mul-loadwait-full-tb RESULT_DIR=/tmp/npc-mul-loadwait-full-results run`：27/27 PASS。
  - `make -C npc/single -j4` PASS。
  - `make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc run NPC_RUN_ARGS="--no-progress -m 0"`：CoreMark PASS，统计仍为 `cycles=356772397`、`commits=303899926`、`CPI=1.174`。

## 后续判定方法

固定同一个 `.bin`，只在组合乘法 RTL 与当前流水乘法 RTL 之间 A/B，并保持 cache/BPU/config 不变。若统计 `commits` 相同，预期流水版 guest cycles 应不少于组合版；若 cycles 反而更少，需要继续查性能计数或流水控制 bug。
