# Dispatch Log

- 读取项目规则与 NPC 相关记忆，确认本次属于跨 IF/cache/MEM 的 RTL 接口任务，需要先梳理调用链再改动。
- 检查 `ICache.v`、`DCache.v`、`IfStage.v`、`MemoryStageControl.v`、`MemoryStage.v`、`NpcCore.v` 和相关 testbench，确认现状是请求侧显式 ready，CPU response 侧没有显式 ready。
- 在 `ICache`/`DCache` CPU 侧加入 `cpu_rsp_ready_i`，让同拍命中和错误响应在上游未 ready 时进入 `S_RESP`。
- 在 `IfStage` 导出 `ifu_rsp_ready_o`，用 active 状态和 fetch response slot 控制 ICache response 消费。
- 在 `MemoryStageControl` 导出 `lsu_rsp_ready_o`，改用 `rsp_fire` 作为 response 完成条件。
- 首次 lint 发现把 `update_en_i` 组合接入 ready/valid 会触发 Verilator `UNOPTFLAT` 组合环；随后改为 `lsu_rsp_ready_o = ex_valid_i & ex_is_mem_w`，让 ready 不反向依赖全局流水推进。
- 更新 ICache/DCache/IF/MEM 相关 testbench，并新增 response backpressure 用例。
- 执行验证：
  - `make -C npc/single/testbench RESULT_DIR=/tmp/npc-cache-rsp-ready-tests2 run`，22/22 PASS。
  - `make -C npc/single lint`，PASS。
  - `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-cache-rsp-ready-pipe pipe_test`，PASS。
  - `make -C npc/single -j14`，PASS。
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`，38/38 PASS。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md` 和本任务记录。
