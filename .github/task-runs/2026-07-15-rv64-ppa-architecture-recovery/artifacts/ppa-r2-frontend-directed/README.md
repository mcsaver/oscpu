# R2 frontend directed test-only patch

This archive contains a testbench-only extension for the canonical R2 frontend.
It changes no RTL. The isolated source baseline was commit
`9bf2f3d22e2c8f7ab7a52ace28cc90334aebddf0`, whose two affected source files
match the canonical workspace byte-for-byte:

- `npc/rv64/testbench/Makefile`:
  `1cc58bc23c76ad068d5d3d399e92ba25d3bdbaf41c57a0f75e1b19df0201e25a`
- `npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv`:
  `4c4fc57877c1233debbbe0cde85076548da7d91af9f48acd3000485a1f9d8195`

## Contents

- `directed-extra.patch`: reproducible patch against the canonical R2 source.
- `tb_ooo_fetch_axi_bridge.sv`: patched testbench snapshot.
- `Makefile.directed`: patched test Makefile snapshot. Its only change adds
  the production RVC decompressor and packet decoder as dependencies of the
  bridge test.
- `*.vvp`: assertion-enabled Icarus simulation artifacts retained from the
  isolated `/tmp/ysyx-ppa-r2-directed-review` worktree.

The patch changes only the two test-infrastructure files listed above. It:

1. raises the existing M-mode/paging-off II=1 turnover baseline from 32 to 64;
2. adds 64 paging-on turnovers alternating U/ASID0 and S/ASID1 contexts;
3. checks conservative fixed-window PMP rejection, exact-halfword PMP fault,
   ITLB permission rejection, and full-SATP/ASID tag isolation;
4. feeds the real `OooFetchPacketDecode` C+32 packet-next-PC output directly
   into the next bridge request.

Apply from the repository root:

```sh
git apply --check .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2-frontend-directed/directed-extra.patch
git apply .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2-frontend-directed/directed-extra.patch
```

No synthesis, STA, or software/Linux boot was run for this directed extension.
The decoder-follow simulation proves functional recurrence and turnover, not
the 5 ns physical timing closure of that recurrence.
