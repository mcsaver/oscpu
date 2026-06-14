# RV64 Linux DTB Tool And Smoke

## 目标

把 Linux/OpenSBI 入口所需的设备树从 fake FDT header 推进到真实 `dtc` 生成的 DTB，并用当前 reset trampoline + multi-image loader 在 guest 中验证 `a1` 指向的 DTB 可以被读取和识别。

## 改动

- `npc/rv64/tools/npc-rv64.dts`
  - 描述当前 RV64 平台的 128MB memory window。
  - 描述 `cpu@0`、`riscv,cpu-intc`、`riscv,clint0`、`riscv,plic0` 和 `ns16550a` UART。
  - 设置 `chosen.stdout-path = "serial0:115200n8"`。
- `npc/rv64/tools/Makefile`
  - 新增 `dtb`、`check-dtb`、`smoke-dtb` 目标。
  - `check-dtb` 用 `fdtget` 检查 model、stdout-path、mmu-type、serial compatible。
  - `smoke-dtb` 组合加载 trampoline、DTB smoke payload 和 DTB。
- `npc/rv64/tools/linux-dtb-smoke.c`
  - freestanding raw payload，入口由 trampoline 跳入。
  - 用固定 PMEM 栈，读取 `a1` 指向的 DTB。
  - 验证 FDT header、结构/字符串表边界和关键平台字符串。

## 验证

- `make -C npc/rv64/tools check-dtb`
  - PASS
  - `model = YSYX NPC RV64`
  - `stdout-path = serial0:115200n8`
  - `mmu-type = riscv,sv39`
  - `serial compatible = ns16550a`
- `make -C npc/rv64/tools smoke-dtb`
  - PASS
  - 加载 `trampoline@0x80000000`
  - 加载 `linux-dtb-smoke@0x80200000`
  - 加载 `npc-rv64.dtb@0x87f00000`
  - `HIT GOOD TRAP`
  - `cycles=38987 / commits=75158 / CPI=0.519`
- `make -C npc/sim BACKEND=rv64 -j4`
  - PASS

## 限制

这证明当前平台已经能生成真实 DTB，并能经 Linux boot ABI 的 `a1` 传给 payload 读取；它仍不是完整 OpenSBI/Linux 启动。真实启动还需要真实 OpenSBI/kernel 镜像、完整设备树、多源 PLIC、virtio/blk 或内置 initramfs 路径，以及实际内核启动日志。
