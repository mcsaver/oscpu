# HIST-SER-QH-YOUNGER-STORE-CYCLE 假设与判别实验

## RTL 对象

本轮只处理本地 RV64 双发射 OoO 核的历史 queue-head CSR / younger
StoreQueue 依赖：

`OooIntBackend.mem_idle_o / mem_retire_quiet_o`
→ `OooRob.head0_csr_mem_hold_w`
→ queue-head CSR C0 retirement。

## 根因假设

历史中间版本把 queue-head CSR 的 `mem_quiet_i` 接为
`mem_idle_o && mem_retire_quiet_o`。其中 `mem_retire_quiet_o` 包含
`sq_empty`，而目标 SQ STORE 年轻于 CSR，只能在 CSR retirement
产生的 C1 flush 后死亡。因此：

1. CSR 等待 younger SQ 为空；
2. younger SQ 又等待 CSR retirement 后的 flush；
3. `head0_csr_mem_hold_w` 持续为 1，构成真实的有界 wait-for cycle。

## 竞争假设

- 当前产品前端能够自然形成 queue-head CSR 与 younger lane1 STORE，
  因而问题仍可在产品路径复现。
- 当前 `mem_idle_o` 足以代表历史 transport idle，backend 双派发状态可直接
  用当前产品 RTL 比较修复前后。
- 历史负向版本只是编译失败、断言触发或无效源码替换，并未到达目标根窗口。
- 既有 older-store positive case 已覆盖 younger-store cycle。

## 最高信息增益实验

同一 backend 原始事件计数器、同一 CSR+younger STORE 定向输入、同一
assertion-on/off 配置矩阵，比较三个可编译语义：

1. `current_owner_guard`：当前产品 owner-lifetime 语义；
2. `historical_fixed`：保留当前 transient transport holder，只从
   `mem_idle_o` 去掉现代 owner-live/terminal-pending 附加项；
3. `historical_cycle`：在 `historical_fixed` 上唯一恢复历史
   `.mem_quiet_i(mem_idle_o && mem_retire_quiet_o)`。

原始计数仅统计 dispatch0/1 acceptance、SQ allocation、probe request/
response、C0 commit/barrier、C1 flush 与 physical non-probe write；
不使用 sticky seen 状态或重复事件抑制。

## 判定条件

- 六个 case 都必须编译成功。
- assertion-on/off 必须分别生成日志并得到相同根窗口语义。
- `historical_fixed` 必须恰有一次 C0/C1、C2 无重复，且 younger STORE
  physical write 为 0。
- `historical_cycle` 必须只在专用根窗口标记被拒绝：
  `mem_idle=1, mem_retire_quiet=0, hold=1, sq_count=1, owner_live=1`。
- 产品前端必须独立证明真实 queue-head CSR birth 的 `lane1_fire=0`；
  backend 双派发只用于 root-cone 判别，不得表述为产品可达波形。
- production `OooIntBackend.v` 和 146-file design-id 前后不得漂移。

## 结果

上述条件全部满足。该历史项达到限域 VD3；它不是完整历史快照或形式化
无限期活性证明，也不改变当前产品 RTL。整体历史账本仍由
`HIST-SER-QH-STOP-HOLD-DROP=VD1` 阻断。
