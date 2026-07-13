# T3I drain/retire 冗余消除任务报告

- task_id: `2026-07-13-rv64-t3i-drain-retire-redundancy`
- baseline: `0b0d71673a40a8e582106857176cd6c106bb847d`
- slice status: `RTL / function / cycle equivalence / directed timing GREEN`
- physical verdict: `fresh 5 ns WNS=-9.38 ns，未达 200 MHz`
- parent goal: 完整功能且 current-source fresh 5 ns WNS `>= 0`；仍 active。

## 根因、定理与切点

T3H 的 40 条最差路径全部从 integer EX0 状态出发，经同拍 writeback-done
bypass、ROB commit valid、`retire_count_o` 加法器，再进入
`OooPendingDrainResolveGate.backend_drained_o`，最后扩散到 fetch SRAM、pending
trap/exit 与 redirect 控制。drain gate 同时要求 ROB count 为零和 retire count 为零，
但后者在合法 ROB 状态域中严格冗余：

```text
commit0_fire -> count_q != 0
commit1_fire -> commit0_fire
commit{0,1}_valid = commit{0,1}_fire
rob_count = count_q
retire_count = commit0_valid + commit1_valid

所以 rob_count == 0 -> retire_count == 0
```

最后一项退休不是反例：时钟沿前 `count_q` 仍为 1/2，old/new drained 都为 0；
沿后 count 稳定为 0 时两个 commit valid 也已为 0。若同拍又 dispatch，新 count
非零，ROB 条件继续阻止 drain。

T3I 只从 `OooPendingDrainResolveGate`、`OooControlPlane` 和 glue ABI 删除这条
retire-count 输入；ROB、IQ、synthetic lane1 pending 与 `mem_retire_quiet` 五个安全项
保持不变。没有插拍、false path、多周期例外或 flush/redirect 优先级改动。

## 实现与契约

- `OooPendingDrainResolveGate` 的 `backend_drained_o` 精确保留五项 conjunction，
  删除 `core_retire_count_i` 端口和比较。
- `OooControlPlane` / `OooCoreTopGlue` 删除 zombie retire ABI；fresh netlist 对
  gate input、control-plane input 和 connection 的精确计数均为 0。
- `OooAluCoreSlice` 新增 `[CORE-RETIRE-REQUIRES-ROB]` assertion；空 ROB 下
  retire 为 1 或 X 都 fail closed。
- 新增 `tb_ooo_pending_drain_resolve_gate`，覆盖 drain 五谓词以及 jump、SYSTEM/CSR、
  branch resolve/clear/replay；baseline assertion ratchet `85 -> 86`。
- `ooo-drain-retire-redundancy.md` 冻结完整端口 owner、ready/valid、stall DAG、
  flush/redirect 清保持表、异常序、访存序、最后退休前后沿和非声明边界。

## 定理牙齿与测试 runner 假绿修复

`prove-t3i-drain-theorem.py` 先从真实 RTL 解析唯一 continuous assignment，要求：

- commit0 RHS 是顶层纯 `&&` 树，`count_q != 0` 是唯一精确 top-level conjunct；
- commit1 RHS 同样是顶层纯 `&&` 树，`commit0_fire_w` 是唯一精确 conjunct；
- commit valid、ROB count 和 retire-count adder 都是精确 identity。

随后枚举 16-entry ROB 的 2176 个有限 2-state legal-domain case。它不是完整
formal/model checking，结论范围在 spec 中显式限定。两种 mutation 都精确失败：

- 删除 count guard：rc=1，目标原因一次；
- 保留 guard 文本但追加顶层 `|| 1'b1`：rc=1，目标原因一次。

负向 assertion 首轮暴露了 test runner 的真实假绿：Icarus `$error` 后继续打印 exact
PASS，旧 `check_tb_result.py` 只看 PASS/FAIL/rc，错误地接受。runner 现会拒绝行首
`ERROR:`、`%Error:` 和 `%Error-*`；19 个 unit/integration tests 包含真实
`tb_error_then_pass.sv`。最终 retire-one 与 retire-X 两个 probe 都是 make rc=2、
exact ERROR=1、marker=1、`[RESULT] FAIL`=1。旧 fail-open 输出保留为 RED 历史。

## 功能、回归与周期等价

- current theorem/structure/两个 mutation：PASS；证据 `evidence/green/`、
  `evidence/proof-mutation/`。
- test-result runner unittest/integration：`19/19` PASS；module TB：`96/96` PASS，
  ERROR-line audit 为 0。
- `check-contract` current/baseline 均 `86/86`；RTL style、Verilator lint、
  `git diff --check` PASS。
- 最终整核回归 `evidence/core-regress/20260713-152814-2442438/`：module、lint、
  build、AM cpu-tests 全 PASS；official + privileged RISC-V tests `177/177`，
  `overall_rc=0`。
- CoreMark 10 iterations：GOOD TRAP、CRC `0xfcaf`、`3020147` cycles、
  `3218532` commits、CPI `0.938`、`3.379/MHz`、CLINT mtime exact match；与 T3H
  cycle/commit/CRC 逐项相同。

## Fresh synthesis 与 200 MHz 裁决

综合从 2026-07-13 15:31:31 开始，pre/post 冻结 110 个 synth RTL、完整 vsrc
tree 与 5 个 flow/config 项；三组 manifest 都 byte-identical。审计结果：

- 110/110 module/end-module；两轮 ABC 共 220 candidates、10 empty、210 result/done；
- 三次 zero-problem check；Yosys Error line=0；runtime `1387.86 s`，peak
  `3609.14 MB`；
