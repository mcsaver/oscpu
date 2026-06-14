# RV64 OooAluFetchCore FPR reset waiver 清理

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动 RTL 中的仿真式写法。本轮聚焦：

- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`

目标是删除 FPR reset loop 中的 `BLKSEQ` waiver，把时序块内的 FPR 清零改为统一的 nonblocking 状态更新，不改变前端、FP pending、FPR 读写或 trap/flush 协议。

## RTL 推导

### 需求

`OooAluFetchCore` 是当前 RV64/OoO 活动核心的前端、dispatch、CSR/trap 与串行 FP owner。旧 reset 分支中对 `fpr_q[0..31]` 使用 blocking `=` 全表清零，并在该 loop 外包 `verilator lint_off BLKSEQ`。这类写法适合功能仿真快速清表，但在商业 RTL 审查中会和同一时序块内大量 nonblocking 状态更新混用，既增加 lint waiver，也降低 reset 行为的一致可读性。

FPR reset 本质是时序状态落库，不需要 blocking 临时顺序依赖；应与 FIFO、RAS、FP pending、CSR/trap 状态一样在 reset clock edge 统一使用 nonblocking 赋值。

### 协议规则

- Reset 后 32 个 FPR 均应在同一个 clock edge 后成为 0。
- 普通运行中 FPR 只由两类完成事件写回：
  - FP load 完成时写 `pending_fp_load_value_w`。
  - FP compute 完成时写 `pending_fp_result_value_w`。
- FP store/compute 读源操作数仍从 `fpr_q[rs1/rs2]` 或 pending path 取值。
- FP pending/drain、frontend stop、trap/flush 和 CSR/fcsr 更新规则保持原样。

### 状态机/不变量

- 本轮不改 `pending_fp_valid_q`、`pending_fp_is_load_q`、`pending_fp_rd_q` 等串行 FP 状态机。
- 不改 dispatch、commit、ROB drain、trap redirect、interrupt/exception handling。
- `fpr_q[i]` reset 后为 0；reset 之外仍只在既有 FP load/compute completion path 写。
- `fpr_q` 没有同一 reset loop 内的先写后读依赖，因此 nonblocking 清零与目标硬件寄存器语义一致。

### 数据通路约束

- 删除 reset loop 周围的 `BLKSEQ` lint waiver。
- 将 `fpr_q[fpr_reset_idx] = {`XLEN{1'b0}}` 改为 `fpr_q[fpr_reset_idx] <= {`XLEN{1'b0}}`。
- 不新增端口、不改 filelist、不改 testbench。

## 代码改动

- `OooAluFetchCore.v` FPR reset loop 改为 nonblocking assignment。
- 增加一条短注释，说明 FPR 与其它前端状态在 reset 边沿统一落库。

## 验证

- 活动 RTL waiver 扫描：
  - `Get-ChildItem npc/rv64/vsrc -Recurse -Include *.v,*.sv | Where-Object { $_.FullName -notmatch '\\legacy\\' } | Select-String -Pattern 'BLKSEQ'`: 无命中
  - 全量 `npc/rv64/vsrc` 扫描剩余命中仅在 `vsrc/legacy/BranchPredictor.v`、`vsrc/legacy/Sram1Rw.v`、`vsrc/legacy/Sram2R1W.v`
- `make -C npc/rv64/testbench TESTS='tb_ooo_alu_fetch_core tb_ooo_fetch_trap_gate tb_ooo_priv_system' RESULT_TIMESTAMP=20260603-alu-fetch-fpr-reset-blkseq-cleanup run`: PASS 3/3
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass smoke-fp-convert`: GOOD TRAP
  - `smoke-fp-loadstore`: cycles=149, commits=34
  - `smoke-fp-fcsr`: cycles=321, commits=88
  - `smoke-fp-fmv-fclass`: cycles=250, commits=95
  - `smoke-fp-convert`: cycles=170, commits=65
- Focused `git diff --check` on本轮触及文件: PASS

## 边界

- 本轮只清理 FPR reset 写法，不拆 FPU，不改变 FP 算术实现或 fflags/dynamic rounding 语义。
- `OooAluFetchCore` 仍有若干 `UNOPTFLAT` waiver 和组合 FP helper；后续 PPA 应优先把 FP convert/FDIV/FSQRT 等拆成独立 ready/valid 多周期单元。
- `npc/rv64/vsrc/legacy` 下仍存在旧历史模块的 `BLKSEQ` waiver，本轮不处理 legacy。
