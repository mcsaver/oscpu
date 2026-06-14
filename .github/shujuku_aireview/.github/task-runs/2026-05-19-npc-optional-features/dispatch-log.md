# 执行日志

## 2026-05-19

- 读取 `.github/AGENTS.md`、项目记忆、NPC/NEMU/AM/AM-Kernels/difftest 模块记录和 NPC study/instructions，确认任务需要先分析再改、跨模块改动后更新记忆。
- 对照 NEMU 当前可选能力，确定 NPC 实现顺序为 M -> B -> C -> cache/fence.i -> BPU。
- 每个阶段完成后先跑轻量级 cpu-test diff，再继续下一阶段。
- 最终跑全量 `cpu-tests` 38/38 difftest PASS。
- 按用户要求继续跑 benchmark：CoreMark、Dhrystone、MicroBench `test` 均 PASS。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/{npc,nemu,am-kernels,difftest}.md`、`.github/memory/known-issues.md` 和本目录任务报告。
