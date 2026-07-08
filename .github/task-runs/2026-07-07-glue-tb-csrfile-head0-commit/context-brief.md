# Context Brief: glue TB CsrFile head0 commit

- User requested continuing the documented 1/2/3/4 lifecycle work and noted that some listed items may already be complete.
- Current B7 `OOO_CSR_QUEUE_HEAD=1` prerequisites had a stale item: "glue TB CsrFile stub".
- Local context showed `tb_ooo_core_top_glue_csr.svh` already instantiates `CsrFile`; the real gap was that the stub committed CSR state only on `pending_system_csr_commit`, not on the queue-head `head0_csr_commit` pulse.
- `NpcCoreTop` is the reference wiring: `csr_commit_i = pending_system_csr_commit || head0_csr_commit`.
- This task only closes the glue TB flag-ON coverage gap. It does not make `OOO_CSR_QUEUE_HEAD` default-on.

