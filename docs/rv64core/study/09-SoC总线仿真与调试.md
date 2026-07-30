# 第 9 章：SoC 总线、仿真与调试观测

## 9.1 Core 不是孤立运行的

一条 `ld` 最终要访问 PMEM；`csrr time` 要看到 CLINT 的时间；UART 输出、PLIC 中断、
VirtIO block 都在 Core 外。当前层次：

```text
NpcSimTop
├── NpcTop
│   ├── NpcCoreTop
│   ├── NpcAxiBus
│   │   └── AxiXbar
│   ├── AxiResetSyscon
│   ├── AxiToUart -> Uart
│   ├── AxiClint
│   ├── AxiPlic
│   └── AxiDefaultSlave × 若干未实现窗口
├── AxiDpiSlave × 外部 memory-backed 窗口
├── AxiVirtioBlk
└── Ooo*Checker（仿真配置下）
```

## 9.2 两个 AXI master

`NpcCoreTop` 对外提供：

- IFU AXI master：取指、ITLB miss PTW、instruction PTE A-bit update；
- LSU AXI master：两个 data bank 经 miss arbiter/lane adapter 合并后的 load/store/PTW/
  D-bit update/MMIO 流量。

IFU 和 LSU 是两个独立 master，可以并行请求；它们在 `AxiXbar` 根据目标 slave 再发生
仲裁。数据侧双 bank 已在进入总线前合成一个 LSU master。

## 9.3 `NpcAxiBus` 与 `AxiXbar`

`NpcAxiBus` 是顶层总线包装，`AxiXbar` 完成两 master 到 16 slave 的路由。每个 AXI
channel 都要保存 owner：

- AR：read address；
- R：read data/response；
- AW：write address；
- W：write data；
- B：write response。

读请求的 slave 选择不能在 response 时重新按地址计算，因为地址 channel 已经结束；
xbar 必须记住哪个 master/slave 拥有该 response。

同理，AW 和 W 可不同拍握手。xbar 不能看到 AWREADY 就忘记 write owner，也不能把另一个
master 的 WDATA 接到前一笔 AWADDR。

当前 `AxiXbar` 是 2-master、16-slave、single-outstanding 子集：每个 slave 做
round-robin，读写彼此独立。slave 的 R 先进入 per-master registered response slice，
下一拍才对 master 可见；AW/W 也要分别 capture 后才能完成 grant。它不是支持任意 burst
并行的通用高性能 AXI fabric。

## 9.4 地址译码与 default slave

地址窗口宏集中在
[`define.v`](../../../npc/rv64/vsrc/include/define.v)，包括 reset syscon、CLINT、PLIC、
UART、VirtIO、SRAM、MROM、VGA、flash、chiplink、PMEM 等。

未实现窗口接 `AxiDefaultSlave`，返回错误响应，不能悄悄读零并声称成功。取指属性通过
`ARPROT[2]` 标识；对 default/权限路由来说，instruction access 与 data access 不应被
无差别处理。

## 9.5 Reset Syscon

`AxiResetSyscon` 提供仿真/平台控制寄存器，软件可通过约定地址请求 reset/shutdown 等
动作。它是 memory-mapped device，仍遵循 AXI byte strobe 和 response。

当前 `syscon_write_valid` 只在成功的 B-channel handshake 后脉冲，而不是看到 W fire 就
产生平台副作用；这样 B 反压不会让同一写被重复执行。

不要把它与 RTL `rst` 输入混淆：

- RTL reset 是硬件初始化信号；
- syscon write 是运行中的软件 transaction，经过总线后请求平台动作。

## 9.6 UART

`AxiToUart` 把 AXI-Lite 风格访问转换为 UART 寄存器访问；`Uart` 保存 TX/RX、状态和中断
相关状态。

这里实现的是 16550 风格教学子集：RX 只有一个 holding byte，TX 始终 ready、没有真实
TX FIFO。因此它足以支撑软件字符 IO，却不能拿来外推完整 UART 吞吐和 FIFO 行为。

软件写 THR：

```text
CPU store -> SQ commit/drain -> LSU AXI -> xbar -> AxiToUart
          -> UART TX side effect -> 仿真终端字符
```

