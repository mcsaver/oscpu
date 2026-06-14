# Dispatch Log

## 2026-05-29

- 任务：把目标已知的 JAL 从 OoO 实验核 control drain barrier 中拆出来，改成 dispatch 后立即前端 redirect。
- 依据：RVC 后实验核 `cpu-tests add` 功能通过但 `CPI=4.347`；默认主线同一程序控制流约 35%，其中 JAL 目标不依赖寄存器，没必要等待整个后端排空。
- 范围边界：本轮只处理 JAL；JALR 仍需 rs1 目标，条件分支仍需方向解析，memory 仍涉及精确 side effect，均保留 drain barrier。
