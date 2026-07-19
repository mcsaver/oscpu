# S2-Q1 module-harness adoption audit

> 日期：2026-07-17
>
> 结果：`expected adoption RED / root cause identified`。这不推翻 focused leaf GREEN；它证明 Q1
> 尚未满足共享 module-testbench 的自动发现/结果行合同，因此 source-catalog adoption 继续 HOLD。

## 实际执行

在不改共享 Makefile 的前提下，用 GNU make 命令行变量把 Q1 TB 和 RTL 注入现有
`npc/rv64/testbench/Makefile` 的 `RUN_TEST`/`check_tb_result.py` 路径，并把结果写到：

```text
evidence/r4-s2-q1-mmu-epoch-owner-green/module-testbench/
```

执行结果：

- 既有 IFU/I-cache coherence contract：PASS。
- Q1 Icarus compile：rc=0。
- Q1 OOO_ASSERT simulation：rc=0，命中精确 focused 行
  `[MMU-EPOCH-Q1][PASS] same-cycle-block/quiet/hold/second-request/multi-cause/wrap`。
- 共享 result checker：FAIL，唯一原因为
  `missing exact PASS line for tb_ooo_mmu_epoch_owner`。

失败日志：

```text
evidence/r4-s2-q1-mmu-epoch-owner-green/module-testbench/logs/tb_ooo_mmu_epoch_owner.log
```

## Root cause 与修复合同

`check_tb_result.py` 只接受整行 `PASS <test_name>` 或 `[PASS] <test_name>`；Q1 TB 目前只有专用
focused marker。因此编译/仿真均成功也必须被共享 harness 拒绝，不能把 Make rc=1 擦成 GREEN。

下一补丁应在所有 Q1 directed checks 通过后、`$finish` 前追加且只追加：

```text
PASS tb_ooo_mmu_epoch_owner
```

专用 focused marker必须保留，mutation runner 继续以专用 marker 判定；共享 PASS 行不得由 wrapper
无条件注入，也不得在失败路径输出。完成后需以正式 Makefile registry 目标重跑，而不是继续依赖命令行
变量，且将当前 RED log 与后续 GREEN log 同时保留以证明结果合同确实承重。
