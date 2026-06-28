# 派发日志

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| recall | claude | npc/rv64 | done | AGENTS、project-status、npc.md、glue/filelist/testbench | 明确目录即架构边界、一模块一文件、逐刀全回归方法学 | 本对话读取记录 |
| design-boundary | claude | core/OooCoreTopGlue | done | 3478 行 glue 静态连通性分析 | 连通性分析器 + 各目录簇边界端口规模；探针/keep 集测绘 | `glue_conn.py`、boundary 输出 |
| build-generator | claude | scratchpad | done | 边界分析 | wrapper 自动生成器（端口/方向/位宽/param/内部下沉/补丁） | `gen_wrapper.py` |
| slice-memory | claude | memory/OooMemoryAccess | pass | memory 簇 2 实例 | wrapper 抽取 + filelist + spec | lint/build/103 TB/177 riscv-tests |
| slice-writeback | claude | writeback/OooWriteback | pass | writeback 簇 5 实例 | wrapper 抽取 + keep 集修复 | lint/build/103 TB/177 riscv-tests |
| slice-execute | claude | execute/OooExecuteBackend | pass | execute 簇 4 实例 | wrapper 抽取 + assign-RHS 外部消费修复 | lint/build/103 TB/177 riscv-tests |
| slice-control | claude | control/OooControlPlane | pass | control 簇 13 实例 | wrapper 抽取 + assign-LHS 输入/wire 位宽/NpcSimTop 探针/endmodule 插入修复 | lint/build/103 TB/177 riscv-tests |
| slice-frontend | claude | frontend/OooFrontend | pass | frontend 49 + 6 DecodeStage | wrapper 抽取 + tb_ooo_fetch_trap_gate 探针路径更新 | lint/build/103 TB/177 riscv-tests |
| docs-record | claude | docs/memory/task-run | done | 代码改动与验证结果 | 5 wrapper spec、glue spec、vsrc README、memory、task-run | 本目录报告 |
| verify-final | claude | npc/rv64 | pass | 全 5 wrapper 在位 | glue 6 实例/1.4k 行/0 always；177 riscv-tests 0 FAIL | `perf/results/core-regress/20260627-213809-168946/` |
