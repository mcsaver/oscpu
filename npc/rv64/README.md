# 承岳64（ChengYue64）v1.0.0

2026-09-16 起，原 `rebuildcore` 正式命名为 **承岳64（ChengYue64）**，作为本目录的默认 RV64 主线。
“承”表示承接旧核积累，“岳”表示建立可持续演进的稳固基础。

- 正式 RTL：[`vsrc/chengyue64/`](vsrc/chengyue64/)；测试：[`testbench/chengyue64/`](testbench/chengyue64/)。
- 版本信息：[`core-version.mk`](core-version.mk)，执行 `make version` 查询。
- 默认产物：`build/chengyue64/`；Linux、NPU 的活动源码引用已同步。
- 旧核源码包：[`../pack/rv64core-legacy-20260916/`](../pack/rv64core-legacy-20260916/README.md)。
- 版本说明、CPI/时序数据和验证范围：[v1.0.0 说明](releases/chengyue64-v1.0.0/README.md)。

本次正式化保持 RTL 内容、`R64CoreTop` / `R64SystemTop` / `R64TensorSystemTop` 模块接口不变。
`rebuild` 目录保留为兼容链接；旧核独有 RTL 已移入归档，原路径通过链接兼容历史工具和测试 oracle。
正式主线继续以时序和 CPI 为优化重点。当前实测 1 ns STA 仍为 **FAIL**，正式命名不改变这一结论。

## 此前系统替换与架构记录

> 2026-09-15：用户已恢复完整替换范围（包含 Linux 与 NPU）。当前任务与缺口见[完整替换记录](design/arch/rv64-replacement.md)。下文此前的暂停/CPU-only 范围属于历史记录。

## 原生双发射乱序核

## 原生系统与旧核消费者替换（2026-09-15）

默认 CPU 为 R64CoreTop，平台为 R64SystemTop；Linux 主入口和完整 NPU runtime/standalone
现已接到新核。旧 PPA runner 的 NpcSimTop 证据格式不适用于这条入口。
2026-09-15 完整功能替换验收已取得 L2 all、Linux 6.6 + PID1 L3 all、NPU 主工作流的通过结果；
L3 完成 23,863,944 次退休、75,766,731 周期及一次自然关机，全程逐退休对拍。
实现取舍、详细验证结果与 Ubuntu/PPA 范围边界见 [完整替换记录](design/arch/rv64-replacement.md)。

系统仿真保持逐退休 PC/GPR/FPR/CSR DiffTest：

```sh
make all difftest-ref
make device-test
make l2-test SYSTEM_CASE=all CORE_THREADS=2
make l3-test SYSTEM_CASE=all CORE_THREADS=2
# 复用已有标准 L2/L3 镜像目录：
make l3-test SYSTEM_IMAGES=/absolute/l3-images SYSTEM_CASE=all CORE_THREADS=2
```

CORE_THREADS 控制宿主 Verilator 线程数，不改变 RTL 时钟或流水拍数。
Linux/Makefile 的 sim/run 默认使用两个线程；核心短回归默认一个线程。

每次 L2/L3 执行保存独立日志、实际命令、模型副本与结果 summary。
仅 all 表示相应层的完整 guest 场景；运行中、超时和缺少终态都不计通过。

直接运行多镜像系统：

```sh
make run IMG=/absolute/fw_jump.bin \
  RUN_ARGS="--system --memory=0x08000000 --load=0x80400000:/absolute/Image --load=0x82300000:/absolute/guest.dtb --load=0x84000000:/absolute/initramfs.cpio --uart-stdin --maxcycles=1500000000 --progress"
```

- --system 让 EBREAK 进入正常异常处理，并以真实 syscon 关机结束。
- --uart-input=MARKER:BYTES 支持按 guest 输出触发测试输入；--uart-stdin 接收真实标准输入。
  实际 UART RTL 支持 8250 的 MCR/MSR/SCR、16 字节 RX FIFO、回环和中断读确认；
  接口传送完整字符，不包含串行位线和波特率时间模型。
