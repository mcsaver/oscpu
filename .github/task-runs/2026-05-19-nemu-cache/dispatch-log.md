# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-nemu-cache`
- `task_slug`: `nemu-cache`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

---

### [2026-05-19 17:34] `recall` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `用户要求实现 NEMU ICache/DCache 与性能计数器`
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`
- `action`: 读取项目规则和 NEMU 历史记忆，梳理 `inst_fetch/vaddr/paddr/cpu-exec` 调用链。
- `outputs`: 确认 cache 插入层为 `vaddr.c`，`paddr.c` 保持 PMEM/MMIO 权威后端。
- `evidence`: 静态读取 `nemu/src/memory/{vaddr.c,paddr.c}`、`nemu/src/cpu/cpu-exec.c`、`nemu/src/isa/riscv32/inst.c`
- `handoff_to`: `design`
- `next_step`: 写设计记录并确认规格。
- `notes`: 当前工作区已有大量未提交变更，本任务只追加相关改动。

### [2026-05-19 17:34] `design` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `用户同意默认 cache 规格`
- `depends_on`: `recall`
- `inputs`: 默认规格：4KB I/D cache、64B line、direct-mapped、DCache write-back/write-allocate、MMIO bypass、counter 输出。
- `action`: 写入设计文档并做占位符扫描。
- `outputs`: `docs/superpowers/specs/2026-05-19-nemu-cache-design.md`
- `evidence`: `rg -n "TBD|TODO|implement later|fill in|占位|待定"` 无命中
- `handoff_to`: `plan`
- `next_step`: 写实施计划。
- `notes`: 设计记录中显式保留 PMEM/MMIO 分层边界。

### [2026-05-19 17:34] `plan` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `设计已写入`
- `depends_on`: `design`
- `inputs`: 设计文档
- `action`: 写入 TDD 实施计划。
- `outputs`: `docs/superpowers/plans/2026-05-19-nemu-cache.md`
- `evidence`: 计划占位符扫描无命中
- `handoff_to`: `cache-unit-red-green`
- `next_step`: 先写失败测试。
- `notes`: 计划选用 inline execution，不启用子 agent。

### [2026-05-19 17:34] `cache-unit-red-green` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `开始实现 cache 核心`
- `depends_on`: `plan`
- `inputs`: `nemu/tests/cache_unit.c` 目标 API
- `action`: 先创建单元测试并编译确认 RED，再添加 `memory/cache.h` 和 `src/memory/cache.c`。
- `outputs`: cache 单元测试、direct-mapped ICache/DCache 实现
- `evidence`: RED: `fatal error: memory/cache.h: No such file or directory` 和 `cache.c: No such file or directory`；GREEN: `/tmp/cache_unit` 输出 `cache_unit PASS`
- `handoff_to`: `build`
- `next_step`: 接入 NEMU 主路径并构建。
- `notes`: 单元测试覆盖 ICache 二次命中、DCache 写命中、脏行替换写回、跨 line 访问。

### [2026-05-19 17:34] `build` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `cache 核心和主路径接线完成`
- `depends_on`: `cache-unit-red-green`
- `inputs`: `vaddr.c`、`paddr.c`、`cpu-exec.c`、`inst.c`、`Kconfig`
- `action`: 同步 Kconfig 后构建 NEMU。
- `outputs`: `nemu/build/riscv32-nemu-interpreter`
- `evidence`: `make -C nemu -j4` 退出 0，编译 `inst.c`、`cpu-exec.c`、`paddr.c`、`cache.c`、`vaddr.c` 并完成链接。
- `handoff_to`: `smoke`
- `next_step`: 跑 `ALL=add` smoke。
- `notes`: 新 Kconfig 生成 `CONFIG_CACHE=y`、`CONFIG_ICACHE_SIZE=4096`、`CONFIG_DCACHE_SIZE=4096`、`CONFIG_CACHE_LINE_SIZE=64`。

### [2026-05-19 17:34] `smoke` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `NEMU 构建通过`
- `depends_on`: `build`
- `inputs`: `am-kernels/tests/cpu-tests` 的 `add`
- `action`: 运行 focused smoke。
- `outputs`: `add` PASS 和 cache counter 输出
- `evidence`: `make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` PASS；输出 `icache access = 1004 ...`、`dcache access = 157 ...`、`dcache writeback = 1`
- `handoff_to`: `regression`
- `next_step`: 跑全量 cpu-tests。
- `notes`: GOOD TRAP PC 为 `0x800000b2`，total guest instructions 为 `840`。

### [2026-05-19 17:34] `regression` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `smoke 通过`
- `depends_on`: `smoke`
- `inputs`: 全量 cpu-tests
- `action`: 运行 180s timeout 回归。
- `outputs`: 35 项全部 PASS
- `evidence`: `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 输出 `test list [35 item(s)]` 且 35/35 PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task report。
- `notes`: 多个测试运行中均输出 cache counter。

### [2026-05-19 17:34] `record` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `验证完成`
- `depends_on`: `regression`
- `inputs`: 改动清单、验证命令和结果
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md` 和本 task-run。
- `outputs`: 长期记忆与单次任务记录
- `evidence`: 当前文件已追加本任务摘要和验证证据。
- `handoff_to`: 无
- `next_step`: 最终汇报。
- `notes`: 无阻塞。

### [2026-05-19 17:34] `final-verify` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `记录后补强 cacheable 跨 line 边界判断`
- `depends_on`: `record`
- `inputs`: 更新后的 `cacheable_range()` 和单元测试专用 `generated/autoconf.h`
- `action`: 重新运行单元测试和最终 cpu-tests 回归。
- `outputs`: 最终验证结果
- `evidence`: `cc -std=gnu11 -Wall -Werror -I nemu/tests -I nemu/include -o /tmp/cache_unit nemu/tests/cache_unit.c nemu/src/memory/cache.c && /tmp/cache_unit` 输出 `cache_unit PASS`；`timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 输出 35/35 PASS。
- `handoff_to`: 无
- `next_step`: 最终汇报。
- `notes`: 边界补强后没有回归。
