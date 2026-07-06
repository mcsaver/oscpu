# DiffTest 模块笔记

## 当前状态
<!-- DiffTest 配置与通过情况 -->
- 2026-07-06: **RV64 difftest 全状态扩展 阶段2/3/4 落地(commit 199aeebbc + d67754c3b)**。**阶段2 FPR**:
  独立通道(对称 CSR)——NEMU `difftest_fpr_snapshot(fpr[32])` + NPC 每 commit 拍 XMR 读 arch FPR(深路径
  `u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.arch_fprs_flat_w`,
  32 scalar DPI)+ 延迟一拍比较。★验证: 全套 rv64uf/rv64ud FP 计算 FPR 误报=0(含双提交 FP,全 TOHOST PASS),
  fp-difftest-probe 注入分歧被正确抓。**阶段3 掩码**: 比较改 `kCsrCmpList` 选择性索引=确定性 CSR[0..16]
  + fflags/frm 纳入; mie/mip/mcycle/minstret 排除。**阶段1.5**: 确认 skip-xret 是正确处理(xret 的 CSR
  效果在下一条验证), 非临时缓解。**阶段4 中断同步**: NPC 取异步中断(csr_trap_irq)补报 `npc_handled_trap_event`
  kind=2 → cpu-exec 登记 pending → difftest.cpp【集成进自主 trap 恢复】: control-flow mismatch 时若 NPC
  报了中断则让 NEMU `difftest_raise_intr(mcause)`(NPC 主导时刻)否则 exec faulting——统一处理异常(faulting
  不 commit)+中断(异步指令边界取)。**验证**: 4 个异步中断(plic-sirq/uart-plic-sirq/sbi-timer/sbi-ipi-reset-hsm)
  从 ABORT → HIT GOOD; 全套 AM 全状态 difftest **GOOD 51→56**(阶段1→item5→阶段4)。剩 3 ABORT:
  fp-difftest-probe(故意 probe 预期 abort)+ counteren-time/misa-priv(counter/misa 读值 GPR 分歧, golden
  guard 暴露的真分歧逐个修 backlog)。非-difftest core-regress overall_rc=0 无回归。★**CSR golden guard
  暴露真分歧 backlog**: CSR 0x744(mnstatus/Smrnmi)——NEMU 取 illegal trap、NPC 不取(NPC 未实现 CSR 的
  illegal 检测缺口, 阻 riscv-tests difftest); counter/misa 读值差异。这些是全状态 difftest 作为持续
  golden guard 的产出。
- 2026-07-06: **misalign 策略对齐 + difftest 自主 trap 恢复(commit 0a399a878)**。消除 sv39-xpage-misalign
  的 NPC↔NEMU 发散。**(1) NEMU 普通 load/store misaligned 也 fault**(对齐 NPC 硬件 LSUControl 的 addr%size):
  rv64i.c `exec_rv64i_load/store` 入口按 `len=1<<(funct3&3)` 查 `addr%len` → CAUSE_LOAD/STORE_MISALIGNED
  (tval=addr); fp.c `exec_rvf_load/store` 同; compressed.c 的 c.sw/c.sd/c.swsp/c.sdsp 改走 exec_rv64i_store。
  AMO 已自查、页表 walk 走 dcache_peek(非 Mr/Mw)、decode_cache 取指走 Mr → 均不受影响(故不改 Mr/Mw 宏)。
  **(2) ★difftest 自主 trap 恢复(通用 exception 同步, difftest.cpp)**: NPC 的 exception faulting 指令
  【不 commit】(直接 trap 到 handler)→ difftest 收不到、NEMU 停在 faulting 指令 → dut handler 首条 commit
  失配。修: control-flow mismatch 时让 NEMU exec(1) 执行 faulting 指令, 若同 fault 则 trap 到同一 handler(pc)
  对齐、否则才真 mismatch, 并刷新延迟 CSR pending 为 trap 后 ref CSR。**通用处理任意 NPC 同步异常**(misalign/
  page/access/illegal), faulting 指令的存在与 handler 入口由 dut commit 流隐式给出。**验证**: sv39-xpage-misalign
  从 ABORT → HIT GOOD; 全套 AM 全状态 difftest GOOD 51→52; 剩 7 ABORT 全是其它类别(4 个异步中断 PLIC/timer/
  SBI-IPI 需 difftest 中断同步 + counteren-time/misa-priv/fp-difftest-probe 各自), 非 misalign。52 GOOD 证
  NEMU 对合法访存不误 fault。未改 NPC RTL, 非-difftest 不受影响。
