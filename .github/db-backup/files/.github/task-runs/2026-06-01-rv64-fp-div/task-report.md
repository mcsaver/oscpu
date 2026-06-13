# RV64 FP Div Focused Gate

## 目标

在不越级声明完整 Ubuntu 22.04 `/bin/sh`、rootfs 或流片 signoff 通过的前提下，继续推进 RV64GC/lp64d 用户态 F/D ladder：本轮只闭合 `FDIV.{S,D}` focused gate。长期口径保持不变：近期以 Verilator/NPC 做真实 OpenSBI + Linux + Ubuntu 分层系统仿真，Vivado/FPGA 不作为当前功能 bring-up 前置。

## RTL 四段式推导

### 需求

- 支持 OP-FP `FDIV.S/FDIV.D`。
- 覆盖 finite exact divide、signed zero、divide-by-zero signed infinity、NaN、`0/0`、`inf/inf`。
- single 结果保持 NaN-boxed，上 32 位为 `0xffffffff`。
- 覆盖基础 RNE/显式 rm 路径；本轮不实现 `FSQRT`、full fflags 或 dynamic frm 全矩阵。

### 协议与状态机

- 复用 `OooAluFetchCore` 现有 FP 串行 drain 通道。
- `FDIV` 不访问 LSU，不写 GPR，只在更老指令 drain 后读 FPR 并写 FPR。
- 与 `FADD/FSUB`、`FMUL`、`FSGNJ`、`FMIN/FMAX`、FPR convert-to-FPR 共用 FPR result mux。

### 不变量

- 每条 `FDIV` 只提交一次，不触发 ArchRegFile 串行 GPR 写。
- single unboxed 输入按 NaN 处理，single 输出必须 NaN-boxed。
- NaN、`0/0` 或 `inf/inf` 返回 canonical quiet NaN。
- 非零 finite 除以 zero 返回 signed infinity。
- zero 除以非零 finite 或 finite 除以 infinity 返回 signed zero。
- 本轮不更新 fflags。

### 数据通路

- 新增 `FP_FUNCT7_FDIV_{S,D}` decode。
- `head*_fp_raw_w` 纳入 div raw 条件，`head*_fp_double_w` 纳入 double div。
- 新增 `fp_div_d_value()`、`fp_div_s_value()`、`fp_div_value()`。
- 结果路径为 special-case -> significand quotient -> normalize -> round -> pack，再进入 FPR write mux。

## 改动

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `FDIV.{S,D}` decode、double 判定和 pending result mux。
  - 新增 double/single divide helper，覆盖 finite/zero/inf/NaN focused 子集。
  - 当前为 FP 串行 gate 中的组合 quotient helper，后续流片水准仍需拆成有时序/PPA 约束的迭代或流水 divider。
- `npc/rv64/tools/Makefile`
  - 新增 `smoke-fp-div` 构建与运行目标。
- `npc/rv64/tools/fp-div-smoke.S`
  - 覆盖 double/single divide、NaN-boxing、signed zero、divide-by-zero、inf 和 canonical qNaN。

## 验证

- `make -C npc/rv64 -j1`
  - PASS
- `make -C npc/rv64/tools smoke-fp-div`
  - GOOD TRAP
  - `cycles=535`
  - `commits=100`
- `make -C npc/rv64/tools smoke-fp-loadstore smoke-fp-fmv-fclass smoke-fp-convert smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub smoke-fp-mul`
  - `smoke-fp-loadstore`: GOOD TRAP, `cycles=216/commits=34`
  - `smoke-fp-fmv-fclass`: GOOD TRAP, `cycles=463/commits=95`
  - `smoke-fp-convert`: GOOD TRAP, `cycles=320/commits=65`
  - `smoke-fp-compare-sgnj`: GOOD TRAP, `cycles=361/commits=65`
  - `smoke-fp-minmax`: GOOD TRAP, `cycles=401/commits=75`
  - `smoke-fp-addsub`: GOOD TRAP, `cycles=422/commits=86`
  - `smoke-fp-mul`: GOOD TRAP, `cycles=463/commits=89`
- `git diff --check`
  - PASS

## 边界

- 尚未实现或验收 `FSQRT`。
- 尚未实现 full fflags、exception flags 或 dynamic frm 全矩阵。
- 尚未证明 NPC 官方 Ubuntu `/bin/sh`、dynamic linker/libc 或完整 rv64gc/lp64d 用户态通过。
- 尚未闭合 virtio-blk/rootfs、多源 PLIC、UART RX/TTY 或 Linux-visible framebuffer/simplefb/display gate。
- 本轮只是在 Verilator/NPC 上推进 FP focused gate，不代表 FPGA/Vivado 或流片级 signoff 已达成。
