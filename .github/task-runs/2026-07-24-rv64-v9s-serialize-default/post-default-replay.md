# V9S post-default replay graph

This graph is inactive until
`rootfs-csr-qh-on-current-systemd-strict-rerun3.status` is `PASS` and its
binding, zero-UART, strict-helper, natural-poweroff, simulator-hash and
cleanup evidence all pass independent reinspection. A bare status token is
not sufficient.

## A. Default transition

The transition must be one coherent architecture edit:

1. `npc/rv64/vsrc/include/define.v`: fallback
   `OOO_CSR_QUEUE_HEAD=1'b1`.
2. `npc/rv64/Makefile`: `OOO_CSR_QUEUE_HEAD ?= 1`.
3. `Linux/Makefile`: `NPC_OOO_CSR_QUEUE_HEAD ?= 1`.
4. The NPC Verilator define must always carry an explicit `0` or `1`, so
   `OOO_CSR_QUEUE_HEAD=0` remains a real rollback configuration after the RTL
   fallback changes to one:
   `+define+OOO_CSR_QUEUE_HEAD=$(if $(filter 1 y,$(OOO_CSR_QUEUE_HEAD)),1,0)`.
5. Update the adjacent `define.v` status comment and
   `npc/rv64/design/arch/serialize-at-retire-phase1.md` so the documented
   default, rollback setting, validated scope, and remaining non-CSR SYSTEM
   owners match the executable configuration.

The edit creates a new RTL source design-id and therefore invalidates every
old `current_design_bound=true` ledger binding until replayed.

## B. Configuration and compile gates

Run in this order under one WSL single-flight owner:

1. default-on lint and full Verilator build;
2. explicit-off lint and full Verilator build;
3. default-on focused queue-head configuration matrix;
4. explicit-off compatibility focused matrix;
5. complete module inventory with the new default;
6. RTL style, producer/holder census, and contract assertion gates.

The build logs must show the effective macro value. Merely observing the
Makefile variable is insufficient.

## C. Current-design control-event evidence

Replay the V9O current-design pipeline against the new source SHA:

1. focused 10-test set;
2. queue-head configuration variants;
3. complete 110-test module aggregate;
4. all 11 compile-success RTL variants;
5. nine directed architecture gates;
6. fail-closed evidence-index verification.

The two queue-head-specific variants must remain compile-success and be
dynamically rejected:

- `pending_csr_owner_ignores_producer_id`;
- `queue_head_mode_requires_both_memory_pair_ids_at_head`.

## D. Fourteen current-design debt bindings

Replay each canonical gate before rebinding:

- `FDG-G1`: `make -C npc/rv64 check-fdg-arch-trap`
- `XRET-G1`: `make -C npc/rv64 check-xret-current-mode`
- `MEM-ISSUE-G1` and `MIQ-FLUSH-G1`:
  `make -C npc/rv64 check-memory-issue-lifecycle`
- `IFU-AXI-G1`: `make -C npc/rv64 check-ifu-axi-flush-drain`
- `IFU-FETCH-G2`: `make -C npc/rv64 check-ifu-fetch-provenance`
- `IFU-ACCESS-G1`: `make -C npc/rv64 check-ifu-access`
- `IFU-TVAL-G1`: `make -C npc/rv64 check-ifu-tval`
- `PTW-PMP-G1`: `make -C npc/rv64 check-ptw-pmp`
- `INSTRET-G1`: `make -C npc/rv64 check-instret-retirement`
- `FENCE-G1`: `make -C npc/rv64 check-fence-ordering`
- `STORE-BRESP-G1`: `make -C npc/rv64 check-memory-ordering`
- `F0-G1`: `make -C npc/rv64 check-functional-aggregate`
- `CONTROL-EVENT-G1`: verify the refreshed V9O evidence index.

Only after all evidence JSON files report the new design-id may the ledger
updater rebind the 14 closed entries and add `SERIALIZE-G1`.

## E. No-override system gate

Build and run the strict Ubuntu rootfs route without passing either
`NPC_OOO_CSR_QUEUE_HEAD` or `OOO_CSR_QUEUE_HEAD`.

The evidence must bind:

- new RTL design-id;
- effective macro value one in the generated Verilator command;
- simulator, Linux Image, OpenSBI, DTB, and rootfs hashes;
- holder/assert configuration;
- VFS/rootfs/systemd milestones;
- strict guest done marker;
- natural poweroff;
- zero runner return code.

An explicit flag-on run, a default-off run, a bounded kernel milestone, or the
absence of an assertion cannot substitute for this gate.

## F. Closure boundary

After A–E pass, `SERIALIZE-G1` may close only for head0 non-FP CSR queue-head
retirement. FP CSR and ECALL/xRET/FENCE/SFENCE/SINVAL/WFI/IRQ pending owners
remain separate architecture items. Full-core arch-stable and physical PPA
remain `GAP/UNQUALIFIED` until their independent blockers are closed.
