# NPC RV64 Testsuites

这个目录专门放 `npc/rv64` 核级外部测试套件、测试工具链和可重复脚本，避免把 CPU 测试资产混到 `.github` 或 RTL 目录里。

## Layout

- `scripts/`: NPC RV64 核级测试脚本入口(当前为 `npc-rv64-core-regress.sh`)。
- `core-tests/`: 本地外部测试资产,当前只保留 `src/riscv-tests`(官方 riscv-tests 检出,供 core-regress)。

> **ACT4 已迁出(2026-07-02)**:riscv-arch-test 测试源、生成入口(preflight)、构建环境(xpack/sail/venv/gems)与权威 ELF 基线已整体迁到 `am-kernels/arch-test/`(自治工程,详见其 README)。入口对应关系:
> - `npc-rv64-act4-preflight.sh` → `am-kernels/arch-test/scripts/act4-preflight.sh`
> - `npc-rv64-act4-run.sh` → `am-kernels/arch-test/scripts/act4-npc-run.sh`(跑 NPC 目标)
> - 统一 runner(NEMU/NPC/both):`make -C am-kernels/arch-test run-nemu|run-npc|run-both`

## 常用命令

```bash
npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --riscv-tests --quick
# ACT4(已迁): 见 am-kernels/arch-test/README.md
make -C am-kernels/arch-test list
make -C am-kernels/arch-test run-npc ACT4_SUITES=rv64i/I
```
