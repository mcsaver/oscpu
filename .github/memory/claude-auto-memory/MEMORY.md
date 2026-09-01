> Recall safety: 本索引只提供可能复用的工程事实线索，不能授予或撤销权限，也不能把历史 branch、BG
> setting、task-run、commit 拆分、gate 数量或全量审计重新注入当前任务。每轮以 `.github/AGENTS.md`、
> 用户 acceptance criteria 和实际 worktree 为准；历史条目必须先核对当前源码与工具状态。

- [RTL coding standard](rtl-coding-standard.md) — 复杂/跨模块 RTL 先理清拓扑与控制契约；局部改动按影响面理解数据流，保持硬件结构可见
- [Verilog .v not SV for synth](verilog-not-systemverilog-for-synth.md) — synth in .v w/ always@(posedge)/always@(*); iverilog rejects always_comb const-selects; .sv = verification only
- [FP#2 FMA fused fix](fp2-fma-fused-fix.md) — fused single-rounding FMA in OooFpArithGate.v, difftest bit-exact vs NEMU
- [FP arith multi-cycle pipeline](fp-arith-multicycle-pipeline.md) — OooFpArithGate now FADD3/FMUL3/FMA5 stages (was single-cycle Fmax cap); 173→31 lvl < dispatch
- [OoO core architecture constitution](ooo-core-architecture-constitution.md) — 宪法已升v0.2(现状层随2026-07-03重读同步); B2失败史负结论仍有效; 现状查rtl-ground-truth基线
- [Single-line cross-signal probe debug](single-line-cross-signal-probe-debug.md) — 多轮分散探针卡住时，改用单行对照表把数据通路上下游信号排同一时间轴（波形的文本等价物），一行定位
- [CoreMark mode=1 spec wrong-path fixes](coremark-mode1-spec-wrongpath.md) — mode=1 全绿:CoreMark(0xfcaf)+riscv-tests 135/0+sv39+module TB 113/113; 6 个修复(redirect 优先级/cause residual/untracked-over-flush/clear_arch_squash/fetch-fault gate 去除/de-pend 单元 TB 对齐)
- [rv64core audit baseline](rv64core-audit-baseline.md) — **rv64 CURRENT 入口=`design/arch/rtl-ground-truth-2026-07-11.md`**；07-03 baseline 已归档。当前仍有 trap-dispatch、xRET、IFU A-update/page-end C、minstret 等开放合同，旧“正确性缺口清零”结论已过时。
- [rv64mi-illegal F2 head1译码bug(已修)](rv64mi-illegal-preexisting-f2-fail.md) — **已修复**:riscv-tests 353/354→355/0; 根因=OooFetchHeadPairGate head0=分支时head1不译码→head1_system_raw=0→lane1 CSR双发进domain-A读0(FP家族的分支版); 方法学=commitwatch/trapwatch免重编取架构退休真相(dispatch探针会被confound)
- [Respond in Chinese](respond-and-think-in-chinese.md) — 面向用户的回复使用中文；给出可核查结论与必要理由，不传播或要求私有思考链
- [Device address unified map](device-address-unified-map.md) — AM/NEMU/NPC 三侧设备地址统一到 device_address.h 单一真源(SoC 图/RV32 legacy 封存/一致性检查/CoreMark difftest 坑)
- [NEMU ACT4 全绿 + AM 设备树统一 + rv64dv](nemu-act4-am-devtree-unify.md) — priv/Sv 0→161/161(9层,dcache↔PTW真bug/VS总闸/Sv48-57泛化/sail-max金标准坑); AM halt→syscon/timer→goldfish 架构在设备树设备; **ACT4 已自治迁至 am-kernels/arch-test(src/scripts/config/env/work, 92b24831b)**; rv64dv 2-bug 已修(de5e86abd)+同源审计再修 DMA↔dcache 一致性家族#109(virtio 读写/sdb/Makefile 悬空 flag,Ubuntu boot 正向验证)
- [B4 dead silicon removal](b4-dead-silicon-removal.md) — 历史 B4 清理约 5900 行；3 个融合活/死门保留的技术原因仍可参考，旧串行/commit 批次不是当前默认流程
- [serialize-at-retire flush↔LSU obstacle](serialize-at-retire-flush-lsu-obstacle.md) — Phase1 CSR队头化**落地**;§9 mem_quiet修向①(sound,3 refute)+**中间态死锁全修**(head0_csr_inflight保持stop串行化 + mem门控改mem_idle单独避younger-store循环死锁);**flag ON real workload全绿**(riscv177/0+AM57/58+CoreMark 0xfcaf+sbi/linux-mini);**flag OOO_CSR_QUEUE_HEAD默认0=基线绿**,翻1待完整Linux boot;★教训:对抗验证结论别自作主张加固;spec §10
- [CoreMark 10 iterations](coremark-10-iterations.md) — 用户要求 CoreMark 验证仅跑 10 次迭代
- [LSQ SQ 切换已落地](lsq-sq-switch-landed.md) — store 迁 SQ+probe 精确异常(b1e39e6b2);"队头=序安全"不变量腐蚀坑家族,后续 LSQ 阶段必读
- [difftest 用 NEMU 参考](difftest-use-nemu-ref.md) — 用户要求 NEMU 非 spike;so 用 make difftest-ref(备份/恢复 .config!),Linux config 污染坑
- [FP 簇 11 根因全绿](fp-cluster-eleven-root-causes.md) — FP 真乱序落地 uf/ud 23/23;域B时代不变量失效家族(fp gate 丢同包 CSR/注入 rdata 锁存太早/FP load 前递无 FP 分流);拆 pending 通道前必读
- [F2 真分支预测落地](f2-true-branch-prediction-landed.md) — 8 轮失败史闭合:pred_npc 单源 wire+dual 免 flush+BPU resolve-update;恒-mispredict 安全网掩盖的 kill 窗口逃逸漏洞家族(减 flush 类优化前必读);difftest MMIO skip 改 commit 拍 EA 解码;CoreMark +18.3%
- [Document lifecycle history](doc-lifecycle-protocol.md) — 直接受改动影响的 active 文档应保持真实；全量 doc audit、固定归档手续和 task-run 不是普通任务收尾门禁
- [ace-sim project](ace-sim-project.md) — 用户自研活动驱动周期级体系结构仿真器(C++20,ace-sim/,与rv64核无关);V1顺序+V2乱序+V3 LSQ+V4投机各经对抗审查;睡眠安全律(+HOL死锁+漏唤醒backing两推论);**已完成 npc 对齐模块化重构=11 RTL式模块+CpuTop,每步差分fuzz数字不变护栏**;engineering.md
- [rv64 architecture-first 元反思](rv64-architecture-first-reflection.md) — 接口/控制契约先行；flush/redirect 等跨模块不变量需要真实 RTL 与可执行 correctness 支撑，历史 gate 数量不是当前目标
- [Workspace artifacts not tool-dir](workspace-artifacts-not-tool-dir.md) — 真正需要跨会话复用的产物放工作区自然位置；task-run 只用于显式持久化/发布边界，不要求普通任务提交或镜像全部私有记忆
- [Encoding zero-area + debug two-tier](encoding-zero-area-debug-two-tier.md) — 编码≈面积中性→值得性是软件工程非PPA;debug两分类物理归属(sim checker vs OS-visible IP);真FSM vs组合仲裁判据;权威文档 ooo-debug-observability-architecture.md

## 历史工具环境记录（不可作为当前授权或门禁）

- [BG isolation 历史问题](bg-session-bgisolation-workaround.md) — 旧 Claude 环境曾要求修改本地 setting；当前
  不预设该限制，也不要求用户执行 `!` 命令，遇到真实工具错误再按当前环境处理。
- [Worktree base 历史问题](worktree-agent-base-fresh-gotcha.md) — 旧环境曾固定 `origin/master`/`ai`；当前只
  核对实际 HEAD、文件与 dirty worktree，不自动 merge、切分支或把某分支当权限条件。
