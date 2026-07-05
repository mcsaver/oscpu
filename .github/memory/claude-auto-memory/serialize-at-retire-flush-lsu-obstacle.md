---
name: serialize-at-retire-flush-lsu-obstacle
description: serialize-at-retire Phase1 落地;§9 mem_quiet+中间态死锁全修(flag ON real workload 全绿);flag-gated OFF 待 Linux
metadata:
  node_type: memory
  type: project
  originSessionId: 0f469065-9395-43a3-bc78-2c6ef32f80ca
---

rv64 OoO 核 **serialize-at-retire**（宪法 §8.4 域 B 拆除最后一步）Phase1（CSR 队头化）。
**2026-07-05 进展：§9 mem-quiescence 修向① 已实现并落地(sound)，§4 核心验证成立，但暴露更深的中间态死锁。
全特性收在编译期 flag `OOO_CSR_QUEUE_HEAD`（默认 0=基线，树保持绿）。** spec 权威记录见
`npc/rv64/design/arch/serialize-at-retire-phase1.md §10`。

**§9 修向① 已解（原障碍=serial_flush→lsu_axi_abort→在飞 store 卡 ROB→drain 死锁）**：门控
head0-CSR commit+serial_flush 在 **`mem_idle && mem_retire_quiet`**（二者：mem_idle=miq_empty 覆盖 younger
在飞 probe/load/drain；mem_retire_quiet=sq_empty 覆盖 committed 未 drain 的更老 store）。**落点=OooRob
commit0_fire 的 loop-free 门控**（用 ROB 内部 head0_is_csr_w 从 inst_q/done/exception 判，不依赖 commit_ready
→ 避开 core_commit0_csr→commit0_valid→commit_ready 组合环；ControlPlane commit_ready mask 会成环）。3 个 refute
agent 对抗验证全 REFUTED=False(high)。

**§4 落地中修的 4 个真 bug（flag ON 生效，均已在树）**：①commit1-CSR 漏 head0_csr_commit(CSR 经 commit1 退休
时只看 commit0 的 head0_csr_commit 漏掉→mtvec 静默不写)→OooRob commit1 加 !head0_is_csr&&!head1_is_csr;
②pending_system_csr_q **全局**抑制(head0-CSR 与 lane1-drain-CSR 共存时后者 pend_csr_q=1 误抑制前者)→改用
!pending_system_csr_commit_w(pc 精确匹配那条);③FP CSR(fcsr/fflags/frm)未排除→serial_flush squash 在飞 FP→
fdiv/fmadd 挂→frontend+arbiter dispatch0_csr_w 排除 FP CSR;④serial_flush 未清 pending_system→arbiter clear 加。

**中间态死锁（父 spec"最脆弱中间态"）—— 2026-07-05 次轮已修(2 修, flag ON real workload 全绿)**：
①**两条 lane1-CSR 越序共存覆写单 pending**(带周期号探针: mtvec 更老在 ROB, younger mstatus 越过它被捕获; 根因=
head0-CSR 单发 pop 后不在 FIFO 头, dispatch0_system set 只 1 拍即被清→stop 不保持)→**修=head0_csr_inflight 锁存器**
(OooFrontend dispatch 置/commit·flush 清), 在飞期间强制 stop_pending=1(StopPendingSequencer 末尾保持臂,排除 commit/
trap 拍) 阻 younger 越序; ②**ecall-drain stuck-store(真 root)**→**门控错选 mem_idle&&mem_retire_quiet**: head0-CSR
在队头等 sq_empty, 但 SQ 有 younger uncommitted store(既不能 drain[未 committed]又不能 retire[被队头 CSR 挡])→循环
死锁→**修=门控只用 mem_idle(miq_empty)**(OooIntBackend; younger store probe 在 mem_idle 前完成、之后被 flush 掉,
不等 retire; refute:sq-flush agent 早证 mem_idle 单独够, 我加 sq_empty 反造死锁——★教训: 对抗验证给的结论别自作
主张"加固")。

**验证矩阵(2 修后)**：flag OFF(提交默认)=**精确基线**(module TB 82/82+lint0+riscv 177/0+AM 57/58,fp-difftest-probe
**预存在**失败与本工作无关); **flag ON=real workload 全绿**(riscv 177/0+AM 57/58+CoreMark 0xfcaf+sbi/linux-mini-boot/
sv39/misa-priv/最小 ecall); 仅 glue module TB MODE_ECALL 在 ON 失败=**TB 层限制**(OooCoreTopGlue 不含 CsrFile→mtvec
写不生效→ecall trap 到 0), **非核 bug**(同序列 NpcSimTop 含 CsrFile 正确 GOOD TRAP)。**默认仍 OFF**: 按 spec"最高危
路径须 Linux boot 护航", 完整内核 boot/difftest/riscv-355(-v-)未与 ON 跑 + glue TB 需 CsrFile stub; 集齐翻默认 1'b1。

**诊断方法学（复用）**：NPC_COMMITWATCH 取退休真相 + **带周期号**自插探针(MIDSTATE/CSRWRITE/CANRUN,ifdef 已移除)
逐层: csr_commit fire→head0_csr_commit→pending 转换→can_run blocker(OooFrontendRunGate)→stop owner; **最小复现序列
在 NpcSimTop 隔离**(vs glue module TB 无 CsrFile 误导)。AM `make run` 单测失败不使 make 退出非 0(fp-difftest-probe
预存在坑); difftest 未编入(需 CONFIG_NPC_DIFFTEST=y)。姊妹项 [[b4-dead-silicon-removal]]; LSU 家族坑 [[lsq-sq-switch-landed]]。
