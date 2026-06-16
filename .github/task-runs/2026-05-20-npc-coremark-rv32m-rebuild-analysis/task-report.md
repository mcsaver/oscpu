# NPC CoreMark RV32M Rebuild Analysis

## 任务

用户给出 CoreMark 结束统计，要求结合工作区中的测试程序分析统计是否正确，并据此进行性能优化。

## 结论

旧统计本身是自洽的，但它反映的是旧 guest 镜像状态，而不是当前 NPC RTL 的最佳性能：

- CoreMark 程序主要由 list、matrix、state 三类负载组成，其中 matrix 内层有大量乘法。
- 用户截图中 branch/JAL/JALR 极高，且 progress PC 曾长期落在 `0x80003154` 附近。
- `objdump` 确认 `0x80003154` 是 libgcc `__mulsi3` 软件乘法循环。
- `readelf -A` 确认旧 `core_matrix.o` attribute 只有 `rv32i2p1_zicsr2p0`，说明镜像没有按当前 `rv32imc_zicsr_zifencei_zba_zbb_zbc_zbs` 重新生成。

强制重编 CoreMark 后：

- ELF attribute 更新为 `rv32i_m_c_zicsr_zifencei_zmmul_zba_zbb_zbc_zbs`。
- 反汇编中矩阵内层使用硬件 `mul`。
- `__mulsi3` 引用消失。

## RTL 推导摘要

- 需求：解释统计并寻找实际性能瓶颈。
- 协议规则：先确认统计采样点是否可信，再确认 guest 镜像是否匹配当前 ISA；不能直接把 branch/cache 数字归因到 RTL cache。
- 状态机：本轮未改 core 状态机；现有 DCache/ICache 统计来自 `NpcSimTop.sv` 层次化观察，统计链路可信。
- 不变量：CoreMark PASS 和 CRC 必须保持正确；guest ISA 不能生成 core 不支持的指令。
- 数据通路约束：当前 NPC 已支持 RV32M `mul`，因此 CoreMark matrix 乘法应走 EX 阶段硬件乘法，而不是 libgcc 软件循环。

## 改动

- 强制重编 `am-kernels/benchmarks/coremark` 镜像，消除旧 `rv32i` 构建产物。
- `npc/single/csrc/monitor/monitor.c` 恢复历史长参数兼容：
  - `--max-cycles=N` -> `-m/--max=N`
  - `--progress-interval=N` -> `--progress=N`
  - `--no-progress` -> progress interval 置 0

## 验证

- `make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc -B image` PASS。
- `readelf -A am-kernels/benchmarks/coremark/build/coremark-riscv32-npc.elf` 显示 M/C/bitmanip 扩展 attribute。
- `objdump -d ... | rg '__mulsi3'` 无输出。
- `make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0'` PASS：
  - `CoreMark PASS 13 Marks`
  - `commits=303899931`
  - `cycles=430634002`
  - `CPI=1.417`
  - `simulation frequency=1416158 inst/s`
  - `branch/JAL/JALR total=64666861 (21.3%)`
  - `icache access=313134458 hit=313081296 miss=53162`
  - `dcache access=68831219 hit=67702008 miss=1129211`
  - `write-through store=14443174`
- `make -C npc/single -j4` PASS。
- `./npc/single/build/NpcSimTop --help` 显示兼容参数。
- `./npc/single/build/NpcSimTop ... --max-cycles 1 --no-progress` 可解析参数并按预期 timeout。
- `make -C npc/single lint` PASS。

## 性能对比

旧截图/旧镜像：

- CoreMark 约 `3 Marks`
- commits 约 `746653794`
- branch/JAL/JALR total `228507865 (30.6%)`
- ICache access `839568156`
- DCache access `69449168`

新镜像：

- CoreMark `13 Marks`
- commits `303899931`
- branch/JAL/JALR total `64666861 (21.3%)`
- ICache access `313134458`
- DCache access `68831219`

主要收益来自删除软件乘法循环：提交指令数下降约 59.3%，CoreMark 分数提升约 4.3x。
