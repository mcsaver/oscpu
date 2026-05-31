# 2026-05-30 rv64 Linux 前置能力与小型启动模拟

## 目标

- 在 `npc/rv64` OoO core 上补齐 Linux 早期启动需要优先遇到的 S-mode CSR/delegation/SRET 和 RV64 A 扩展原子访存路径。
- 保持 CoreMark CPI 低于 `0.8`。
- 新增测试覆盖新增指令/CSR，并用一个小型 Linux 启动骨架模拟 M-mode firmware handoff 到 S-mode、S-mode trap handler 和返回。

## 实现摘要

- `CsrFile` 增加当前 privilege mode、`medeleg/mideleg`、S-mode CSR、`satp`、S-mode trap target、`MRET/SRET` mode/PC 恢复，并让 `ECALL` cause 随当前 mode 变化。
- `DecodeUnit/OooAluFetchCore` 增加 `SRET`，把 `MRET/SRET` 统一作为 xRET 精确 drain 控制事件。
- `DecodeUnit/OooIntBackend` 增加 RV64 A 扩展 `LR/SC/AMO*.{W,D}`。AMO 地址生成修正为 `rs1+0`，`rs2` 只作为原子运算/写入值；普通 AMO 使用单 outstanding read-modify-write 两阶段请求；LR/SC 使用一个 reservation。
- 测试更新：
  - `tb_decode_unit`: 覆盖 SRET、AMOADD.D、LR.W、SC.W decode。
  - `tb_ooo_int_backend`: 覆盖 `LR.D`、`SC.D` 成功/失败、`AMOADD.D` RMW 和 AMO 地址不加 rs2。
  - `tb_ooo_priv_system`: 新增 M-mode 设置 `stvec/medeleg/mepc/mstatus.MPP=S` 后 `mret` 到 S-mode，S-mode 写 `satp`、执行 `sfence.vma`、触发委派 ecall、S handler 读取 `scause/sepc` 并 `sret` 回 S-mode 的小型启动骨架。
  - `tb_alu/tb_compare`: 修正 RV64 下旧 RV32 预期。

## 验证证据

- Focused RTL tests:
  - `make -C npc/rv64/testbench TESTS="tb_decode_unit tb_ooo_int_backend tb_ooo_priv_system" RESULT_DIR=/tmp/rv64-linux-prereq-test run`
  - 结果：`3/3 PASS`
- RV64 lint:
  - `make -C npc/sim BACKEND=rv64 lint`
  - 结果：PASS
- RV64 Verilator build:
  - `make -C npc/sim BACKEND=rv64 -j4`
  - 结果：PASS
- cpu-tests:
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
  - 结果：`40/40 PASS`
- CoreMark:
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=1000 run NPC_RUN_ARGS="--no-progress --max-cycles 1000000000"`
  - 结果：`CoreMark PASS 8 Marks`，`cycles=247287515`，`commits=317356136`，`CPI=0.779`
- 空白检查：
  - `rg -n "[ \t]$" <changed rv64 files>`
  - 结果：无输出

## 残余风险

- 这轮完成的是 Linux 早期启动前置 ISA/特权路径和小型启动模拟，不是完整 Linux boot。完整 Linux 仍需要 Sv39 page-table walk/TLB/PTE 权限、SBI、PLIC/virtio/设备树等平台能力。
- `npc/rv64/testbench` 全量 run 仍会被旧 `tb_ooo_alu_fetch_core` 语义挡住；该 test 仍期待 MRET illegal、旧 32-bit memory/exit 协议，已记录到 `.github/memory/known-issues.md`。
