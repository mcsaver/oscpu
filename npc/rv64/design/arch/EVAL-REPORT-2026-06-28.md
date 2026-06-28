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

## 7. 验证证据
- `eval/results/20260628-161022-reeval-milestone/summary.md`(三 gate + CPI)
- `eval/results/20260628-160441-difftest-validate/summary.md`(33/33)
- 工作树干净(仅 2 个 test 子模块 pre-existing,不提交)。
