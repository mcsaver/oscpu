# RV64 OoO Flush-Drain 与 CoreMark 卡死回归

## 目标

- 继续分析 fault-trap 后 CoreMark/WSL 崩溃链路，优先定位 NPC 无进展根因。
- 在 `npc/rv64` OoO memory/flush 边界闭合 outstanding response 所有权。
- 补充测试覆盖新增 flush-drain 规则，并复验 CoreMark CPI 是否仍低于 0.8。

## RTL 推导

### 1. 需求

CoreMark 在 fault-trap 后不再报 BAD TRAP 或 difftest mismatch，而是在固定 `commits=325846` 后无进展，长跑叠加 WSL 会话不稳定表现为 `E_UNEXPECTED`。旧证据里 memory req/rsp 差 1，说明 flush/异常路径可能清掉后端 pending，但 memory bridge 仍持有或即将收到一个 response。修复目标不是让后端“假装完成”，而是把 flush 后 memory bridge 对 CPU response 与 AXI in-flight transaction 的 ownership 定义完整。

### 2. 协议规则 / 状态机

- flush 后 CPU 侧不能再看到旧请求的 response，也不能接收新 CPU 请求，直到旧 AXI transaction 被取消或 drain。
- 若 bridge 已在 `S_RESP` 持有 CPU response，flush 直接丢弃该 response 并回到 idle。
- 若 AXI read address 已发出，必须保持 `rready` drain R channel；未发出的 walk/read address 可以取消。
- 若 AXI write 的 AW/W 均未发出，可以取消；若只发出一半，必须补完剩余通道并 drain B response。
- checkpoint restore 也需要 flush memory bridge，但不能把 combinational restore 信号直接拉进 bridge 形成 Verilator `UNOPTFLAT` 环。

### 3. 不变量 / 数据通路

- 后端 `mem_pending_q` 被 flush/restore 清零后，bridge 不允许把旧 response 再送给后端。
- AXI 侧一旦握手成功，仍需按 AXI-Lite 风格完成对应 response drain，不能遗留 bus busy。
- `stop_pending_q` 期间已有 pending arch trap 时，不能让无 owner 的 branch resolve 抢占精确 drain/trap 状态机。
- flush-drain 修复只改变异常/flush 边界，不改变正常 load/store response 数据路径。

### 4. RTL 落点

- `npc/rv64/vsrc/core/OooMemAxiBridge.v`
  - 新增 `flush_i`、`drop_rsp_q`。
  - CPU request/response valid/ready 在 flush/drop 期间屏蔽。
  - 按状态实现 response drop、read drain、partial write drain。
- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `mem_flush_o`。
  - trap/local flush 同拍送 memory bridge；checkpoint restore 通过 `checkpoint_mem_flush_q` 打一拍。
  - `branch_resolve_untracked_w` 加 `!stop_pending_q` 门控，并在 untracked 恢复路径清 `pending_arch_trap_q`。
- `npc/rv64/vsrc/core/NpcCoreTop.v`
  - 接线 `ooo_mem_flush_w` 到 `OooMemAxiBridge.flush_i`。
- `npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv`
  - 覆盖 held response flush-drop、in-flight read flush-drain、partial write flush-drain。

## AM/测试侧修复

CoreMark 越过旧 `325846` commit 卡点后，又在 CRC 输出的 `out_uint` 反向 digit 循环中稳定长跑。临时 commit 探针显示 `sp=0x000000008010cda0` 且 `digit_count=1` 时终止指针变成 `0xffffffff8010cda0`。根因是 `while (digit_count > 0) tmp[--digit_count]` 在 RV64/Zba 下被编成 `zext.w` 参与 64-bit 指针终止地址计算。`abstract-machine/klib/src/stdio.c` 已改成从 `tmp + digit_count` 纯指针回走到 `tmp`，并新增 `am-kernels/tests/cpu-tests/tests/stdio-format.c` 覆盖 CoreMark CRC 输出样式。

## 验证

- PASS: `make -C npc/rv64/testbench TESTS="tb_ooo_mem_axi_bridge tb_ooo_sv39_boot tb_ooo_priv_system tb_ooo_int_backend" RESULT_DIR=/tmp/rv64-bridge-flush-focused run`
- PASS: `make -C npc/sim BACKEND=rv64 lint`
- PASS: `make -C npc/sim BACKEND=rv64 -j4`
- PASS: `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=stdio-format run`
- PASS: CoreMark `ITERATIONS=10` direct run, `HIT GOOD TRAP` / `CoreMark PASS`，`cycles=2518692`，`commits=3216171`，`CPI=0.783`
- CHECK: `rg "DEBUG_STALL|debug_no_retire_q|debug_stall_dumped_q|NPC_DEBUG_OUTUINT|\\[OUTUINT\\]" npc/rv64/vsrc/sim/NpcSimTop.sv npc/rv64/csrc/cpu/cpu-exec.cpp` 无结果。

## 未完成 / 风险

- 本轮没有宣称真实 Linux 已启动；仍缺 SBI、PLIC、virtio、DTB、真实 kernel/rootfs 加载和完整平台 boot 验收。
- CoreMark 1000 iterations 未在本轮重跑，避免继续刺激当前不稳定 WSL 会话；最近完整 1000-iteration 证据仍是前序 `CPI=0.779`。
- Host 侧 commit-time branch taken 统计仍依赖 ROB `next_pc` 元数据，当前显示 taken=0 不代表 RTL 没有实际 taken；BPU resolve 统计仍可用。后续若要使用该字段做性能分析，应单独修正 commit next_pc 或统计来源。
