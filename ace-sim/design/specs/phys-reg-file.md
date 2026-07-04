# PhysRegFile — 物理寄存器堆 + ready 位

**文件**:`src/core/regfile/PhysRegFile.hh` · **↔ npc**:`OooPhysRegFile` + `OooBusyTable`

## 职责
物理寄存器的值 + ready(就绪)位。ready = npc BusyTable 的"非忙";ace-sim 把值与 ready 合并存储。

## 状态
- `regs_`:`vector<{value, ready}>`,`0..num_arch-1` 初始 ready(承载初始架构值)。

## 接口
- `uint64_t value(p)` / `bool ready(p)`:读端口。
- `void write(p, v)`:完成拍写(值 + 置 ready)。
- `void set_unready(p)`:dispatch 分配 dst 时置未就绪。

## 不变量 / 行为
- 生命周期:dispatch `set_unready(new_phys)` → 完成拍 `write(phys, result)`(置 ready)→
  依赖者经 `IssueQueue::wakeup(phys)` 被唤醒。
- squash 归还的 phys 复用时由 dispatch `set_unready` 重置 ready,故陈旧 ready 位不会误导
  (V4 审查确认:realloc 重置 + 存活 IQ 源必更老,双重防御)。
- **completion ≠ commit**:`write` 发生在完成拍;架构状态在 commit 边界由 RAT + 已 ready 的 phys 决定。

## 测试
`tb_modules::test_physregfile`:初始架构就绪 → set_unready → write 后 ready + 值正确。
