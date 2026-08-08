# V15W head0 CSR permit-block final report

- Candidate: `head0-csr-inflight-permit-block-v1`
- Design ID: `sha256:aafa17f7bd385ad57265875b21f484c2d10a1b668d2f967cd12df1bd73a36aa7`
- Functional result: `PASS` (`L0 + L1 + L2 + L3`)
- Independent review: `PASS_RETAIN`
- PPA result: `UNQUALIFIED`
- 200 MHz achieved: `false`
- Accepted baseline replacement: `false`
- Ubuntu 22.04: `NOT_RUN`
- Frozen receipt: `evidence/head0-csr-permit-block-ab-receipt-v1.json`
- Frozen review: `evidence/independent-frozen-review-v1.md`
- Next target: `csr_trap_mem_valid -> system_csr_dispatch_cancel`

The candidate is retained as a functionally qualified engineering checkpoint. It removes `head0_csr_commit` from the Top40 critical cone without changing the measured CoreMark or Dhrystone transactions, but it does not meet the 5 ns timing target and must not be promoted as the PPA baseline.
