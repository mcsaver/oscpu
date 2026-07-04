# StoreQueue — store queue 兼 store buffer

**文件**:`src/core/memory/StoreQueue.hh` · **↔ npc**:`OooStoreQueue`

## 职责
程序序 store 生命周期 + store→load 前递 + 内存消歧 + 按序落存。是全项目"队头=序安全"最敏感的一块
(rv64 主核 LSQ 反复腐蚀的家族)。

## 状态
- `sq_`:`deque<Entry{dyn_id, rob_idx, addr, data, addr_ready, data_ready, committed}>`(程序序);`cap_` 容量。
- **STA/STD 分离(⑥)**:`addr_ready`/`data_ready` 各由一个微 op 独立回填(旧 `ready` 拆成两位)。

## 生命周期
`alloc`(dispatch)→ **STA** `execute_addr`(算地址,`addr_ready`)/ **STD** `execute_data`(取数据,`data_ready`)→ `commit`(退休标 `committed`)→ `drain_one`(按序落存,要求地址+数据俱全)。

## 接口
- `full/empty`;`alloc(dyn,rob)`;`execute_addr(dyn,addr)` / `execute_data(dyn,data)`(各返回该 store 是否此刻俱全);`commit(dyn)`。
- `front_committed()` / `drain_one(mem)`:按程序序把队头已提交 store 落存(`mem->write`),返回是否落存。
- `void squash(branch_dyn)`:丢弃更年轻(未提交)store;`squash_uncommitted()`:精确中断只丢未提交(③)。
- `disambiguate(ld_dyn, addr, &wait, &fwd, &fwd_data)`:见下。

## 内存消歧(核心不变量,STA/STD 后更精确)
在 SQ 里找"**最年轻的更老同址 store**":
- 任一更老 store **地址未知**(`!addr_ready`,STA 未执行)→ `wait`(保守:它可能也命中本地址)。
- 最年轻更老同址 store:**数据就绪**(STD 已执行)→ `fwd`(前递);**数据未就绪** → `wait`(等 STD)。
- 无匹配且更老地址全已知 → 走内存。
- **关键收益**:地址已知但**不同址**的 store 不再阻塞 load(旧模型要等整条 store)—— 地址/数据解耦。

关键自检:store 数据锁在 20 周期 DIV 之后(STD 滞后),异址 load 越过、同址 load 等 STD 再前递,均不读陈旧内存。

## 不变量 / 行为
- **同址写序 = 程序序**:按队头顺序 drain,故内存看到同址 store 的顺序 = 程序序。
- committed store 仍留 SQ 供前递,`drain` 才离队落存 → load 要么前递(在 SQ)要么读内存(已落存),无窗口。
- HALT 前 `CpuTop` 用 `empty()` 做 store buffer fence(先排空再停机)。

## 测试
`tb_modules::test_store_queue`:同址前递选最年轻、不同址走内存、未知更老地址等待、drain 落存、squash 丢更年轻。
