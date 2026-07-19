# RV64 v8c FP completion kill-now 合同

## 允许签收的范围

本合同只覆盖 production `OooFpBackend` 中 exec1 与 held-long 两类 completion 在 selective
branch kill 当拍进入共享 completion arbiter 的资格。它不覆盖全 producer identity、ROB 槽重用、
shared WB→PRF/IQ 的 full-ID 授权、Q1/CSR/FENCE owner、Linux、200 MHz 或 PPA。

## 单一年龄与仲裁方程

令 `age(x) = x - rob_head_idx`（`ROB_INDEX_W` 模环形减法），则：

```text
kill_age    = age(kill_rob_idx)
exec1_kill  = kill_valid && exec1_valid && age(exec1_rob) > kill_age
long_kill   = kill_valid && long_meta_valid && age(long_rob) > kill_age

exec1_take  = exec1_valid && !arith_out_valid && !exec1_kill
long_take   = long_done_hold && long_meta_valid &&
              !arith_out_valid && !exec1_take && !long_kill
```

- 比 kill boundary 严格年轻的项不得完成；等龄与更老项必须存活。
- 优先级保持 `arith > eligible exec1 > eligible long`。
- killed exec1 不得占住优先级并阻挡 live long 递补。
- `long_done` 与 kill 同沿时，kill 的 nonblocking assignment 必须最终同时清 meta 与 done-hold。

## 副作用闭包

以下所有路径均以最终 `exec1_take/long_take` 为唯一入口；被 kill 的 candidate 在该沿前必须全部为
quiet：

- generic `fp_result_wb_valid` 与 done FIFO push；
- FPR write、FP busy clear、ready 前视与 wake；
- ROB/pdest/value/fflags completion payload；
- kill 后任何 delayed completion pulse。

`PipeStageReg.valid`、`long_meta_valid` 的沿上清除太晚；done FIFO 的 killed bit 也只能保护后续
ROB dequeue，不能撤销入 FIFO 前的 FPR/busy/wakeup 副作用，因此二者都不能替代 arbiter 入口的
组合 kill mask。

## 机器门

唯一 focused 入口：

```bash
bash .github/task-runs/2026-07-19-rv64-v8c-fp-completion-kill-cut/run-focused.sh --all
```

它必须同时满足：

1. 冻结 pre-fix Git blob `7fc8e14154c260ba9b1e737d6180975aa063234d` 的 SHA-256 精确为
   `00e64e48...a9ba6f0`，并在当前 170-check TB 下命中 exec1、long、mixed 三组 RED；
2. 当前 RTL 精确产生一次 `PASS ... checks=170`，且无 `[FAIL]`；
3. 14 个语义 mutation 均先编译成功，再跑完整 170-check TB 后由目标 oracle 检出；它们
   覆盖 kill mask/年龄/owner、live GPR 分类与 rd_en、arith/exec1/long 优先级、FIFO ready
   以及 long ROB tuple；
4. scoped Verilator lint 通过。

扩展门为 module aggregate 104/104、RTL style、contract assertion ratchet。全核 strict lint 已在
当前共享源码重跑且仍为 115 warnings RED；本刀不以 scoped lint 或与旧基线相同覆盖它。
