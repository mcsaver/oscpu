# V15Y E1 priority redirect PPA screening

- Evidence runner: `PASS` (synthesis, OpenSTA, traceability, manifest and cleanup completed).
- Candidate decision: `REJECT_PPA_REGRESSION`.
- Candidate simulator-source hash: `6d3607e86b7378c8747a24fc2c9910f8ff435de3db4cbd363e2eb8f31d2acdb8`.
- Candidate canonical RTL design ID: not captured before rollback; it is not reconstructed or guessed.
- Candidate binding: the 127-file synthesis manifest, complete production manifest and STA input manifest retained below `evidence/traceable-6d36-a1/`.
- Reference design: V15X `f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`.

The typed E1 priority port passed the 17-case arbiter test, the core-top glue test,
and a compile-success `OOO_ASSERT_OFF` mutation that removed the E1 PC selection.
It did not improve the mapped implementation:

| Metric | V15X | V15Y | V15Y - V15X |
| --- | ---: | ---: | ---: |
| WNS (ns) | -13.382589340 | -13.473010063 | -0.090420723 |
| TNS (ns) | -315554.093750 | -315652.718750 | -98.625000 |
| Logic-area proxy | 2181706.52 | 2181796.12 | +89.60 |
| Known standard cells | 929223 | 929331 | +108 |
| Vectorless power (W) | 0.136 | 0.136 | 0.000 |

All 40 worst paths still start at the mapped `CsrFile.csr_mtvec_q[63]` cone.  The
endpoint distribution remains 34 JALR-prefetch, 5 redirect-valid and 1
pending-branch-misaligned.  Mapping re-merged the E1/E6 target logic into a
`commit_trap_pc_w`-named cone, so the RTL-level mux split did not survive as a
shorter physical path.

The V15Y RTL/TB/spec delta is therefore rolled back.  Full L0, L1, L2 and L3
were intentionally not run; Ubuntu was not run.  The failed experiment is kept
only as compact PPA, directed-test, mutation, hash and cleanup evidence.
Rollback identity is independently recomputed as V15X
`sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`
over 146 production RTL files; its simulator-source hash is the frozen V15X
value `fc2f3d2b2473a7516ee08714c90ad9e6f2a2ecd3e034aa40b135e0b722cecdf2`.

Authoritative machine-readable decision:
`evidence/rejection-decision.json`.
