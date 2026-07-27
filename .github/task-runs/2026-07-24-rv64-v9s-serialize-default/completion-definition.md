# V9S completion definition

`SERIALIZE-G1` may close for the current design only when all items below hold:

1. `OOO_CSR_QUEUE_HEAD=1` passes current-design strict rootfs guest checks and
   natural poweroff with the simulator and boot artifacts hash-bound.
2. RTL, `npc/rv64/Makefile`, and `Linux/Makefile` use one consistent default.
3. The changed default is replayed through focused/config, complete module
   inventory, compile-success RTL variants, full-state DiffTest, functional
   aggregate, and applicable Linux gates.
4. `architecture-debt-ledger.json` binds `SERIALIZE-G1` closure to the current
   design and evidence hashes.
5. The full-core candidate remains `GAP/PPA UNQUALIFIED` unless every separate
   arch-stable blocker is closed.

Any timeout, RTL assertion, guest-check failure, binding mismatch, or source
change keeps this slice `GAP` and leaves the defaults unchanged.
