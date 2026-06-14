# NPC cache SRAM/AXI 调度记录

- 2026-05-20 16:xx：读取 AGENTS、copilot instructions、project status、known issues、NPC module memory 与 RTL workflow/memory protocol 说明。
- 2026-05-20 16:xx：梳理现有 `ICache/DCache/NpcCore/NpcSimTop/MemoryStage` 调用链，确定 CPU-side 专用 ready/valid 保持不变，miss-side 改为 AXI。
- 2026-05-20 16:xx：按 RTL workflow 写出需求、协议规则、状态机、不变量和数据通路约束。
- 2026-05-20 16:xx：新增 SRAM-like wrapper，并改造 ICache/DCache 内部阵列与 AXI miss/refill/writeback。
- 2026-05-20 16:xx：改造 `NpcCore` 外部总线 ABI 与 `NpcSimTop` DPI AXI slave。
- 2026-05-20 17:0x：更新 ICache/DCache/pipe testbench，验证 hit 不走 AXI、miss/refill/writeback 走 AXI。
- 2026-05-20 17:1x：修复 Verilator `--build` PCH include 问题，改为 generate + symlink + generated make。
- 2026-05-20 17:1x：`fence-i` 首次回归失败，定位为 write-back DCache invalidate 丢脏线。
- 2026-05-20 17:1x：新增 DCache dirty flush 扫描/写回状态机，核心让 `fence.i` 等待 flush 完成后再失效/重定向。
- 2026-05-20 17:20：完成 lint、模块 testbench、pipe_test、Verilator build、`load-store`、`fence-i` 验证，并更新 memory 与任务记录。
