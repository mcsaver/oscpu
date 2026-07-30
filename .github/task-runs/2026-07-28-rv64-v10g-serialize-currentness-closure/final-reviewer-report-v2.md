# SERIALIZE-G1 independent final review v2

RV64 RTL 结论｜对象=SERIALIZE-G1 queue-head CSR 与 pending SYSTEM/trap/exit 证据链｜周期/配置=design_id=sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897；OOO_CSR_QUEUE_HEAD=1；OOO_ASSERT=on/off｜TB/EDA 观测=两模式各 3 committed/2 selective-kill、2/2 C2 负向拒绝、SYSTEM 3/3 baseline+14/14 mutation、current replay 26/26 PASS｜范围=PASS

裁定：`APPROVED_FOR_CURRENT_SCOPE`；建议将 `SERIALIZE-G1` 从
`OPEN_PENDING_REVIEW` 更新为 `CLOSED`。未发现未解决的 RTL 反例。

- 产品绑定：合同 SHA
  `b1316f46171145a8265393d29a0069a9b12f0eb61ae8f13e68b43d8c21aa1af2`
  正确；manifest、Makefile 消费链和 `define.v` fallback 均为 queue-head=1。
  关键 summary 与 replay 文件的 SHA-256 全部匹配 closure candidate，当前设计
  ID 无漂移。
- queue-head 原始周期：assert/release 日志均直接记录三条事务的
  `birth=1 → C0 commit/barrier/CsrFile request=1 → C1 apply=1 → C2 quiet`；
  branch、JALR 两条 wrong-path CSR 均为
  `birth=1/selective_kill=1/C0=0/C1=0`。计数来自 raw pulse 和 owner
  scoreboard，不依赖 sticky seen-bit。
- C2 反例：typed-apply 生产 RTL 版本编译成功、仿真 `rc=1`，三次触发 C2
  repeat/unowned apply；CsrFile-request 版本编译成功、仿真 `rc=1`，三次观测
  request 从 1 变为 2，并触发 unowned/repeated request。后者是生产绑定等价的
  verification RTL wiring，不是 `NpcCoreTop.v` 源码 mutation；因此可证明当前
  oracle 对 CsrFile 边界敏感，但不能宣称“两份都是生产 RTL mutation”。
- split-domain：合法 non-FP head0 CSR 独占 queue-head；lane1/FP CSR 及
  ECALL/XRET/WFI/SFENCE/FENCEI/FENCE/IRQ/trap/exit 保持 pending/full-drain。
  lane1 SATP 产生 registered MMU pulse；head0 SATP 只走 queue-head CSR/flush，
  未伪造 pending-SYSTEM MMU pulse。产品矩阵为 3/3 baseline 与 14/14
  compile-success mutation 动态拒绝。
- trap/exit：相关 11 个生产 RTL 文件哈希与 V10D 证据一致，assert/release 各
  5/5、7/7 mutation 拒绝，并被本次 26-stage replay 重新纳入。standalone
  跨周期 trap→exit 未单独做对抗用例，但当前 terminal priority、holder 与 run
  gate 方程使 raw exit 在 trap owner 存活时不可达；这是非阻断假设，不是已发现
  反例。
- A3 边界：原始 `FAIL rc=1` 保留；5,071,521,696 cycles、1,223,536,213
  commits、6/6 terminal exactly-once/ordered 和空 RTL assertion 文件仅支持
  `execution_state=COMPLETE`、`oracle_state=INVALID`。冻结输入 checker replay
  PASS 不能改写 A3 发布状态；A4 `TERM/rc=143` 也不是 PASS。
- 非声明：本裁定不关闭 Phase2–5，不代表 architecture freeze；
  `ARCH_STABLE=GAP`、PPA `UNQUALIFIED` 保持不变。源码中少量“默认=0”陈旧注释
  属于 non-blocking documentation GAP，后续文档清理即可。

最小后续动作：只需把账本、ROADMAP/memory/task-run 中的 `SERIALIZE-G1` 状态
同步为 `CLOSED`，保留上述非声明；无需新增高成本运行。任何改变当前 RTL design
ID 的后续修改必须重新绑定证据。

本节点未写入文件、未启动残留工程进程；只读命令已停止，WSL shell ownership
已归还 `/root`。