- 2026-07-06: **RV64 difftest 全状态扩展 阶段1 落地: CSR + priv 比较通道(commit f4e115fc8)**。在 gpr+pc
  之上新增 **CSR+priv 比较旁路通道**(不动 regcpy 的 gpr+pc memcpy, 分阶段友好)。机制跨四层: NEMU
  `isa_difftest_csr_snapshot`(dut.c 按固定索引扁平化 CSR+priv)+ ref.c 导出 `difftest_csr_snapshot`;
  NPC NpcSimTop 每 commit 拍 XMR 读 u_csr_file → `npc_arch_csr_event` DPI(23 scalar); cpu-exec
  `g_dut_csr_live`+CommitEvent.csr 快照; difftest.cpp 可选 dlsym(旧 ref.so 降级只比 gpr/pc)。阶段1 比较
  索引 [0,17)(mstatus/mepc/mcause/mtvec/mtval/mscratch + S 态 + medeleg/mideleg/satp/mcounteren/
  scounteren + priv)。★**两个 snapshot 时序修正(非功能 bug)**: (1)**延迟一拍比较**——每拍 XMR 读的
  csr_*_q 因 CSR 写 NBA 在同拍 always_ff 读之后 → 滞后一拍, 用「当前 DUT CSR(上条写后) vs 暂存上条
  ref CSR」抵消; (2)**skip xret**——mret/sret 的 mstatus/priv 更新时序与 csrw 不一致使统一滞后模型
  失配(测试仍 HIT GOOD), 暂跳过 xret 比较点(阶段1.5 根本修=RTL 暴露 CSR next-state 组合 wire)。诊断开关
  `NPC_DIFF_CSR_WARN`(每类分歧打印一次不中止)。**验证: ★零新增 abort** —— 全套 AM 全状态 difftest
  GOOD=51/59; 剩 8 ABORT 全是 GPR/PC 层已有 control-flow mismatch(sv39-xpage-misalign=misalign 差待
  对齐; counteren-time/sbi-timer/plic-sirq/uart-plic-sirq/sbi-ipi-reset-hsm/misa-priv/fp-difftest-probe
  =timer/中断/SBI/FP 异步难对齐), CSR 字段全空(非 CSR 引入); sv39-ad-bits/ras-relocate 的 CSR+priv 全对齐。
  非-difftest core-regress overall_rc=0 无回归。**剩: 阶段1.5(xret/trap 时序精化)+阶段2(FPR)+阶段3
  (counter/mip 掩码)**。
