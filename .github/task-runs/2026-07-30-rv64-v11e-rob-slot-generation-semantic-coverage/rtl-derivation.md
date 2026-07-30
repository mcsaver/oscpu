# V11E `OooRob` slot-generation RTL 推导

## 组合候选

`dispatch0_rob_idx_o = tail_q`，
`dispatch1_rob_idx_o = tail_q + dispatch0_fire_w`。production RTL 分别从
两个 actual slot 的 `slot_generation_q` 加一，生成 lane0/lane1
ProducerId。`dispatch1_pair_producer_id_o` 始终从 `tail_q + 1` 的
generation 加一，表达双发射 pair candidate；lane1-only 时它不是 actual
lane1 ProducerId。

## 时序写入

`slot_generation_q` 只有两类赋值：

- hard reset edge：所有 slot 写全 1；
- normal state edge：`dispatch0_fire_w` / `dispatch1_fire_w` 分别把该拍
  组合 candidate 写入被接受的 slot。

ordinary flush 分支仅在 `rst` 同时为 1 时重置 generation。recovery walk、
kill-start、writeback、commit 与生命周期清理均不写 generation。

## 可判别观测

定向 testbench 使用独立 `expected_generation[ROB_ENTRIES]`：

- model 只消费 stimulus、沿前 ready/fire、已知 reset/flush/recovery/commit
  事件，不读取 DUT generation 或 ProducerId 来构造 expected；
- 每个候选周期先比较 lane0 actual、lane1 actual 与 lane1 pair ProducerId；
- accepted edge 后比较独立 model 与所有 slot 的登记 generation；
- 通过 head、commit、walk 与 query 接口观察已登记 generation 的 carrier；
- assert/release 使用相同 scoreboard；release 配置不定义 `OOO_ASSERT`。

## 定向变异矩阵

每个变体必须编译成功，并在关闭 `OOO_ASSERT` 时由独立 testbench 拒绝：

1. reset seed 改为全 0；
2. ordinary flush 也重置 generation；
3. candidate 不加一；
4. candidate 加二；
5. lane1 actual 错用 lane0 slot generation；
6. pair candidate 错用 actual lane1 slot；
7. accepted lane0 改为 valid-qualified write；
8. accepted lane1 写到 lane0 slot；
9. commit0 额外推进 head slot generation；
10. recovery squash 额外重置 squashed slot generation。
11. full ROB 借用同沿 commit 释放的 slot；
12. head carrier 把 generation 置零；
13. commit carrier 把 generation 置零；
14. walk0/walk1 carrier 把 generation 置零；
15. current0/current1 query 忽略 generation；
16. completion0..7 query 忽略 generation；
17. resolve query 忽略 generation。

若某个文本变异因 production 源码形态无法唯一命中，runner 必须 fail closed；
不得把未生成或未编译的变体计为被 testbench 检出。

## 最高信息增益实验

- 配置 A：`PRODUCER_GEN_W=1`，覆盖 reset→allocate→commit→reuse、
  flush 保留、selective-recovery 保留与有限回绕；
- 配置 B：当前 production `PRODUCER_GEN_W=4`，覆盖非截断候选和双发射
  独立 source；
- 两种配置各跑 assert/release；
- production baseline 全部 PASS 后再运行变异矩阵；
- 不启动 full-core、Linux、A4、综合或 PPA 流程。
