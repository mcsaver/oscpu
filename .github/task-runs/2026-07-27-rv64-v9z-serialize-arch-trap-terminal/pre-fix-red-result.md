# Pre-fix RED result

- Testbench: `tb_ooo_pending_arch_trap_memory_terminal`
- Configuration: Icarus Verilog, SystemVerilog 2012, `OOO_ASSERT=1`
- Compile result: `0` (success)
- Simulation/check result: non-zero (expected RED)
- Persistent log:
  `pre-fix-red/logs/tb_ooo_pending_arch_trap_memory_terminal.log`

Observed pre-fix failures:

```text
[CHECK-FAIL] V9Z active memory holder blocks drain got=1 expected=0
[CHECK-FAIL] V9Z active memory holder blocks arch trap fire got=1 expected=0
[CHECK-FAIL] V9Z active memory holder blocks trap request got=1 expected=0
[CHECK-FAIL] V9Z active memory holder blocks predictor boundary got=1 expected=0
```

The same run reached the exact-terminal/pending-only positive marker, so the
RED result isolates the missing active-holder qualification rather than a
compile failure or an unrelated testbench setup error.

