# V15X C0 trap dispatch-closure final report

- Candidate: `trap-c0-dispatch-closure-v1`
- Design ID: `sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`
- Functional result: `PASS` (`L0 + L1 + L2 + L3`)
- Independent review: `PASS_RETAIN`
- PPA result: `UNQUALIFIED`
- 200 MHz achieved: `false`
- Accepted baseline replacement: `false`
- Ubuntu 22.04: `NOT_RUN`
- Frozen receipt: `evidence/trap-c0-dispatch-closure-ab-receipt-v1.json` (`sha256:5f70a728957d13ff519d6ba6b56dd5e9d3d650cbbdb6781311b0395e4a883d18`)
- Frozen review: `evidence/independent-frozen-review-v1.md` (`sha256:b93f23fa8e17be013efbe95b2ba4144986c80d6863cc923eb75e4fdf48480aab`)
- Review contract: `subagent-contracts/rv64-v15x-trap-c0-dispatch-closure-final-frozen-review-v1.json` (`sha256:a2ca3e67b9c10138bbaa77e6d3a1101f8e2d77582b26575fc0b8c3f265206648`)
- Next target: `CsrFile.csr_mtvec_q[63] -> architectural trap target/redirect -> frontend fetch-PC state`

The candidate is retained as a functionally qualified engineering checkpoint.  It removes `csr_trap_mem_valid`, `system_csr_dispatch_cancel`, `system_csr_dispatch_valid`, and `pending_system_inst` from all 40 mapped critical paths without changing the measured CoreMark, Dhrystone, L2, or L3 transactions.  Relative to the parent it improves WNS by `0.27569294 ns` and TNS by `81981.65625 ns`, with unchanged cell count and fixed-toggle relative power and a `0.56` logic-area-proxy increase.  It still violates all 40 paths at 5 ns and must not be promoted as the PPA baseline.
