# NPC one-module-per-file 拆分记录

## 任务目标

- 将 `npc/single/vsrc/IDCache.v` 中并列定义的 `ICache`/`DCache` 拆成一个文件一个 RTL module。
- 将 `npc/single/vsrc/PipelineRegs.v` 中并列定义的 4 个流水线寄存器 module 拆成独立文件。
- 保持 `NpcCore.v` 中的实例名、端口连接、cache 协议和行为不变。
- 保持仿真和纯 RTL 构建清单一致，避免后续综合/查阅时继续依赖多 module 文件。

## RTL 推导摘要

### 需求

- cache 模块按查阅和迭代边界拆分为 `ICache.v`、`DCache.v`。
- 流水线寄存器按阶段边界拆分为 `IfIdPipeReg.v`、`IdExPipeReg.v`、`ExMemPipeReg.v`、`MemWbPipeReg.v`。
- 本轮只改变源码组织，不改变 I/D cache 微结构、流水线寄存器端口、状态机或数据通路。

### 协议规则

- `ICache` CPU-side 仍保持 fetch request/response ready-valid 语义；memory-side 仍用逐 word refill 请求访问原 IF memory bus。
- `DCache` CPU-side 仍保持 LSU request/response ready-valid 语义；memory-side 仍区分 load fill、store write-through 和 uncached 直通访问。
- `NpcCore` 对 `u_icache`、`u_dcache` 的连接不变，因此外部 IF/LSU 与 cache 之间的握手时序不变。
- `NpcCore` 对 `IfIdPipeReg/IdExPipeReg/ExMemPipeReg/MemWbPipeReg` 的实例化不变，因此各流水级推进、清空、kill、leave、load 的寄存器协议不变。

### 状态机

- `ICache` 的 `S_IDLE/S_LOOKUP/S_FILL_REQ/S_FILL_WAIT/S_UNCACHED_REQ/S_UNCACHED_WAIT/S_RESP` 不变。
- `DCache` 的 `S_IDLE/S_LOOKUP/S_FILL_REQ/S_FILL_WAIT/S_STORE_REQ/S_STORE_WAIT/S_UNCACHED_REQ/S_UNCACHED_WAIT/S_RESP` 不变。
- 4 个流水线寄存器 module 的 reset/clear/load/consume/kill/leave 优先级不变。
- 本轮没有新增、删除或重编码状态。

### 不变量

- 每个新增 RTL 文件只定义一个顶层 module。
- `ICache`/`DCache` module 名称和端口列表保持原样，避免破坏 `NpcCore` 实例化。
- `RTL_CORE_SRCS` 同时包含 `ICache.v` 和 `DCache.v`，仿真、lint、综合入口看到同一套纯 RTL 文件。
- `RTL_CORE_SRCS` 同时包含 4 个独立流水线寄存器文件。
- 删除旧 `IDCache.v` 和 `PipelineRegs.v` 后，源文件清单中不再引用这两个聚合文件。
- 静态扫描 `npc/single/vsrc/*.v` 与 `npc/single/vsrc/*.sv`，当前没有多 module 源文件。

### 数据通路约束

- ICache 的 tag/valid/data array、跨 cache line RVC fetch byte assembly、fill path、abort/invalidate path 原样保留。
- DCache 的 tag/valid/data array、load miss refill、store write-through/no-write-allocate、store hit cached word update 原样保留。
- IF/ID、ID/EX、EX/MEM、MEM/WB 流水线寄存器保存的数据字段、清空条件和载入条件原样保留。
- 不新增组合跨模块路径，不改变 cache 到外部 memory bus 的请求地址/数据选择。

## 验证

- `make -C npc/single lint`：PASS。
- `make -C npc/single`：PASS。
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=fence-i run NPC_RUN_ARGS='--diff=default -m 0'`：PASS。
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='--diff=default -m 0'`：PASS。

## 变更文件

- 新增 `npc/single/vsrc/ICache.v`、`npc/single/vsrc/DCache.v`。
- 新增 `npc/single/vsrc/IfIdPipeReg.v`、`IdExPipeReg.v`、`ExMemPipeReg.v`、`MemWbPipeReg.v`。
- 删除 `npc/single/vsrc/IDCache.v`、`npc/single/vsrc/PipelineRegs.v`。
- 更新 `npc/single/Makefile` 的 `RTL_CORE_SRCS`。
