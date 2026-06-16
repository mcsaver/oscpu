# Dispatch Log

- 复核当前状态：仓库已有真实 OpenSBI + mini payload smoke，但 next-stage 直接写 UART，尚未通过真实 OpenSBI runtime SBI 服务。
- 选择下一步：新增 S-mode payload，覆盖 Linux early boot 最常见的 SBI base、console、timer 路径。
- 新增 `opensbi-sbi-payload.S`：检查 `a0/a1/DTB`，调用 SBI base `get_spec_version/probe_extension`，probe `TIME` 与 legacy console。
- 增加 console smoke：通过 SBI legacy putchar 输出 `B\n`，验证 payload 不再直接依赖 UART MMIO。
- 增加 timer smoke：通过 SBI TIME `set_timer` 产生未来 timer event，payload 打开 `STIE/SIE` 等待 S-mode timer interrupt。
- 初次运行失败 code 9：timer 设为 0 时 STIP 可能在到达 `wfi` 前 pending，`sepc` 不等于 `wfi`。
- 调整为 `rdtime + 1024` 后仍失败 code 9：OpenSBI ecall 自身耗时可能超过 1024 cycles。
- 调整为 `rdtime + 100000` 后失败 code 7：当前 WFI 不停钟，等待循环 1024 次不足以等到 timer。
- 将等待预算改为 200000，并把 `sepc` 检查放宽为等待循环区间。
- 最终 `smoke-opensbi-sbi` PASS：OpenSBI banner 后输出 `B`，收到 STIP，GOOD TRAP。