UART 属于 IO/非 cacheable 地址。它不能进入 D-cache，也不能由非对齐 PMEM split 路径拆分。

## 9.7 CLINT

`AxiClint` 提供：

- `mtime`；
- `mtimecmp`；
- software interrupt 等本地中断状态。

当 `mtime >= mtimecmp`，比较事实成立；当前 `mtip` 输出还会注册一拍。Core 的
CSR/privilege 逻辑再决定它何时在精确边界被接纳并委托到 M/S mode。

```wavedrom
{
  "signal": [
    {"name": "clk",            "wave": "p........"},
    {"name": "mtime>=mtimecmp","wave": "0..1....."},
    {"name": "timer_pending",  "wave": "0...1...."},
    {"name": "older drain",    "wave": "1....0..."},
    {"name": "IRQ capture",    "wave": "0....10.."},
    {"name": "trap apply",     "wave": "0.....10."},
    {"name": "xTVEC redirect", "wave": "0......1."}
  ],
  "head": {"text": "设备中断可异步 pending，但只在 Core 精确边界形成 trap"}
}
```

波形是控制关系示意，不表示 mtime comparator 与 trap apply 固定相差四拍。

## 9.8 PLIC

`AxiPlic` 管理外部 interrupt source 的：

- priority；
- pending；
- enable；
- threshold；
- claim/complete。

Core 看到的是聚合后的 external interrupt。软件必须 claim 得到 source ID，服务后再
complete。PLIC 自身并不知道 ROB/commit；精确 interrupt 由 Core control plane 负责。
当前 PLIC 保存 priority、pending、in-service、M/S enable/threshold，claim 会清 pending
并置 in-service，complete 再释放；聚合 `external_irq` 也是注册输出。

## 9.9 `AxiDpiSlave`

`AxiDpiSlave.sv` 是仿真专用 AXI slave，通过 DPI 调用 C++ host memory/device model。
它处理：

- read/write channel handshake；
- byte strobe；
- address/size；
- DPI read/write；
- response。

它不进入可综合 Core。DPI 能让 Verilator 访问宿主 PMEM，但不能借此绕开 Core 的
cache/MMU/PMP/AXI transaction 路径。

读请求在 AR fire 的时钟沿调用 sized DPI，随后保持 R；写侧先分别收集 AW/W，二者齐备
才调用 DPI 并产生 B。非法 size、跨 beat 或 mask 组合应返回错误，而不是静默截断。

## 9.10 `AxiVirtioBlk`

`AxiVirtioBlk.sv` 实现仿真侧 virtio-mmio block device 寄存器/队列交互，与 host block
backend 配合。它是 Linux rootfs 路径的一部分，但存在此 module 不等于完整 rootfs 已启动：
还需要 vring、PLIC 中断、guest driver、VFS mount 和用户态证据。

QueueNotify 完成 host DMA 后，当前模型先发一个注册的 D-cache invalidate-all pulse，
再晚一拍释放 B/IRQ；这个顺序保证 guest 在看到 completion 前不继续使用旧 cache 数据。

## 9.11 `NpcSimTop`

`NpcSimTop.sv` 是仿真顶层：

- 产生/接收 clock/reset；
- 例化 `NpcTop`；
- 连接 DPI memory 和 VirtIO；
- 导出 commit、trap、exit、halt 等观测；
- 收集性能/cache/branch/OoO stats；
- 在 `OOO_ASSERT` 配置下例化部分 checker；
- 使用 XMR 读取内部 debug net。

XMR 对学习很方便，但绑定内部层次名；重构 module/instance 后可能断。它不能成为 Core
功能逻辑的反向输入。

## 9.12 Checker 与 Facts

### 当前 SimTop 旁挂 checker

- `OooAdUpdateChecker`：PTW A/D update transaction；
- `OooRedirectMuxChecker`：redirect winner/payload；
- `OooRedirectSeqChecker`：redirect sequence/flush。

### focused TB 使用的 checker

- `OooBranchDirectionPredictorChecker`；
- `OooFetchPacketCacheChecker`；
- `OooDataWordCacheChecker`。

