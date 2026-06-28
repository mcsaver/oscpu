# 派发日志

## 节点表

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| recall | codex | repo-memory | PASS | AGENTS、RTL workflow、npc memory、rv64 README、vsrc README、边界 specs | 确认当前壳已无 `always`，主要问题是命名与目录边界 | `.github/memory/modules/npc.md` |
| rtl-protocol | codex | npc/rv64/core | PASS | 用户边界要求、现有 filelist/TB/top 实例 | `OooCoreTopGlue` 等价迁移协议 | `task-report.md` |
| rtl-edit | codex | npc/rv64/vsrc | PASS | `frontend/OooAluFetchCore.v` | `core/OooCoreTopGlue.v` 与 filelist/top 同步 | `npc/rv64/vsrc/core/OooCoreTopGlue.v` |
| tb-edit | codex | npc/rv64/testbench | PASS | 旧 focused TB 名称和实例 | `tb_ooo_core_top_glue` | `npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv` |
| docs-record | codex | repo-docs | PASS | vsrc/spec/memory 当前边界 | 当前架构入口改为 core glue | `npc/rv64/design/specs/ooo-core-top-glue.md` |
| verify | codex | npc/rv64 | PASS | focused TB、默认 module TB、lint、build、残留扫描 | focused 6/6 PASS，默认 103/103 PASS，lint/build PASS，旧 RTL 名称无源码残留 | `npc/rv64/perf/results/20260627-ooo-core-top-glue-rename/` |

## 时间线

- 读取仓库规则、RV64 README、vsrc README、当前拆分 specs 与模块记忆。
- 扫描 `OooAluFetchCore.v`：3436 行、无 `always`、无状态块，主要由 wire/assign/实例化构成。
- 选择等价迁移为本切片边界，避免在同一轮重排 pending/redirect/FP commit/fetch packet 行为。
- 移动并改名 core glue，更新顶层、testbench、filelist 和活跃文档。
- focused TB 6/6 PASS，默认 module TB 103/103 PASS。
- `make -C npc/rv64 lint` PASS，`make -C npc/rv64 -j2` PASS。
- 旧 RTL 名称源码残留扫描无输出，旧文件路径不存在，`OooCoreTopGlue.v` 内 `always` 数量为 0。
