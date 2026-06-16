# RV64 UART Lane Mux Dispatch Log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`。
- 读取 `.github/memory/modules/npc.md`、`.github/instructions/rtl-generation-workflow.instructions.md`、`.github/instructions/npc-study.instructions.md`、`npc/rv64/README.md`、`npc/rv64/design/study/README.md`、`.github/instructions/verilator-tapeout-realism.instructions.md`。
- 关键约束：RTL 改动必须按四段式留痕；活动 RV64 core/SoC RTL 需要保持可综合边界；仿真壳可用 DPI，但 core/IP 代码不引入不可综合后门；修改后必须给验证证据并更新 memory/task-run。

## PLAN

1. 审计 `npc/rv64/vsrc` 中非 legacy 的仿真式循环/waiver/宽组合热点。
2. 选择本轮低风险目标：`Uart.v` 的 read/write byte-lane procedural loop。
3. 按 RTL 四段式推导并落盘。
4. 补 `tb_uart` 64-bit 实例，覆盖 `NpcTop` 实际 `DATA_W=64/STRB_W=8`。
5. 跑 focused TB、lint、build、UART 输出 smoke、静态扫描与 diff check。
6. 回写 `.github/memory/**` 与本 task-run。

## DISPATCH

- 发现 `Uart.v` 中旧实现用 `read_lane_i/write_lane_i` procedural loop 按 `STRB_W` 访问 16550 subset 寄存器窗口。
- 第一版改为 `uart_read_byte()` + packed register function，`tb_uart` 暴露 FCR/LCR/DLL/DLM 读回失败。
- 定位：寄存器本身已正确更新，读数据未刷新；根因是连续赋值调用的 function 隐式引用外部状态，Icarus 在入参不变时没有随外部寄存器变化重算。
- 最终实现：
  - `uart_read_byte()` 的 `dlab/fifo/irq/ier/dll/dlm/lcr` 均改成显式入参。
  - 读路径固定展开 32/64-bit lane。
  - 写路径固定展开 8 个 byte lane，生成 `ier_next_r/dll_next_r/dlm_next_r/fcr_next_r/lcr_next_r`。
  - 时序块只做 reset 和 nonblocking 寄存器落库。

## VERIFY

- `make -C npc/rv64/testbench TESTS="tb_uart tb_axi_lite_to_uart" run`
  - PASS，结果目录：`npc/rv64/perf/results/20260604-112644/module-testbench`
- 静态扫描：
  - `rg -n "for \(|read_lane|write_lane|integer .*lane" npc/rv64/vsrc/bus/Uart.v`
  - 无命中。
- `make -C npc/rv64 lint`
  - PASS。
- `make -C npc/rv64 -j2`
  - PASS。
- `make -C Linux/tools smoke-opensbi`
  - PASS，OpenSBI v1.8 banner 与 `S` marker 可见，GOOD TRAP。
  - 统计：`cycles=4847043`，`commits=4626235`，build time `11:27:42, Jun 4 2026`。
- `git diff --check -- npc/rv64/vsrc/bus/Uart.v npc/rv64/testbench/tests/tb_uart.sv`
  - PASS。

## ADAPT

- `make -C Linux ARCH=riscv64-npc smoke-opensbi` 失败在重建 OpenSBI 阶段，报 generic platform MIPS/Andes 相关 undefined reference，未进入 NPC；该失败与本轮 UART RTL 改动无直接关系。
- 为获得端到端 UART 输出证据，改跑历史 `Linux/tools smoke-opensbi`，使用既有 OpenSBI firmware 并通过 NPC/UART 输出 banner 与 marker。

## RECORD

- 更新 `.github/memory/project-status.md`。
- 更新 `.github/memory/modules/npc.md`，包含 RTL 四段式摘要。
- 更新 `.github/memory/known-issues.md`，追加 UART lane PPA 更新与函数隐式依赖教训。
