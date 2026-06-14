# RV64 Linux Top-Level Makefile Migration

## Objective

按用户要求，把 RV64 Linux/Ubuntu 启动相关资源从 `npc/rv64` 迁移到仓库根目录 `Linux/`，让 `npc/rv64` 保持为纯 core RTL、testbench、Kconfig/Verilator 仿真环境；同时迁移 Linux bring-up 相关 tools/tests，并规范 Makefile 命令语义。

## Result

- 新增 `Linux/Makefile` 作为 Linux/Ubuntu bring-up 总入口，默认 `ARCH=riscv64-npc`、`BOOT=ubuntu-rootfs`。
- 固化命令契约：`make -C Linux ARCH=riscv64-npc run` 是完整 Ubuntu rootfs 路线；低层 gate 必须显式写 `BOOT=ubuntu-shell`、`BOOT=ubuntu-probe`、`BOOT=busybox-initramfs` 或使用明确别名。
- 迁移 `env/`、`platform/`、`scripts/`、`patches/`、`regression/`、Linux 专用 `configs/` 与 Linux bring-up 相关 `tools/` 到 `Linux/`。
- `npc/rv64/Makefile` 移除 Linux/OpenSBI/Ubuntu 管理目标，仅保留 core/sim/config/testbench 相关职责。
- `Linux/tools/Makefile` 接管 JAL/SRET/Sv39/RAS/FP/DTB/OpenSBI focused gates，并把 generated outputs 放入忽略的 `Linux/tools/build/`。
- `.gitignore` 和 `.github` agent/instructions/memory 已同步更新，后续调试入口不再指向旧的 `npc/rv64/env` 或 `npc/rv64/tools`。

## Validation

- `make -C Linux help` PASS。
- `make -C Linux ARCH=riscv64-npc BOOT=ubuntu-shell paths` PASS，路径指向 `Linux/env` 和 `Linux/build`。
- `make -C Linux/tools boot-tools` PASS。
- `make -C Linux/tools check-dtb` PASS，DTB smoke 解析到 `YSYX NPC RV64`、`serial0:115200n8`、`riscv,sv39`、`ns16550a`。
- `make -C Linux ARCH=riscv64-npc linux-defconfig` PASS，二次执行命中 stamp。
- `make -C Linux ARCH=riscv64-npc BOOT=ubuntu-shell check` PASS。
- `bash -n Linux/scripts/*.sh Linux/regression/run_all.sh` PASS。
- `python3 -m py_compile Linux/platform/gen_dts.py` PASS。
- `make -C Linux ARCH=riscv64-npc smoke-jal-link` GOOD TRAP。
- `make -C Linux ARCH=riscv64-npc smoke-dtb` GOOD TRAP。
- `git diff --check` PASS。

## Boundary

本轮不声明新的完整 Ubuntu rootfs/virtio-blk PASS。完整 rootfs 路线已经被 `make -C Linux ARCH=riscv64-npc run` 明确占位，但当前 `NpcSimTop` 仍需要继续补 rootfs/virtio-blk 等设备后端；后续必须沿 root cause 修 bug，不用降级 gate 或关闭真实问题来制造“跑通”。
