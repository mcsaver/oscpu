# RV64 OpenSBI SBI Runtime Smoke Task Report

## 目标

在已跑通真实 OpenSBI v1.8 handoff 的基础上，让 next-stage S-mode payload 通过真实 OpenSBI runtime SBI 服务完成 base probe、console 输出和 timer interrupt，进一步逼近 Linux early boot 路径。

## 改动

- `npc/rv64/tools/opensbi-sbi-payload.S`
  - 检查 OpenSBI handoff ABI：`a0=hart0`，`a1` 指向 DTB magic。
  - 通过 SBI base extension 调 `get_spec_version`，并 probe `TIME` 与 legacy console。
  - 通过 legacy console putchar 输出 `B\n`，不直接写 UART。
  - 通过 `rdtime + 100000` 调 SBI TIME `set_timer`。
  - 打开 `sie.STIE/sstatus.SIE`，等待并验证 S-mode timer interrupt。

- `npc/rv64/tools/Makefile`
  - 新增 `OPENSBI_SBI_*` 配置项。
  - 新增 `opensbi-sbi-payload.elf/bin` 构建规则。
  - 新增 `smoke-opensbi-sbi` target。

## 调试记录

- 第一版把 timer 设置为 0，OpenSBI 立即触发 STIP，`sepc` 不一定落在 `wfi`。
- 改为 `rdtime + 1024` 后仍可能在 OpenSBI ecall 返回前到期。
- 改为 `rdtime + 100000` 后，当前 `WFI` 模型按 no-op/序列化执行，1024 次等待循环过短。
- 最终等待预算改为 200000 次，验证 STIP 到达；`sepc` 只要求落在等待循环区间，而不绑定到具体 `wfi` 指令。

## 验证

- `make -C npc/rv64/tools smoke-opensbi-sbi OPENSBI_FW_JUMP_BIN=/tmp/ysyx-opensbi/build-npc/platform/generic/firmware/fw_jump.bin OPENSBI_SBI_MAX_CYCLES=8000000`
  - PASS。
  - OpenSBI v1.8 banner 完整输出。
  - payload 通过 SBI legacy console 输出 `B`。
  - GOOD TRAP at `0x8020014c`。
  - `cycles=4472259/commits=4727351/CPI=0.946`。

- `make -C npc/rv64/tools smoke-opensbi OPENSBI_FW_JUMP_BIN=/tmp/ysyx-opensbi/build-npc/platform/generic/firmware/fw_jump.bin OPENSBI_MAX_CYCLES=5000000`
  - PASS。
  - payload 输出 `S`。
  - `cycles=4366855/commits=4626201/CPI=0.944`。

- `make -C npc/rv64/tools smoke-dtb`
  - PASS。
  - `cycles=38987/commits=75158/CPI=0.519`。

- `git diff --check`
  - PASS。

## 剩余限制

这仍是小型 S-mode payload，不是真实 Linux kernel。它证明真实 OpenSBI runtime SBI base/console/time 路径可用；下一步仍要接真实 Linux kernel/rootfs，并补 virtio/blk、多源 PLIC 和 kernel 期望的完整 DTB/设备模型。
