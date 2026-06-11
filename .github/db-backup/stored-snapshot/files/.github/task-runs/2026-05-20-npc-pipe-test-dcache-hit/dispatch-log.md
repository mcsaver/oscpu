# 2026-05-20 NPC pipe_test 与 DCache 命中读气泡优化派发日志

- 13:05 读取 NPC 记忆、RTL 工作流和流水线/缓存相关源码。
- 13:05 新增 `pipe_test` 流水线级微基准，覆盖 MEM 级 DCache load hit、load miss、store write-through 和 ID 级 load-use。
- 13:05 跑基线：`mem_stage_dcache_load_hit_wait_cycles=2`，确认为可移除气泡。
- 13:06 记录 RTL 四段式推导，准备优化 DCache load-hit 快路径与 MemoryStageControl 同周期响应。
- 13:07 完成 RTL 优化，`pipe_test` 默认断言 PASS，load-hit 等待降为 0。
- 13:08 补充 DCache/MEM 控制单元同周期响应回归断言，模块级 testbench 21/21 PASS。
- 13:09 完成 `make -C npc/single lint` 和 `cpu-tests load-store` 功能回归。
