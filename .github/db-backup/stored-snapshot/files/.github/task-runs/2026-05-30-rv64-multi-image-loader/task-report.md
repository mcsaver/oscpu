# RV64 Multi Image Loader

## 目标

为真实 OpenSBI/Linux 启动准备 host 侧装载基础：除了原来把单个 AM 镜像放到 `0x80000000`，仿真入口还需要能把 OpenSBI、kernel、DTB 或 reset trampoline 分别装到指定物理地址。

## 改动

- `npc/rv64/csrc/include/utils.h`
  - 新增 `NpcLoadImageSpec` 与 `NPC_MAX_LOAD_IMAGES`。
  - `NpcSimConfig` 增加额外装载项数组和计数。
- `npc/rv64/csrc/include/memory/paddr.h`
  - 新增 `npc_load_img_at()` 声明。
- `npc/rv64/csrc/memory/paddr.c`
  - 新增 PMEM 范围检查。
  - 新增 `npc_load_img_at(path, addr)`，支持将二进制装到任意 PMEM 物理地址。
  - 原 `npc_load_img()` 保持兼容，等价于加载到 `NPC_RESET_PC`。
- `npc/rv64/csrc/monitor/monitor.c`
  - 新增可重复命令行参数 `--load=ADDR:FILE`。
  - 在内存初始化后依次加载 `--image` 与额外 `--load` 项。

## 验证

- `make -C npc/sim BACKEND=rv64 -j4`
  - PASS
  - 仍有既有 `disasm.c` Capstone 路径截断 warning，非本轮新增。
- `./npc/rv64/build/NpcSimTop --image=am-kernels/tests/cpu-tests/build/add-riscv64-npc.bin --load=0x80001000:/tmp/rv64-extra.bin --no-diff --no-progress --max=2000000`
  - PASS
  - 日志显示 `/tmp/rv64-extra.bin` 装载到 `0x80001000`
  - `add` GOOD TRAP，`cycles=755 / commits=839 / CPI=0.900`
- `./npc/rv64/build/NpcSimTop --load=0x80000000:am-kernels/tests/cpu-tests/build/add-riscv64-npc.bin --no-diff --no-progress --max=2000000`
  - PASS
  - 无 `--image` 时也能从 `--load` 放到 reset PC 启动
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=sbi-base-console run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS
  - guest 输出 `OK`

## 限制

本轮只解决“多个二进制如何进入 PMEM”。真实 OpenSBI/Linux 还需要 a0/a1/DTB handoff、reset trampoline 或可配置初始寄存器、真实 OpenSBI/kernel/DTB 镜像，以及 IPI/reset/HSM、virtio/blk、多源 PLIC 等平台能力。
