# RV64 OoO 核 · 架构演进路线图（living document）

> 本文件是 RV64 乱序核优化/重构的**主干文档**：记录当前已验证状态、架构再评估、
> 优先级 backlog 与专业化工作流。每轮迭代后按"迭代→深度再评估→据此修改"更新。
> 配套：评估系统 `eval/`，模块规范 `design/specs/`，架构规范 `design/arch/`，文献 `design/literature/`。

最近更新：2026-07-06（gate 数字/正确性状态/下一步决策同步到当前真相。
最新现状以 `.github/memory/project-status.md` 为准；`rtl-ground-truth-2026-07-03.md` 是 07-03 时点基线快照）

---

## 1. 当前已验证状态（三大 gate 全绿）
| gate | 结果 | 工具 |
| --- | --- | --- |
| 模块 testbench | 82/82 | iverilog（死硅删除后 TB 数从 112 降至 82） |
| 官方 riscv-tests（默认+特权） | 355/0 | tohost 协议 |
| AM cpu-tests | 59/0 | ebreak GOOD TRAP |

性能（AM 全量加权 CPI，含 PMP=真实场景）：**1.2638**（自禁缓存基线 3.7427 累计 **−66%**）。
真实代码：CoreMark CPI≈1.23（2026-07 LSQ SQ 切换后 10-iter；F2 收益待 domain-B 拆除变现）。

容量（`include/define.v`）：dual-issue / PRF 64 / ROB 16 / IQ 8 / Fetch FIFO 4。
**正确性缺口：清零**（fence.i/SMC #111 #3B 已修、翻默认 ON、全绿闭环 2026-07-05）。
**验证基础设施新增**：redirect 观测层三 checker（`vsrc/debug/`，旁挂零面积；范式见
`interface-contract-first.instructions.md`「外部抽象状态观测层」节）。

---

## 2. 已完成迭代
- **iter-0 回归修复**：核 PMP 规范性默认拒绝 S/U + AM 测试未配 PMP → 启动配 PMP(trm.c)修 9 项；
  sv39-ad-bits 改 SW 管理 A/D（核非 Svadu）修 1 项。基线 46/56→56/56。
- **iter-1 PMP 取指缓存**：PMP 一活动就禁用取指 cache → Linux/OpenSBI 下 ~2x 惩罚。改 PMP-grant 逐访问门控。
- **iter-2 DIV word + radix-4**：word 除法 32 拍、radix-4 16 拍。shuixianhua −69%、prime −70%。
- **撤回**：ROB16→32/IQ8→16 扩容零收益（实测瓶颈非乱序窗口深度），按工作流撤回。
- **iter-4 B1 访存 store 写回解耦**：cacheable-PMEM store 提前完成、B 交 bpend 跟踪器；CPI 1.8722→1.5772(-15.8%)，branch-resolve-loop -30%、ooo-mem-order -27%、linux-mini-boot -31%。踩坑：解耦需同步 dcache store-commit(否则同地址 load 读旧值)。

详见 `.github/task-runs/2026-06-28-npc-rv64-ooo-perf-opt/`。

---

## 3. 架构深度再评估（按"用户更看重工程质量"的新目标）

### 3.1 当前瓶颈（post-B1 深度再评估，eval top cycles 贡献）
1. `branch-resolve-loop` 47.8k(cpi 1.34) —— B1 后降 30%，残余=load-use 延迟 + 循环分支解析；进一步需 load 流水/前递。
2. `shuixianhua` 34.6k(cpi 5.69)/`prime` 24.9k(cpi 3.89) —— 小操作数 div 主导；radix-4 固定 16 拍未利用前导零，CLZ 早终止可再减但复杂度/收益递减、且偏微基准。
3. `ooo-mem-order` 16.6k / `linux-mini-boot` 13.7k —— 残余访存串行（读仍单 outstanding；store-to-load forward 当时未做，2026-07 已随 store→SQ 切换落地，见 B-LSQ 行）。
→ 易得的大 CPI 红利已收割(累计 -58%)。后续 CPI 收益递减且偏微基准；**按用户"CPI 之外更重工程质量"，下一阶段重心转向 B2/B4(状态机化+组织+spec)与 load 侧访存(读多 outstanding/forward)。**

