# 规范：load 侧访存解耦 / LSQ（目标 B）

> 模板见 `SPEC-TEMPLATE.md`。目标模块：`vsrc/memory/OooMemAxiBridge.v` + 后端访存发射。
> 状态：**部分落地(2026-07-03 RTL 重读复核)**——store-to-load 前递已随 store→SQ 切换实现
> (4 项 SQ 全包含单拍前递,M-mode 非 MMIO 限定);load 多 outstanding 仍未做(桥仍单 outstanding、
> MIQ 深 4 仅解耦发射侧、真实 MLP≈1),§5b 暂缓决策仍有效。difftest 已解锁逐指令验证。

## 1. 目的与范围
当前访存桥**单 outstanding**:一次只一个内存事务在飞,连续独立 load 串行(各自全延迟)。真实代码
(branch-resolve-loop 拷贝循环、CoreMark/Dhrystone)受此限。目标:让**独立 load 重叠**(2-outstanding 读
或更一般 LSQ),并保持 store→load 顺序与精确异常。B1 已做 cacheable-store 写回解耦,本规范做 load 侧。

## 2. 关键不变量(difftest 逐指令护航)
- **LSQ-I1 store→load 顺序**:younger load 到 older(未排空)store 的同地址,必须读到 store 新值
  (现由 SQ 机制保证:IQ older-store 拦 / 在飞 probe 8B-line 重叠判定 / SQ snoop + SQ 单拍前递;
  多 outstanding 下需保持)。
- **LSQ-I2 顺序**:与中间 store 的相对序必须保持(单 hart)。
- **LSQ-I3 精确异常**:load page/access fault 在该 load 的 commit 边界精确上报;乱序返回的 fault 按 ROB 序提交。
- **LSQ-I4 response ownership**:多事务 response 路由回正确后端端口,flush 正确 drain;无 ready/valid 组合环。

### 2.1 MEM-ISSUE-G1 双 lane request owner 合同（2026-07-12，RTL 前冻结）

- 先抽取不含 `mem_req_ready` 的 lane0 资格事实：
  `issue0_mem_issue_eligible = issue0_is_mem && !mem_issue_block && mem_order_ready && amo_quiet`；
  lane0 memory exception 只有在自身本拍 eligible 时才可把唯一 issue-side memory owner 交给 lane1：
  `issue1_mem_port_available = !issue0_is_mem || (issue0_mem_exception && issue0_mem_issue_eligible)`。
- lane1 normal memory 的 `can_fire/ready`、`req_valid/req_fire` 与 request mux/MIQ push 必须复用
  同一个 port-available 事实；禁止任一条件单独复制 `!issue0_is_mem`。
- 若 lane1 normal memory 从 IQ dequeue，则同拍必须存在 matching bridge request fire 与 MIQ owner；
  exception/SQ-forward completion 是明确的非请求分支。反向地，issue-source request fire 必须对应
  同拍 dequeue，未来引入 station 后则对应 held station owner。
- flush/block/order/SQ/AMO/slot/bridge-ready 约束保持既有语义；本合同不放宽 memory ordering。
- 旧 RTL 已以 misaligned LR.D(lane0)+aligned PMEM LW(lane1) 精确 RED：lane1 fire=1 而
  req_valid/fire=0、MIQ空。修复必须让 lane0 exception completion 与 lane1 request 各归其 owner。
- 审查负探针又证伪了过宽公式 `!issue0_is_mem || issue0_mem_exception`：更老 CLMUL 尚未完成时，
  lane0 misaligned LR 尚非 ROB head，曾出现 lane1 `req_valid=1, fire=0` 且 MIQ 错入一条 ownerless
  DRAIN。故“exception 本地完成”不等于“exception 本拍有资格完成”；eligible 必须进入唯一 owner 事实。

## 3. 增量路线(每步 difftest+eval 全绿才进下一步)
- **step 0(基线)**:difftest 跑通计算+整数访存子集(已验证 8 测全过)。
- **step 1**:桥读路径支持 2 outstanding AR(AXI 允许多读在飞)+1 深 read response skid,按发起序路由 R;
  store 仍单序、store→load 同地址用 dcache 转发。验证 ooo-mem-order/string/mem-test/load-store +
  difftest 逐指令 + eval(branch-resolve-loop 应降)。
- **step 2(可选)**:真正 LSQ(load queue+地址消歧+store buffer forward),覆盖跨 store 的乱序 load。
  (2026-07 复核:store buffer forward 已由 SQ 前递落地;剩 load queue/地址消歧,且 Sv39 开启时
  前递/重叠精判整体退化为 blind 阻塞。)
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

> 2026-07-03 复核:桥仍为单 FSM 单 outstanding(仅 S_RESP 拍可 back-to-back 接续 + 1 笔解耦 store
> 滞后 B),本节"根本性单 outstanding"结论仍成立;但桥已演进出 probe/pretrans/nokill 事务属性、
> bpend 写解耦与 4 项 MIQ(仅解耦发射侧),原文提到的 `active_port_q` 等信号名已不存在。

## 6. 变更记录
- 2026-06-28：建立规范(difftest 解锁后 load 侧解耦增量路线 + 不变量 + 验证)。
- 2026-06-28：读代码后补可行性评估(§5b),step 1 判定为高风险/有限收益,本阶段暂缓并记录重启条件。
- 2026-07-03：RTL 重读复核——store-to-load 前递部分已由 store→SQ 切换落地,load 多 outstanding
  维持暂缓;更新状态行与 §2/§3/§5b 的现状描述。
