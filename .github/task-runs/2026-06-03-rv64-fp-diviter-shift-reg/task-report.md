# RV64 FP divider shift-register cleanup

## 范围

- 修改 `npc/rv64/vsrc/ooo/frontend/OooFpDivIter.v`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fp_iter.sv`。
- 更新 `npc/rv64/testbench/Makefile`，把 `tb_ooo_fp_iter` 纳入模块 testbench 列表。

## 四段式推导

- 需求：在前一轮 FDIV/FSQRT 串行长操作边界已建立后，继续把 divider 子模块内部的运行态变量移位器收敛掉；并补上可独立复跑的模块级 testbench。
- 协议规则、状态机、不变量：`start_i && !busy_q` 捕获一次请求，busy 期间忽略新 start，`done_o` 单拍；`rst/flush_i` 清空所有 partial 状态。状态机保持 idle/busy/done-pulse。每拍只处理一个 quotient bit，compare/subtract 的 shifted divisor 必须与 quotient bit 对齐向低位推进。
- RTL：新增 `shifted_divisor_q`，start 时用常量 shift 装载最高 quotient bit 对应的 divisor；busy 期间每拍右移该寄存器，并用 `{quotient_q[QUOTIENT_W-2:0], subtract_step_w}` 顺序生成 quotient。删除运行态 `divisor_ext_w << bit_idx_q`、`quotient_bit_w` 和无真实消费的 `divisor_q`。`OooFpSqrtIter` RTL 不变。
- 验证：新增 `tb_ooo_fp_iter` 对 div/sqrt 的结果、remainder_nonzero、busy-start 忽略和 flush 清空做模块级覆盖；再跑集成 TB、lint、build、FP long-op smoke 和静态扫描。

## 验证记录

- `make -C npc/rv64/testbench TESTS=tb_ooo_fp_iter RESULT_TIMESTAMP=20260603-rv64-fp-iter-shift-reg run`: PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_TIMESTAMP=20260603-rv64-fp-iter-shift-reg-fetch run`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C Linux/tools smoke-fp-div smoke-fp-sqrt`: both GOOD TRAP；`smoke-fp-div cycles=921/commits=100`，`smoke-fp-sqrt cycles=1015/commits=94`。
- `rg -n "<<\s*bit_idx_q|>>\s*bit_idx_q|quotient_bit_w|divisor_q|shifted_divisor_w" npc/rv64/vsrc/ooo/frontend/OooFpDivIter.v`: 仅剩 `shifted_divisor_q`/`next_shifted_divisor_w` 相关实现，无旧动态移位或残留寄存器。
- 活动 RTL waiver 扫描排除 `legacy/` 后无 `UNOPTFLAT/UNUSEDSIGNAL/BLKSEQ/lint_off/lint_on` 命中。
- `git diff --check`: PASS。

## 边界

- 本轮只收敛 `OooFpDivIter` 子模块内部数据通路，并补充 div/sqrt 迭代单元模块 TB。
- 不改变 `OooAluFetchCore` pending FP long-op 外部协议，不改变 FDIV/FSQRT 指令 latency。
- FP add/sub/mul/convert 仍保留组合 helper；full fflags 与 dynamic rounding 全矩阵仍未闭合。
