# fence.i / SMC (#111 #3B) 修复方案 + Step A 证据

> task-run 证据。2026-07-05。confirmed-bug: fence.i 纯译码 no-op、无 flush 无重取,SMC 静默错执。
> workflow wf_f9bb3337 落实(sfence-template agent 失效但内容被 fence.i 修法 agent 覆盖,无影响)。

## Step A 证据(已实测,SMC 微测 agent)

root cause 三点, 已代码坐实:
1) fence.i = 纯 no-op: DecodeUnit.v:782-787 仅置 CTRL_FENCE_BIT (define.v:592 注 "当前实现视为合法 no-op"); 全仓 grep 无任何 fence 在 retire 触发 flush/redirect。fence.i 不 flush 流水。
2) store->ifetch 唯一相干机制在 NpcCoreTop.v:160-162: ooo_icache_invalidate_valid_w = mem0 store fire, 只失效 OooFetchPacketCache (vsrc/cache/OooFetchPacketCache.v 的 valid 位), 绝不 flush 流水/ROB。=> 已离开取指级、进了 ROB 的陈旧目标 uop 无任何保护。
3) 结论: 直线 fall-through 上、紧邻 fence.i 的 SMC 目标 L 会被宽/流水取指以旧字节译码进 ROB(store 尚未写回内存), store fire 只失效 cache(L 早已离开取指), fence.i 又不 flush => 陈旧 L 直接提交, 与 NEMU(每步新鲜取指)发散。

