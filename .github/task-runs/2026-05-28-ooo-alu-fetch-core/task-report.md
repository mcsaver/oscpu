# OoO ALU Fetch Core

## 目标

把前几轮已经闭合的 ALU-only OoO slice 往真实主核边界再推进一步：新增一个受控实验壳，从 IFU AXI-like read channel 自行取指，按 `PC/PC+4` 形成 2-wide dispatch packet，并用 `OooAluCoreSlice` 完成双路 rename、issue、execute、ROB retirement 和架构 GPR 可见状态更新。

## RTL 推导摘要

- 需求边界：本轮只承诺 ALU-only 顺序取指实验路径，不替换默认 `NpcCore`，不实现 load/store、控制流预测、CSR 或精确 trap 回滚。
- 接口协议：`OooAluFetchCore` 外侧复用 IFU read channel 的 `arvalid/arready/araddr` 与 `rvalid/rready/rdata/rresp`；内部一拍只保留一个 outstanding fetch read，先取 lane0 再取 lane1。
- 派发协议：两条指令都抓到后才进入 `DISPATCH`；若任意 lane 被 `OooAluDecodeBackend` 标为 unsupported，则整包不派发，记录 illegal instruction trap；若后端可接收且无 unsupported，则同拍向 slice 发两路 raw `pc+inst`。
- PC 更新：成功派发后 `packet_pc += 8`；当前只适合 32-bit 顺序 ALU 片段，尚未处理 RVC、branch redirect 或预测 PC。
- 停机语义：fetch fault 产生 `EXC_INST_ACCESS_FAULT`，unsupported 指令产生 `EXC_ILLEGAL_INST`；进入 halt 后停止新 fetch/dispatch，但不冲掉已经进 ROB 的旧指令提交。
- 可观察状态：双路 commit、retire count、debug GPR、ROB/IQ/FreeList 计数都由 slice 或后端透出，便于后续接 host commit/DiffTest 边界。

## 改动

- 新增 `npc/single/vsrc/ooo/OooAluFetchCore.v`。
- 新增 `npc/single/testbench/tests/tb_ooo_alu_fetch_core.sv`。
- 更新 `npc/single/vsrc/filelist.mk`，把 fetch core 纳入核心 RTL 清单。
- 更新 `npc/single/testbench/Makefile`，把 fetch core testbench 纳入全量模块回归。

## 验证

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo-fetch-core-build RESULT_DIR=/tmp/npc-ooo-fetch-core-results /tmp/npc-ooo-fetch-core-results/logs/tb_ooo_alu_fetch_core.log`：PASS。
- OoO 定向套件 11 个 testbench：PASS。
- `make -C npc/single lint`：PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb4-build RESULT_DIR=/tmp/npc-single-full-tb4-results run`：38/38 PASS。
- `make -C npc/single -j4`：PASS，生成 `npc/single/build/NpcSimTop`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`：GOOD TRAP，`cycles=1509`、`commits=838`、`CPI=1.801`。

## 结论与限制

本轮已经把 OoO ALU 后端从“外部 testbench 喂 raw 指令”推进到“实验核壳自己从 IFU 抓两条连续指令并双发”的边界，局部证明了取指、双发、同包 RAW/WAW、双提交与架构 GPR 状态可以闭合。

CPI=0.5 目标仍未达成。原因是默认 `NpcCore/NpcSimTop` 仍走原顺序流水线，真实 AM smoke 的 CPI 仍为 1.801；新壳也尚缺 ICache/BTB/RVC/branch checkpoint/LSQ/CSR/trap 精确接入。下一步应先做可配置顶层选择或双提交 host/DiffTest 边界，再扩展 LSU 和控制流恢复。
