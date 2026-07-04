# RenameMap — 推测寄存器别名表(RAT)

**文件**:`src/core/rename/RenameMap.hh` · **↔ npc**:`OooRenameMap`

## 职责
维护架构寄存器 → 物理寄存器的推测映射;分支处快照,误判时回滚(= npc 的 ROB-walk 恢复)。

## 状态
- `map_`:`vector<int>`,`map_[arch] = phys`,初值恒等(`map_[i]=i`)。

## 接口
- `int phys(arch)`:读端口(rename 源)。
- `int remap(arch, new_phys)`:写端口(rename 目的),返回**旧映射**(供 commit 时释放)。
- `vector<int> snapshot()`:整表快照(分支检查点)。
- `void restore(ckpt)`:整表回滚。

## 不变量 / 行为
- 分支无目的寄存器,故其 `snapshot()` = 分支前后的 RAT(回滚点精确落在分支之后)。
- 每个物理寄存器同时至多被一个架构寄存器映射;`remap` 返回的旧 phys 交由 `Rob`/`CpuTop`
  在 commit 时归还 `FreeList`,squash 时不归还(错误路径指令未提交)。
- **回滚正确性**:整表快照 + 整表 restore,故嵌套误判各自独立恢复,无增量 walk 的耦合腐蚀
  (V4 审查确认)。

## 测试
`tb_modules::test_rename_freelist`:恒等 → remap 返回旧值 → snapshot/remap/restore 回滚。
