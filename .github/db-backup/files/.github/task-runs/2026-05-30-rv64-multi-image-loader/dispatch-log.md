# Dispatch Log

- 搜索仓库内 OpenSBI/Linux/DTB 镜像，确认当前没有可直接运行的 RISC-V Linux 启动资产。
- 复核 `npc/rv64` 现有镜像加载路径：`--image` 或位置参数只会把单个 bin 放到 `NPC_RESET_PC=0x80000000`。
- 设计最小 host 侧扩展：保留 `--image` 兼容行为，新增可重复 `--load=ADDR:FILE`，为后续 OpenSBI/kernel/DTB/trampoline 分别装载做准备。
- 修改 `utils.h/paddr.h/paddr.c/monitor.c`，新增配置项、任意 PMEM 地址装载函数、命令行解析和初始化阶段加载顺序。
- 串行构建 `npc/sim BACKEND=rv64 -j4`。
- 用 `add` 主镜像 + `--load=0x80001000:/tmp/rv64-extra.bin` 验证额外装载不影响正常执行。
- 用单独 `--load=0x80000000:add.bin` 验证无 `--image` 的 reset PC 装载路径。
- 回归 `sbi-base-console`，确认常规 AM 路径和 mini SBI/console 测试仍 PASS。
- 更新 memory 与 task-run，记录 loader 能力和剩余真实 Linux boot 缺口。
