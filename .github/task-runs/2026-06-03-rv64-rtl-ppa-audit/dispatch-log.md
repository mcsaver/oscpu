# 派发日志

## node-0-recall

- **输入**: 用户要求从仿真顶层出发逐模块分析 RV64 core，目标是商业级 RTL 规范、PPA 和可读性。
- **动作**: 读取 AGENTS、copilot 指令、project status、known issues、npc memory、RTL 生成流程、NPC 优化流程、Verilator/流片真实性约束、RV64 README 与 study README。
- **输出**: 明确本轮需先审计边界和模块树，不直接跳到 RTL 修改。
- **证据**: 已读文件清单记录在 `task-report.md`。

## node-1-topology

- **输入**: `npc/rv64/vsrc/filelist.mk`、`NpcSimTop.sv`、`NpcTop.v`、`NpcCoreTop.v`。
- **动作**: 用 `rg` 抽取 module/instance；阅读顶层三层例化和仿真事件采样。
- **输出**: 得到 `NpcSimTop -> NpcTop -> NpcCoreTop -> OoO` 例化树。
- **证据**: `NpcSimTop` 例化 `NpcTop/AxiLiteVirtioBlk/AxiDpiSlave`；`NpcTop` 例化 core/bus/UART/CLINT/PLIC/default slave；`NpcCoreTop` 例化 fetch bridge/mem bridge/OoO core。

## node-2-risk-scan

- **输入**: 活动 RTL 源码目录。
- **动作**: 扫描 DPI、`initial/final/$display/$finish/force`、层次化引用、全表循环、数组存储体、模块规模。
- **输出**: DPI 只存在于 sim 目录；核心风险从不可综合语法转向大组合 helper、全表扫描、大模块可维护性和 xbar 仲裁路径。
- **证据**: `make -C npc/rv64 lint` PASS；`wc -l` 显示 `OooAluFetchCore.v` 5539 行、`OooIntBackend.v` 1878 行。

## node-3-record

- **输入**: 审计结论和验证输出。
- **动作**: 新增本任务报告与 dispatch log；更新项目状态和 NPC 模块记忆。
- **输出**: `.github/task-runs/2026-06-03-rv64-rtl-ppa-audit/` 与 memory 条目。
- **证据**: 本文件与 `task-report.md`。
