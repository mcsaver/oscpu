# V9C INSTRET-G1 independent review summary

## Review identity

- Mode: self-contained, no tools, no shell, no filesystem and no network.
- Contract: `subagent-contracts/v9c-final-review.json`.
- Contract SHA-256: `f6a0920d20ad47f479541a67ee0ae54764b2bd74ebcdd1d613b7e9ab7cb49ad1`.
- Frozen input: `review-packet.md` and the exact hashes listed there.
- Verdict: `PASS`; no P0 or P1 finding.

## Reviewer-preserved claim boundary

The review accepts `INSTRET-G1=CLOSED` only for
`design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`, after reset exit,
while `mcountinhibit.IR=0` and without software writes to `minstret`.  It does not cover WFI product scope,
program-level FENCE.I, inhibit switching, software write/overflow behavior, full-core architecture stability or PPA
promotion.  `ARCH_STABLE=GAP`, `ppa=UNQUALIFIED` and `promotion_eligible=false` remain mandatory.

## P2 residuals

1. The Sv39 program observes a lane-1 exceptional final lane but does not independently prove a lane-1 exception
   event is non-vacuous with a dedicated event counter.  The focused commit-output-mux test covers lane 1; a future
   program variant may add a lane-1-specific exact event without changing the present claim.
2. The cross-cycle edge oracle samples the prior final count.  The program-end equality between `csr_minstret_q` and
   the accumulated final non-exception lane population closes the terminal edge, but the sampling rationale should
   remain explicit when this testbench is extended.
3. Exact local hashes detect accidental or stale-evidence mismatch, but do not independently establish provenance
   when every bound artifact is coherently regenerated.  The accepted trust model is canonical local RTL replay plus
   independent semantic recomputation; cross-authority provenance attestation is outside this workflow claim.

These are limitations, not closure blockers for the stated current-design INSTRET contract.
