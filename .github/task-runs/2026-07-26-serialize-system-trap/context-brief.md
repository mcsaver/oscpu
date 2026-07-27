# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: rv64-linux
- `terms`: serialize system trap
- `focus_scope`: non-history
- `token_estimate`: 2371 / 2400

## Profile Suggestions
- `rv64-linux` score=18 matched=requested-profile, system command=`scripts/agent-e2e.sh --profile rv64-linux`
- `agent-system` score=6 matched=system command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=2 matched=system command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=2 matched=system, trap command=`scripts/agent-e2e.sh --profile nemu`
- `npc` score=2 matched=system, trap command=`scripts/agent-e2e.sh --profile npc`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile rv64-linux`

## Missing Paths
- `.github/memory/modules/rv64-linux.md`

## Chunks

### .github/AGENTS.md#chunk-0001

- `kind`: agent-rule
- `lines`: 1-15
- `tokens`: 328
- `heading`: AGENTS.md — YSYX 工作区 Agent 通用工作流规范
- `summary`: > 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent / > （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等） / > 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。 / > / > 与本文件协作的入口文件分两类： / > 根...

# AGENTS.md — YSYX 工作区 Agent 通用工作流规范

> 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent
> （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等）
> 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。
>
> 与本文件协作的入口文件分两类：
> 根目录 `AGENTS.md` / 其他兼容入口文件是兼容 shim，保留最小可执行契约并回链本文件；
> `.github/copilot-instructions.md` 不是薄指针，而是 GitHub Copilot 专属工程级补充规则。
> 多份文件出现重叠时，以本文件作为跨 agent 通用基线；Copilot 的额外构建、调试与记录细则再叠加读取 `copilot-instructions.md`。
>
> 当前阶段的目标是“工程规则自动发现与会话恢复”，不是“插件式 UI 扩展”。因此本仓库优先补齐兼容 shim，不主动引入 `.codex-plugin/` 或 `.agents/plugins/marketplace.json`。

---

### .github/e2e/profiles/rv64-linux.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-8
- `tokens`: 413
- `heading`: rv64-linux.tsv
- `summary`: @include|discovery|||| / npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在 / npc-rv64-sv39-sret-u-mode|npc|e2e_npc_rv64_sv39_sret_u_mode|npc|npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB|NPC RV64 SRET 到 U-...

@include|discovery||||
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在
npc-rv64-sv39-sret-u-mode|npc|e2e_npc_rv64_sv39_sret_u_mode|npc|npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB|NPC RV64 SRET 到 U-mode、U 页取指、U ecall、U load page fault 回 S 并 sret 回 U 的回归 PASS
npc-rv64-linux-focused-smokes|npc|e2e_npc_rv64_linux_focused_smokes|npc|Linux/tools SRET/Sv39/pagefault/virtio focused smokes on NPC|NPC RV64 Linux focused smokes 覆盖 SRET/Sv39、ret_from_exception、U pagefault 与 virtio-blk
npc-rv64-uart-rx-smoke|npc|e2e_npc_rv64_uart_rx_smoke|npc|NPC 16550 UART RX register + gated DPI injection smoke|NPC RV64 UART RX 支持 RBR/LSR/IIR/IER[0]，并支持 NPC_UART_RX_WAIT 按 guest 输出 marker 释放宿主输入
npc-rv64-linux-rootfs-mount-smoke|npc|e2e_npc_rv64_linux_rootfs_mount_smoke|npc|Ubuntu rootfs mount + systemd banner smoke on NPC|NPC RV64 Ubuntu rootfs 至少完成 ttyS0 console、virtio-blk、EXT4/VFS root mount，并进入 systemd PID1 打印 Ubuntu 22.04 banner
npc-rv64-systemd-guest-check-contract|npc|e2e_npc_rv64_systemd_guest_check_contract|npc|Linux systemd guest checker + isolated writable rootfs work image|NPC RV64 guest checker具备 UART/autocheck/systemd-strict 入口，并将可写 block image 隔离到每轮工作副本
rv64-linux-contract|rv64-linux|e2e_rv64_linux_contract|rv64-linux|Linux Makefile/env/platform/instructions|RV64 Linux/Ubuntu 合约入口存在

### .github/memory/claude-auto-memory/serialize-at-retire-flush-lsu-obstacle.md#chunk-0001

- `kind`: memory
- `lines`: 1-53
- `tokens`: 1333
- `heading`: serialize-at-retire-flush-lsu-obstacle.md
- `summary`: --- / name: serialize-at-retire-flush-lsu-obstacle / description: serialize-at-retire Phase1 落地;§9 mem_quiet+中间态死锁全修(flag ON real workload 全绿);flag-gated OFF 待 Linux / metadata: / node_type: memory / type: project / originSessionId: 0f469065-9395-43a3-bc78-...

---
name: serialize-at-retire-flush-lsu-obstacle
description: serialize-at-retire Phase1 落地;§9 mem_quiet+中间态死锁全修(flag ON real workload 全绿);flag-gated OFF 待 Linux
metadata:
  node_type: memory
  type: project
  originSessionId: 0f469065-9395-43a3-bc78-2c6ef32f80ca
---

rv64 OoO 核 **serialize-at-retire**（宪法 §8.4 域 B 拆除最后一步）Phase1（CSR 队头化）。
> 生命周期更新（2026-07-07）：下文记录的是 2026-07-05 当时状态；其中“glue TB 需 CsrFile stub/
> MODE_ECALL flag ON 失败”已关闭。当前 `tb_ooo_core_top_glue_csr.svh` 的 CsrFile stub 已接入
> `head0_csr_commit_w`，`tb_ooo_core_top_glue` 在 `-DOOO_CSR_QUEUE_HEAD=1` 下 PASS。2026-07-07 又补
> flag-ON focused Linux smokes（SRET/Sv39/pagefault/virtio-blk）并修正 virtio-blk DPI 写入口 wstrb 生命周期。
> 剩余前置为完整 rootfs boot 与 `-v-`/full-state difftest。

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

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-2
- `tokens`: 8
- `heading`: YSYX 项目状态总览
- `summary`: YSYX 项目状态总览

# YSYX 项目状态总览

### .github/memory/known-issues.md#chunk-0001

- `kind`: memory
- `lines`: 1-4
- `tokens`: 35
- `heading`: 已知问题与调试历史
- `summary`: > 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

### .github/e2e/README.md#chunk-0001

- `kind`: markdown
- `lines`: 1-2
- `tokens`: 6
- `heading`: Agent E2E Profiles
- `summary`: Agent E2E Profiles

# Agent E2E Profiles

### .github/e2e/modules/rv64-linux.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-12
- `tokens`: 237
- `heading`: rv64-linux E2E Contract
- `summary`: - **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。 / - **上游**: npc/rv64 core、Linux env、device contracts。 / - **下游**: linux-device、display-vga、verilator-tapeout。 / - **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 i...

# rv64-linux E2E Contract

- **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。
- **上游**: npc/rv64 core、Linux env、device contracts。
- **下游**: linux-device、display-vga、verilator-tapeout。
- **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 instructions。
- **L1 gate**: 后续按 `rv64-ubuntu-probe-loop` 跑 QEMU/NPC probe。
- **证据**: `/init`、`/etc/os-release`、`/bin/sh`、rootfs mount、poweroff，以及只读模板/
  每轮可写 block-image 副本的 pre/post SHA-256；NPC systemd 严格事务由
  `Linux/scripts/npc_systemd_transaction_evidence.py` 对 preflight、autocheck、strict
  三个有序周期窗口做整行 marker 原始计数，并写出绑定 console SHA 的 JSON。
- **升级路线**: 按 gate 分层生成机器可读 boot status。
