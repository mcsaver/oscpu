# Dispatch Log

- 读取当前 `NpcCore`/`PipelineControl` 乘法等待逻辑，确认 `ex_muldiv_wait_w` 阻塞 `ex_fire_o` 到乘法响应 valid。
- 检查当前 CoreMark 构建产物：ELF attribute 为 `rv32i_m_c_zicsr_zifencei_zmmul_zba_zbb_zbc_zbs`；反汇编包含硬件乘法指令且无 `__mulsi3`。
- 复跑 CoreMark，得到 `cycles=356772397`、`commits=303899926`、`CPI=1.174`。
- 对比历史记录：旧软件乘法镜像约 746M commits；2026-05-22 硬件乘法/BPU 基线为 `cycles=389956180`、`CPI=1.283`。
- 发现 mul/div 请求可早于 `ex_fire` 捕获操作数；补上 `ex_operand_load_wait_w`，避免源寄存器依赖未返回 load miss 时提前发请求。
- 将 `tb_npc_core_smoke` 改为 `lw miss -> mul` 定向场景，检查 x10=42；定向日志 `/tmp/npc-mul-loadwait-results/logs/tb_npc_core_smoke.log` PASS。
- 跑 `make -C npc/single lint`、full module testbench 27/27、`make -C npc/single -j4`，均 PASS。
- 修补后再次复跑 CoreMark，仍为 `cycles=356772397`、`commits=303899926`、`CPI=1.174`。
- 形成结论：CPI 突降不是当前阻塞式乘法流水本身带来的同流 guest-cycle 优化；应区分镜像重编、2-way cache 消除 DCache 冲突、BPU/工作树差异与 host 仿真速度。
