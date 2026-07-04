# Rob — 重排序缓冲

**文件**:`src/core/dispatch/Rob.hh` · **↔ npc**:`OooRob`

## 职责
程序序环形缓冲:dispatch 入队、完成拍标 done、retire 按序出队(精确 commit)、误判 squash walk。

## 状态
- `rob_`:`vector<Entry>` 环;`head_`、`count_`、`size_`。
- `Entry`:`{dyn_id, valid, done, is_halt, is_store, arch_dst, phys_dst, old_phys, fu,
  is_branch, pc, br_target, pred_taken, pred_next_pc, rat_ckpt}`。

## 接口
- `full/empty/count`;`int alloc()`(返回新 rob_idx,内部 `++count`);`Entry& at(idx)`。
- `Entry& head()` / `void pop_head()`(提交队头:置无效 + 进 head + `--count`)。
- `void squash(branch_idx, FreeList&)`:回收分支之后(更年轻)条目,归还其 `phys_dst` 到 free list,截断 count。

## 不变量 / 行为
- **按序精确 commit**:只有 `head().done` 才退休;completion ≠ commit(架构状态在此边界改变)。
- **squash walk**:`k = (branch_idx - head + size) % size`;`[0,k]` 存活,`(k,count)` 全部 squash;
  分支条目本身(位置 k)存活。环回卷、满 ROB、队头分支各边界经 V4 审查逐条确认无 off-by-one。
- squash 只归还更年轻条目的 `phys_dst`(不还 `old_phys`,因未提交);`old_phys` 在正常 commit 时归还。
- 惰性取消:完成事件按 `rob_idx` 命中条目,`CpuTop::on_wakeup` 用 `!valid || dyn_id≠payload0` 守卫
  丢弃错误路径的陈旧完成(dyn_id 全局唯一单调,squash 后槽复用则不匹配)。

## 测试
`tb_modules::test_rob`:alloc/count、squash 回收更年轻并归还 phys(LIFO)、pop_head 提交。
