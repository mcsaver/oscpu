# S1 typed ABI `/tmp` evidence archive

This directory is the workspace-resident, byte-preserving archive of every
`/tmp/s1-*` artifact related to the S1 typed-memory ABI focused repair as of
2026-07-16 13:31 Asia/Shanghai.  Failed intermediate runs are retained beside
the final passing runs; they are not promotion evidence.

## Source and layout

- Source namespace: host WSL `/tmp/s1-*`
- Archived payload: `system-tmp/`
- File integrity inventory: `SHA256SUMS`
- Copy method: metadata-preserving `cp -a`; source files were not removed
- Scope: 23 top-level objects and 29 regular files, including build products,
  compile/run logs, the
  independent review logs, and `/tmp/s1-fault-review-brief.txt`

The archive intentionally contains these failed development checkpoints:
`s1-backend-test`, `s1-backend-test2`, `s1-backend-test4`,
`s1-bridge-test`, `s1-bridge-test2`, and `s1-bridge-test3`.  Passing focused
evidence is in `s1-backend-test5`, `s1-bridge-test4`, `s1-sq`, `s1-wrap`, and
`s1-typed-classifier`.  Independent reruns are in
`s1-fault-review-final-results` and `s1-fault-review-final-bridge-results`.
The final public response-provenance coverage is in `s1-attr-stall-v2`; its
pre-marker development run `s1-attr-stall-v1` is retained as well.  The
workspace copy also retains `s1-archive-verify.log`, which recorded the first
archive verification before those two final coverage runs were appended.

## Stable source hashes at review freeze

- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`:
  `8306c391cf797c2e320b9f79c2dfe4bc8702911ea13e330a055d752c9f492437`
- `npc/rv64/vsrc/execute/OooIntBackend.v`:
  `65ab94f68c5e07e04dbeb515ac034100fdf1113fc3fb796fbe06e79c2add3bdc`
- `npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv`:
  `d9ea7a1bbb23db3938fb78f613c6998f1f21db10008b326f27ee4bf59f177c9a`
- `npc/rv64/vsrc/memory/OooMemAxiBridge.v`:
  `47ee45d3045b67cf4eb1f7da9b4db3c20a4f73b7abfa46079cdb741e02624652`
- `npc/rv64/testbench/Makefile`:
  `9087a53d8a9a8449c594182443531a86eb625c87b8b48d93603d41db88665181`

After the public B-response attr-stall coverage was added, the final
`tb_ooo_mem_axi_bridge.sv` SHA-256 became
`6e5430a7c6443028fc29292f62c0efbed9d170172dd292e6504f838d3c3b5c61`.
The corresponding passing log SHA-256 is
`1d3da45c0d8a358e7b64ea3c2b3a8178ec6d20bde8ac06733649dc72def1333a`.

## Qualification boundary

This is focused S1 development evidence only.  Linux, the full 103-test
regression, synthesis, STA, and PPA were not run.  The hash-bound contract's
102-test inventory drift remains a formal-promotion blocker.  The forwarding
test uses public stimulus/commit oracles plus hierarchical timing oracles; it
is non-vacuous but is not represented as a pure black-box proof.

Verify the copied payload from the workspace root with:

```sh
sha256sum -c tmp/2026-07-15-rv64-ppa-architecture-recovery/s1-typed-abi/SHA256SUMS
```
