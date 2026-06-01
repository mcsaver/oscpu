# RV64 FP FSQRT Focused Gate

## 任务目标

- 继续推进 RV64GC/lp64d 用户态 ladder，在既有 FP 串行 drain 通道中补 `FSQRT.{S,D}` focused gate。
- 近期仍以 Verilator/NPC 为主验证平台，不把 Vivado/FPGA 作为当前功能 bring-up 前置。
- 本轮目标是功能前沿 smoke 和既有 FP 回归，不声明完整 fflags/dynamic frm、官方 Ubuntu `/bin/sh`、rootfs/virtio 或最终可流片 FPU 微结构已闭合。

## RTL 推导摘要

### 阶段 1 - 需求

- 功能目标：支持 OP-FP 编码下的 `FSQRT.S` 与 `FSQRT.D`，结果写回 FPR；覆盖 finite exact sqrt、`+0/-0`、`+inf`、负非零 canonical qNaN、NaN canonical qNaN，单精度结果保持 NaN-boxed。
- 输入输出：沿用 `OooAluFetchCore` 现有 fetch/decode、`pending_fp_*` 与 FPR 文件；新增组合 helper 只消费 `frs1`、`pending_fp_double_q` 与指令 `rm`。
- 性能/时序：本轮仍是 backend drain 后的串行 FP focused path；组合整数 sqrt helper 用于功能 gate，不作为最终 PPA/STA 可签核 FPU。
- 上下游边界：decode 负责只接收 `rs2=0` 的 `FSQRT` 编码；pending FP result mux 负责写回 FPR；不触碰 memory request 协议。
- Out of scope：full fflags、动态 frm 全矩阵、完整 IEEE 754 subnormal/rounding stress、流水化 FPU、NPC 官方 Ubuntu `/bin/sh` 和 rootfs gate。

### 阶段 2a - 协议规则

- `FSQRT` 复用现有 FP stop/drain 协议：前端遇到 FP raw 指令后停止常规发射，等待 backend drained，再由 pending FP path 读取 FPR 并产生结果。
- `FSQRT` 是 FPR-only 写回，不走 `pending_fp_gpr_write_q`，也不触发 FP load/store memory request。
- `FSQRT.S/D` 只在 `rm<=4` 或 `rm==7` 且 `rs2==0` 时进入 raw FP 路径；其它编码不由本 focused path 接管。
- 单精度输入沿用 NaN-boxing 检查；未 NaN-boxed 的单精度源操作数按 NaN 处理。

### 阶段 2b - 状态机

- 不新增状态机状态。
- 现有状态骨架保持为：decode raw FP -> stop pending -> backend drained -> pending FP result combinational -> commit/writeback -> 清 pending。
- `FSQRT` 只是扩展 pending 分类：`pending_fp_sqrt_w` 与 `pending_fp_sqrt_value_w` 插入 FPR result mux。

### 阶段 2c - 不变量

- I1：`FSQRT` decode 必须满足 `rs2==5'b00000`；违反会把非法/保留编码误当成合法 sqrt。
- I2：`FSQRT.S` 输出高 32 位必须为 `32'hffff_ffff`；违反会让后续单精度操作把结果视为未 NaN-boxed。
- I3：负非零输入必须返回 canonical quiet NaN；违反会让 libc/math 路径观察到错误数值而非 invalid-result 表征。
- I4：`sqrt(-0)` 必须保持 `-0`；违反会破坏 IEEE/RISC-V 对 signed zero 的可观察语义。
- I5：本轮不更新 fflags；不能用 smoke PASS 推断异常标志或动态 frm 已完整。

### 阶段 2d - 数据通路约束

