# V9X scope-extension verification v3

RV64 RTL 结论｜对象=CSR lease/queue-head CSR owner/C0→C1 trap-exit holder 与 `evidence/v3-flag-on`｜周期/配置=edge-old→edge-new、`OOO_CSR_QUEUE_HEAD=1`、`OOO_ASSERT`｜TB/EDA 观测=`tb_ooo_core_top_glue_v9o_csr_qh` 返回码 0、V9O/V9P marker 与 `[RESULT] PASS`｜范围=GAP

## Contract binding

- Contract: `reviewer-contract-v3.json`
- SHA-256: `7b9b2991642bc0d6f0db77397d97ad46bbd6c437b2676a0c8ffb7842968a4dbc`
- The verification node wrote only `evidence/v3-flag-on`.

## Three edge chains

1. `system_csr_dispatch_fire_w && drain_complete_w` is statically
   unreachable. A pending CSR makes `pending_replay_wait_o=1`, while
   `drain_complete_o` requires that term to be zero. The exact lease birth
   therefore cannot collide with the stop drain-clear arm.
2. The flag-on positive queue-head path passes, but v3 found that
   `OooControlPlane` reconstructed owner birth from merged
   `core_dispatch0_fire_w` plus current head facts. The backend mux can assert
   merged fire for pending-system injection when the real frontend
   queue-head fire is zero. A direct accepted-fire source or a fail-closed
   equivalence check was required.
3. Trap C0 clears the holder through `late_clear_i` before C1, but the
   trap/exit sequencer did not directly consume the general C1
   `core_local_flush_w` reset. A module-boundary live-holder plus C1 state
   therefore exposed a contract gap even though normal TRAP C0 already clears
   it.

## Flag-on evidence

- Log:
  `evidence/v3-flag-on/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log`
- Log SHA-256:
  `79b1ab996a8ab280a041c8f9b55ed8a84079c8763263a84d0aa725c905e328ef`
- Design identity:
  `sha256:69fe9222e3aa7e92a18bca9a61c93680323193f37b7d0d8f5ee6d7ee3b935c7a`
- Markers:
  `[V9O-CSR-QH-CORE-INTEGRATION]`,
  `[V9O-PENDING-CSR-OWNER-INTEGRATION]`,
  `[V9O-CSR-MEMORY-ORDER-INTEGRATION]`,
  `[V9P-CSR-BRANCH-RECOVERY]`,
  `[V9P-CSR-JALR-RECOVERY]`,
  `[V9P-CSR-JALR-CALLBACK-CHAIN]`, and `[RESULT] PASS`.

The v3 conclusion predates the root-node follow-up correction. It does not
bind the later final design identity. The reviewer returned WSL shell
ownership and made no RTL/spec/TB changes.