- 2026-07-06: **RV64 NPC↔NEMU difftest 验证 Sv39 HW-managed A/D 对齐成功**。NPC 已把 Sv39 A/D 从 SW-managed(缺失即 page fault)全面改为 HW-managed(Svadu, 对齐 NEMU) —— 数据侧 `020499a70` + 取指侧 `d3302ee9b` + 观测层 checker `6b5da3e99`。流程: 备份 NPC 三件套(.config/auto.conf/autoconf.h)+NEMU .config → `make -C npc/rv64 difftest-ref`(建 NEMU 参考 `nemu/build/riscv64-nemu-interpreter-so`, GUEST_ISA=riscv64 含 SoftFloat) → `sed CONFIG_NPC_DIFFTEST=y` + `tool/kconfig/build/conf --syncconfig Kconfig`(三处一致) → 构建 → `./build/NpcSimTop -i <bin> -b`(difftest 默认 on) → 恢复配置。**验证**: `sv39-ad-bits`(A/D 专测) HIT GOOD TRAP 全程锁步无 mismatch + `sv39-ras-relocate` + 5 compute 测试均锁步 → A/D 路径不再是 NPC↔NEMU 发散源。★**当前 RV64 difftest 比较范围仍是提交后 GPR/PC(DIFFTEST_REG_SIZE=33)**, CSR/FP 未比(step 4 待扩)。
- 2026-07-06: **★difftest misalign 策略差(step 4 待处理)**: `sv39-xpage-misalign` difftest **发散** = control-flow mismatch(NPC 提交 trap 处理器读 mcause=6, NEMU 顺序执行)。根因 = **misaligned 普通访存策略差**: NPC 硬件对 misaligned load/store 取 fault(cause 4/6, spec 允许), NEMU 只对 AMO 查对齐(`nemu/src/isa/riscv64/inst/amo.c`), 普通访存 misaligned 经 `vaddr_read/write` 透明处理**不 fault**。**与 A/D 无关**(A/D 是 page-fault cause 13/15)。step 4 全状态 difftest 扩展前须先对齐 misalign 策略(令 NEMU 也 fault, 或 difftest skip misalign, 或测试避 misalign)。
- 2026-07-06: **★config 备份/还原坑(再次踩)**: 启用 `CONFIG_NPC_DIFFTEST=y` 后备份/还原 NPC config **必须含三件套** `.config` + `include/config/auto.conf`(make 变量) + `include/generated/autoconf.h`(C 宏), 只还原部分会导致 auto.conf(=y)↔autoconf.h(off) 不一致 → difftest.cpp 编译又撞 header stub 假重定义(红鲱鱼)。修/验证用 `conf --syncconfig Kconfig` 从 `.config` 一致重生成; 三处 `grep DIFFTEST` 必须同号。
- 2026-05-24: SoC MROM/SRAM 初始同步已加上双重门控：NPC 侧 `CONFIG_NPC_SOC_DIFFTEST=y` 只表示允许 SoC 本地存储同步，真正执行前还会 `dlsym()` reference so 的 `soc_sim_in_range()` 并确认 NEMU 报告 MROM/SRAM 在 SoC 地址空间内。这样只有 NEMU 以 `CONFIG_SOC_SIM=y` 构建时才会走 `difftest_memcpy(MROM/SRAM)`；若 reset PC 落在 MROM 但 reference 不是 SoC 模式，会在 NPC 初始化阶段报出配置不匹配，而不是让普通 NEMU PMEM assert。验证：`nm -D nemu/build/riscv32-nemu-interpreter-so` 可见 `soc_sim_in_range`，`riscv32-ysyxsoc` cpu-tests 39/39 PASS。
- 2026-05-24: NPC SoC difftest 已按 MROM/SRAM 模式重新接上：`npc/soc/csrc/memory/paddr.c` 暴露 `NpcDifftestMemRegion` 枚举，目前列出 MROM 与 SRAM；`cpu/difftest.cpp` 在 `difftest_init()` 后先用既有 `difftest_memcpy(..., DIFFTEST_TO_REF)` 同步整段 MROM/SRAM，再设置 reset PC，不新增 DiffTest API。为了保留简洁默认配置，新增 `npc/soc/configs/difftest_defconfig`，验证时使用 `make -C npc/sim BACKEND=soc backend-difftest_defconfig` 打开 `CONFIG_NPC_DIFFTEST=y`。验证：NEMU `riscv32-soc_defconfig` + `make -C npc/sim BACKEND=soc difftest-ref -j4` PASS；`ARCH=riscv32-ysyxsoc` cpu-tests 在 `NPC_RUN_ARGS="--diff=default --no-progress -m 0"` 下 39/39 PASS，日志每项启动可见 `[npc-diff] sync mrom` 与 `[npc-diff] sync sram`。
- 2026-05-23: NPC SoC 后端现在可使用 NEMU `CONFIG_SOC_SIM` reference 跑通 difftest。流程为先让 NEMU 处于 `riscv32-soc_defconfig`，再执行 `make -C npc/sim BACKEND=soc difftest-ref` 生成 `/home/lyg/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so`；`npc/soc` 需使用 `default_defconfig` 或等价配置打开 `CONFIG_NPC_DIFFTEST=y`，性能配置会主动拒绝 `--diff`。验证命令：`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_SIM_BACKEND=soc NPC_RUN_ARGS="--diff=default --no-progress -m 0"`，38/38 PASS，启动日志显示 `Difftest: ON`。本轮还修复了 reference so 中 Capstone 相对路径导致的段错误；当前 difftest 比较范围仍是提交后 GPR/PC，不比较 SoC 外设内部状态。
- 2026-05-22: NPC -> NEMU difftest reference 已随 NEMU machine CSR/CLINT 补齐重新验证。`make -C npc/single difftest-ref` 生成的 `/home/lyg/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so` 现在包含 `mvendorid/marchid`、`mcycle/cycle/mcountinhibit`、CLINT `msip/mtimecmp/mtime` 和 M-mode 中断查询基础；切到 `npc/single/default_defconfig` 后重建 NPC，执行 `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS="--diff=default --no-progress -m 0"`，38/38 PASS，日志每项启动均显示 `Difftest: ON`。当前比较范围仍是提交后 GPR/PC，不比较 CSR；NEMU 的 `mtime/mcycle` 为指令级近似，针对异步 timer 精确时序的 difftest 仍需后续专项策略。
- 2026-05-21: NPC difftest 默认语义已按验证预期调整：`CONFIG_NPC_DIFFTEST=y` 时，`npc_simconfig_init()` 默认置 `difftest=true`，启动后自动加载 `NPC_DEFAULT_DIFF_SO`（当前为 `nemu/build/riscv32-nemu-interpreter-so`），每条 NPC commit 后执行 `ref_exec(1)` 并比较提交后 GPR/PC。`--diff=default|path` 现在用于显式选择 reference，新增 `--no-diff` 用于本次运行裸跑；`perf_defconfig` 仍保持 `CONFIG_NPC_DIFFTEST=n`，从编译期去掉 reference loader 与热路径检查。welcome 会显示 `Difftest: ON/OFF`，ON 为绿色、OFF 为红色。验证：`make -C npc/single -j4` PASS；`NpcSimTop --help` 显示 `--no-diff`；直接运行 `add-riscv32-npc.bin --no-progress` 默认打印 `[npc-diff] reference enabled...`、`Difftest: ON` 并 GOOD TRAP；追加 `--no-diff --no-progress` 后不加载 reference、显示 `Difftest: OFF` 且 GOOD TRAP。
- 2026-05-20: NPC difftest 由单纯运行时 `--diff=...` 扩展为两层开关：先用 `CONFIG_NPC_DIFFTEST` 决定是否编译 difftest 能力，再用运行参数 `--diff=default|path` 决定本次是否启用 reference。`default_defconfig` 保持 `CONFIG_NPC_DIFFTEST=y`，`perf_defconfig` 使用 `CONFIG_NPC_DIFFTEST=n`；关闭时 `difftest.cpp` 不参与构建，`-ldl` 不参与链接，提交热路径不检查 difftest 状态。验证：关闭配置构建 + 裸跑 `cpu-tests add` PASS；打开配置后 `cpu-tests add NPC_RUN_ARGS='--diff=default -m 0'` PASS；本地最终恢复为进入任务前的关闭配置。
- 2026-05-19: NPC 扩到 RV32IMC + Zba/Zbb/Zbc/Zbs + cache/fence.i + BPU 后，`--diff=default` 继续以 NEMU shared object 为参考，比较范围仍为提交后 GPR 与 PC；全量 `timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 38/38 PASS。benchmark 也在同一 difftest 参数下通过：CoreMark 默认 1000 iterations、Dhrystone 默认 500000 runs、MicroBench `mainargs=test` 全部 `HIT GOOD TRAP`。新增 RVC 路径下，NPC 提交给 difftest 的 `commit_inst_o` 是解压后的内部 32-bit 指令，PC 对比以 `commit_next_pc_o` 为准。
- 2026-05-19: 本轮按当前源码复核 `riscv32-npc` difftest，`--diff=default` 的启动日志显示实际加载 `/home/lyg/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so`；NEMU 自身的 `riscv32-nemu` 回归仍开启 Spike difftest，并加载 `nemu/tools/spike-diff/build/riscv32-spike-so`。验证：`make -C npc/single difftest-ref`、`make -C npc/single lint`、`timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`，NPC 35/35 PASS；`timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run`，NEMU 35/35 PASS。
- 2026-05-19: `riscv32-npc` 已具备运行时可选 difftest：命令行 `--diff=default` 使用 `npc/single/Makefile` 注入的默认 reference so（当前源码为 `nemu/build/riscv32-nemu-interpreter-so`），也可用 `--diff=/path/to/ref.so` 指定；`--diff-port=N` 透传给 reference init。当前比较范围为 RV32 GPR[0..31] 与提交后 PC，不比较 CSR；MMIO 指令通过 `npc_difftest_skip_ref()` 做 reference skip + DUT 状态同步。
- 2026-05-19: 已验证 NPC difftest 回归：`make -C nemu/tools/spike-diff GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter`、`make -C npc/single lint`、`make -C npc/single` 均通过；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'` PASS；`timeout 240s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` 35/35 PASS；Dhrystone/CoreMark 默认负载和 MicroBench `mainargs=test` 均 PASS。

