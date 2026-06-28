# RV64 OoO 核 · 架构演进路线图（living document）

> 本文件是 RV64 乱序核优化/重构的**主干文档**：记录当前已验证状态、架构再评估、
> 优先级 backlog 与专业化工作流。每轮迭代后按"迭代→深度再评估→据此修改"更新。
> 配套：评估系统 `eval/`，模块规范 `design/specs/`，架构规范 `design/arch/`，文献 `design/literature/`。

最近更新：2026-06-28 (iter4 后)

---

## 1. 当前已验证状态（三大 gate 全绿）
| gate | 结果 | 工具 |
| --- | --- | --- |
| 模块 testbench | 112/112 | iverilog |
| 官方 riscv-tests（默认+特权） | 271/0 | tohost 协议 |
| AM cpu-tests | 56/56 | ebreak GOOD TRAP |

性能（AM 全量加权 CPI，含 PMP=真实场景）：**1.5772**（自禁缓存基线 3.7427 累计 **−58%**）。
真实代码：CoreMark CPI≈1.146(B1 前测；store 解耦后预期下降，待复测)。

容量（`include/define.v`）：dual-issue / PRF 64 / ROB 16 / IQ 8 / Fetch FIFO 4。

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
3. `ooo-mem-order` 16.6k / `linux-mini-boot` 13.7k —— 残余访存串行（读仍单 outstanding；store-to-load forward 未做）。
→ 易得的大 CPI 红利已收割(累计 -58%)。后续 CPI 收益递减且偏微基准；**按用户"CPI 之外更重工程质量"，下一阶段重心转向 B2/B4(状态机化+组织+spec)与 load 侧访存(读多 outstanding/forward)。**

### 3.2 工程质量问题（用户明确点名）
- **深组合逻辑应改时序状态机**：`OooFetchPcOutstandingSequencer`(8 层优先级 if 链)、
  `OooFrontendBackendDispatchMux`(5-6 层嵌套三元) 等靠书写顺序自洽，脆弱且是关键路径。
- **文件组织**：frontend 44 文件（偏碎）、`OooFrontend.v` 2258 行/`OooIntBackend.v` 1845 行（偏大）。
  按职责适度合并/拆分，命名与注释统一。
- **规范覆盖**：`design/specs/` 多为文本散描述，缺统一专业模板与图示；要求 **spec 先行**。

### 3.3 微架构限制（评估报告原结论，仍成立）
- 单 entry pending sequencer（branch/jump/mem/system/FP）+ backend-drain 串行困难路径。
- 单级 branch spec checkpoint（同时只一条投机分支）。
- DIV/SQRT 仍多周期（radix-4 后 word 16 拍）。

---

## 4. 优先级 backlog（spec 先行 → RTL → eval → commit）

| # | 项目 | 价值 | 风险 | 方式 | 状态 |
|---|---|---|---|---|---|
| B3 | **规范体系**：统一 spec 模板(图文并茂)+ 逐模块补 | 中(可维护/交付质量) | 低 | 先定模板，再分模块 | **模板✓**，逐模块补进行中 |
| B1 | **访存解耦：cacheable-PMEM store 写回解耦** | 高(真实代码+#1 微基准) | 中(已限定 cacheable;保留 MMIO 精确异常) | spec✓+FSM✓ | **spec✓ + FSM 文档✓**(`specs/ooo-mem-axi-bridge-fsm.md`)；设计已定(bpend 跟踪器+仅 cacheable 解耦,保 MEM-I3)；实现为下一专注迭代 |
| B-LSQ | **load 多 outstanding / store-to-load forward(目标 B)** | 高(真实代码访存瓶颈) | 高(顺序/forward) | **difftest 已解锁逐指令验证** + eval | spec 先行,difftest 护航 | 待开始(已具备安全验证) |
| B2 | **redirect/PC sequencer 改显式状态机** | 中(时序+清晰+稳健) | 中 | spec 先行；先补 redirect 优先级定向 TB 再改 | 待开始(先补 TB) |
| B4 | 文件组织：碎片合并/大文件拆分、命名注释统一 | 中(交付质量) | 低-中 | 纯结构变换，逐目录，build+gate 不变 | 待开始(低风险，可先行) |
| B5 | DIV radix-8 / 64 位 CLZ 跳零 | 低(递减) | 低 | 同 radix-4 套路 | 暂缓 |
| B6 | 分支多级 spec checkpoint | 中 | 高 | spec 先行 | 暂缓 |

### 下一步决策（自主判断）
- **B1 实现门控**：访存 store 解耦是 #1 性能杠杆，但触碰访存顺序/response ownership，
  历史有"读旧值"踩坑，且本环境无 difftest 参考。按 B1 规范 §6 与"干净正解"交付纪律，
  **先建访存顺序定向 testbench（store→load 同/异地址、flush-during-write、AMO/lrsc 边界）**，
  再实现解耦；不在无充分验证下仓促落地高风险改动。
- **可并行先行的低风险项**：B4(文件组织) 与 B3(逐模块 spec) 不改行为/可被 gate 守住，
  可在 B1 验证准备期穿插推进，持续提升交付质量。

---

## 5. 专业化工作流（本项目固化）
1. **RECALL**：读 ROADMAP + 相关 spec + 记忆。
2. **SPEC**：动 RTL 前先在 `design/specs|arch/` 写/更新规范（图文并茂、状态机优先）。
3. **IMPL**：按 spec 实现；一职责一文件；深组合优先改时序状态机。
4. **EVAL**：`eval/npc-eval.sh --all`（自带 self-check），三大 gate 全绿 + CPI 对比。
5. **DECIDE**：有效则留、负优化撤回（原因落盘）。
6. **RECORD+COMMIT**：更新 ROADMAP/spec/记忆/task-run，`git commit` 该迭代。

## 6. 已知环境约束
- **difftest 现已修复并全面工作**(NEMU 构建 + 结构 ABI + 比较模式三修复;计算/整数访存测试逐指令对照 NEMU 全过)。
  开 `CONFIG_NPC_DIFFTEST` 构建即可作 LSQ/dispatch 等访存敏感重构的逐指令安全验证。注:NEMU 对 A/D/PMP 与本核
  有意不同(NEMU HW A/D),故 Sv39/PMP 路径会差异性 diverge,difftest 重点用于计算/整数访存正确性。
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
