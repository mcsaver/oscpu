# NPC / NEMU DiffTest

适用范围：承岳64 当前默认 core/system/tensor 仿真入口。行为真源是
[差分引擎](src/r64_difftest.cpp)、[仿真宿主](../sim/src/r64_sim_main.cpp)、[整核仿真封装](../sim/vsrc/R64CoreTestTop.sv)
及 [系统封装](../sim/vsrc/R64SystemTestTop.sv)，以及 NEMU 的
[导出接口](../../../nemu/src/cpu/difftest/ref.c) 和
[RISC-V 快照实现](../../../nemu/src/isa/riscv64/difftest/dut.c)。

## 两端的职责

NPC 是 DUT，NEMU 是参考模型。[独立差分引擎](src/r64_difftest.cpp) 的 `r64::DiffTest` 通过 `dlopen()` 加载参考共享库，
通过 `dlsym()` 获取执行、寄存器传输、CSR/FPR 快照、trap 与内存读取接口。
必需接口缺失会立即失败，不会退化成只检查通用寄存器。
参考库由本目录的 [Makefile](Makefile) 和 [reference.config](config/reference.config) 构建；
使用它的具体回归见 [验证 README](../testbench/chengyue64/README.md)。

```text
RTL 退休 / trap 事件 ──→ NPC 宿主按架构顺序推进 NEMU
RTL CSR 状态 ──→ csr_snapshot_o ──→ DiffTest::check_csrs() 比较
NEMU cpu.csr ──→ isa_difftest_csr_snapshot()
              ──→ difftest_csr_snapshot(rc) ──→ rc[]
```

`difftest_csr_snapshot(void *buf)` 把 NPC 提供的数组交给
`isa_difftest_csr_snapshot(uint64_t *buf)` 填写。它是独立的只读快照接口，
不经过只传 GPR 和 PC 的 `difftest_regcpy()`。
因此，[DIFFTEST_REG_SIZE](../../../nemu/include/difftest-def.h) 没包含 CSR，
不妨碍这条 NPC/NEMU 扩展链路比较 CSR。

NEMU 作为 DUT 与 Spike 比较时使用的是另一条基础检查路径：
`isa_difftest_checkregs()` 当前只比较 PC/GPR。不要把这条路径的覆盖范围套到 NPC 宿主上。
旧核宿主归 [legacy/sim/](../legacy/sim/)；当前默认宿主位于 [sim/](../sim/README.md)。

## 模块接口与构建

[include/r64_difftest.h](include/r64_difftest.h) 定义独立于 Verilator 的接口：
`ArchitecturalState` 是宿主按退休顺序恢复的 GPR/FPR/PC；`CsrSnapshot` 是 27 项的 RTL
快照；`ReferenceConfig` 提供启动内存、参考磁盘及 UART 观察回调。
`src/r64_difftest.cpp` 单独编译，负责动态库接口、参考模型推进、EEI/计数器对齐和状态比较。
它不依赖宿主全局变量或具体 RTL 包装类。

宿主负责事件采样、时钟和设备调度，在下述边界调用差分引擎；差分引擎不会驱动 DUT。
NEMU 参考构建入口为 [Makefile](Makefile)，配置位于 [config/](config/)，准备脚本位于
[scripts/](scripts/)。从 RV64 根仍可执行 `make difftest-ref`。

## 比较时机

1. 宿主按 lane 0、lane 1 顺序处理本拍有效退休事件，用退休写回信息维护 DUT 的架构 GPR/FPR。
2. 对每条普通退休指令，`DiffTest::step()` 先检查参考 PC，再执行 `difftest_exec(1)`，随后比较
   下一 PC、全部 32 个 GPR 和全部 32 个 FPR。
3. 如本拍还有 trap，先在参考端处理对应异常或中断并检查状态。
4. 有退休或 trap 事件时，在本拍全部事件处理后调用一次 `DiffTest::check_csrs()` 比较 CSR 快照。

CSR 不是每个提交槽单独比较：双退休时，RTL 快照表示整拍更新后的状态，因此参考端也必须先
推进到相同边界。`mret/sret` 没有跳过后续 CSR 检查的特殊宽限。

普通程序的显式 `EBREAK` 在满足结束条件时是一个例外：宿主检查 `a0` 等终态后直接返回，
不会继续对该结束 trap 推进参考模型，也不会执行该拍末尾的 CSR 检查。
`--system` 模式下 `EBREAK` 进入正常异常处理；syscon 正常关机要等待参考端执行相同 MMIO
写入且该拍状态检查完成。

## CSR 快照布局

NEMU 接收至少 32 个 `uint64_t` 的缓冲区，当前填写索引 0–26。
RTL 将第 `i` 项放在 `csr_snapshot_o[64*i +: 64]`；C++ 的 `word()` 读取相应 64 位。
实际比较遍历 0–26，排除 18、19、20。

| 索引 | 内容 | 直接比较 |
| --- | --- | --- |
| 0 | `mstatus` | 是，先规范化参考侧 `SD` |
| 1–5 | `mepc`、`mcause`、`mtvec`、`mtval`、`mscratch` | 是 |
| 6–10 | `sepc`、`scause`、`stvec`、`stval`、`sscratch` | 是 |
| 11–15 | `medeleg`、`mideleg`、`satp`、`mcounteren`、`scounteren` | 是 |
| 16 | 当前特权级 `priv` | 是，这是特权状态字段 |
| 17 | `mie` | 是 |
| 18 | `mip` | 否，异步 pending 状态 |
| 19–20 | `mcycle`、`minstret` | 否，计数状态 |
| 21–22 | `fflags`、`frm` | 是 |
| 23 | 固定零占位 | 是 |
| 24–26 | `tdata1`、`tdata2`、触发器信息常量 `0x01008044` | 是，NEMU 字段依赖 `CONFIG_RISCV_EXT_SDTRIG` |

参考快照导出存储态 `mstatus`，RTL 导出读视图。比较前按 `FS/VS/XS` 是否为 Dirty 计算
`mstatus.SD`；其它位继续比较。NEMU 快照函数上方关于 `mie` 排除的旧注释并不代表当前宿主策略，
实际循环包含索引 17。

快照未列出的 CSR 不在这项直接比较范围内。例如 PMP 配置没有进入该数组，不能据此声称
所有 CSR 都已逐项验证。发现差异会输出 `CSR mismatch`、索引、DUT/REF 值和最近 PC，并失败退出。

## 环境对齐边界

硬件周期与参考指令步数不同。宿主对 cycle/time/instret 读取及选定时间 MMIO 读取，只同步
该指令的目标 GPR，继续比较其它架构效果；系统中的 `mip/sip` 读取只同步返回值的 MTIP 位。
这些规则不是对整份 PC/GPR/CSR 状态的覆盖恢复。

中断由 DUT 的架构 trap 边界驱动参考端；普通同步异常由参考执行检查。平台允许的访存异常优先级、
非对齐访问异常和显式 `EBREAK` 使用源码中明确校验的 EEI 规则。
参考 MMU 能力初始化为 Bare/Sv39，与当前 hart 配置一致。

系统 UART 字节、syscon 与相关内存/设备结果另有检查，具体运行方法见 [系统仿真说明](../sim/README.md)。
Tensor 自定义指令走 `DiffTest::extension()` 的独立描述符、数值结果及 DMA 校验；当前整机定向 oracle
只接受源码明确支持的 F32 ADD 形状，不能由 `tensor-test` 推断任意 NPU 算子均已完成整机验证。
