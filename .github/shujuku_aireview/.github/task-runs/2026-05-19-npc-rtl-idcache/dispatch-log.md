# NPC RTL I/D Cache 接入调度记录

## 需求约束
- 将缓存行为从 C/DPI host cache 下沉到可综合 RTL core 内部，DPI 顶层只作为下级内存模型。
- ICache 必须保持当前 RVC 取指语义：PC 允许 2 字节对齐，返回从 PC 开始的 32-bit 小端窗口。
- DCache 接 MemoryStage 的 word-aligned LSU 总线，保证 load/store difftest 功能正确。
- `fence.i` 至少要使后续取指看到已写入 PMEM 的新指令；采用 write-through DCache + ICache invalidate。

## 协议 / FSM / 不变量
- CPU-cache 侧保持现有 ready/valid + 单拍 response 语义：request fire 后 response 至少晚一拍，避免 IfStage 忽略同拍返回。
- cache-memory 侧保持现有一请求一响应下级总线，DPI 顶层仍可用一拍返回模型。
- ICache 为阻塞直映 4KB/64B line：miss 后逐 word refill；请求窗口跨 line 时按需填第二条 line。
- DCache 为阻塞直映 4KB/64B line：load miss refill；store write-through，hit 时更新缓存行，miss 时 no-write-allocate。
- PMEM `[0x80000000, 0x87ffffff]` 为 cacheable；MMIO/越界通过 uncached 下级访问或错误返回。
- `flush_i/fence.i` 使 ICache 失效；DCache 因 write-through 无 dirty 数据，失效即可。

## 数据通路落点
- 新增 `npc/single/vsrc/IDCache.v`，包含 `ICache` 与 `DCache`。
- `NpcCore` 内部在 `IfStage` 与外部 IFU memory port 之间插入 ICache，在 `MemoryStage` 与外部 LSU memory port 之间插入 DCache。
- `NpcSimTop` 不再通过 core ABI 暴露 fence flush；仿真兼容事件用层次化引用观察 core 内部 cache flush 信号。
- `dpi.c` 的总线回调绕过 C host cache，直接访问 `npc_paddr_read/write`，避免 RTL cache 与 host cache 双重建模。
