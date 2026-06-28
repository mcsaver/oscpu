# OooWriteback 子系统 wrapper Spec

## 1. 目标

把 `writeback/` 目录的 5 个 commit/retire owner 聚合到 `writeback/OooWriteback.v`，
让 `OooCoreTopGlue` 只对写回子系统做一次实例化。纯结构聚合，不新增逻辑、不改行为。

## 2. 责任边界（内部 owner，行为不变）

| 内部 owner | 职责（不变） |
| --- | --- |
| `OooCommitOutputMux` | commit0/commit1 输出选择 |
| `OooControlCommitSequencer` | control commit 注册状态 |
| `OooFpCommitGate` | FP result/fflags/GPR-FPR 写回修饰 |
| `OooSyntheticLane1RetCommitGate` | synthetic lane1 return commit/drop 判定 |
| `OooSyntheticLane1RetSequencer` | synthetic lane1 return 注册状态 |

## 3. 接口与不变量

- wrapper 端口 = 5 个内部实例跨边界信号（113 个）。
- glue 顶层 wire 名保留；commit 输出端口（`commit0_*_o`/`commit1_*_o`）由 wrapper
  输出直接驱动 glue 同名顶层输出端口。
- `synth_lane1_ret_commit_w` 被 `tb_ooo_core_top_glue` 以 `dut.synth_lane1_ret_commit_w`
  探测，故作为 wrapper **输出**保留（不下沉），保证探针不失效。
- wrapper 无结构参数（内部实例不使用 `OOO_*` 参数）。

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。

## 5. 边界

只完成 writeback 子系统 wrapper 抽取；不改变 commit/retire/synthetic-ret 语义、
精确异常或 ROB retirement。