### 3.2 工程质量问题（用户明确点名）
- **深组合逻辑应改时序状态机**：`OooFetchPcOutstandingSequencer`(8 层优先级 if 链)、
  `OooFrontendBackendDispatchMux`(5-6 层嵌套三元) 等靠书写顺序自洽，脆弱且是关键路径。
- **文件组织**：frontend 44 文件（偏碎）、`OooFrontend.v` 2258 行/`OooIntBackend.v` 1845 行（偏大）。
  按职责适度合并/拆分，命名与注释统一。
- **规范覆盖**：`design/specs/` 多为文本散描述，缺统一专业模板与图示；要求 **spec 先行**。
- **架构宪法（2026-06-29 新增）**：核"实现先长、架构后补"，缺顶层 normative 约束。已立
  `arch/ooo-core-architecture.md`（微架构宪法）：定指令生命周期/标准 uop·event 字段/状态 owner 表/
  副作用·flush·redirect 宪法/pending 退出计划。经全核 11 路审计佐证，是 B2/B3/B4/B-LSQ 的**父规范**——
  后续重构应"反过来用宪法约束实现"。关键裁决：前端过载/控制面补丁总线/uop 散线/pending 隐藏串行主干
  均 **confirmed**；commit 唯一改架构态基本成立（+3 受规约例外：B1 store、FPR、fflags）。

### 3.3 微架构限制（评估报告原结论；2026-07-03 按 RTL 重读更新）
- 域 B 串行（stop_pending + backend-drain）现仅剩 system/trap/IRQ 类；branch/jump/FP 已迁回域 A，
  pending_branch/jump/mem 与 pending-FP 通道已被形式化证死待拆（见 `rtl-ground-truth-2026-07-03.md` §4）。
- 单级 branch spec checkpoint 机制已死：误预测恢复 = redirect + ROB-walk（无 checkpoint），
  五套 checkpoint 影子阵列判死待删。
- DIV/SQRT 仍多周期（radix-4 后 word 16 拍）。

---

## 4. 优先级 backlog（spec 先行 → RTL → eval → commit）