- --expect=TEXT 要求关机前出现该输出；它本身不会提前结束仿真。
- --block=/absolute/writable-run.ext4 连接 virtio-mmio IRQ2；直接调用者应传运行副本。
  Linux/Makefile 会自动从模板创建独立副本，参考侧另用独立快照。
- 宿主 block 模型复用 NEMU 的设备代码，但以独立实例运行；ISA 参考的内存、设备、
  磁盘与执行状态独立，完整寄存器/CSR 比较保留。

NPU 主命令保持原入口：

```sh
bash ../../npu/version_0820/scripts/run_rv64_direct_npu_system.sh
```

该顶层内部现为原生 CPU。旧 OoO 内部统计请求不适用，新路径报告实际事务时序。
完整 Linux/PID1、rootfs mount、Ubuntu 和 1 GHz PPA 必须分别依据结果判断，不能相互替代。

本任务从取指到 AXI、提交与异常重写 RV64 RTL，借鉴用户 IFU 的清晰代码风格。
当前默认实现位于 [vsrc/chengyue64](vsrc/chengyue64/)，架构和验证状态见
[架构入口](ARCHITECTURE.md) 与 [详细说明](design/arch/rv64-rebuild.md)。

保留 RV64IMAFDC、Zba/Zbb/Zbc/Zbs、Zicsr/Zifencei、M/S/U、Sv39、PMP×16、
原子操作及 Tensor 命令接口。
Sdtrig 地址触发器及官方 `rv64mi-p-breakpoint` 纳入必过回归。
当前范围包含 OS 和完整 Tensor/NPU 系统验证，实际源码包含 09-08 全核拓扑反馈版。

### 早期冻结版本记录

以下是此前暂停时保留的比较数据，不是当前默认源码的测量结果。
冻结28：112项主模块、全部相关矩阵、352项软件、8项整机定向、
两个完整基准和7个CPI 0.5理想窗口通过。默认仿真／综合入口与85份冻结源一致，严格lint通过。
同源1ns布局前单元优化及hold修复后的setup为−1.543375254ns、hold为+0.005088600ns，
单元面积为3,615,844.96µm²；**1GHz尚未闭合**，默认入口不代表最优PPA版本。

后续联合候选保存在独立快照：31已完成全部CPU回归与整核布局前PPA，
最终setup−1.882808447ns、hold+0.005088600ns、面积3,605,016.80µm²；
32a已全CPU通过并完成整核原始映射，后续单元优化按用户暂停指示未运行；
33已通过146项主模块及矩阵、352项软件、8项整机定向、7个CPI 0.5窗口和两个完整基准，
CoreMark／Dhrystone周期相对32a下降3.2768%／5.9410%。
33 的整核综合在该次暂停时尚未运行；已启动的局部综合对比与报告当时已收尾。
各版本的功能、实际周期、整核时序与暂缓工作见[架构入口](ARCHITECTURE.md)和
[本轮暂停记录](design/arch/rv64-rebuild-pause.md)。

## 当前工程命令

从工作区根运行：

```bash
make -C npc/rv64
make -C npc/rv64 lint
make -C npc/rv64 test
make -C npc/rv64 core-test
make -C npc/rv64 tensor-test    # 原生 Tensor 系统对拍
make -C npc/rv64 software-test  # AM + official ISA + ACT4，全量非 OS 软件
make -C npc/rv64 regression     # CPU 模块、整核、软件、设备及 lint
make -C npc/rv64 run IMG=/absolute/guest.bin RUN_ARGS="--maxcycles=20000000 --progress"
```

`npc/sim BACKEND=rv64` 的 default/lint/run 继续转发到此入口。测试程序以 EBREAK 的 a0=0，
或 ELF 给出的 tohost=1 完成；`--tohost=0x...` 显式传入该地址。
AM、官方 ISA 和 ACT4 均从当前测试源码及明确的 hart 配置构建；不依赖历史 build 目录。
系统仿真保留 RTL 断言、逐指令 GPR/FPR、CSR、真实 UART 字节和参考内存比较。
`core-test` 包含真实整核理想吞吐回归：I-cache自然预热后，7个稳态窗口均需达到768条／384拍（CPI=0.5）；完整NEMU检查仍执行。
外部 AXI-Lite 端点提供 RAM 及已有 legacy RTC/VGA/framebuffer 仿真设备。

