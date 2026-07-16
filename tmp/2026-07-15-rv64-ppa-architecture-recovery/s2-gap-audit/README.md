# S2 gap-audit `/tmp` archive

This directory preserves the three `/tmp/s2-audit-*.txt` memory/context files
created during the read-only post-S1 gap audit.  They are contextual inputs,
not architecture or PPA evidence.  The source files remain in system `/tmp`;
the workspace copies are under `system-tmp/` and are bound by `SHA256SUMS`.

The audit selected `R4-S1-ID exact-owner-provenance` as the next development
checkpoint: close `{owner_kind, owner_token, mmu_epoch}` identity on the
existing single-width path before enabling a second AGU.  DI-3/DI-5 and the
single-reservation part of OOO-2 remain RED throughout this checkpoint.

Verify from the workspace root with:

```sh
sha256sum -c tmp/2026-07-15-rv64-ppa-architecture-recovery/s2-gap-audit/SHA256SUMS
```