## 不一致历史
<!-- 曾出现的 NPC vs NEMU 不一致记录 -->

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 2026-05-24: `riscv32-am_defconfig` 是 NEMU 的 AM target 配置，不适合直接拿来构建 NPC 使用的 native shared-object reference；如果当前 `.config` 已切到 `CONFIG_TARGET_AM=y`，再运行 NEMU make 目标时需要先提供 `AM_HOME/ARCH` 或重新生成 native defconfig，否则会在包含 `$(AM_HOME)/Makefile` 时失败。验证 SoC ref 后务必恢复 `riscv32-soc_defconfig`。
- 2026-05-24: `riscv32-ysyxsoc` 从 MROM 复位后，若 AM 链接脚本把可写 `.data/.bss` 也放在 MROM，difftest 本身不会先报 mismatch，DUT 会在全局数组写入时触发 `store to read-only mrom`/store access fault。正确布局是 `.text/.rodata` 在 MROM，`.data/.bss/heap/stack` 在 SRAM，并由启动代码复制 `.data`、清零 `.bss`。
- 2026-05-23: `am-kernels/tests/cpu-tests` 的汇总 Makefile 会把单项失败写进 `.result`，但总 `make run` 不一定非零退出；验证 difftest 回归时要额外 grep `***FAIL***`、`mismatch`、`Segmentation fault` 或 `ABORT`，不能只看外层命令退出码。
- 2026-05-23: `npc/soc/perf_defconfig` 会关闭 `CONFIG_NPC_DIFFTEST`，带 `--diff` 运行会被宿主参数解析主动拒绝。要验证 SoC difftest，先执行 `make -C npc/sim BACKEND=soc backend-default_defconfig` 或确保 `npc/soc/.config` 中 `CONFIG_NPC_DIFFTEST=y`。
- 2026-05-19: `fence.i` + cache 的 difftest 成功依赖两侧语义同步：NEMU reference 本身按 ISA 重新执行自修改代码；NPC 侧 host cache 必须在 RTL 检测到 EX-stage `fence.i` 时 flush I/D cache，否则下一次 indirect call 可能从 ICache 取到修改前的旧指令，表现为 GPR/PC mismatch。
- 2026-05-19: 当前工作区 difftest 有两层参考路径：NPC 的 `--diff=default` 实测加载 NEMU shared object；NEMU 自身的 `CONFIG_DIFFTEST_REF_SPIKE=y` 再加载 `nemu/tools/spike-diff/build/riscv32-spike-so`。排查 reference 差异时先看启动日志中的实际 so 路径，不要只根据历史记忆判断。
- 2026-05-19: 差分 PC 必须来自提交级 `commit_next_pc_o`，不能用 RTL `debug_pc_o` 或 fetch PC 推断；流水线里 fetch frontier 与“当前提交指令之后的架构 PC”经常不同，尤其是 branch/JAL/JALR/mret 与 LSU stall 后。
- 2026-05-19: MicroBench 含 C++ benchmark，当前系统缺 `riscv64-linux-gnu-g++`；可用 `/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-g++`，运行时需覆盖 `CROSS_COMPILE=/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-` 后再构建。
