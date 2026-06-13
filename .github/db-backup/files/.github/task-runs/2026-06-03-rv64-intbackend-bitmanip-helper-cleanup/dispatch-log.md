# Dispatch Log

- 2026-06-03: 继承当前 RV64 商业 RTL 收敛目标，确认本轮聚焦 `OooIntBackend` 的 bitmanip helper 局部 `UNUSEDSIGNAL`。
- 2026-06-03: 复核 `rv32b_result()` 完整函数和 issue0/issue1 调用点，确认 root cause 是完整 `inst[31:0]` 输入过宽。
- 2026-06-03: 按需求、协议规则、状态机、不变量、数据通路约束完成 RTL 推导。
- 2026-06-03: 修改 `OooIntBackend.v`，把 helper 收窄为 `opcode/funct10/imm/src1/src2` 字段接口，并删除局部 waiver。
- 2026-06-03: 完成 focused testbench、项目级 lint/build、Linux/tools smoke 和 focused diff check。
- 2026-06-03: 额外尝试不关闭 `UNUSEDSIGNAL` 的局部 lint，记录仍存在的既有 OooIntBackend/OooMulDivUnit unused 边界。
- 2026-06-03: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
