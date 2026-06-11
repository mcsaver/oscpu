# RV64 FP Long Iter Unit

## 目标

把 `OooAluFetchCore` 中 FDIV/FSQRT 的功能仿真式单周期宽组合算子，收敛为更适合 ASIC timing/PPA 的串行长操作边界，同时保持当前 FP 精确 drain 与提交语义。

## 四段式推导

- 需求：去掉 FP divide 的组合 `/`/`%`，去掉 FSQRT 的组合 integer sqrt、candidate square/root square 比较；FP 指令仍通过现有 pending_fp 串行精确边界提交。
- 协议规则、状态机、不变量：pending FP 在后端 drain 且 FP memory 子流程完成后，只能启动一次长操作；`pending_fp_long_done_q=0` 时阻止 `drain_complete_w`；done 后结果锁存到 `pending_fp_long_result_q` 再提交。reset/flush/新 pending capture 必须清 long 状态。FP load/store 不启动长操作，非 div/sqrt FP 仍原路径。
- 数据通路约束：除法单元只输出 quotient 与 remainder_nonzero；sqrt 单元只输出 root 与 remainder_nonzero；NaN/Inf/Zero、subnormal normalize、rounding 与最终 FP 打包仍由原 helper 处理。
- RTL：新增 `OooFpDivIter`、`OooFpSqrtIter`，并在 `OooAluFetchCore` 接入 `pending_fp_long_pending_q/done_q/result_q`。

## 改动

- 新增 `npc/rv64/vsrc/ooo/frontend/OooFpDivIter.v`：每拍处理一个 quotient bit，用 compare/subtract 替代组合除法和取余。
- 新增 `npc/rv64/vsrc/ooo/frontend/OooFpSqrtIter.v`：每拍消费一个 radicand bit-pair，用 digit-by-digit sqrt 替代组合开方/平方比较。
- 更新 `npc/rv64/vsrc/filelist.mk`，把两个新 helper 纳入 `RTL_OOO_FRONTEND_HELPERS`。
- 更新 `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`：
  - FDIV/FSQRT pending_fp 增加 long start/wait/done/result 状态；
  - `pending_replay_wait_w` 增加 long wait；
  - `fp_div_*` helper 改为消费迭代 quotient/remainder_nonzero；
  - `fp_sqrt_*` helper 改为消费迭代 root/remainder_nonzero；
  - 删除旧 `fp_isqrt_*` 和组合 square 比较路径。

## 验证

- `make -C npc/rv64 lint`：PASS
- `make -C npc/rv64/testbench TESTS="tb_ooo_alu_fetch_core" RESULT_TIMESTAMP=20260603-rv64-fp-long-iter run`：PASS
- `make -C npc/rv64 -j2`：PASS
- 新二进制下 `make -C Linux/tools smoke-fp-div smoke-fp-sqrt`：GOOD TRAP
  - `smoke-fp-div`: `cycles=921/commits=100`
  - `smoke-fp-sqrt`: `cycles=1015/commits=94`
- `make -C Linux/tools smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass smoke-fp-convert smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub smoke-fp-mul smoke-fp-div smoke-fp-sqrt`：全部 GOOD TRAP
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user-sv39-halfword`：全部 GOOD TRAP
- 旧组合 div/sqrt helper 扫描无命中：
  - `dividend /`
  - `dividend %`
  - `fp_isqrt`
  - `candidate_sq`
  - `root_sq`
- 活动 RTL waiver 扫描排除 `legacy/` 后无 `UNOPTFLAT/UNUSEDSIGNAL/BLKSEQ/lint_off` 命中。
- `git diff --check`：PASS

## 后续

- 本轮是 ASIC timing/PPA 风格收敛，FDIV/FSQRT latency 增加为预期。
- 后续可以在同一 ready/done 边界内替换为流水或共享 FPU，并继续补 fflags/exception flag 聚合。
