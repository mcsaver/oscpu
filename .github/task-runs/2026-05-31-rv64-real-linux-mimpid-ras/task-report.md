# RV64 Real Linux MIMPID and RAS/SATP Task Report

## 目标

在真实 OpenSBI v1.8 已能 handoff mini payload 的基础上，直接加载 Debian RISC-V kernel，定位并修复真实 Linux early boot 的下一批缺口。

## 改动

- `npc/rv64/vsrc/include/define.v`
  - 新增 `CSR_MIMPID = 12'hf13`。

- `npc/rv64/vsrc/core/CsrFile.v`
  - 将 `mimpid` 纳入 known CSR。
  - 读 `mimpid` 返回 `0`，保持只读。

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 识别 `satp` CSR 写提交。
  - 在 `satp` 写的精确提交边界清空 RAS、return continuation、synthetic lane1 return、branch target cache 和 JALR BTB，避免预测目标跨地址空间切换复用。

- `am-kernels/tests/cpu-tests/tests/misa-priv.c`
  - 扩展检查 `mvendorid/marchid/mimpid/mhartid`。

- `am-kernels/tests/cpu-tests/tests/sv39-ras-relocate.c`
  - 新增回归，复现 Linux relocation 的 RAS/SATP 边界：低地址 call 填 RAS，真实 `ra/sp` 改高地址，high-only `satp` 后 `ret`。

- `npc/rv64/tools/Makefile`
  - 新增 `smoke-linux-kernel`，装载真实 OpenSBI、真实 Linux kernel 和 DTB。

## 根因

第一处缺口是 OpenSBI SBI base `get_mimpid` 读取 `CSR 0xf13`，此前 RV64 CSRFile 未实现 `mimpid`。

第二处缺口是 Linux `relocate_enable_mmu` 中的地址空间切换：低地址 call 先把低返回地址压入 RAS，Linux 随后把真实架构 `ra` 调整为高半区地址。旧 frontend 在 high-only `satp` 后把 RAS 低地址项当成返回目标，取指到低地址 `0x80201152` 时触发 instruction page fault，进入 early `stvec` 的 `0xffffffff800010bc`/`wfi` 循环。

## 验证

- `make -C npc/sim BACKEND=rv64 -j2`
  - PASS。

- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="misa-priv sv39-ras-relocate semihost-ebreak counteren-time sbi-timer sbi-base-console bitmanip" run NPC_RUN_ARGS="--no-progress --max-cycles 8000000"`
  - 7/7 PASS。
  - `sv39-ras-relocate` GOOD TRAP at `0xffffffff80000080`。

- `make -C npc/rv64/tools smoke-opensbi-sbi OPENSBI_FW_JUMP_BIN=/tmp/ysyx-opensbi/build-npc/platform/generic/firmware/fw_jump.bin OPENSBI_SBI_MAX_CYCLES=8000000`
  - PASS。
  - OpenSBI banner 后 payload 输出 `B`。
  - GOOD TRAP at `0x8020014c`。
  - `cycles=4472277/commits=4727351/CPI=0.946`。

- `make -C am-kernels/benchmarks/coremark AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ITERATIONS=10 run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`
  - PASS。
  - `CoreMark PASS 5 Marks`。
  - `cycles=2518694/commits=3216171/CPI=0.783`，保持低于 0.8。

- `make -C npc/rv64/tools smoke-linux-kernel OPENSBI_FW_JUMP_BIN=/tmp/ysyx-opensbi/build-npc/platform/generic/firmware/fw_jump.bin LINUX_IMAGE=/tmp/ysyx-rv64-linux/root/boot/vmlinux-6.12.90+deb13-riscv64 LINUX_MAX_CYCLES=20000000`
  - 预期内 max-cycles 退出。
  - 已越过旧 early trap loop。
  - `pc=0xffffffff8051be34`，`commits=6637254`。

- 同一真实 kernel smoke，`LINUX_MAX_CYCLES=40000000`
  - 预期内 max-cycles 退出。
  - PC 继续变化，说明不是同一 PC 死锁。
  - `pc=0xffffffff8021531e`，`commits=8830390`。

## 剩余限制

真实 Linux kernel 尚未完整 boot；当前 smoke 只证明已经越过 OpenSBI `mimpid` 与 Linux early MMU relocation/RAS 缺口，并且 40M cycles 内仍在继续退休。下一步需要继续收敛 kernel 后续路径，补设备模型、console/rootfs/virtio/blk、多源 PLIC，以及真实 Linux smoke 的通过判据。
