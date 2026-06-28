# RV64 OoO 核 — 里程碑再评估报告(2026-06-28)

> 数据来源:`eval/npc-eval.sh --all`(tag=reeval-milestone, git_head=bdc446f08)
> + `--difftest`(33/33 逐指令对照 NEMU)。本报告是"优化一轮 → 重新审视 → 报告"里程碑的产物。

## 1. 结论(TL;DR)
核处于**充分优化且全验证绿**的稳定态。三道正确性闸门全过,加权 CPI 1.26。本轮起手时报告
指出的可优化项已落地;**剩余可见增益均需高风险结构性改动(LSQ 多 outstanding / 降 load 延迟),
换有限回报,本阶段经评估后暂缓并记录了重启条件**(见 §5)。

## 2. 正确性闸门(三层,全绿)
| 闸门 | 结果 | 说明 |
|---|---|---|
| module TB(iverilog) | **112/112** | 单模块定向 |
| riscv-tests(tohost) | **271** | 官方指令级回归 |
| AM cpu-tests(ebreak GOOD TRAP) | **56** | 系统级,含 PMP/Sv39/特权 |
| difftest(逐指令对照 NEMU) | **33/33** | 计算+整数访存子集,比 GOOD-TRAP 强的架构等价 |

## 3. 性能画像(加权 CPI = 1.2647,cycles=187299 / commits=148092)
- 最高 CPI:counteren-time(3.33)、plic-sirq(2.83)——均为**极短**(<330 cyc)的 CSR/中断微测,
  启动开销占比高,非热点,CPI 高不影响整体。
- 最低 CPI:crc32(0.56)、matrix-mul(0.91)——计算密集,双发射+乱序充分发挥(CPI<1)。
- **Top cycles 贡献**:branch-resolve-loop(47838)、ooo-mem-order(16562)、shuixianhua(15634)、
  linux-mini-boot(13713)、crc32(10291)、prime(10124)。

### 3.1 头部贡献者根因(branch-resolve-loop,占总周期 ~25%)
内循环 = `lbu t3,0(t0); addi; sb t3,0(t2); addi; bne`(字节拷贝)。诊断:
- `bne` 高度可预测(24/25 taken),**锦标赛预测器**(gshare GHR + 本地 history/PHT)已正确处理,
  误预测**不是**瓶颈。
- 真正瓶颈是 **load→store 数据依赖链 + dcache load-use 延迟**(`lbu`→`sb` 需 load 结果)。
- 故该测试是 **访存延迟受限**,非分支受限。降它只能(a)dcache load 降到 2 拍以下(已近底)或
  (b)load 侧多 outstanding(见 §5,高风险)。

## 4. 本轮(及前序)已落地优化(全部 difftest+eval 护航)
1. **PMP 取指门控**:`OooFetchAxiBridge` cache_hit 由"PMP 活跃即关 cache"改为 **PMP-grant 门控**,
   PMP 开启下取指吞吐 ~2×。
2. **除法器**:radix-2 → **radix-4**(2 bit/周期)+ **CLZ 提前终止** + word-op count=32 + 3×divisor 预算。
3. **FreeList 并行双分配**:alloc1 并行读 head0/head1,双发射重命名不再串行。
4. **store 写回解耦(B1)**:`bpend_q` 跟踪器,cacheable store 写回与后端解耦;
   配 `store_decouple_commit_w` 保 dcache 一致性(回归捕获并修复过一致性 bug)。
5. **平台回归修复**:AM `_trm_init` 加 PMP NAPOT 全放行(修 9 个 S-mode 回归);sv39-ad-bits SW 管 A/D。
6. **difftest 全链路恢复**:NEMU 结构体 `{gpr,pc,fpr,csr,priv}` 重排(ABI)+ commit-pc-before-step
   比较模式(避开 OoO ROB 存预测 next_pc 的误报)→ 33/33 逐指令通过。
7. **评估系统升级**:`--difftest` 一等模式(自动建参考核→逐指令→恢复 perf 基线);
   per-test CPI |Δ|>20% 自检 + dummy smoke 自校验。
8. **时序工具链**:Vivado OOC 逐模块综合 + 内存看门狗(MEM_FLOOR_MB=2500)+ taskset 8-11 + nice
   (根因:WSL 崩溃来自内存峰值而非 CPU;全核 flatten 综合内存爆掉)。

## 5. 剩余项与暂缓决策(诚实记录)
| 项 | 风险 | 回报 | 决策 |
|---|---|---|---|
| LSQ / load 多 outstanding | 高 | 有限(仅益于 miss/流式;dcache-hit 已近 2 拍底) | **暂缓**,见 `mem-lsq.md` §5b |
| 降 dcache load-use 延迟 | 高 | 中(直击 branch-resolve-loop) | 暂缓,需重构访存流水 |
| 分支预测增强 | 中 | 低(预测器已锦标赛式,头部测试非分支受限) | 不做 |

**LSQ 暂缓理由**(详 `mem-lsq.md` §5b):访存桥是单 `state_q` 串行 FSM,把 PTW/读/写序列化,
单 `active_port_q`——根本性单 outstanding。改 2-outstanding 需拆 FSM 双轨 + response 按序路由 +
PTW 交织仲裁,即对已绿的桥大规模重写。当前测试集多 dcache 常驻,性价比不利。
**重启条件**:出现 miss 密集/流式目标负载,或时序/CPI 报告指认访存串行为头部瓶颈。

