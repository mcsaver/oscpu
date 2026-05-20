# NPC RTL I/D Cache 接入任务报告

## 范围

- 将 cache 从 Verilator host bus 透明模型下沉到 `NpcCore` 可综合层。
- 保持 `NpcSimTop` 作为 DPI-C 仿真顶层，通过层次化引用观察仿真事件，避免为仿真需求污染 core public port。
- 在功能正确性闭环内先实现 blocking direct-mapped baseline，再保留后续 write-back/perf counter/PPA 优化空间。

## 主要改动

- 新增 `npc/single/vsrc/IDCache.v`：
  - `ICache`: 4KB、64B line、direct-mapped、blocking refill，支持 RVC 半字对齐取指窗口，PMEM cacheable、MMIO/越界 uncached。
  - `DCache`: 4KB、64B line、direct-mapped，load miss refill，store write-through/no-write-allocate，命中 store 更新 cached word。
- 更新 `npc/single/vsrc/NpcCore.v`：
  - `IfStage` 与 `MemoryStage` 改接 cache CPU-side ready/valid。
  - cache memory-side 继续接原外部 IFU/LSU 总线端口。
  - 删除仿真专用 `fence_i_flush_o` public port。
  - 修复 cache 长延迟下的 decode/EX/RF 写端口前递。
  - 修复 difftest commit `rd` 通道，使其与 MEM/WB 提交指令同源。
- 更新 `npc/single/vsrc/NpcSimTop.sv`：
  - 用 `u_core.cache_flush_valid_w` 层次化引用观察 `fence.i` flush 事件。
  - 继续保留 legacy `npc_cache_flush_all()` 调用作为仿真侧同步钩子。
- 更新 `npc/single/csrc/dpi.c`：
  - DPI bus 改为 raw PMEM/MMIO 访问，不再经 host cache。
  - `npc_ifetch()` 允许 RVC 所需的半字对齐取指，奇地址仍报错。
- 更新 `npc/single/Makefile`：
  - 显式区分 `RTL_CORE_SRCS`、`SIM_TOP_SRCS`、`RTL_HEADER_SRCS`。
  - `STA_RTL_FILES` 默认使用纯 RTL core 集合并包含 `IDCache.v`。

## 根因修复

- `fence-i` 失败：`lw; jalr` 路径在 load response 同拍仍读旧寄存器值。已补当前 MEM response 到 decode/EX 的前递。
- `add-longlong` 失败：cache miss 拉长后，同拍 RF 写读边界暴露。已补 RF write-port bypass。
- `microbench ssort` 取错指令：ICache refill 被 branch flush abort 时，旧 valid/tag 仍有效但 data array 已被局部新 line 污染。已在 refill 开始清 victim valid，并在 abort fill 时保持 invalid，整条 line 完成后再置 valid/tag。
- difftest 远端 GPR mismatch：`commit_valid/pc/inst` 来自 MEM/WB，但 `commit_rd_en/data` 曾来自下一拍 RF 写影子信号。已改为全部来自 MEM/WB。

## 验证

- `make -C npc/single lint`: PASS
- `make -C npc/single`: PASS
- `timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`: 38/38 PASS
- `timeout 120s make -C am-kernels/benchmarks/microbench ARCH=riscv32-npc mainargs=test CROSS_COMPILE=/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf- run NPC_RUN_ARGS='--diff=default -m 0'`: PASS
- `make -C npc/single syn-check-env`: FAIL，当前缺 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`

## 后续

- 为 RTL I/D cache 增加 perf counter，并通过仿真专用层次化读取或 debug/perf 端口暴露给 host。
- 恢复 Yosys/STA 环境后重新生成面积、时序、功耗基线。
- 若升级 DCache write-back/write-allocate，需要补 dirty victim 回写、store buffer、MMIO ordering 与更多压力测试。
