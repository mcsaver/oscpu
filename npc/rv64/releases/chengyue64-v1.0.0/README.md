# 承岳64（ChengYue64）v1.0.0

日期：**2026-09-16**。原开发代号：`rebuildcore`。

承岳64是 `npc/rv64` 的正式默认 RV64 实现。“承”表示承接旧核经验，“岳”表示稳固的架构基础。
本版采用 2026-09-16 已验证的 CPI/时序优化结果，并完成正式命名、目录迁移和旧核封装。

## 正式入口

| 项目 | 入口 |
| --- | --- |
| 版本真源 | [../../core-version.mk](../../core-version.mk) |
| RTL | [../../vsrc/chengyue64/](../../vsrc/chengyue64/) |
| CPU / 系统 / 可选 NPU 顶层 | `R64CoreTop` / `R64SystemTop` / `R64TensorSystemTop` |
| 模块与系统测试 | [../../testbench/chengyue64/](../../testbench/chengyue64/) |
| 默认构建输出 | `npc/rv64/build/chengyue64/` |
| 综合与 STA 约束 | [../../syn/chengyue64.sdc](../../syn/chengyue64.sdc) |
| 旧 rv64core | [../../../pack/rv64core-legacy-20260916/](../../../pack/rv64core-legacy-20260916/README.md) |

从工作区根运行：

```sh
make -C npc/rv64 version
make -C npc/rv64
make -C npc/rv64 lint
make -C npc/rv64 core-test
make -C npc/rv64 test
make -C npc/rv64 software-test
make -C npc/rv64 tensor-test
make -C npc/rv64 l2-test SYSTEM_CASE=all
make -C npc/rv64 l3-test SYSTEM_CASE=all
make -C npc BACKEND=rv64 lint
```

Linux 与 NPU 活动引用使用正式目录。已有 NEMU 的 `rv64-rebuild-reference` 和 ACT4 的
`r64-rebuild` 是独立验证配置标识，保持原值。旧 `rebuild` 源码/测试目录以及
`syn/rebuild.sdc` 保留兼容链接。已有 `build/rebuild` 历史产物保持原处，新构建使用正式输出目录。

## RTL 与架构范围

保持 RV64IMAFDC、Zba/Zbb/Zbc/Zbs、Zicsr/Zifencei、M/S/U、Sv39、16 项 PMP、
Sdtrig、原子操作及 Tensor 接口；旧核独有源码已归档。
本次命名迁移的 85 份原生 RTL/header 内容逐字节不变，共享总线 IP 同样不变。
默认综合清单有 87 份 RTL，不包含旧 OoO 主核。模块名和硬件端口保持稳定。

源清单见 [SOURCE-MANIFEST.json](SOURCE-MANIFEST.json)；
架构与协议从 [../../ARCHITECTURE.md](../../ARCHITECTURE.md) 进入。
旧核归档包括源码、配置、仿真器、测试、设计资料和旧构建入口，保留归档时未提交内容；
原位置的 15 个旧核独有 RTL 目录通过相对链接访问归档副本。

## 性能与时序基线

以下来自本次命名之前、已选用的 2026-09-16 held-ready RTL 测量。
比较基线是同日优化前的 rebuildcore，**不是旧 rv64core**；命名迁移不改变硬件。

| 完整工作负载 | 周期 | 退休指令 | CPI | 相对优化前周期变化 |
| --- | ---: | ---: | ---: | ---: |
| CoreMark，10 次迭代 | 9,241,964 | 3,218,524 | 2.871491404 | −3.460367% |
| Dhrystone，10,000 次迭代 | 14,568,135 | 4,260,670 | 3.419212237 | −4.529761% |

同约束 SystemTop 布局前 STA：icsprout55 TT / 1.2 V / 25 °C、1 ns 周期、
0.05 ns 不确定度、真实 ICG、无黑盒、ABC 600 ps / fanout 8。
setup slack 为 **−2.173909903 ns**，hold slack 为 **−0.036660694 ns**，**1 ns 判定仍为 FAIL**。
面积仅记录；后续以时序与 CPI 为优先优化目标。本版正式化不代表 1 GHz 已闭合或物理签核通过。

数据见 [performance-comparison-20260916.json](performance-comparison-20260916.json)；
优化实现与原始报告见 [2026-09-16 优化记录](../../../../tmp/rv64-cpi-timing-20260916/REPORT.md)。

## 本次迁移验证

实际重新执行并通过：

- CoreTop、SystemTop 严格 lint；完整 TensorSystemTop 严格 lint。
- 正式路径全新构建 `VR64CoreTestTop` 和 `VR64SystemTestTop`。
- 5 个整核定向程序 × 2 个顶层 × 正常/随机停顿，共 **20 次 DiffTest**；
  保留真实 RTL 断言及 PC/GPR/FPR/CSR 比较。
- **7 个吞吐窗口**，每个 768 条指令 / 384 周期，CPI=0.5。
- 系统映像解析测试；UART / 系统 I/O **4 次自然关机**。
- 译码、CSR、RVC、LSU event count、LSU WB request、Service bank pair **6 项定向模块测试**，
  同时覆盖旧核 oracle 的归档链接。
- NPU runtime CMake 配置、NPU standalone 脚本语法、Linux sim 构建命令展开、
  NPC RV64 后端入口解析。
- 新核源码内容一致性、旧核 2,747 个源码条目和压缩包内容核验。

旧核归档的严格 lint 复现原位置相同的 5 条告警并返回失败：
NpcTop 未连接 timer_wait_o / machine_irq_o / supervisor_irq_o，
AxiPlic 存在 GENUNNAMED / BLKSEQ。保留原文件和严格判定，未把它计为通过。

详细命令、返回码及日志位置见 [migration-validation.json](migration-validation.json)。

## 既有系统验证范围

2026-09-16 优化版已经完成 135 项主模块、矩阵、352 项非 OS 软件等回归，记录见
[cpu-validation-20260916.json](cpu-validation-20260916.json)。
2026-09-15 系统接入版完成过 L2 all、Linux 6.6 + PID1 L3 all 与 NPU 主工作流，详见
[完整替换记录](../../design/arch/rv64-replacement.md)。

本次是内容保持的命名与归档迁移，未重新运行完整 Linux 启动、完整 NPU 工作负载或综合/STA。
这些既有结果按各自版本与日期保留；当前版本没有因此获得新的完整系统或时序签核结论。