- Decode：新增 `FP_FUNCT7_FSQRT_S/D`，并把 head0/head1 raw FP 与 double 判定接入现有分支。
- Operand：只读取 `frs1`，`frs2` 对结果无贡献；double/single 由 `pending_fp_double_q` 控制。
- Special cases：NaN/negative/inf/zero 先于普通路径处理，单精度同时检查 NaN-box。
- Finite path：normalize significand，按指数奇偶构造定点 radicand，使用组合整数 sqrt 得到带 guard/sticky 的 root，再复用 `fp_round_increment` 打包。
- PPA 风险：`fp_isqrt_112/fp_isqrt_54` 是组合搜索 helper，后续 tapeout FPU 应替换为定时 divider/sqrt pipeline 或迭代单元，并保留同一架构 special-case 语义。

### 阶段 3 - RTL 自检

- `head*_fp_raw_w` 已纳入 `head*_fp_sqrt_raw_w`，`head*_fp_double_w` 已纳入 `FSQRT_D`。
- `pending_fp_sqrt_w` 与 `pending_fp_sqrt_value_w` 插入在 div 与 minmax 之间，不改变 GPR write 或 memory request 路径。
- `fp-sqrt-smoke.S` 覆盖 double/single finite、zero、inf、negative NaN 和 single boxing 二次使用。

## 实现记录

- 修改 `npc/rv64/vsrc/ooo/OooAluFetchCore.v`：
  - 新增 `FP_FUNCT7_FSQRT_S/D`。
  - 新增 head0/head1 `FSQRT` raw decode，要求 `rs2=0` 与合法 `rm`。
  - 新增 `fp_isqrt_112/fp_isqrt_54`、`fp_sqrt_d_value`、`fp_sqrt_s_value`、`fp_sqrt_value`。
  - 新增 pending sqrt mux 与 double 判定。
- 修改 `npc/rv64/tools/Makefile`：
  - 新增 `FP_SQRT_ELF/BIN` 与 `smoke-fp-sqrt`。
  - `fp-sqrt-smoke` 显式加 `-no-pie`，避免工具链默认 PIE 让 `objcopy` 生成超大低地址填充二进制。
- 新增 `npc/rv64/tools/fp-sqrt-smoke.S`。

## 验证证据

- `make -C npc/rv64 -j1`：PASS。
- 首次 `make -C npc/rv64/tools smoke-fp-sqrt` 暴露构建问题：ELF 被默认链接为 PIE，`objcopy` 后 image size 约 2GB，超出 PMEM；修复 Makefile 加 `-no-pie` 后重跑 PASS。
- `make -C npc/rv64/tools smoke-fp-sqrt`：GOOD TRAP，`cycles=490/commits=94`。
- 回归：
  - `smoke-fp-loadstore` GOOD TRAP，`cycles=216/commits=34`
  - `smoke-fp-fmv-fclass` GOOD TRAP，`cycles=463/commits=95`
  - `smoke-fp-convert` GOOD TRAP，`cycles=320/commits=65`
  - `smoke-fp-compare-sgnj` GOOD TRAP，`cycles=361/commits=65`
  - `smoke-fp-minmax` GOOD TRAP，`cycles=401/commits=75`
  - `smoke-fp-addsub` GOOD TRAP，`cycles=422/commits=86`
  - `smoke-fp-mul` GOOD TRAP，`cycles=463/commits=89`
  - `smoke-fp-div` GOOD TRAP，`cycles=535/commits=100`
- `git diff --check`：PASS。

## 边界与下一步

- 当前 F/D arithmetic frontier 已补到 `FSQRT` focused gate，但这仍不是完整 IEEE 754/rv64gc-lp64d 用户态签核。
- 后续应继续补 full fflags、动态 frm 行为、官方 Ubuntu `/bin/sh` NPC gate、dynamic linker/libc 小程序、virtio/rootfs、多源 PLIC、UART RX/TTY、Linux-visible framebuffer。
- 面向流片水准，组合 `FSQRT/FDIV` helper 需要拆成可时序收敛的迭代或流水 FPU，并新增模块级 testbench、lint/PPA/STA 证据。
