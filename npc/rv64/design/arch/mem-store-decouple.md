# 规范：访存桥 store 写回解耦（B1）

> 模板见 `SPEC-TEMPLATE.md`。目标模块：`vsrc/memory/OooMemAxiBridge.v`。
> 状态：**设计中（spec 先行）**，实现为后续迭代。

## 1. 目的与范围
降低访存子系统的串行延迟。当前访存桥**单 outstanding**：一条 store 必须走完
`S_WRITE_REQ → S_WRITE_RESP → S_IDLE` 才能接受下一条访问。但 store 对后端是
fire-and-forget（不经 S_RESP，不产生寄存器写回），其 AXI B 响应只是协议收尾。
本规范让桥在 store 数据落地后即接受下一条访问，把滞后的 B 收尾交给一个独立的
**写收尾跟踪器（B-drain tracker）**，从而让"store + 紧随的 load/store"重叠。

范围：仅改桥对"何时可接受下一请求 / 何时收 B"的控制；不改地址翻译、PMP、dcache、
load 读路径与精确异常边界。

## 2. 关键不变量（决定可行性）
- **I1 写顺序**：sim AXI slave 在 `AW.fire && W.fire`（write_complete）当拍即调
  `npc_mem_write` 落 PMEM，`B` 在其后一拍。⇒ **store 数据在 write_complete 当拍已对后续访问可见**。
  故一旦本 store 的 AW+W 均 fire，下一条访问（含同地址 load）读到的就是新值，无 stale-read。
  （历史踩坑：2026-05-29 "response 同拍接受下一请求 → load reads stored word got=0"，
  根因是当时在数据落地前就接受。本设计严格要求 **AW+W 都 fire 之后**才放行，规避该坑。）
- **I2 单写在飞**：任意时刻至多一个 store 的 B 未收。新访问放行的前提是上一个 B 已被
  跟踪器接管，且 AXI 写通道（AW/W）已空闲，避免两笔写交叠。
- **I3 精确异常/flush**：flush 时必须丢弃在途响应（沿用现有 `drop_rsp_q`/`cpu_kill_w` 语义），
  跟踪器中的待收 B 也必须被正确 drain 且不误判为新访问的响应。
- **I4 无组合环**：放行谓词不得依赖"本拍新请求是否 fire"形成 ready/valid 回边。

## 3. 状态与时序模型

当前（单 outstanding，store 阻塞）：
```
 S_IDLE --store--> S_WRITE_REQ --(AW&W fired)--> S_WRITE_RESP --(B)--> S_IDLE
   ^                                                                     |
   +---------------------------- 期间不接受新请求 ----------------------+
```

目标（store 写回解耦，B 交给跟踪器）：
```
 主 FSM:  S_IDLE --store--> S_WRITE_REQ --(AW&W fired = 数据已落 PMEM)--> S_IDLE'
                                              |（把"待收 B"交给跟踪器）
                                              v
 B-drain: idle --arm--> wait_b --(B.fire)--> idle      （与主 FSM 并行）
 放行下一请求 req_slot_ready = (主FSM 可接受) && (B-drain 空闲 或 本拍能接管 B)
```
- 主 FSM 的 store 分支在 `aw_done && w_done`（数据落地）后**直接回 S_IDLE**，
  并置 `bpend_q`（跟踪器 arm）。
- B-drain 跟踪器：`bpend_q` 期间拉 `bready`，收到 `bvalid` 即清 `bpend_q`。
- `req_slot_ready_w` 增加约束：`!bpend_q || (bvalid 本拍可收)`，保证 I2。

## 4. 寄存器与优先级
- 新增 `bpend_q`（1 bit）：store 数据落地→1，B.fire→0，flush→按 drop 语义清。
- 复位 0。与 flush 同拍：flush 优先（drain 在途 B，不放行新写）。

## 5. 关键路径与权衡
- 放行谓词新增一项 `bpend_q` 判定，组合深度增加极小。
- 收益：store 后紧邻访问可提前一拍以上启动；对 store 密集/读写交替循环
  （branch-resolve-loop、ooo-mem-order、CoreMark 写回）有效。
- 不引入第二个读事务在飞（读仍单 outstanding），把风险限定在"写收尾"这一最小面。

## 6. 验证计划（全绿才保留）
- 三大 gate：模块 TB 112、riscv-tests 271（含 ua AMO/lrsc、ui ld/st/ma_data）、AM 56。
- 重点样本：`ooo-mem-order`（访存顺序）、`branch-resolve-loop`（读写交替）、
  `mem-test`/`string`/`load-store`（历史踩坑样本）、`add`（冒烟）。
- CPI 对比：`eval/npc-eval.sh --all`，期望 branch-resolve-loop / ooo-mem-order 下降，
  全量加权 CPI 下降且无任一 PASS 退化为 FAIL。
- 自校验：eval 自带 dummy smoke；改动后先单测 `ooo-mem-order` + `string` 确认不读旧值。

## 7. 风险与回退
- 风险等级：高（触碰访存顺序/response ownership）。
- 回退点：git 绿检查点（commit `0bb371593` 之后的最新绿提交）。不收敛立即 `git checkout` 回退。
- 参考文献：见 `design/literature/`（LSQ/store buffer/memory disambiguation 待补）。

## 8. 变更记录
- 2026-06-28：建立规范（spec 先行），实现待后续迭代。
