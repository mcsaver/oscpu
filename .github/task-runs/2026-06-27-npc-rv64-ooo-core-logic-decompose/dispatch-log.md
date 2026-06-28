# 派发日志

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| recall | codex | npc/rv64 | done | AGENTS、copilot、memory、RTL workflow、rv64 README/study | 明确目录就是架构边界；RTL 修改需四段式推导 | 本对话读取记录 |
| inspect-core | codex | core/OooCoreTopGlue | done | 静态扫描剩余 `assign`/`wire =`/旧规则 | 定位 branch prefetch clear、pending/drain、operand read、FP commit、observable output | `Select-String` 扫描 |
| rtl-decompose | codex | frontend/control/writeback/regread_bypass | done | 既有 wire/状态/接口 | 新增 5 个组合 owner 并更新 filelist/core glue | 源码 diff |
| docs-record | codex | docs/memory/task-run | done | 代码改动与验证结果 | 更新 README/spec/memory/task-run | 本目录报告 |
| verify-focused | codex | npc/rv64/testbench | pass | focused tests | 5/5 PASS | `npc/rv64/perf/results/20260627-ooo-core-logic-decompose/focused-rerun/` |
| verify-all | codex | npc/rv64/testbench | pass | default module tests | 103/103 PASS | `npc/rv64/perf/results/20260627-ooo-core-logic-decompose/all-rerun/` |
| verify-lint-build | codex | npc/rv64 | pass | Verilator lint/build | lint PASS；build PASS | terminal output |
| verify-static | codex | npc/rv64/vsrc | pass | name/rule/whitespace scans | old name scan empty；core assign/rule scan empty；diff-check PASS | terminal output |
