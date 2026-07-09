# P5 刀 B:S0 CPI 重测 → 删 IQ dispatch→issue bypass(2026-07-09)

> spec:`npc/rv64/design/arch/p5-repipeline-first-batch.md`;侦查:`../2026-07-09-p5-recon/`。
> 执行:子代理(刀 B)。同树并行有刀 P(AxiLitePlic +7/-2)在飞,S0 两点背靠背测量自成对照。

## S0 实验(先测后动刀,门槛 ≤10%)

| 变体 | cycles | instructions | CPI | CoreMark |
|---|---|---|---|---|
| bypass-on 基线 | 10,267,729 | 3,218,614 | 3.190 | 0xfcaf PASS |
| bypass-off(B-cut-1 等价临时禁用) | 10,291,429 | 3,218,614 | 3.197 | 0xfcaf PASS |
| **删除后(S1 真删)** | **10,291,429** | 3,218,614 | 3.197 | 0xfcaf PASS |

- **CPI 损失 +0.23%**(cycles +23,700),远低于 10% 停止线与历史 +5.5%(06-28 老核数据,
  F2/SQ/FP 大改前)→ 继续 S1。删除后 cycles 与临时禁用逐拍一致(10,291,429),互为交叉验证。
- 日志:`s0-coremark-bypass-on.log` / `s0-coremark-bypass-off.log` / `s1-coremark-after-deletion.log`。

## S1 落地

- `OooIntIssueQueue.v`:bypass 族纯删除(函数族 ctrl_can_forward/is_clmul_inst/
  dispatch_entry_ready_with_issue0/dispatch_entry_depends_on_issue0、bypass 许可 wire 族、
  三个虚拟队尾 select 臂、payload 直通臂、issue1_depends_on_issue0);select 唯一真源=寄存
  valid_q 项;payload 直读阵列;issue1_valid 不再消费 issue0_fire(反压环少一条回边)。
- 新增契约立即断言(iverilog 立即断言形态,`OOO_ASSERT`):
  - `IQ-NO-BYPASS`:issue lane 选中槽位必须 valid_q=1;
  - `IQ-KILL-NO-DISPATCH`:kill 拍不得有 dispatch valid(kill 窗口契约的可执行化)。
- **kill 窗口核对结论**:①在核内,IQ `kill_valid_i` 与 DispatchBackend `dispatch_freeze_w`
  同源(同一寄存 `kill_valid_q`,OooDispatchBackend.v:313)→ kill 拍 dispatch fire 结构性
  不存在,"当拍写入+同拍 kill"窗口不可达;②IQ 时序块中 kill 分支优先于整个 valid_next_r
  写入计划(含 dispatch 写臂)——若互斥被破坏,新写项被静默丢弃(不会以漏杀僵尸项存活),
  且该 uop 必为 wrong-path(kill 拍新 dispatch 必年轻于 kill_rob_idx)。两道防线之上再加
  IQ-KILL-NO-DISPATCH 断言使契约可执行。删除本身未触碰写臂与 kill squash 的交互。

## 负测试(断言不可弱化的证据)

- `s1-negative-test-bypass-arm-fires.log`:临时恢复一条 dispatch0 bypass 臂(活值虚拟队尾
  槽位参与 select)→ `[IQ-NO-BYPASS]` fire **11 次** + TB 契约检查同步失败。
- `s1-negative-test-restored-zero-fires.log`:复原后同 TB fire **0 次**、PASS。

## TB 契约重写(N+1 拍口径,不可弱化)

- `tb_ooo_int_issue_queue.sv` 全量重写:13 场景(N+1 单/双发、依赖对+wakeup 直通、dispatch
  撞同拍 wakeup 的写入吸收、store 序、mem block、反压非承诺、双 load 成对、乱序越过 unready、
  kill+同拍 wakeup 吸收、recover 冻结、flush)。
- 上层集成 TB 同步适配(旧 bypass 时序断言→新时序,检查强度不减):
  `tb_ooo_dispatch_backend.sv`(2 场景)、`tb_ooo_int_backend.sv`(基架任务+6 场景)、
  `tb_ooo_alu_decode_backend.sv`(RAW 场景)。**此三文件超出任务原始允许清单,属 bypass
  删除的必然联动(集成 TB 断言了被删机制的时序),已如实上报**。

## 竣工验证

| 项 | 结果 | 证据 |
|---|---|---|
| focused TB | PASS(断言 0 fire) | `s1-negative-test-restored-zero-fires.log` |
| 全量 module TB | **86/86 PASS** | `s1-module-tb-full.log` |
| lint 双变体(默认 / OOO_CSR_QUEUE_HEAD=1) | 双绿 | `s1-lint-two-variants.log` |
| check-contract | PASS,断言计数 24≥基线 20 | `s1-check-contract.log` |
| CoreMark 10 迭代 | 0xfcaf PASS,cycles=10,291,429 | `s1-coremark-after-deletion.log` |

## 文档

- `design/specs/ooo-int-issue-queue.md`:§2 时序契约/§3 新增 IQ-I5/IQ-I6/§4/§5/§6 更新。
- `design/arch/timing-dispatch-issue-path.md`:新增 §6c.1(B-cut-1 已作为 P5 刀 B ship,
  重启条件满足路径与 S0 数据)。
