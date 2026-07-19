# 规范：OooPmaChecker / OooTypedPmaChecker（具体实例静态物理地址属性）

> 模块：`vsrc/memory/OooPmaChecker.v`、`vsrc/memory/OooTypedPmaChecker.v`。
> 状态：**S0 compatibility checker 保持冻结；S1.1 typed 叶模块已实现并定向验证，尚未接 bridge**。

## 1. 目的与边界

`OooPmaChecker` 固化当前 `NpcTop` 实例真正可达的数据读写地址图。它解决的是静态可判定的
physical memory attribute：在 plain store 退休前的 probe 阶段拒绝 default slave、空壳设备、
跨区域和地址回绕，使其形成精确 access fault。它不替代 Sv39、PMP 或设备自身寄存器合法性检查。

checker 是组合、无状态、fail-closed 的叶模块，不从 AXI xbar 反取 decode 结果，以避免形成
LSU request→xbar→LSU authorization 的组合回边。地址常量与 xbar 共用 `define.v` 宏；任何
`NpcTop` slave 实现或优先级变化都必须同步审查本模块和本规范。

## 2. 当前允许地址图

仅允许当前顶层中有真实 RTL 或真实外部端口的区域：

- reset-syscon、CLINT、PLIC、UART；
- virtio-blk、PSRAM、legacy-MMIO、SDRAM。

GPIO、PS2、MROM、VGA、FLASH、ChipLink-MMIO、ChipLink-MEM 与 default 当前都接
`AxiDefaultSlave`，因此拒绝。名义 SRAM decode 完整落在更早、优先级更高的 PLIC 窗口内；
checker 按 xbar 的实际首命中结果允许这些地址为 PLIC，而不把 SRAM 当作独立实现。

## 3. 范围语义

输入 `access_size_i` 是 byte 数；0 防御性按 1 byte 处理。对任意 read/write 请求：

1. 以扩展位宽计算 `last = paddr + size - 1`，溢出即 fault；
2. first 与 last 必须同时被同一个允许 region 完整覆盖；
3. 两个相邻允许 region 之间的跨界访问也拒绝，不把它们拼成一个事务窗口；
4. read/write 均使用同一当前 RW 区域表；无访问请求时 `fault_o=0`。

这是一条 region-level 合同。UART/PLIC 等设备内部未实现 offset 或外部设备运行时拒绝所产生的
R/B `SLVERR` 仍由设备响应路径处理，不能被静态 PMA 预知。

## 4. OooMemAxiBridge 集成

- Bare、DTLB hit 与 PTW leaf 都对最终数据 PA 和原访问 byte size 检查；
- deny 返回 `rsp_error=1,page_fault=0`，不发 data AR/AW/W、不填 DTLB、不进入成功 probe；
- SQ physical-write 的 `pretrans` 路径由 `MEM-PMA-PRETRANS` 断言证明
  PA 来自同一静态地址图认可的先前 probe；
- PTE read/write 是原指令退休前的隐式访问，其 AXI error 已有精确 PTW 响应路径；本模块只检查
  最终数据 PA。

## 5. R4-S1.1 typed 基础类型实现

精确编码和 PBMT 合并矩阵见
[`ooo-memory-typed-abi.md`](ooo-memory-typed-abi.md)。S1.1 的
`OooTypedPmaChecker` 已在完整 byte-range allow/deny 之外输出唯一 PMA 基础类型：

- PMEM 子窗口优先于重叠的较宽 PSRAM decode，输出 CACHED；
- PSRAM residual 与 SDRAM 输出 NC；
- reset-syscon、CLINT、PLIC、UART、virtio-blk、legacy-MMIO 输出 IO；
- default、空壳、wrap、跨 region 与 deny 不产生合法 attr。

PBMT 不在 PMA checker 内合并；`OooTypedMemoryClassifier` 在叶模块级实现唯一合并真值表。
当前 live bridge 仍例化只有 `fault_o` 的旧 `OooPmaChecker`；该文件保持 P0-A 冻结 SHA，
typed checker/classifier 尚未成为 routing authority。因此可以声明 typed 叶模块已实现，不能
声明 post-translation typed ABI 已贯通。

## 6. 验证合同

- `tb_ooo_pma_checker`：真实窗口 allow、所有空壳/default deny、PLIC/SRAM 优先级别名、跨区域、
  地址回绕和 zero-size 防御；
- `tb_ooo_mem_axi_bridge`：Bare 与 Sv39 leaf 的 store probe deny 均返回 access fault，且无 data
  AR/AW/W；
- `tb_ooo_int_backend`：正式 store 指令的 probe error 以 cause=7、原 VA `tval` 写回，SQ 不 fill、
  不 drain；
- mutation-negative：强制 checker allow、绕过 direct deny、绕过 walk deny 都必须被测试拒绝。

## 7. 与动态 B error 的边界

T4N 已改变 store 提交协议：ROB/SQ owner 保持到 physical write 的聚合 B，因而设备动态
`SLVERR/DECERR` 现在都能精确形成 cause 7，且 `tval` 保留 original VA。PMA checker 仍只负责
静态可判定的早期 probe fault；late-B owner 合同见 `ooo-store-bresp-precise-terminal.md`。

## 8. 变更记录

- 2026-07-16（R4-S1.1 typed leaves）：新增独立 `OooTypedPmaChecker` 与
  `OooTypedMemoryClassifier`，完成 enabled/disabled 两组 PMA×PBMT 16 格、fail-closed、断言
  和 mutation-negative；旧 `OooPmaChecker` 精确保持 S0 行为，bridge 迁移留给 S1.2。
- 2026-07-16（R4-S1.0 docs-only）：冻结 CACHED/NC/IO 基础区域映射以及 PMA 与 PBMT 的
  owner 边界；RTL 状态仍为 T4H fault-only checker。
- 2026-07-14（T4H）：建立静态 PMA checker、桥内 direct/walk/pretrans 三条合同和后端精确
  store access-fault 端到端定向测试。
- 2026-07-14（T4N）：ROB/SQ owner 延长到聚合 B，关闭设备动态 B error 的精确异常缺口。
