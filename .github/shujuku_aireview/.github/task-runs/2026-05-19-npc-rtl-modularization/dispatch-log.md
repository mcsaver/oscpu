# 调度记录

- 读取 `.github/AGENTS.md`、Copilot 指令、project status、known issues、NPC/difftest 模块记忆，以及 RTL 生成、NPC study、memory protocol 指令。
- 复读 `IfStage.v`、`NpcCore.v`、`NpcSimTop.sv`、`Makefile`，确认 BPU 内联在 IF，cache 为 host bus 模型，DPI 顶层只有 `NpcSimTop.sv`。
- 按 RTL 四阶段推导确定拆分边界：IF 只管取指/RVC，BPU 独立，CacheControl 只管 `fence.i` 事件，SimTop 只管 DPI。
- 新增 `BranchPredictor.v` 和 `CacheControl.v`，修改 `IfStage.v`、`NpcCore.v`、`NpcSimTop.sv`、`Makefile`、`README.md`。
- 首次 `make -C npc/single lint` 因 `BranchPredictor` helper 函数未使用字段告警失败；仅在 helper 函数周围加 Verilator `UNUSEDSIGNAL` 抑制后 lint 通过。
- 运行 Verilator build、轻量 cpu-tests difftest、Dhrystone、CoreMark 长跑观察、MicroBench `test`。
- 尝试 `make -C npc/single syn`，因本地缺 oss-cad-suite yosys 被环境检查挡住。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md` 和本任务记录。