后三者编译在仓库中，但不在当前 `NpcSimTop` 展开层次；它们由 focused testbench 消费。

### Facts 头文件

`OooBranchDirectionPredictorFacts.vh`、`OooFetchPacketCacheFacts.vh`、
`OooDataWordCacheFacts.vh`、`OooRedirectMuxFacts.vh`、
`OooRedirectSeqFacts.vh` 定义 packed observation layout。checker 和 RTL 必须对同一 bit
含义达成一致，否则 checker 可能“通过”一个错位 bus。

`OooSlotFacts.v` 定义前端 slot packed facts，虽然扩展名是 `.v`，它是 include/header，
不声明 module。

## 9.13 SRAM 行为模型

`Sram4096x199` 为 fetch packet cache payload，`Sram4096x113` 为 D-cache line。两者是
同步读行为模型，并在综合/STA 流程中可被当作宏/blackbox。

SRAM 内容本身不 reset、上电未定义；合法性由 Cache 外部 valid FF 独立拥有。任何在
`valid=0` 时读取到的 payload 都只能视作脏数据，不能参与 hit。

必须区分：

- 仿真模型的 read-during-write 行为；
- 综合宏的端口时序；
- STA placeholder liberty；
- 真实物理 SRAM macro。

仿真 PASS 不能自动证明宏时序签核。

## 9.14 本章相关文件

| 文件 | 职责 |
| --- | --- |
| [`NpcTop.v`](../../../npc/rv64/vsrc/core/NpcTop.v) | Core、总线和片上设备装配 |
| [`NpcCoreTop.v`](../../../npc/rv64/vsrc/core/NpcCoreTop.v) | IFU/dual LSU/glue/CSR Core 边界 |
| [`NpcAxiBus.v`](../../../npc/rv64/vsrc/bus/NpcAxiBus.v) | 两 master/多 slave 总线 wrapper |
| [`AxiXbar.v`](../../../npc/rv64/vsrc/bus/AxiXbar.v) | 地址译码、channel owner 与仲裁 |
| [`AxiDefaultSlave.v`](../../../npc/rv64/vsrc/bus/AxiDefaultSlave.v) | 未实现/非法窗口错误响应 |
| [`AxiResetSyscon.v`](../../../npc/rv64/vsrc/bus/AxiResetSyscon.v) | reset/shutdown syscon |
| [`AxiToUart.v`](../../../npc/rv64/vsrc/bus/AxiToUart.v) | AXI 到 UART 寄存器桥 |
| [`Uart.v`](../../../npc/rv64/vsrc/bus/Uart.v) | UART 状态与 TX/RX |
| [`AxiClint.v`](../../../npc/rv64/vsrc/bus/AxiClint.v) | mtime/mtimecmp/software interrupt |
| [`AxiPlic.v`](../../../npc/rv64/vsrc/bus/AxiPlic.v) | priority/pending/enable/claim-complete |
| [`NpcSimTop.sv`](../../../npc/rv64/vsrc/sim/NpcSimTop.sv) | Verilator 仿真顶层 |
| [`AxiDpiSlave.sv`](../../../npc/rv64/vsrc/sim/AxiDpiSlave.sv) | DPI memory/device AXI slave |
| [`AxiVirtioBlk.sv`](../../../npc/rv64/vsrc/sim/AxiVirtioBlk.sv) | virtio-mmio block 仿真设备 |
| [`Sram4096x199.v`](../../../npc/rv64/vsrc/sram/Sram4096x199.v) | fetch packet cache SRAM |
| [`Sram4096x113.v`](../../../npc/rv64/vsrc/sram/Sram4096x113.v) | D-cache SRAM |

## 9.15 本章检查点

1. 为什么数据双 bank 最终只占一个 LSU AXI master？
2. AW 和 W 不同拍握手时，xbar 必须保存什么？
3. UART 为什么不能 cache，也不能用普通 PMEM split？
4. PLIC pending 为什么不等于 Core 已经进入 trap？
5. debug checker 不进综合是否意味着它可以改变功能逻辑？
