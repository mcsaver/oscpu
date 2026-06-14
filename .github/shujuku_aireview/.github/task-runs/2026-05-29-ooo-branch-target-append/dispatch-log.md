# Dispatch Log

| 节点 | 动作 | 证据 | 状态 |
| --- | --- | --- | --- |
| recall | 复核 AGENTS、NPC 优化流程、已有 lane1-ret 全量结果和 OoO 画像 | `.github/AGENTS.md`、`.github/instructions/npc-optimization-workflow.instructions.md`、`/tmp/ysyx-ooo-full-cputests-lane1-ret.tsv` | 完成 |
| design | 推导 resolved branch append 与 target cache 扩容边界 | 本报告 RTL 推导摘要 | 完成 |
| implement | 修改 `OooAluFetchCore.v`，加入 branch target/fallthrough append、16-entry target cache 与 store/MISC_MEM 失效 | `npc/single/vsrc/ooo/OooAluFetchCore.v` | 完成 |
| adapt | 修复 append attempt 直接影响 optional decode 导致的 ready 组合环 | `matrix-mul` 曾触发 Verilator active region did not converge，candidate/attempt 拆分后通过 | 完成 |
| verify | 构建、focused test、CPU-test 全量 | build PASS、`tb_ooo_alu_fetch_core` PASS、`/tmp/ysyx-ooo-full-cputests-btc16.tsv` 40/40 GOOD | 完成 |
| record | 更新 memory 与 task-run | project-status、modules/npc、known-issues、本目录报告 | 完成 |
