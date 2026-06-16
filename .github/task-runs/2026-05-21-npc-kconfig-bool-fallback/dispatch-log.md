# Dispatch Log

## 基本信息

- `task_id`: `2026-05-21-npc-kconfig-bool-fallback`
- `task_slug`: `npc-kconfig-bool-fallback`
- `graph_template`: `regression-debug-loop`
- `log_policy`: `append-only`

---

### [2026-05-21 20:21] `localize` - `completed`

- `owner_agent`: Codex
- `trigger`: benchmark 弹 VGA 窗口
- `depends_on`: recall
- `inputs`: `perf_defconfig`、`autoconf.h`、`utils.h`、`vga.c`、AM `ioe.c/gpu.c`
- `action`: 追踪 CoreMark 的 IOE 初始化链路，并核对 Kconfig bool 在生成头中的表达。
- `outputs`: 根因定位为 `CONFIG_NPC_HAS_VGA` fallback 把 not-set 解释成 enabled；同类风险覆盖 `SDB/EXPR/WATCHPOINT`。
- `evidence`: `perf_defconfig` 写 `CONFIG_NPC_HAS_VGA=n`，但修复前预处理会得到 `CONFIG_NPC_HAS_VGA=1`。
- `next_step`: 修改 fallback。

### [2026-05-21 20:21] `fix-verify` - `completed`

- `owner_agent`: Codex
- `trigger`: localize 完成
- `depends_on`: localize
- `inputs`: `npc/single/csrc/include/utils.h`
- `action`: 将 `CONFIG_NPC_HAS_VGA/SDB/EXPR/WATCHPOINT` fallback 统一改为 0，并强制重建 NPC。
- `outputs`: 修复进入 `build/NpcSimTop`。
- `evidence`: 预处理宏值均为 0；`make -C npc/single -B -j4` PASS；CoreMark 短跑显示 `NPC VGA disabled`；`cpu-tests add` PASS。
- `next_step`: 已更新 memory。
