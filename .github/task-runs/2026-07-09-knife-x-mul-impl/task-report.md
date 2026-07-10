# 任务报告：刀 X 实施——MUL 拍数收复（radix-4+CLZ 早退出+swap）

spec：`npc/rv64/design/arch/knife-x-mul-latency-recovery.md`（冻结于同日，三路侦查+对抗审查）。
用户指令："开工，同时你需要从架构的角度思考这么优化"。

## 1. 实施与验证结果

| 指标 | 刀 X 前 | 刀 X 后 | 变化 |
| --- | --- | --- | --- |
| CoreMark CPI（10 迭代） | 3.280 | **1.633** | **收复 1.65（-50.2%），超预估带 1.3~1.5 上限** |
| CoreMark cycles | 10555505 | 5254589 | -50.2%（0xfcaf GOOD TRAP） |
| matrix-mul cycles | 67766 | **18354** | -73%（验收线 1-2 万达标；单拍时代 10301） |
| mul-longlong cycles | 885 | 510 | -42% |
| 等待源 hazard 桶 | 51-55% | **0.5%** | MulDiv 阴影清零 |
| 等待源 fetch 桶 | 46-49% | **90.8%** | 唯一压倒性瓶颈（刀 F 铁证） |
| OooMulDivUnit OOC area | 18944.80 | 22385.16 | +18%（m3 128FF+装载逻辑），ABC 15s 0 problems |
| 断言基线 | 29 | 32 | +MD-I6/I7 |

门禁：focused TB（64×64 穷举×4 变体+随机 500×5+角例矩阵+kill 三用例+MUL flush）全绿；
module TB 86/86；lint 双变体；check-contract 32≥20；mutation 手测 MD-I7 fire→复原 0。
全核综合（IntBackend delay 对照）与 core-regress --riscv-tests 结果见 §4。

提交链：`affc12255`（S1-1 radix-4）→ `9a81a11d4`（S1-2/S2 CLZ+swap+断言+TB）→
`a8c35539b`（S3 spec 同步+CoreMark 数据）。

## 2. 实施中抓到的两个非计划收获

1. **muldiv_killed 潜伏 bug（跨仿真器语义差异）**：原 function 形态中函数体引用模块级
   kill 信号，iverilog 的连续赋值不把 hidden dependency 进敏感列表——kill 脉冲被无视。
   该 bug 自 UC-A 补 kill 端口以来一直存在，从未暴露（旧 TB kill 恒 0；大节点走 Verilator
   正确处理）。本刀 TB 首次解除 kill_valid=0 即暴露。修复=展开为显式 wire。
   **iverilog14 "函数体引用模块级变量"禁令家族新成员**——此前禁令只覆盖"引用后声明的
   变量"（编译报错形态），本例是"引用先声明的端口"（静默错误形态），更毒。
2. **MD-I7 断言的意外实弹**：TB 穷举块 integer 越界切片产生 X 操作数，X 使零特判失效
   （`X==0` 求值假）→ count_init=0 绕回 64 拍、结果仍正确——正是 spec R1 风险预言的
   "全门禁假 pass"形态，被拍数断言当场逮住。证明"结果正确但拍数错误"类性能 bug
   唯有拍数不变量可见。

## 3. 架构角度的思考（用户点题）

### 3.1 为什么这刀在架构上是"免费"的

本单元的接口契约（ready/valid 长延迟协议）从设计之初就把**延迟做成了不可观测量**：
消费方（wb 仲裁组合优先级、ROB done 标记、IQ 唤醒广播）没有任何拍数假设，DIV 的
除零特判早已是"装载次拍即 RESP"的 2 拍变拍先例。所以 64→(2+eff/2) 拍的剧烈变化
零契约泄漏、kill/flush 逻辑一行不动。**好架构的标志：优化被契约免费吸收**——这也是
级间边界治理（PipeStageReg/六类契约）路线正确性的一个佐证。

### 3.2 真正的架构债在消费方结构，而非单元延迟

侦查实锤两个结构问题：①IQ oldest-first select **不感知 FU busy**——最老 ready 的
MUL 在 unit busy 期间恒占 issue0 槽，阴影内整机降级单发；②**单 outstanding**——
背靠背 MUL 串行。拍数收复只缩短阴影长度，不消除阻塞结构。但数据（hazard 0.5%）
证明当前 workload 下阴影已够短，结构修复（第二 outstanding / IQ busy 感知）的
边际收益 ~0.2 CPI，**不值得现在做**——留作触发条件式演进（CoreMark 剖析 MUL 回到
top 桶时再动，预期不会）。架构决策的正确姿势：结构债要认账，但按数据排期，不按洁癖排期。

