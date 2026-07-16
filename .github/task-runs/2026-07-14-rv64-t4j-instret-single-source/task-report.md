# RV64 T4J INSTRET-G1 single-source report（草稿）

## 目标与根因

本任务只处理 `INSTRET-G1`：把 ROB entry 出队事件与 ISA retirement 分离，并让
`CsrFile.minstret` 只消费最终 commit 仲裁边界的唯一计数。

旧 RTL 有两处不等价：

1. `OooAluCoreSlice` 直接按 ROB `commit_valid` 计数；精确异常 entry 为了交付 trap
   payload 仍会 valid 出队，因此 head0 exception 被误计 1，normal+lane1 exception
   被误计 2。
2. `NpcCoreTop` 把 raw core count 接给 `CsrFile`，漏掉合法 mret/sret/wfi/sfence/
   fence.i 等 control pseudo-commit。旧 output mux 虽合并 control，却按多个隐藏源
   直接相加，计数与最终可见 commit lanes 也不严格同源。

修复不改变 `OooRob` 的异常出队与 trap 顺序；过滤只发生在 retirement count 边界。

## 实现

- `OooAluCoreSlice.v`
  - core count 改为两条 core lane 的 `valid && !exception`。
  - 用 AND/XOR 两位 popcount 显式编码 0/1/2，结构上不能产生 3。
  - `OOO_ASSERT` 增加 core range 护栏。
- `OooCommitOutputMux.v`
  - final count 只从优先级仲裁后的最终 `commit0/commit1` 的
    `valid && !exception` 生成。
  - ctrl 覆盖 core、synthetic 覆盖 lane1 时，隐藏源不再重复进入计数。
- `OooWriteback.v`
  - `OOO_ASSERT` 逐拍核对 core count 与 core lanes、final count 与 final lanes；
    final count 为 3 直接失败。
- `NpcCoreTop.v`
  - `CsrFile.instret_inc_i` 从 raw `ooo_core_retire_count_w` 改接 final
    `retire_count_o`。
- focused TB
  - `tb_ooo_commit_output_mux`：head0 exception=0、normal+lane1 exception=1、
    normal dual=2、ctrl-only=1、ctrl 优先级隐藏其它源仍=1、synthetic lane=2。
  - `tb_ooo_alu_core_slice`：白盒锁住 core 0/1/2 exception-filter 合同。
  - `tb_csr_file`：inc 1/2、`mcountinhibit.IR`、显式 minstret 写覆盖同沿自增。

## 验证证据

- focused module：`evidence/module-testbench/summary.txt`，3/3 PASS。
- focused integration：`evidence/integration-testbench/summary.txt`，2/2 PASS
  (`tb_ooo_core_top_glue`、`tb_ooo_priv_system`)。
- `evidence/lint.log`：`make -C npc/rv64 lint` PASS，零诊断。
- `evidence/check-contract.log`：PASS，`OOO_ASSERT` 常驻门禁满足，当前
  `$error` 计数 194 >= 基线 89。
- `evidence/rtl-style.log`：可综合 RTL 风格检查 PASS。
- `evidence/static-contract.log`：core/final 过滤、assertion 与 NpcCoreTop 绑定的
  逐行静态证据。

## 审查与边界

实现者结论：focused 与最小 integration 已证明 RTL 根因修复，异常 ROB entry 仍能
valid 出队但不进入 ISA count，control commit 进入最终 count，CsrFile 与外部观察同源。

审查者反例：本任务没有运行 ROADMAP 要求的程序级 exception/control `minstret`
delta 长回归，因此只可称为“RTL/focused 已实现”，尚不能宣称 `INSTRET-G1` 的全系统
证据关闭。也没有运行 fresh synthesis/STA。

5ns 风险：CsrFile 的 64-bit minstret 加法器输入从 raw core count 改为最终 output-mux
lane 的 exception-filter popcount，新增一小段组合锥。AND/XOR 编码已避免通用多源加法，
但在已知 exact-5ns 余量仅约 17.9ps 的前提下，必须由后续 current-source fresh 5ns STA
重新裁决；本报告不继承旧 STA 结果。

按主任务约束，本子任务没有修改 DB-backed memory、没有提交 Git、没有运行全量回归或综合。
