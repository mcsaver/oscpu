# RV64 F1：XRET-G1 current-mode 合法性

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-xret-g1
- `task_slug`: rv64-f1-xret-g1
- `graph_template`: regression-debug-loop + npc-sim-regression
- `graph_mode`: static+dynamic
- `status`: completed
- `owner`: root + xret_f1_slice + xret_review
- `started_at`: 2026-07-12 10:43:00 +0800
- `updated_at`: 2026-07-12 11:16:55 +0800

## 任务目标与范围

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `goal`: 关闭 `XRET-G1`：MRET 只能在 M-mode 执行；SRET 在 U-mode 非法，且 TSR
  只拦截 S-mode SRET。
- `scope`: `DecodeUnit -> OooFetchHeadClassifyGate -> head0/lane1 pending trap -> CsrFile`；
  不改变合法 xRET 的 drain/redirect/状态恢复，不修改 CsrFile 状态机。

## Root cause

`OooFetchHeadClassifyGate` 已生成 MRET/SRET raw facts，也已检查 S-mode+TSR 的 SRET，
但 `priv_system_illegal_o` 漏掉 `MRET && priv!=M` 与 `SRET && priv==U`。下游 CsrFile
相信上游已判定合法，不再复查 current mode，因此非法 xRET 会被错误捕获为 system 请求。

## 接口合同冻结（RTL 阶段 0）

1. **握手**：classifier 为同拍纯组合 facts；无 valid/ready 状态。pending owner 只在既有
   capture 条件满足时接收一条事件。
2. **stall**：classifier 不持有事务；父级 FIFO/head owner 在 stop/drain 期间保持输入。
3. **flush/redirect/trap**：非法 xRET 同拍保留 xRET raw fact，但 `arch_trap` 必须抢占
   system/xRET capture；错误路径仍由既有 flush 清除。
4. **异常序**：MRET@S/U、SRET@U 形成 precise illegal-instruction，`tval` 为零扩展原指令；
   不得形成合法 mret/sret side effect 或普通 backend uop。
5. **访存序**：本刀不读写 SQ/MIQ/AXI，不改变任何已握手访存副作用。
6. **投机恢复/单一真源**：priv mode 与 TSR 只取自 CsrFile 架构状态；classifier 不保存镜像，
   CsrFile 只消费已过 classifier 的合法请求。

### 同拍优先级

| 条件 | classifier facts | pending owner | CsrFile / backend |
| --- | --- | --- | --- |
| MRET 且 `priv!=M` | `mret_raw=1, arch_trap=1` | arch trap 胜过 system | mret pulse=0，backend present=0 |
| SRET 且 `priv==U` | `sret_raw=1, arch_trap=1` | arch trap 胜过 system | sret pulse=0，backend present=0 |
| SRET 且 `priv==S && TSR` | 同上 | 同上 | 同上 |
| MRET@M / SRET@S+TSR0 / SRET@M | legal system fact | 既有 drain/xRET | 保持合法语义 |

## RTL 拓扑（RTL 前冻结）

- 不改端口、寄存器、FSM、pipeline 或 reset/flush 接线。
- 在 classifier 中新增两个 2-bit privilege compare：`mret_raw && priv!=M`、
  `sret_raw && priv==U`，与既有 privileged-illegal 源做浅 OR 汇合。
- 下游复用既有 `priv_system_illegal -> arch_trap -> pending trap` 单一链；不在 CsrFile
  复制第二份 legality decode。
- timing 边界只增加两个小比较器和 OR 输入；本功能刀不声称改善 5 ns STA。

## RED -> GREEN

### 旧 RTL RED

- 常驻 classifier ISA 矩阵加入 MRET@S/U、SRET@U，保留 MRET@M、SRET@S+TSR0/1、
  SRET@M+TSR1 正对照。
- 旧 RTL runner rc=1，精确 6 个失败：三类反例分别缺
  `priv_system_illegal` 与 `arch_trap`；其它检查通过。
- 原始日志：`npc/rv64/perf/results/20260712-xret-g1/red/logs/tb_ooo_fetch_head_classify_gate.log`。

### 实现与 integration GREEN

- classifier 仅加入两条 current-mode illegal predicate；CsrFile 不改 RTL。
- `tb_ooo_priv_system` 新增真实编码端到端场景：S-mode lane0 MRET、U-mode lane1 SRET。
  两者均检查 `mcause=2`、原 fault PC、`mtval=xRET encoding`、handler/return，且非法 xRET
  不得提交；sticky 直接监视 CsrFile mret/sret request 对非法 PC 恒为 0，排除
  arch-trap/system 双 owner 被 trap 优先级掩蔽的假绿；lane1 场景同时证明更老 lane0 ADDI 正常退休。
- focused 5/5 PASS：classifier、head pair、lane1 capture、pending dispatch、priv-system 整核 TB。

## 当前验证状态

- focused current RTL：5/5 PASS；最终当前 module 87/87 PASS。
- bundled core-regress（Verilator 5.051）：module/lint/build/AM/official 全部 PASS，
  177 tests attempted，`overall_rc=0`。其中 current-config AM 59/59 明确 Difftest OFF。
- 独立 default_defconfig Difftest-ON AM：runtime `Difftest: ON` 59 次、reference enabled
  59 次、59/59 PASS。退出 trap 后 NPC/NEMU 六配置文件与 backup 逐字节 MATCH。
- 配置恢复后执行 clean rebuild；fresh `add` smoke 明确打印 `Difftest: OFF` 且 1/1 PASS，
  证明当前 artifacts 与恢复后的 OFF 配置一致。
- structural：RTL style PASS；contract `current=35 baseline=35`；Verilator lint PASS。
- 独立 reviewer 两轮复核 privilege 矩阵、head0/lane1 trap 优先级、真实编码 integration 与
  CsrFile request sticky，最终无 blocker。
- memory 与 1001 个 raw asset 的 DB index 已更新；bounded `evidence-index.md` 保留关键哈希。
- `blockers`: 无。fresh npc-dev、strict guard、DB-first、Markdown coverage 与 artifact audit 均 PASS。
- `boundary`: XRET-G1 的关闭不等于全部 F1 功能合同闭合，也不等于 200 MHz 已达到；本刀无新 STA。

## 最终裁决

- `final_result`: XRET-G1 CLOSED；实现、真实编码集成、CsrFile request 边界、全量回归、
  Difftest/config artifact reconciliation、memory/task-run、独立 reviewer 与 strict guard 全部闭合。
- `next_step`: 先把 naive IQ FIFO 的活性反例写入 T3 合同，转向按类 registered-credit +
  PRF/AGU 后 age-aware memory reservation station；随后做功能/CPI/target-driven 5ns A/B。
