# Dispatch Log

## 2026-05-30

- 接续用户给出的 WSL 崩溃与 CoreMark 卡死分析，优先复核 fault-trap 后 OoO 访存/flush ownership，而不是把问题归咎于 CoreMark 或 WSL OOM。
- 根据 RTL 协议推导出关键不变量：后端清掉 memory pending 之后，AXI bridge 仍可能持有或即将收到 response；flush 路径必须继续 drain 总线响应，或者显式 drop CPU 侧 response，不能让 bridge 停在 response state。
- 修改 `OooMemAxiBridge`：新增 `flush_i` 与 `drop_rsp_q`，在 read/write/page-walk 各状态下区分 cancel、drain、drop，保证外部 AXI 握手闭合。
- 修改 `OooAluFetchCore` 与 `NpcCoreTop`：新增 `mem_flush_o` 到 memory bridge；trap/local flush 同周期送达，checkpoint restore 使用寄存器延后一拍，避免组合环。
- 首轮 CoreMark 复验发现原先单 outstanding load 卡死消失，但出现空 ROB、decode stop pending、pending arch trap 卡住的第二类 forward-progress 问题。
- 定位第二类问题为 untracked branch recovery 抢占 stop/drain 异常处理；在 stop pending 期间禁止 `branch_resolve_untracked_w`，并在该恢复路径清掉 `pending_arch_trap_q`。
- CoreMark 继续推进后暴露 AM `stdio.c::out_uint()` 在 RV64 高地址栈上的 32-bit 截断问题：GCC/Zba 生成的 `zext.w` 边界导致 reverse digit loop 可能走约 4GB。
- 修改 AM `out_uint()` 为指针回退循环，并新增 `stdio-format` cpu-test 覆盖 CoreMark 风格 `%d`/`%04x` 输出。
- 新增 `tb_ooo_mem_axi_bridge` 覆盖 held response flush-drop、in-flight read flush-drain、partial write flush-drain；同时补齐相关 testbench 端口连接。
- 验证完成：focused RTL tests 4/4 PASS、RV64 lint PASS、CoreMark ITERATIONS=10 PASS 且 CPI=0.783、`stdio-format` cpu-test PASS。
- 环境观察：并发 WSL 命令仍可能触发 `Wsl/Service/0x8007274c` / `E_UNEXPECTED`，随后串行命令恢复；该问题已记录为 WSL/vsock/utility VM 稳定性风险。
- 剩余工作：真实 Linux boot 尚未完成；本轮只修复 fault-trap 后 CoreMark/OoO flush-drain forward-progress 问题，并为后续 mini Linux boot 测试扫清一类关键死锁。
