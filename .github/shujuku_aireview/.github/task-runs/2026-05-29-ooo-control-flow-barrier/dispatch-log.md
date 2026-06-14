# Dispatch Log

- 审计 `DecodeUnit`/`ImmGen`/`CompareUnit` 和 OoO ALU-only 前端，确认条件分支可用已提交架构态精确解析。
- 决策：先实现 lane0 conditional branch barrier；`jal/jalr` 等待合成链接寄存器写回设计。
- 实现 `OooAluFetchCore` lane0 branch decode、pending branch metadata、synthetic commit mux、stale fetch response drop 和 redirect 清空。
- 扩展 `tb_ooo_alu_fetch_core`：unsupported 哨兵改为 load，新增 taken/not-taken 分支程序。
- 补 `tb_ooo_alu_fetch_core` 的 `CompareUnit` testbench 依赖；单测、OoO testbench、实验 lint/build、默认 lint/build/full testbench、AM `cpu-tests add` 均通过。
