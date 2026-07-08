# Dispatch Log

1. Rechecked worktree and bounded npc-dev context.
2. Located the stale lifecycle item in `serialize-at-retire-phase1.md`: glue MODE_ECALL was listed as needing a CsrFile stub.
3. Compared `tb_ooo_core_top_glue_csr.svh` with `NpcCoreTop`.
4. Root cause found: testbench CsrFile stub existed but did not receive `head0_csr_commit_w`.
5. Patched `tb_ooo_core_top_glue_csr.svh` to add `tb_head0_csr_commit_w`, export it through `TB_OOO_CORE_TOP_GLUE_CSR_PORTS`, and OR it into `csr_commit_i`.
6. Ran default and flag-ON focused glue tests.
7. Updated current lifecycle docs and memory while leaving historical task-run evidence unchanged.
8. Ran `git diff --check` and `check-contract`.