## 6. 下一步建议(按性价比)
1. **时序/Fmax**(数据驱动,correctness 风险低):用 `vivado/synth-changed.sh` 逐模块跑 OOC,
   按 logic-level/logic-delay 找关键路径,只重构被数据指认的模块(每改 difftest+eval+综合三验)。
2. LSQ 仅在 §5 重启条件满足时启动。

## 6b. 真实代码 CPI 画像(2026-06-28 补全)
| 负载 | CPI | 说明 |
|---|---|---|
| CoreMark | **~1.02** | 50M-cycle 窗口(完整迭代 RTL 仿真不可行;CPI 与迭代数无关);计算/循环密集分支可预测,OoO 充分发挥 |
| AM 加权 | 1.26 | 56 系统测加权(含 PMP/微测,偏微基准) |
| Dhrystone | 1.52 | 分支/访存密集 |
真实负载 CPI 优于 AM 加权(后者被 branch-resolve-loop 等微测拉高),说明核在真实代码上表现更好。

## 7. 验证证据
- `eval/results/20260628-161022-reeval-milestone/summary.md`(三 gate + CPI)
- `eval/results/20260628-160441-difftest-validate/summary.md`(33/33)
- 工作树干净(仅 2 个 test 子模块 pre-existing,不提交)。

## 8. 验证加固与 bug-hunt(报告生成后的延续工作)
本报告初版后,迭代重心从"性能优化"转向"验证加固"(因易得性能红利已收割、剩余项需用户决策或更大内存):
1. **评估系统 level-2 元评估**(`eval/META-EVAL.md`):识别 5 盲点并逐一处理——difftest 逐指令 33→**40**
   (新增 RVC/fence-i/mem-order/switch/stdio)、新增 `--timing` 时序回归 gate、CoreMark CPI **1.02**、
   module TB 覆盖率量化(82/104 Ooo 模块有专属单测,良好)、CPI 加权代表性已说明。
2. **五轮对抗性 bug-hunt 战役**(覆盖 7 大高风险区,详见 `.github/memory/known-issues.md`):
   **修复 3 个真 bug(全验证全绿)**:
   - 隐患B(取指跨页 PMP 绕过,**安全**):`OooFetchAxiBridge.v` 不缓存跨页包,结构性消除 stale 槽1 PMP grant。
   - B1(中断委托位错,**Linux-breaking**):`CsrFile.v` 软件/定时器 hw 委托用 M 位(MSI=3/MTI=7)应为
     S 位(SSI=1/STI=5);协调修核 4 处 + `sbi-timer.c` 测试,真 Linux 写 mideleg=0x222 时中断方能委托到 S。
   - B2(中断优先级反转):`CsrFile.v` 双 pending 无条件选 S,改 M>S 全序。
   **文档化(非贸然修复)**:隐患A(访存桥 B off-by-one,IP复用;简单门控修复经实证**死锁**,需侵入式 B-tracker);
   flush-drain 隐患(追根为桥 `drop_rsp_q` 已缓解,非问题)。
   **逐角落核对无真 bug**:除法器 radix-4/CLZ、FreeList 并行分配、PMP TOR/NAPOT/默认拒绝、trap/异常交付编排
   (7 区精确异常)、OoO 旁路/唤醒/写回 FSM(前递/唤醒/写回仲裁/load-use/分支解析全对);顺带移除 PMP 死代码。
   后 3 轮多 clean → 核心逻辑严谨、覆盖充分。两次 CSR/中断 spec 修复破坏测试均被 eval 安全网拦截+回退(教训:
   此核中断模型有测试背书的约定,改动需协调+验证)。
3. **整核 P&R 证 16GB WSL 不可行**(并行综合 worker 撑爆内存,看门狗护航防崩)。

## 9. 待用户决策项(非可自主推进)
| 项 | 需要 |
|---|---|
| ship dispatch-bypass(去旁路:−38% logic level / +5.5% CPI) | 用户定 FPGA 目标是否 Fmax-critical |
| 推送本地提交到 myfork/ai | 用户授权 push |
| 隐患A 侵入式修复(B-tracker) | 用户知情(高风险路径,简单修复已证死锁) |
| Sv39/PMP 指令级 difftest | 改 NEMU 对齐核语义(中风险) |
| dispatch 流水化净收益确认 / LSQ | ≥32GB 机器跑整核 P&R |

## 10. 交付态总结
核处于**高置信交付态**:三 gate + difftest 40 全绿、CPI 1.26(真实代码 CoreMark 1.02)、**7 大高风险区经
5 轮对抗审查、修复 3 个真 bug**(取指跨页 PMP 绕过-安全、中断委托位-Linux、中断优先级)、评估系统经 level-2
元评估加固、唯一 Fmax 封顶项量化。本会话不仅完成性能优化平台期表征,更通过系统性对抗审查实质提升了核的
**正确性与安全性**(尤其 S-mode/Linux 上线相关的中断交付)。`ai` 分支,工作树干净,所有改动验证全绿。
