# RV64 JAL Link 与 Ubuntu Shell Watch 进展

## 目标

- 继续推进“Ubuntu 22.04 full shell on NPC/Verilator”目标，不使用 Vivado 作为前置。
- 区分 QEMU reference、NPC 固件/Linux 进展、官方 `/bin/sh` marker 三层证据。
- 修复任何会导致 L5 gate 误判的基础 RTL root cause。

## 过程与结论

1. 复核 L5 shell 产物存在：`NpcSimTop`、shell OpenSBI `fw_jump.bin`、Linux `Image`、`ubuntu-22.04-riscv64.cpio`、shell DTB 均存在。
2. QEMU reference 复验通过：`make -C npc/rv64 qemu-ubuntu-shell-initramfs QEMU_TIMEOUT=30s` 打印 Ubuntu 22.04.5 os-release、`[ysyx-sh] /bin/sh -c marker`、`/bin/sh -c exit=0`。
3. NPC 首次 `smoke-ubuntu-shell-watch UBUNTU_INITRAMFS_MAX_CYCLES=1200000000` 失败在 OpenSBI 早期：`pc=0x80000680/0x80000682`，反汇编对应 `fw_boot_hart: li a0,-1; ret`，recent commit 显示 `ret` 回到自己。
4. 新增 `jal-link-smoke.S` 和 `smoke-jal-link`，最小复现 JAL link 写回错误：修复前 BAD TRAP code=1。
5. RTL root cause：`OooAluFetchCore` direct JAL 派发给 backend 的 `next_pc` 使用 jump target；`OooIntBackend/WBU` 的 `WB_SEL_PC4` 使用 issue `next_pc` 作为 link value，导致 `ra=target`。
6. 修复：direct JAL 派发 `next_pc` 改用 fallthrough；提交 mux 对 core commit JAL 重新计算 `pc + imm_j` 作为架构 next_pc。
7. 修复后 `smoke-jal-link` GOOD TRAP，`cycles=74/commits=16`；短回归 `smoke-fp-fcsr`、`smoke-fp-loadstore`、`smoke-fp-convert` 均 GOOD TRAP。
8. 修复后 NPC L5 shell watch 已越过 OpenSBI 和 Linux early boot，日志到 `Unpacking initramfs...`、`ttyS0 enabled`、`SuperH (H)SCI(F) driver initialized`，最终 12 亿 cycles 到期，尚未到 `/init` 或 `[ysyx-sh]`。

## 验证命令

```bash
make -C npc/rv64 qemu-ubuntu-shell-initramfs QEMU_TIMEOUT=30s
make -C npc/rv64 sim
make -C npc/rv64/tools smoke-jal-link
make -C npc/rv64/tools smoke-jal-link smoke-fp-fcsr smoke-fp-loadstore smoke-fp-convert
make -C npc/rv64/tools smoke-ubuntu-shell-watch UBUNTU_INITRAMFS_MAX_CYCLES=1200000000
```

备注：`make -C npc/rv64 sim` 已完成 Verilator 编译/链接并刷新 `build/NpcSimTop`，但该 Makefile 目标末尾会尝试无 `IMG` 运行 wrapper 并触发既有 `.git/index.ai` 路径 warning，最终返回 1；后续 smoke 使用新二进制已证明构建产物有效。

## 关键证据

- `smoke-jal-link`: GOOD TRAP, `cycles=74`, `commits=16`。
- `smoke-fp-fcsr`: GOOD TRAP, `cycles=492`, `commits=88`。
- `smoke-fp-loadstore`: GOOD TRAP, `cycles=216`, `commits=34`。
- `smoke-fp-convert`: GOOD TRAP, `cycles=320`, `commits=65`。
- 修复后 shell watch: OpenSBI v1.8 和 Linux 6.6 banner 可见；`cycles=1200000000`, `commits=180848360`, `CPI=6.635`, host simulation frequency about `51937 inst/s`。
- shell watch 未命中 `[ysyx-sh] /bin/sh -c marker`，因此 L5 不可声明通过。

## 下一步

- 把 L5 full-shell gate 拆成更短的 checkpoint/marker，避免每次重跑 12 亿 cycles 才知道是否推进。
- 优先确认 full initramfs 解包阶段是否只是预算不足，还是存在高 miss/控制等待造成的性能瓶颈。
- 继续补 arithmetic fflags/dynamic rounding 与 dynamic linker/libc gate；rootfs/virtio/display 仍保持独立 gate。