### 3.3 综合驱动重构的方法论修正（07-07~08 重写的根因反思）

64 拍 iter-mul 是把"综合可行性"当唯一目标的产物；本刀证明存在同时满足综合与性能的
设计点（area +18% 换 CPI -50%，ABC 依旧秒级）。**正确流程应是：先算延迟预算
（MUL 动态占比 2.7% → 每拍延迟值 0.027 CPI），再在预算内选实现形态**。长延迟单元
的形态谱系——迭代 radix-2（最小面积）→ radix-4/16（面积↑拍数↓）→ 流水阵列
（吞吐 1/拍，面积最大）——选点由 workload 占比×延迟敏感度决定，不由"最容易写/最容易
综合"决定。此教训直接适用于将来任何"为综合把组合逻辑改多拍"的刀（fetch/dcache 已付
同类学费：SRAM 化吞吐减半 +0.50 CPI）。

### 3.4 等待源分解是排刀的第一仪表

hazard 55%→0.5%、fetch 48%→90.8% 的跃迁完整演示了 ooo_window 分解的决策价值：
刀 X 前它指认 hazard（MulDiv）为最大等待源，刀 X 后它把下一刀（刀 F fetch lookup
流水化）的优先级变成定量铁证。**每刀收尾必须留窗口分解快照**，让下一刀的选择永远
有数据背书。

### 3.5 变延迟单元的验证标配

MD-I6（行为金标准等价）+MD-I7（拍数精确不变量）应成为所有变延迟单元的标配断言对：
前者杀功能错误，后者杀"结果正确但拍数错误"的性能 bug（全门禁假 pass 类）。
**DIV 侧目前只有功能不变量（MD-I1..I3）没有拍数断言**——同型缺口，后续顺手补。

## 4. 全核综合与 riscv-tests 收尾数据（2026-07-10 停电重跑后回填）

- **riscv-tests 177/177 全绿 0 FAIL**（`--riscv-tests --riscv-privileged`，含 rv64mi/si；
  rv64um 13/13）；core-regress overall_rc=0（module TB/lint/npc-build/AM 全 PASS）。
  发现并绕过 regress 脚本坑：07-07 vendor 子仓剥离 `.git` 后 auto 模式判
  riscv-tests "checkout absent" 静默 SKIP——须显式 `--riscv-tests`。
- **全核综合 1810s**（前次 4926s，快 2.7 倍——ABC 全局重收敛路径不同）；
  IntBackend 本体 maxlev 46、OooMulDivUnit 34 lev/17063 area（模块内聚合口径）——
  **R4（装载拍锥劣化）排除**。
- **全核 OpenSTA @100MHz：WNS -5.59（前 -6.06，微改善）/TNS -53129（前 -49431，+7.5%）**。
  top 违例换到 SQ snoop 前递 CAM→mem 桥 state_q 路径——刀 X 只动 MulDiv，
  此变化属 ABC 全局扰动带，非语义效果；刀 X 判定**时序中性**。
- 停电事故副产品：OpenSTA binary 随 /tmp scratchpad 丢失（"工具放 git 工作区"教训
  第二次实弹）——重建流程固化为 `yosys-sta/scripts/build-opensta.sh`
  （venv cmake/swig + eigen cmake-install + CUDD 源码 + 系统 tcl 头），
  产物落持久目录 `~/tools/OpenSTA/build/sta`（3.1.0）。

## 5. 审查者人格

- CoreMark 收复量（1.65）超预估带上限——预估的"阴影内 issue1 仍单发"折扣实际被
  fetch 瓶颈掩盖（fetch 90.8% 意味着 issue 侧根本吃不满），收复量以 fetch 供给为上限。
- matrix-mul 未回到单拍时代 10301 的残差（18354-10301≈8k）归 SRAM 化 fetch/load 拍数
  与刀 M，非 MUL 残留——与 §3.4 的 fetch 瓶颈结论一致。
- 全状态 difftest 按用户 07-08 决策仍推迟至重构整体收口；本刀正确性由行为金标准
  断言（MD-I6 全程武装跑过 CoreMark 5.2M 拍+全部 TB）+riscv-tests rv64um+AM 数论
  用例背书。
