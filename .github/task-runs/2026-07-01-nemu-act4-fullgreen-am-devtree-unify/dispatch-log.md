# Dispatch Log：NEMU ACT4 全绿 + AM 设备树统一

| node_id | module | status | 关键动作 | evidence |
| --- | --- | --- | --- | --- |
| act4-run-nemu | am-kernels/nemu | PASS | NEMU 跑 ACT4 全套(I/M/priv-Sv) | I 51/51, M 13/13, priv/Sv 初 0/97 |
| rootcause-priv-sv | nemu | PASS | workflow 多角定位: dcache↔PTW 真bug + Sv48/57 未实现 + robustness | A/B: cache-on FAIL→cache-off PASS |
| fix-dcache-coherence | nemu | PASS | dcache_peek_read/coherent_write, walker 走一致视图 | sv39 0→9, I/M/smoke 无回归 |
| fix-satp-warl | nemu | PASS | 写非法 MODE 保持旧值 | Sv48 satp 不再清0跑飞 |
| fix-oob-accessfault | nemu | PASS | paddr_is_accessible + vaddr 预检抬 access-fault | SIGABRT 32→0 |
| fix-vs-field | nemu | PASS | mstatus/sstatus VS 暴露可写 Dirty(总闸) | sv39 9→27(一修解锁18) |
| impl-sv48-sv57 | nemu | PASS | walker N 级泛化(3/4/5), 对 Sv39 bit-exact | priv/Sv 9→87 |
| impl-tvm | nemu | PASS | MSTATUS_TVM + satp/sfence illegal | 87→88 |
| impl-menvcfg-svnapot-svrsw | nemu | PASS | menvcfg CSR + NAPOT 翻译 + PTE_RSVD 收窄 bits58:54 | 88→97, 全绿 |
| verify-act4-noregr | nemu | PASS | 全套复验 + I/M/smoke | 161/161, config 恢复后仍全绿 |
| diagnose-am-guest | abstract-machine | PASS | dummy 跑飞 pc=0 定位: ebreak halt vs system breakpoint + 简易设备未实现 | pre-#1 binary 亦崩(pre-existing) |
| unify-am-devtree | abstract-machine/nemu | PASS | halt→syscon, timer→goldfish, gpu/input gate, bitmanip march+B, syscon fail-code | CoreMark PASS 81 Marks + GOOD TRAP; cpu-tests 0→53 |
| gate-devmap | Linux | PASS | 三侧设备地址一致性门禁 | check-device-address-map.sh PASS |
| record | .github | PASS | task-run + memory | 本文件 |
| sys-tests-deepfix | am-kernels/nemu | PASS | 深挖 4 个 Sv39/SBI 系统测试: ebreak 恒 breakpoint + AM 测试统一 syscon 退出; linux-mini-boot 页表 map syscon; sbi-timer 补完整 SBI(MTIP→STIP) | cpu-tests 57/57 GOOD; ACT4 161/161; CoreMark PASS 81 |
| rv64dv-intro | am-kernels/nemu | TODO | 引入 riscv-dv 到 am, 仅 NEMU(#6) | — |
