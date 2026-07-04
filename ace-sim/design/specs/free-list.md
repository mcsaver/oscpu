# FreeList — 物理寄存器空闲列表

**文件**:`src/core/rename/FreeList.hh` · **↔ npc**:`OooFreeList`

## 职责
管理物理寄存器的分配 / 释放。初始 `[num_arch, num_phys)` 空闲(`0..num_arch-1` 由架构寄存器恒等占用)。

## 状态
- `free_`:`vector<int>` 空闲栈(LIFO)。

## 接口
- `bool empty()`:无空闲 → dispatch 停顿(backpressure)。
- `int alloc()`:弹出一个空闲 phys(调用方须先查 `!empty()`;debug 下 assert)。
- `void free(int p)`:归还。

## 不变量 / 行为
- **平衡律**(R10K 式):dispatch 写指令 `alloc` 一个 new_phys;commit 时归还其 `old_phys`;
  squash 时归还错误路径指令的 `phys_dst`(其 `old_phys` 不归还,因未提交)。任一 phys 不双重归还、
  不泄漏(V2/V4 审查逐条确认)。
- 存活下界:`num_phys > num_arch`(否则首条写指令永久停顿);`CpuTop` 构造函数 fail-fast assert。

## 测试
`tb_modules::test_rename_freelist`:非空 → alloc 落在 `[32,64)` → free 后 LIFO 取回。
