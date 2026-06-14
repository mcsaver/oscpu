# Dispatch Log

- 复核用户给出的崩溃分析：CoreMark/WSL 崩溃不是单纯 OOM，当前继续推进真实 Linux boot 缺口。
- 跑真实 Debian RISC-V kernel，OpenSBI 在 SBI base `get_mimpid` 处读取 `CSR 0xf13`，确认缺失 `mimpid`。
- 在 `define.v/CsrFile.v` 补 `CSR_MIMPID`，读值固定为 `0`，不加入 writable CSR。
- 扩展 `misa-priv`，把 `mvendorid/marchid/mimpid/mhartid` 纳入特权 CSR 回归。
- 复跑真实 kernel：OpenSBI `mimpid` 缺口消失，但 Linux 进入 `0xffffffff800010bc` early `stvec`/`wfi` 循环。
- 反汇编 Linux `relocate_enable_mmu`，确认 `0x80201014` 会把 `ra` 从低地址调整到 `0xffffffff80001152`。
- 用临时 patch early trap vector 读取 `scause/stval/sepc`，确认 fault 是 instruction page fault，`stval/sepc=0x80201152`。
- 判定根因：direct-return/RAS 把低地址 RAS 项当成架构返回目标，跨 `satp` 地址空间切换后错误取低地址。
- 第一版尝试在 dispatch 组合侧阻止同拍控制流，Verilator 报 UNOPTFLAT 组合环；撤回该方向。
- 改为在 `satp` CSR 写提交边界清预测状态：RAS、return continuation、synthetic lane1 return、branch target cache、JALR BTB。
- 新增 `sv39-ras-relocate` cpu-test，把 Linux relocation 的低 call/高 ra/high-only satp/ret 场景固化成快速回归。
- 运行 `sv39-ras-relocate`：GOOD TRAP at 高半区 `0xffffffff80000080`。
- 运行 focused 回归：`misa-priv sv39-ras-relocate semihost-ebreak counteren-time sbi-timer sbi-base-console bitmanip` 全部 PASS。
- 复跑 `smoke-opensbi-sbi`：OpenSBI runtime SBI payload 仍 PASS，输出 `B`。
- 复跑 CoreMark `ITERATIONS=10`：PASS，`cycles=2518694/commits=3216171/CPI=0.783`，保持低于 0.8。
- 复跑真实 Linux kernel：20M cycles 到 `0xffffffff8051be34`，40M cycles 到 `0xffffffff8021531e`，不再停在 early relocation trap loop，但完整 Linux boot 尚未完成。