- fresh netlist SHA256
  `91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926`；
- 已知标准单元面积 `1572549.16`，与 T3H `1572550.00` 基本不变。

OpenSTA 使用与 synthesis flow 完全一致的 H7CL typical 1.2 V / 25 C 标准库和四个
macro liberty；三个正式 console 的 unknown-module `Warning 198` 都为 0。exact 5.000 ns
结果：

- combinational loops=0，top40=40；最差报告路径 slack `-9.377 ns`；
- WNS `-9.38 ns`，TNS `-199464.16 ns`，功耗代理 `0.120 W`；
- 相对 T3H WNS `-10.10 ns` 回收约 `0.72 ns`，与冻结 projection 一致；
- top40 的 retire-port/drain-gate token 均为 0；端点是 fetch payload SRAM 1 条、
  pending-trap D 39 条。

定向证据排除了真空绿：旧 T3H canonical retire fanout 有 7288 endpoints，精确命中
fetch=1、pending-trap D=137；fresh T3I 仍有 66 个合法 instret/debug endpoints，但
fetch/trap 命中均为 0。旧 retire-through→fetch/trap 路径存在，fresh retire gate port
精确删除；fresh ROB-through→fetch/trap residual path 继续存在。

T3I 因而完成了自己的物理切点，但 WNS 仍负，不能声明 200 MHz。当前 top1 已转为
integer EX→fetch payload SRAM enable，39 条次差路径落 pending trap；下一切片 T3J
优先拆分 fetch cache 的物理 SRAM read window 与语义 accept。

## 审查者抓到并保留的无效中间证据

以下都未被删除或冒充成功，精确边界见 `evidence/superseded-evidence.md`：

1. 首次 PowerShell→Bash 命令被 PowerShell 提前展开变量，保护 wrapper 不可信；
   `151246-*` 在 AM/ISA 前中断。改为仓内 WSL-native wrapper 后完整重跑。
2. theorem 第一版跨大 RTL 使用灾难性 regex 导致 WSL 挂起；进程终止后改为线性
   assignment extraction。早期 `4224` 日志 superseded，当前为 2176。
3. assertion negative 暴露 `$error`+PASS runner 假绿；全局 runner 修复后重跑
   96/96 module 与两种 negative。
4. reviewer 发现 theorem 只搜索 guard 文本可被 `|| 1'b1` 绕过；升级顶层 AST-like
   conjunction ratchet，并加入 OR-bypass mutation。
5. STA 初稿错误使用 H7CR 库，204 类 H7L cell 被 OpenSTA 建成 black box；current
   checker 精确拒绝。改用 synthesis flow 的 H7CL 后正式证据零 blackbox。
6. hierarchy input/output pin 不能当 `report_checks -from/-to` 起终点；错误 smoke
   假红后改为 `-through`、完整 query binding 与 canonical fanout endpoint manifest。

## 用户工作树保护与归档

验证基于共享工作树，包含用户在任务前已有的
`OooAdUpdateChecker.sv`、`OooFrontend.v`、`NpcSimTop.sv` 修改；三者在 T3H/T3I
vsrc manifests 中 hash 完全一致，未混入本 checkpoint。`build/linux-logs/npc-linux.log`
每次运行前后由 `/tmp` 副本保护，当前与 backup SHA256 都仍为
`3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`。
证据 `evidence/protected-inputs-status.txt`。

- fresh synthesis/STA 的 38 个精确成员已归档为
  `tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/fresh-sta-archive/`
  下 `NpcTop-200MHz-t3i-drain-retire-redundancy.tar.zst`，22,190,809 bytes；
  zstd/tar/inventory/SHA 全 PASS。
- OS `/tmp` 中 5 个 T3I 相关顶层对象全部复制归档到 workspace
  `tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/tmp-archive/`；36 entries，
  archive 26,345 bytes。source-list pre/post、逐文件 inventory pre/post、top-level
  roots、provenance 和 SHA 全 PASS；原 `/tmp` 内容未删除。

## DB-first 持久化与结构化 profile

- DB stored 全文 materialize 后再追加，未用短条目覆盖原文：project-status
  `647412 -> 648820` bytes、NPC `617933 -> 619192`、Yosys-STA
  `36747 -> 37966`、known-issues `529719 -> 531510`；四次
  `update-stored --refresh-shim` 均 PASS。
- `snapshot-stored` 写回 rehydratable backup；`audit-db-first` 为
  candidates=5439、stored=5481、materialized=5275、shims=21，PASS。
- 主 task-run 原始 evidence 共登记 2140 assets，生成 `evidence-index.md`；长日志只存
  路径、hash、marker 与 bounded 摘要，不把全文塞入 DB。
- `npc-dev` profile 展开 5 个节点：software-flow、npc-sim、npc-single、npc-soc、
  npc-rv64 全 PASS；结构化 completed report、context brief、profile resolve、manifest、
  dispatch log 与 evidence index 位于
  `.github/task-runs/2026-07-13-2026-07-13-rv64-t3i-drain-retire-redundancy-final/`。
  该 profile 只证明开发环境合同，不替代本报告的功能/STA 证据。

## 审查者裁决

实现者证据证明 T3I 的功能、周期、结构和定向路径合同闭合。审查者优先寻找的五类
假绿（runner、proof、错误 liberty、无效 hierarchy pin、用户脏输入）均已用负向牙齿或
provenance 关闭。唯一未闭合的是父目标本身：fresh WNS 仍为 `-9.38 ns`。因此 T3I 可作为
独立 checkpoint 提交，但父 goal 不能完成，必须继续 T3J 及后续架构优化。