```bash
make -C npc/rv64 syn
make -C npc/rv64 sta
```

综合默认 R64CoreTop、icsprout55、1 GHz，全部 CPU 算术和存储数组可见，不使用占位黑盒。
SDC 包含 1 ns 时钟、50 ps uncertainty、400 ps I/O 延迟和 20 fF 输出负载。
1 GHz 是用户指定的新里程碑，当前尚未闭合；500 MHz 结果仅作历史基线。
当前 iEDA 必须用四条显式 edge/check-type 命令才能实际启用50 ps；主 SDC 和报告检查已修正，历史省略flag的报告不具备该余量资格。
这些是布局前约束；没有寄生提取结果时不声称物理签核或合格功耗。


旧优化方向已退出主线。旧用法、自动生成架构记录和构建配方分别保存在
[README.legacy.md](README.legacy.md)、[ARCHITECTURE.legacy.md](ARCHITECTURE.legacy.md)、
[Makefile.legacy](Makefile.legacy)；历史结果不代表新核通过。


真实时序主入口为 OpenSTA（`make sta` / `make sta-opensta`），可通过
`OPENSTA=/absolute/path/to/sta` 指定工具。当前本地构建在
`../../tmp/rv64-opensta/build/sta`。原 iEDA 留在 `make sta-ieda` 用于诊断；
其 ICG path group 漏扣 uncertainty，不能用于含 ICG 设计的时序通过判定。
主入口保持 1 ns、50 ps uncertainty、400 ps I/O、20 fF 输出，setup/hold 任意负值均失败。
`SYNTH_MAX_FANOUT` 控制真实 ABC 缓冲树的扇出目标，默认 8；
`SYNTH_MAP_DELAY_PS` 默认为600，与当前完整组合测量一致；这不是把时钟约束改为600ps。
改变这些值会重新综合，不能复用旧映射结果。


可对原始映射执行真实输入 hold 缓冲修复：

```bash
make -C npc/rv64 sta-hold STA_HOLD_ARGS=--through-logic
```

该入口生成独立的 hold-repaired 网表，验证所插 Liberty 单元是正向缓冲，
校验原有单元类型与收缩缓冲后的连接图，并统计真实新增面积。
默认只处理直接输入到 D 的负 hold 路径；through-logic 也处理输入经过组合逻辑到 D 的路径。
显式增加 --clock-enable 可处理 Liberty 标记的 ICG enable 数据端，默认不处理；时钟引脚始终禁止修改。
对复位等同时进入许多寄存器、又与正常数据路径汇合的短输入，可使用
STA_HOLD_ARGS="--source-branches --clock-enable"：根据实际 min 路径在输入的首个负载前
共享缓冲，避免给正常提交路径的最终 D 端一起补延迟。--source-fanout（默认8）
限制每条缓冲链的负载数量。若短路径终止于数据输出（例如reset到VALID），可再加
--output-branches；仍只在实际输入首个负载前插入正向单元，不改输出逻辑或正常数据分支。
Liberty标记的时钟网络及其经缓冲连接的输入根均排除。工具支持重复 --checks 合并同一逻辑图的 min 报告；
同一 endpoint 的其它短输入在初次修复后可能暴露，仍须完整 STA 判定，不能因已插缓冲就算通过。
它不修改时钟约束、I/O、load 或 uncertainty，也不改变 RTL 拍数；
修复后使用同一 SDC 重新检查全部 setup 与 hold，剩余任意负值仍报失败。
面积比较应使用 sta_area.txt 或 cell-changes.json 中实际参与 STA 的网表面积；
synth_stat.txt 是层次映射结果，可能还含 flatten/opt_clean 删除的冗余单元。

输入 hold 修复可用 `--output-stages 1` 为仅通向顶层数据输出的输入分支指定较短的真实 buffer 链，寄存器分支仍使用 `--stages`。同一首级输入引脚同时通向输出和寄存器时取两者较大值；修复后仍必须按原 SDC 完整检查 setup 和 hold。