为何既有用例测不到本核缺口: 二者都经间接 jalr 到达被改写代码, 目标在 store 退休后才取指, 单靠 cache 失效即够, 与 fence.i 是否 flush 无关:
- riscv-tests: isa/rv64ui/fence_i.S (jalr t1,a5,0 跳到 .data 里的 2f/3f)
- cpu-tests: tests/fence-i.c (函数指针 fn() = jalr 到 code_buf)
两者当前 DUT 均 PASS (eval/results/*/riscv.log: PASS rv64ui-p-fence_i)。
答问4: 是, riscv-tests 有 fence_i 且确实测 SMC, 但它(和 AM fence-i.c 一样)测的是 "store 后 cache 相干", 测不到 "陈旧 uop 已在 ROB" 这条真缺口。

实测发散 (修前 DUT vs NEMM 参考), difftest.cpp:205-206:
  [npc-diff] mismatch at dut commit pc=0x000000008000002c inst=0x00150513
  [npc-diff] x10 ref=0x0000000000000066 dut=0x0000000000000065
即目标 L(0x2c, 与 fence.i@0x28 同一 8B 取指包)DUT 提交了陈旧 0x00150513(addi a0,a0,1)得 a0=101=0x65; store 明明在 0x20 已把 0x00250513 写入 0x2c; NEMU 取到新字节 addi a0,a0,2 得 a0=102=0x66。bug 现形。

### 微测与复现
- 文件: am-kernels/tests/cpu-tests/tests/smc-fencei-trigger.c(已在工作区)
- 实测发散(修前): 已实跑并证明发散(非纸面推演):
1) 开 difftest 重建 NPC: cd npc/rv64; sed -i 's/^# CONFIG_NPC_DIFFTEST is not set/CONFIG_NPC_DIFFTEST=y/' .config; <nemu>/tools/kconfig/build/conf --syncconfig Kconfig; make -j8 default
2) 建/校 NEMU ref .so(备份 nemu/.config!): cp nemu/.config /tmp/bak; make -C npc/rv64 difftest-ref; cp /tmp/bak nemu/.config
3) 跑微测(difftest 默认开): cd am-kernels/tests/cpu-tests; AM_HOME=<abs> make ALL=smc-fencei-trigger run ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 NPC_RUN_ARGS="--no-progress --max-cycles 200000"
观测结果(修前, 已获得): 进程 Error 退出 + [smc-fencei-trigger] ***FAIL***; 日志含 [npc-diff] mismatch at dut commit pc=0x8000002c inst=0x00150513 与 x10 ref=0x66 dut=0x65; commit trace #21=sw(0062a023 写 0x2c)、#23=fence.i(0000100f)、#24=pc0x2c 却提交陈旧 00150513。
修后期望: difftest 收敛, 两变体 check 通过, HIT GOOD TRAP。
收尾: 

## Step B 修法(镜像 sfence.vma, fence.i 修法 agent)

根因(#3B): fence.i 现在只译码成 no-op。DecodeUnit.v:782-788 把 FENCE 与 FENCE_I 一起塞成 CTRL_FENCE_BIT+CTRL_MISC_MEM_BIT+NEED_EXEC 的合法 no-op,流经 ROB 无任何副作用。真正的 icache 一致性完全依赖 NpcCoreTop.v:160-162 的"每 store fire 就 eager 失效取指包"启发式——足迹有限(OooFetchPacketCache.v:57-115 只覆盖 store±邻域窗口),且不撤销已被前端投机取入流水的 stale 指令,故 fence.i 语义(此后取指必见新码)不成立。

关键机会——sfence.vma 已经把 fence.i 需要的两件事都做全了:
1) 整块清取指 cache: OooMemoryRequestGate.v:61-62 mmu_flush_o = satp_write_commit || sfence_commit → NpcCoreTop ooo_mmu_flush_w → OooFetchAxiBridge.mmu_flush_i → OooFetchPacketCache.v:312 clear_i(mmu_flush_i) = valid_q 全清(:164-166)。
2) 前端 redirect 到 next_pc: 普通 pending_system(非 ecall/mret/irq)在退休拍走 OooFetchPcOutstandingSequencer.v:223-231 else 分支 next_fetch_pc_q <= pending_system_next_pc_i,并清 outstanding+discard 在飞取指响应。

sfence 走的是经典 pending_system stop→drain→commit 路(默认 ON、全绿),与 OOO_CSR_QUEUE_HEAD(默认 0、有死锁史)完全不同一条路。捕获是通用的: OooPendingDispatchArbiter.v:158-164 pending_system_capture_head0 = capture_base && dispatch0_system_w && !dispatch0_csr_w && !head0_csr_illegal,对任何"system 且非 CSR"的队头都成立。dispatch0_system_w 来自 facts[FACT_SYSTEM]=classify 的 system_raw_o(OooFetchHeadClassifyGate.v:149-150,202)。

结论: fence.i = wfi(纯 system→redirect 到 next_pc,无 CSR/trap 副作用) + 额外一个 mmu_flush 脉冲。只要把 fencei 折进 system_raw(使其 stop+被通用捕获),再加一个 pending_system_fencei_commit 把 mmu_flush 拉起,redirect 完全免费复用。fence.i 在 U/S/M 全合法,故绝不能复用 sfence_raw(会误触 U-illegal/TVM,见 classify:129-133),必须独立 fencei 轨。

空位: CTRL_FENCEI_BIT=50(define.v CTRL_BUS_W 现 50,:625);OOO_SLOT_FACT_FENCEI=41(OooSlotFacts.v FACTS_W 现 41,:47)。sfence 的 raw 信号 plumb 链: classify→OooFetchHeadPairGate.v:177/251→OooFrontend.v:212/224 端口 +639/681 连线→OooCoreTopGlue.v:251/270 wire +910/916 与 1162/1174 端口→OooControlPlane.v:78/84 输入→:534/544 喂 sequencer。fencei 轨逐点镜像。

### 精确改动清单(12 处)
- define.v:625 CTRL_BUS_W 50→51;紧接 :624 新增 CTRL_FENCEI_BIT=50
- OooSlotFacts.v:46 之后新增 OOO_SLOT_FACT_FENCEI=41;:47 OOO_SLOT_FACTS_W 41→42
- DecodeUnit.v:782-788 拆分:FENCE(funct3=000)保持旧 no-op 臂;FENCE_I(funct3=001)改设 CTRL_FENCEI_BIT+CTRL_MISC_MEM_BIT(不设 NEED_EXEC,作 stop 类退休);此臂用 OOO_FENCEI_TRUE_FLUSH ifdef 门控,flag OFF 回落旧 CTRL_FENCE_BIT no-op=零回归
- OooFetchHeadClassifyGate.v:新增 output fencei_raw_o;:127 后加 assign fencei_raw_o = ctrl_legal_w && ctrl_i[CTRL_FENCEI_BIT];:150 system_raw_o 末尾 || fencei_raw_o;:199 后加 facts_o[OOO_SLOT_FACT_FENCEI]=fencei_raw_o。注意:不要加进 priv_system_illegal(fence.i 全特权合法)
- OooFetchHeadPairGate.v:58/101 加 output head0_fencei_raw_o/head1_fencei_raw_o;:177/:251 子实例连 .fencei_raw_o(...)
- OooFrontend.v:212/224 加 output head0_fencei_raw_w/head1_fencei_raw_w;:639/:681 连 .head0_fencei_raw_o/.head1_fencei_raw_o
- OooCoreTopGlue.v:251/270 旁新增 wire head0_fencei_raw_w/head1_fencei_raw_w;frontend 实例(~:910/916)与 controlplane 实例(~:1162/1174)各加端口透传
- OooPendingSystemSequencer.v:新增 input capture_head0_fencei_i/capture_lane1_fencei_i、output fencei_o、reg fencei_q;rst(:72)/clear(:86)/capture_irq(:95)三处 fencei_q<=0;capture_head0(:109)fencei_q<=capture_head0_fencei_i;capture_lane1(:123)fencei_q<=capture_lane1_fencei_i;末尾 assign fencei_o=fencei_q
- OooControlPlane.v:78/84 加 input head0_fencei_raw_w/head1_fencei_raw_w;新增 output pending_system_fencei_commit_w;:234 旁加 wire pending_system_fencei_q;sequencer 实例(:529-548)加 .capture_head0_fencei_i(head0_fencei_raw_w)/.capture_lane1_fencei_i(head1_fencei_raw_w)/.fencei_o(pending_system_fencei_q);新增 assign pending_system_fencei_commit_w = stop_pending_q && drain_complete_w && pending_system_q && pending_system_fencei_q(镜像 CsrAccessRequestMux.v:84-86 的 sfence_commit)
- OooMemoryRequestGate.v:7 后加 input pending_system_fencei_commit_i;:61-62 mmu_flush_o 末尾 || pending_system_fencei_commit_i
- OooMemoryAccess.v:23 后加 input pending_system_fencei_commit_w;:43 旁子实例加 .pending_system_fencei_commit_i(pending_system_fencei_commit_w);OooCoreTopGlue.v 对应实例透传 pending_system_fencei_commit_w(与 sfence_commit_w 同处)
- redirect 侧无需改动:fence.i 是通用 pending_system(非 ecall/mret/irq)→ OooFetchPcOutstandingSequencer.v:230-231 else 分支自动 next_fetch_pc<=pending_system_next_pc,并清 outstanding

### 代码片段


### serialize 死锁风险评估
serialize 死锁风险: 低/可控。死锁史(serialize-at-retire-flush-lsu-obstacle)专属 OOO_CSR_QUEUE_HEAD=1——它把 CSR 保留在 ROB 队头(age=0)同时要求 mem 静默,younger-store 与队头形成循环依赖。本修法完全不碰那条路:fence.i 走的是 sfence.vma 同款经典 pending_system stop 路(默认 ON、riscv-tests/Linux 全绿)。机理:fence.i 折进 system_raw→stop_raw,停前端(不再 dispatch)→backend_drained(含 mem_retire_quiet_i,SQ 全排空、老 store 已落存)→通用 capture_head0 收入 pending_system→退休拍 fencei_commit 拉 mmu_flush + redirect。没有 younger store(前端已停),不存在队头↔younger 循环。这正是"更轻的替代"本身:fence.i 无架构状态写,pending_system_csr 恒 0,CsrAccessRequestMux 不发 csr_access(:74-78 无 fence.i 项),只触发 mmu_flush + redirect——即"清 icache + redirect,不进 CSR 序列化",与"镜像 sfence"在实现上收敛为同一条(sfence 减 TLB、加 icache 全清,而 icache 全清 mmu_flush 本就做)。

需核对的两个正确性点(非死锁): (1) fence.i commit 与 younger-branch-mispredict 同拍互斥——本核契约 INV-3(ControlPlane:755-778)只护 head0_csr_commit;fencei_commit 因走 drain(younger 已排空)同样天然互斥,建议顺带纳入该断言覆盖。(2) 顺序保证:老 store 必须在 fence.i 退休前全局可见——drain 已保证 SQ 空 + mem_retire_quiet,且 NpcCoreTop:160 每 store fire eager 失效 + fence.i 全块清双保险,充分。

替代方案权衡:另一条"更轻"的思路是让 fence.i 照旧进 ROB、只在 commit 拍旁路一个 flush 脉冲(不 stop、不 drain)。判否——本核没有给普通 ROB 指令的退休 redirect 通道(redirect owner 只有 pending_system/branch/jump),新建通道工作量与风险都远大于复用 pending_system;且不 drain 无法保证老 store 已可见,语义不全。故复用 pending_system(即本方案)反而是最轻且唯一 sound 的落点。

### 验证
flag-gate 建议: 新增 OOO_FENCEI_TRUE_FLUSH,初始默认 1'b0(合入即零回归,fence.i 仍走旧 no-op),验证通过后翻 1'b1。因它复用默认 ON 的 sfence 经典路(非 OOO_CSR_QUEUE_HEAD 风险路),验证成本远低于 CSR 队头化;但遵循本核'对抗验证别自作主张加固'与既有 flag 惯例,仍先 gate 做 A/B。

验证顺序: (1) flag OFF 全回归=纯基线(riscv-tests 355/0、CoreMark 0xfcaf、AM、Linux-mini 应逐位不变,证明零回归)。(2) flag ON 跑 riscv-tests 的 fence_i 专项(rv64ui-p/v-fence_i,自改码测试,当前#3B 缺口的正靶),期望由 eager-invalidate 侥幸过渡到真通过;并复跑 riscv-tests 全套 + CoreMark(10 迭代)+ AM + sbi/linux-mini,difftest 对 NEMU 逐指令。(3) 波形/commitwatch 免重编确认 fence.i 退休拍: mmu_flush 拉高一拍、valid_q 全清、next_fetch_pc=pc+4、outstanding 清、无 CSR 写。

CPI 代价: fence.i 现在=整机后端 drain + 前端重启 + 取指包全清,是真序列化屏障(架构本义)。CoreMark/riscv-tests 里 fence.i 近乎不出现→CPI 影响≈0。高频场景仅 JIT/动态链接器/模块加载(每次 fence.i≈后端 drain 深度 + 重取延迟,数十拍气泡)。这是 fence.i 语义的固有代价,可接受;若某工作负载 fence.i 过密,后续可退化为'只清命中足迹+redirect'的精确版优化,但当前正确性优先,全清最 sound。