| # | 项目 | 价值 | 风险 | 方式 | 状态 |
|---|---|---|---|---|---|
| B3 | **规范体系**：统一 spec 模板(图文并茂)+ 逐模块补 | 中(可维护/交付质量) | 低 | 先定模板，再分模块 | **模板✓**，逐模块补进行中 |
| B1 | **访存解耦：cacheable-PMEM store 写回解耦** | 高(真实代码+#1 微基准) | 中(已限定 cacheable;保留 MMIO 精确异常) | spec✓+FSM✓ | **已实现并验证**(iter4：bpend 跟踪器+仅 cacheable-PMEM 解耦，加权 CPI −15.8%；详见 `history/mem-store-decouple.md` §8(已归档)) |
| B-LSQ | **load 多 outstanding / store-to-load forward(目标 B)** | 高(真实代码访存瓶颈) | 高(顺序/forward) | **difftest 已解锁逐指令验证** + eval | spec 先行,difftest 护航 | **部分完成(2026-07)**：store 迁 SQ(probe→commit→drain)+SQ 全包含单拍前递已落地(M-mode 非 MMIO 限定)；load 多 outstanding/MSHR 未做(桥仍单 outstanding、MLP≈1)，暂缓依据见 `mem-lsq.md` §5b |
| B2 | **多级分支投机 + 统一 redirect（拆 branch/jump pending）** | 高(真乱序前置;branch-resolve-loop #1 瓶颈) | 高(横切~30 文件) | spec 先行；地基(显式 mispredict+rob_idx+单 arbiter+kill-younger)→启用投机+ROB-walk 恢复→删 pending | **spec✓ + 方案定案**(`history/b2-branch-spec-redirect.md`,已归档)：评审定 **B(ROB-walk)** 为基线、C 快照作 Phase-2。**地基 slice-1/2 ✅**：①`OooRedirectArbiter.v`(age-律 selector)+`tb_ooo_redirect_arbiter`(13 例 RED→GREEN);②`OooIntBackend` 导出 `branch_resolve_rob_idx_o` 并 plumb 到 `OooCoreTopGlue`(纯增量,暂 unused)。均 113/113+lint+风格全绿、未接核。**发现**:mispredict 现由前端检测(`issue0_next_pc_w` 是 fallthrough 非预测),后端算 mispredict 需把预测 next_pc 作新 uop 字段 threaded 下来→列整合切片。③**高风险大刀=点火休眠单 checkpoint 投机(`direct_branch_spec_start` 1'b0→1'b1):验证负结论——riscv 16 FAIL(store/div/clmul)+AM 分支程序活锁,该 weak 机器对多周期/访存在飞指令系统性损坏态,已精确回退绿核(riscv 271/0 复原)。坐实不复活此废弃路径、真 OoO 走 ROB-walk**。④**ROB-walk 恢复 FSM ✅**(决定的正道起步):`OooRob` 加 `kill_valid_i`/`kill_rob_idx_i`+多周期反向 walk(2/拍 emit walk{0,1} old_pdest/arch_rd 供 rename 还原/free 回收+回退 tail+`recover_active_o` 冻结),in-core kill 接 1'b0=行为中性(构造可证+113/113),`tb_ooo_rob` 定向 walk 测(奇/偶终止 last_one/last_two+负对照证有效)。⑤**B2 全整合 + Step B 投机 flip 实测(决定性负结论)**:续建 IQ age-squash + Step A 端到端接线(walk→rename/free/IQ,行为中性) + Step B `OOO_ROB_WALK_MODE` 开关(spec_start=1 + mispredict→ROB-walk kill + checkpoint 抑制;调试修 UNOPTFLAT 环=kill 打拍、BLKSEQ=组合 count)。mode=1 实测 **riscv 251/20、AM 14/43(分支程序全活锁)**,与③父会话 checkpoint 投机失败几乎一致。**定性:ROB-walk(已隔离验证正确)取代 checkpoint 后失败不变→问题不在恢复机制,在前端投机流本身(fetch-past-branch+单 spec tracker+redirect 休眠机器,启用即广泛破)。真正使分支投机=重建前端投机流(多会话级),非恢复修复**。已回退 mode=0 保绿;恢复基础设施(ROB-walk FSM/rename-restore/free-reclaim/IQ-squash/arbiter/rob_idx)全保留 mode-gated 隔离验证待接入。〔eval AM 45/12=`.config DIFFTEST=y`+device artifact,非回归〕 **【2026-07-03 更新：主体已落地】**F2 真预测已成为生产形态(`OOO_ROB_WALK_MODE=1'b1`：pred_npc 单源随 uop + issue 级统一解析 + 显式 mispredict + ROB-walk 恢复，BPU 回训单源=issue-resolve)；残余：pending_branch/jump 全链与五套 checkpoint 影子阵列已证死但未物理拆除，`OooRedirectArbiter` 未入编译清单/未实例化(统一 redirect 未接，优先级仍由 `OooFetchRequestMux` 隐式链承担)。见 `rtl-ground-truth-2026-07-03.md` §2.4/§4。 |
| B4 | 死硅物理删除（宪法"只加不减"债）+ 文件组织：碎片合并/大文件拆分、命名注释统一 | 中(交付质量/面积/可维护) | 低-中 | worktree 串行代理逐族删+主树 cycle-exact+difftest+CoreMark 验收；纯结构变换 build+gate 不变 | **死硅删除基本完成(2026-07-04)**：**9 批 ~5900 行可分离死硅已物理删除**（csrc/PRF read4-9全/SyntheticLane1Ret/checkpoint影子×5/前端prefetch-BTC网13模块/WBU-LOAD/IQ-load-branch-fast/dispatch快解析族/pending_mem链/pending-branch-jump链+BPU旧臂+fetch-bypass），各 cycle 逐位中性+difftest 38/3+CoreMark 0xfcaf 不变，见 rtl-ground-truth §4 逐行 commit。**剩余 3 项（DirectBranchResolveGate/SpecTracker/RecoveryGate臂）经 wave6a/6b 穷举证明=「融合活+死」门，死臂已中性化但与活 F2/RAS 同壳，物理删除需架构重构，保留为行为中性死码**。文件组织（大文件拆分）仍待做 |
| B5 | DIV radix-8 / 64 位 CLZ 跳零 | 低(递减) | 低 | 同 radix-4 套路 | 暂缓 |
| B6 | 分支多级 spec checkpoint | 中 | 高 | spec 先行 | 已被 B2 ROB-walk 取代(walk 天然支持多在飞分支，无需 checkpoint) |
| B7 | **serialize-at-retire（宪法 §8.4 step 4，域 B 拆除最后一步）**：system/trap 改 ROB 队头执行+退休刷 younger，删 stop_pending/drain 机制 | 中(交付质量/CSR 指令延迟) | **高(精确异常/CSR/特权全路径)** | **spec✓**(`serialize-at-retire.md`)；6 阶段(CSR→sfence→ecall/trap→mret/IRQ→删机制)，每阶段 355/0+difftest+Linux smoke | **只读调查完成(2026-07-04)=高风险大重写、走专项**：宪法框定"改标志位语义不变"经证实低估——非 CSR 系统指令今天不进 ROB，副作用由控制面 drain 拍合成→须新建系统指令 ROB 数据通路(~15-20 RTL+~15 TB)。cycle-exact 不适用(改语义守正确性,需 Linux boot smoke=CSR 侧唯一护栏)。详见 spec |

### 下一步决策（2026-07-07 生命周期校正：四步护栏链已闭合 → 转 B7 flag-ON 前置）

2026-07-06 记录的"先补 CSR 侧金标准护栏，再回来拆 domain-B"四步链已完成：
1. ✅ **刷新 ROADMAP**：本文件已同步到 gate 355/0、AM 59/0、正确性缺口清零的当前基线。
2. ✅ **Kconfig 通用化**：`kconfig/fixdep` 已迁到工作区级 `tool/`，npc/{rv64,single,sim,soc}+nemu+Linux
   均经 `$(YSYX_HOME)/tool/{kconfig,fixdep}` 使用；2026-07-07 又补齐 `tool/` 自身 Makefile 的反向依赖，
   使其 include 工作区级 `scripts/build.mk`，不再依赖 `$(NEMU_HOME)/scripts/build.mk`。
3. ✅ **NEMU CSR/特权正确性**：RV64 NEMU 已补齐 riscv-tests/ACT4 暴露的 CSR、trap、Sv 语义，并由官方/金标
   测试链验证；当前 NEMU 可作为 NPC CSR/priv/FPR 全状态 difftest reference。
4. ✅ **NPC↔NEMU 全状态 difftest**：已启用 CSR+priv+FPR(+fflags/frm) 比较、异常/中断同步、counter 同步与
   spec-允许掩码；AM 与 riscv-tests full-state difftest 分歧已逐个清零，`ssvnapot` 边界也已闭合。

因此 B7 / `OOO_CSR_QUEUE_HEAD=1` 不再被"CSR difftest 盲区"阻塞；下一步应按
`serialize-at-retire.md` / `serialize-at-retire-phase1.md` 推进 **flag ON 前置**：补 full Linux boot 护航、
`-v-`/full-state difftest 覆盖和 glue TB CsrFile stub，然后再评估把 `OOO_CSR_QUEUE_HEAD` 默认翻 1。
其它高价值项（load 多 outstanding / dcache word→line 粒度 = CoreMark load miss 47% 根因）在 B7 护栏闭合后择机。

---

## 5. 专业化工作流（本项目固化）
1. **RECALL**：读 ROADMAP + 相关 spec + 记忆。
2. **SPEC**：动 RTL 前先在 `design/specs|arch/` 写/更新规范（图文并茂、状态机优先）。
3. **IMPL**：按 spec 实现；一职责一文件；深组合优先改时序状态机。
4. **EVAL**：`eval/npc-eval.sh --all`（自带 self-check），三大 gate 全绿 + CPI 对比。
5. **DECIDE**：有效则留、负优化撤回（原因落盘）。
6. **RECORD+COMMIT**：更新 ROADMAP/spec/记忆/task-run，`git commit` 该迭代。

## 6. 已知环境约束
- **difftest 现已修复并全面工作**：NPC↔NEMU 全状态比较覆盖 GPR/PC、确定性 CSR+priv、FPR、fflags/frm，
  并有异常/中断同步、counter 读同步与 spec-允许掩码。开 `CONFIG_NPC_DIFFTEST` 构建即可作 LSQ/dispatch/
  CSR 队头化等敏感重构的逐指令安全验证；Sv39 A/D 与 Svnapot 边界已对齐，PMP/异步计数仍按既有策略处理。
- **NEMU FP 已升级 Berkeley SoftFloat(RISC-V spec, `tool/softfloat`)**(2026-07-06)：原 host-float 近似实现 →
  proper IEEE-754;官方 rv64uf/ud 23/0 + 与 spike 逐指令 bit-一致。FP 现可作 difftest 金标准(FPR 对比前提已备)。
  该 SoftFloat 结果已进入 NPC↔NEMU FPR difftest 金标准链。
- 大型测试集/日志不入 git（`eval/results/` 已忽略），结论写文档/记忆。

## 7. 时序(Fmax)track（Vivado OOC,数据驱动）
工具就绪:`vivado/run-synth-module.sh`(按模块 OOC+内存看门狗,零崩溃)、`survey-modules.sh`。
方法学:OOC route 不可信,看 logic delay+Logic Levels。WSL 崩溃根因=整核全展平综合内存峰值(见记忆)。
- iter6 ✓ 除法器:3×divisor 移出迭代环寄存,logic 8.65→6.79ns(-21%)。
- iter7 ✓ free list alloc1 并行读,DispatchBackend 42→39 级、logic 8.32→7.95ns。
- **下一深目标**:DispatchBackend rename/alloc/IQ 链(39 级最深)流水化为 2 拍(rename+dispatch),
  及 OooIntIssueQueue oldest-select——影响 CPI/正确性,须 spec 先行+eval 守+重综合验 WNS。
- iter8(2026-06-28)✓ 实测关键路径完整定位:`free_list.count_q[4]→busy_table.query0_ready→
  issue_queue.issue_valid/count→ctrl_q.CE`,39 级唯一封顶。**spec 先行产出
  `timing-dispatch-issue-path.md`**:分 A(CPI-中性组合重构,OOC 可验级数)/B(流水化,需整核 P&R)。
  决策:A 类 free-count 预算经分析判边际(仅省~2/39 级、route 主导不可信、下游仍封顶),不为"显得动"
  而做无效改动;真正有效项=issue_queue issue_valid/count 重构(高风险)或 B 流水化(需先搭整核 P&R)。
  **前置阻塞**:Vivado 当前仅 OOC 模块综合,整核 P&R 流程(取真实 WNS 判流水化净收益)尚未就位。
- iter9(2026-06-28)整核 P&R 尝试→**WSL 不可行**:`run-pnr-core.sh` synth 阶段 Vivado 自动 spawn 多个
  `vivado -notrace` 并行综合 worker(各~3.2GB),总 RSS~11.4GB,free 跌到 167MB,已主动终止防崩(WSL 安全)。
  根因+教训记 `known-issues.md`。**改道**:spec-B 决策不必整核 P&R,用模块级 OOC(OooDispatchBackend
  单模块,内存安全)测 logic-depth 下降 + eval 测 CPI 退化,二者足够定量判净收益(routed WNS 仅锦上添花)。
- iter10(2026-06-28)**spec-B 实验定案(数据完备的负决策)**:实测 B-cut-1(全禁 dispatch-bypass)使
  OooDispatchBackend logic levels **39→24(−38%)**、logic delay 7.95→3.62ns,但加权 CPI **+5.5%**
  (1.2647→1.3340)且破 IQ 单测;B-cut-2(仅留 wakeup 旁路)CPI 与全禁**完全相同**(旁路价值全在"已就绪"
  case)。唯一 Fmax 封顶段确证=dispatch-bypass 同拍 busy_table 依赖。**决策:不 ship,回退基线**——确定 CPI
  损失 + routed 净收益不可验(整核 P&R 此 WSL 不可行)+ 破单测。详见 `timing-dispatch-issue-path.md` §6c。
  **此为易得时序红利的边界:再进需 ≥32GB 机器做整核 P&R 验证,或接受 5.5% CPI 的明确 Fmax-critical 目标。**
