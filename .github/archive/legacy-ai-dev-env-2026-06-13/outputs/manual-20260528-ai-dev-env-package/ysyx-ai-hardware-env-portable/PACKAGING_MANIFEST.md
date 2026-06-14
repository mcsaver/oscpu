# 打包清单

## 已包含

- `.github/AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/agentic-hardware-blueprint.md`
- `.github/agents/*.agent.md`
- `.github/instructions/*.instructions.md`
- `.github/memory/**`
- `.github/task-runs/templates/**`
- `AGENTS.md`
- `CLAUDE.md`
- `GEMINI.md`
- `CONVENTIONS.md`
- `.windsurfrules`
- `.cursor/rules/agents.mdc`
- `docs/README.md`
- `docs/init.sh`
- `docs/npc/**/README.md`
- `docs/npc/*/testbench/README.md`
- `docs/npc/*/design/study/*.md`
- `docs/nemu/README.md`
- `docs/ysyxSoC/spec/cpu-interface.md`
- `examples/env.example.sh`

## 已排除

- `.github/task-runs/YYYY-*` 历史任务记录
- `outputs/` 历史生成物
- `.git/`
- 构建目录、仿真波形、日志和本地工具链
- `.env`、私钥、token 文件候选

## 脱敏替换

- `<OLD_YSYX_HOME>` -> `${YSYX_HOME}`
- `<OLD_LOCAL_BIN>` -> `${LOCAL_BIN}`
- `<OLD_RISCV_TOOLCHAIN_ROOT>` -> `${RISCV_TOOLCHAIN_ROOT}`
- `<OLD_TMPDIR>/` -> `${TMPDIR}/`
- `ysyx_<number>` -> `<YSYX_ID_TOP>`
- `<YSYX_ID_NUM>` -> `<YSYX_ID_NUM>`
