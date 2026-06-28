# 规范：load 侧访存解耦 / LSQ（目标 B）

> 模板见 `SPEC-TEMPLATE.md`。目标模块：`vsrc/memory/OooMemAxiBridge.v` + 后端访存发射。
> 状态：**设计中(spec 先行)**;difftest 已解锁逐指令验证。

## 1. 目的与范围
当前访存桥**单 outstanding**:一次只一个内存事务在飞,连续独立 load 串行(各自全延迟)。真实代码
(branch-resolve-loop 拷贝循环、CoreMark/Dhrystone)受此限。目标:让**独立 load 重叠**(2-outstanding 读
或更一般 LSQ),并保持 store→load 顺序与精确异常。B1 已做 cacheable-store 写回解耦,本规范做 load 侧。

## 2. 关键不变量(difftest 逐指令护航)
- **LSQ-I1 store→load 顺序**:younger load 到 older(未排空)store 的同地址,必须读到 store 新值
  (现 dcache 在 store-commit 全失效+更新已保证;多 outstanding 下需保持)。
- **LSQ-I2 顺序**:与中间 store 的相对序必须保持(单 hart)。
- **LSQ-I3 精确异常**:load page/access fault 在该 load 的 commit 边界精确上报;乱序返回的 fault 按 ROB 序提交。
- **LSQ-I4 response ownership**:多事务 response 路由回正确后端端口,flush 正确 drain;无 ready/valid 组合环。

## 3. 增量路线(每步 difftest+eval 全绿才进下一步)
- **step 0(基线)**:difftest 跑通计算+整数访存子集(已验证 8 测全过)。
- **step 1**:桥读路径支持 2 outstanding AR(AXI 允许多读在飞)+1 深 read response skid,按发起序路由 R;
  store 仍单序、store→load 同地址用 dcache 转发。验证 ooo-mem-order/string/mem-test/load-store +
  difftest 逐指令 + eval(branch-resolve-loop 应降)。
- **step 2(可选)**:真正 LSQ(load queue+地址消歧+store buffer forward),覆盖跨 store 的乱序 load。
- 任一步 difftest/eval 退化即 revert(git 检查点)。

## 4. 风险与回退
- 风险:高(访存顺序/response ownership/精确异常)。缓解:difftest 逐指令(已解锁)+ eval 三 gate +
  ooo-mem-order 定向 + git 检查点;增量小步,每步全验证。
- 收益面:load-miss 密集/读写交替;dcache-hit 已近 2 拍下限,主要益于 miss 与跨迭代独立 load 重叠。

## 5. 验证计划
- `CONFIG_NPC_DIFFTEST` 构建,跑 AM 计算+访存子集逐指令对照 NEMU。
- `eval/npc-eval.sh --all` 守 CPI/正确性 + `vivado/synth-changed.sh` 看时序。
- 重点:ooo-mem-order、branch-resolve-loop、string、mem-test、load-store、riscv-tests ua/ui。

## 5b. 可行性评估与决策(2026-06-28,读代码后)
读 `OooMemAxiBridge.v`(726 行)定论:桥是**单 `state_q` 串行 FSM**,把 PTW 页表走查
(S_WALK_AR/S_WALK_R)、读(S_READ_ADDR/DATA)、写(S_WRITE_REQ/RESP)全序列化,且只有单一
`active_port_q`/`write_q`/`paging_q`——**根本性单 outstanding**。

step 1(读路径 2-outstanding)需要:① 拆单 FSM 为 AR-发起 与 R-接收 两条独立轨道;
② 多事务 response 按发起序路由回正确后端端口(需 1 深 response skid + 端口/序号 tag 队列);
③ 与 PTW(自身也走 AR/R)交织时的仲裁与 flush drain;④ 维持 LSQ-I1..I4 不变量。
即对已验证全绿的访存桥做**大规模 FSM 重写**。

**收益侧**(见 §4):dcache-hit 已近 2 拍下限,增益主要落在 **miss-heavy / 流式 load**;
当前测试集多 dcache 常驻,实测 CPI 已低(Dhrystone 1.52)。

**决策:step 1 评估后暂缓(risk=高 / reward=有限,当前性价比不利)。**
非"做不到",而是当前阶段不值得在深上下文里重写已绿的桥换取边际增益。
**重启条件**:出现 miss 密集 / 大数据流式目标负载,或时序/CPI 报告指认访存串行为头部瓶颈时,
按 §3 增量路线小步推进,每步 difftest 逐指令 + eval 三 gate + ooo-mem-order 定向 + git 检查点。

## 6. 变更记录
- 2026-06-28：建立规范(difftest 解锁后 load 侧解耦增量路线 + 不变量 + 验证)。
- 2026-06-28：读代码后补可行性评估(§5b),step 1 判定为高风险/有限收益,本阶段暂缓并记录重启条件。
