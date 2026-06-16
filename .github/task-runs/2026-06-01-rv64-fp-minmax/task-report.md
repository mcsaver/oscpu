# RV64 FP Min/Max Focused Gate

## 目标

在不越级声明完整 Ubuntu 22.04 `/bin/sh` 或 rootfs 通过的前提下，继续推进 RV64GC/lp64d 用户态 F/D ladder：本轮只闭合 `FMIN.{S,D}` 与 `FMAX.{S,D}` focused gate。结合用户上传文档，本轮记录继续强调 Ubuntu gate 分层、Linux-visible display/virtio/rootfs 不能由 probe 代替，以及近期使用 Verilator 做真实系统仿真、不以前置 Vivado 绕过功能缺口。

## RTL 四段式推导

### 需求

- 支持 OP-FP `FMIN.S/FMAX.S/FMIN.D/FMAX.D`。
- 覆盖 finite、`-0/+0`、one-NaN、both-NaN canonical quiet NaN。
- single 结果保持 NaN-boxed，上 32 位为 `0xffffffff`。
- 本轮不实现 fflags、dynamic rounding，也不声明 `fadd/fsub/fmul/fdiv/fsqrt`。

### 协议与状态机

- 复用 `OooAluFetchCore` 现有 FP 串行 drain 通道。
- `FMIN/FMAX` 不访问 LSU，不写 GPR，只在更老指令 drain 后写 FPR。
- 与 `FSGNJ`、FPR move、FPR convert-to-FPR 共用 FPR result mux。

### 不变量

- 每条 `FMIN/FMAX` 只提交一次，不触发 ArchRegFile 串行 GPR 写。
- one-NaN 返回非 NaN 操作数。
- both-NaN 返回 canonical quiet NaN。
- `fmin(-0,+0)` 返回 `-0`，`fmax(-0,+0)` 返回 `+0`。
- `FMIN/FMAX.S` 输出必须保持 NaN-boxing。

### 数据通路

- 新增 `FP_FUNCT7_FMINMAX_S/D` 与 lane0/lane1 raw decode。
- `head*_fp_raw_w` 纳入 minmax raw 条件。
- 新增 `fp_minmax_value()`，按 double/single 分支处理 NaN、zero sign 和 magnitude compare。
- FPR write mux 增加 `pending_fp_minmax_w ? pending_fp_minmax_value_w` 分支。

## 改动

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `FMIN/FMAX.{S,D}` decode。
  - 新增 `fp_minmax_value()`。
  - FP 串行 FPR result mux 接入 min/max 结果。
- `npc/rv64/tools/Makefile`
  - 新增 `smoke-fp-minmax` 构建与运行目标。
- `npc/rv64/tools/fp-minmax-smoke.S`
  - 覆盖 double/single finite、zero sign、one-NaN、both-NaN canonical qNaN。

## 验证

- `make -C npc/rv64 -j1`
  - PASS
- `make -C npc/rv64/tools smoke-fp-minmax`
  - GOOD TRAP
  - `cycles=401`
  - `commits=75`
- `make -C npc/rv64/tools smoke-fp-loadstore smoke-fp-fmv-fclass smoke-fp-convert smoke-fp-compare-sgnj`
  - `smoke-fp-loadstore`: GOOD TRAP, `cycles=216/commits=34`
  - `smoke-fp-fmv-fclass`: GOOD TRAP, `cycles=463/commits=95`
  - `smoke-fp-convert`: GOOD TRAP, `cycles=320/commits=65`
  - `smoke-fp-compare-sgnj`: GOOD TRAP, `cycles=361/commits=65`
- `git diff --check`
  - PASS

## 边界

- 尚未实现或验收 `fadd/fsub/fmul/fdiv/fsqrt`。
- 尚未实现 full fflags 或 dynamic rounding 全矩阵。
- 尚未证明 NPC 官方 Ubuntu `/bin/sh`、dynamic linker/libc 或完整 rv64gc/lp64d 用户态通过。
- 尚未闭合 virtio-blk/rootfs、多源 PLIC、UART RX/TTY 或 Linux-visible framebuffer/simplefb/display gate。
- 本轮只是在 Verilator/NPC 上推进 FP focused gate，不代表 FPGA/Vivado 或流片级 signoff 已达成。
