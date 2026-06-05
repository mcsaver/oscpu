# RV64 FP short-compute register boundary

## 范围

- 修改 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`。
- 未新增 testbench 文件；复用 `tb_ooo_alu_fetch_core` 和既有 FP/Linux smoke。

## 四段式推导

- 需求：`FADD/FSUB/FMUL/FCVT/FSGNJ/FCMP/FMINMAX/FMV/FCLASS` 等 short FP helper 结果原先在 pending drain 完成当拍直接进入 commit/FPR/ArchRegFile serial write，组合锥过长且不利于 ASIC timing/PPA 审查；需要在 pending FP commit 前增加寄存边界。
- 协议规则、状态机、不变量：pending FP 仍按 drain 后提交；short-compute FP 在 `backend_drained_q && pending_fp_mem_done_q` 后先打一拍 `pending_fp_compute_done_q/result_q`，done 之后才允许 `drain_complete_w`。flush/trap、新 pending capture、commit clear 必须清 latch；load/store 和 FDIV/FSQRT 绕过该 short-compute 子状态。
- RTL：新增 `pending_fp_compute_done_q`、`pending_fp_compute_result_q`、`pending_fp_compute_op_w`、`pending_fp_compute_wait_w`、`pending_fp_compute_start_w`。把原 short FP result mux 拆成 `pending_fp_compute_value_w`，提交侧 `pending_fp_result_value_w` 改为 long-op result 与 registered compute result 二选一。
- 验证：跑 focused fetch core、lint、全量 build、FP 全家 smoke、非 FP 基线 smoke、结构搜索、活动 RTL waiver 扫描和 whitespace 检查。

## 验证记录

- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_TIMESTAMP=20260603-rv64-fp-short-compute-reg-fetch run`: PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C Linux/tools smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass smoke-fp-convert smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub smoke-fp-mul smoke-fp-div smoke-fp-sqrt`: all GOOD TRAP。
- 精简采样：`smoke-fp-loadstore 154/34`，`smoke-fp-fcsr 323/88`，`smoke-fp-fmv-fclass 278/95`，`smoke-fp-convert 192/65`，`smoke-fp-compare-sgnj 207/65`，`smoke-fp-minmax 234/75`，`smoke-fp-addsub 266/86`，`smoke-fp-mul 287/89`，`smoke-fp-div 946/100`，`smoke-fp-sqrt 1039/94`。
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user-sv39-halfword`: all GOOD TRAP；精简采样分别为 `41/16`、`192541/122893`、`637/88`、`362/134`。
- `rg -n "pending_fp_compute|pending_fp_result_value_w|pending_fp_compute_value_w" npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`: 命中仅覆盖寄存声明、op/wait/start、result mux、reset/clear/capture 和提交使用点。
- `rg -n "UNOPTFLAT|UNUSEDSIGNAL|BLKSEQ|lint_off|lint_on" npc/rv64/vsrc | rg -v "[/\\]legacy[/\\]"`: 无命中。
- `git diff --check`: PASS。

## 边界

- 本轮有意给 short FP compute 增加一拍 drain 气泡，用时序/面积可控性换取少量 cycle 增长。
- 不改变 FP load/store、FDIV/FSQRT long-op 或 pending FP 精确 drain/flush 协议。
- 仍未声明 full fflags、dynamic rounding 全矩阵或高吞吐 FPU pipeline 完成。
