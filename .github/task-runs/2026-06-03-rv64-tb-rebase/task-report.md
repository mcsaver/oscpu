# RV64 old OoO fetch-core testbench rebase

## 目标

把旧 `npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv` 改成符合当前 RV64/OoO 语义的 focused testbench，避免它继续用 RV32/早期 OoO 假设误报当前 core 的合法行为。

## Baseline

命令：

```sh
make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_TIMESTAMP=20260603-rv64-tb-rebase-baseline run
```

结果：FAIL，26 个 check failure。

主要旧语义残留：

- `mem_req_wstrb`/`mem1_req_wstrb` 仍是 4-bit，而 RV64 LSU 端口是 8-byte strobe。
- 默认程序用 `MRET` 期待 illegal trap；当前 RV64 中 `MRET` 是合法精确控制事件。
- `ECALL` 仍期待 legacy exit；当前 `ECALL` 走 CSR trap/`mtvec`，`EBREAK` 才是实验壳退出。
- JALR 和 memory 程序用 `LUI 0x80000` 构造 `0x8000_0000`；RV64 下该立即数会符号扩展，地址语义错误。
- fetch fault mock 使用旧 response 编码，且 lane1 fetch-fault 断言不再属于该集成 tb 的 owner。
- return/branch fast-path 层次化观测点仍指向旧实现信号。

## 修改

- LSU mock 改用 `` `STRB_W``，并按 8 个 byte lane 更新/比较 64-bit data word。
- 新增 `inst_auipc()` 和 `inst_csrrw()` helper。
- JALR/memory/lane1-memory 程序改用 `AUIPC+ADDI` 生成当前 PC 附近地址，避免 RV64 `LUI` 符号扩展。
- 默认 smoke 程序保留双发、双提交、RAW、same-packet RAW、WAW 覆盖，最后以普通 `EBREAK` 退出；断言 `trap_valid=0`、`exit_is_ebreak=1`。
- `ECALL` 场景先写 `mtvec`，执行 `ecall` 后进入 handler，再由 handler 的 `EBREAK` 退出；断言旧 packet lane1 未 dispatch，handler 指令已执行。
- fetch response fault 编码改为当前 access-fault 值 `2'b01`。
- return fast-path 观测改为当前 `direct_ret0_fire_w/direct_ret1_fire_w/pending_jump_return_fire_w`，lane1 return 断言接受 fallthrough、return fast path 或 synthetic commit 任一路径。
- 移除旧 lane1 fetch-fault 集成断言；该语义由 `tb_ooo_fetch_axi_bridge`/Sv39 focused 测试覆盖。

## 验证

```sh
git diff --check -- npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv
make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_TIMESTAMP=20260603-rv64-tb-rebase-5 run
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge tb_ooo_priv_system tb_ooo_sv39_boot" RESULT_TIMESTAMP=20260603-rv64-tb-rebase-neighbor run
```

结果：

- `git diff --check -- npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv`: PASS
- `tb_ooo_alu_fetch_core`: PASS
- `tb_ooo_fetch_axi_bridge/tb_ooo_mem_axi_bridge/tb_ooo_priv_system/tb_ooo_sv39_boot`: 4/4 PASS

## 边界

本轮只重基线旧 testbench，不改变 RTL 数据通路、ready/valid、AXI 或 CSR 实现。`tb_ooo_alu_fetch_core` 重新成为当前 RV64/OoO focused 证据；known issue [33] 已移入已解决问题。
