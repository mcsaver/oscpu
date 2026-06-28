# RV64 OoO 核 · 架构演进路线图（living document）

> 本文件是 RV64 乱序核优化/重构的**主干文档**：记录当前已验证状态、架构再评估、
> 优先级 backlog 与专业化工作流。每轮迭代后按"迭代→深度再评估→据此修改"更新。
> 配套：评估系统 `eval/`，模块规范 `design/specs/`，架构规范 `design/arch/`，文献 `design/literature/`。

最近更新：2026-06-28

---

## 1. 当前已验证状态（三大 gate 全绿）
| gate | 结果 | 工具 |
| --- | --- | --- |
| 模块 testbench | 112/112 | iverilog |
| 官方 riscv-tests（默认+特权） | 271/0 | tohost 协议 |
| AM cpu-tests | 56/56 | ebreak GOOD TRAP |

性能（AM 全量加权 CPI，含 PMP=真实场景）：**1.8722**（自禁缓存基线 3.7427 累计 −50%）。
真实代码：CoreMark CPI≈1.146（含 PMP，受访存串行限制）。

容量（`include/define.v`）：dual-issue / PRF 64 / ROB 16 / IQ 8 / Fetch FIFO 4。

---

## 2. 已完成迭代
- **iter-0 回归修复**：核 PMP 规范性默认拒绝 S/U + AM 测试未配 PMP → 启动配 PMP(trm.c)修 9 项；
  sv39-ad-bits 改 SW 管理 A/D（核非 Svadu）修 1 项。基线 46/56→56/56。
- **iter-1 PMP 取指缓存**：PMP 一活动就禁用取指 cache → Linux/OpenSBI 下 ~2x 惩罚。改 PMP-grant 逐访问门控。
- **iter-2 DIV word + radix-4**：word 除法 32 拍、radix-4 16 拍。shuixianhua −69%、prime −70%。
- **撤回**：ROB16→32/IQ8→16 扩容零收益（实测瓶颈非乱序窗口深度），按工作流撤回。

详见 `.github/task-runs/2026-06-28-npc-rv64-ooo-perf-opt/`。

---

## 3. 架构深度再评估（按"用户更看重工程质量"的新目标）

### 3.1 当前瓶颈（数据驱动，eval top cycles 贡献）
1. `branch-resolve-loop` 68k —— load→store 依赖 + **单 outstanding 访存**串行。
2. `shuixianhua/prime` —— 仍 div（已 −70%，radix-8 收益递减）。
3. `ooo-mem-order`/`linux-mini-boot` —— 访存顺序/单 outstanding。
→ **真实代码与最大微基准的共同瓶颈是访存子系统**（单 outstanding、store 不解耦、无 store-to-load forward）。

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
| B1 | **访存解耦：store 写回解耦 / 多 outstanding** | 高(真实代码+#1 微基准) | 高(顺序/forward/精确异常) | spec 先行 + 状态机 + 验证先行 | **spec✓**(`mem-store-decouple.md`)；实现**门控于**先建访存顺序定向 TB(见 §6) |
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
- difftest/NEMU 本环境不可构建（vga.c `update_screen` 缺声明），且 NEMU 对 A/D/PMP 与本核有意不同，
  非干净参考。访存类改动依赖现有 gate（历史上能捕获访存 bug）严验，不强依赖 NEMU。
- 大型测试集/日志不入 git（`eval/results/` 已忽略），结论写文档/记忆。
