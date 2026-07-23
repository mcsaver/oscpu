# Review summary

## V1 current-coverage review

- contract SHA-256: `a220740b551338f882651a140197fb3c96bc3270600a8cea20e3b9ed130b8ed0`
- result: evidence `GAP`, not a confirmed production RTL function error.

V1 requested current-design binding, IFU second-page `F=2/4/6`, LSU owner snapshots,
grant-side `AWSIZE=3`, an 8B partial-cover counterexample and current-source RTL variants.

## V2 current-coverage review

- contract SHA-256: `c89ee2d214f8aae18531859c5275131d2951ad53029d07b551d66178fc4220b5`
- result: narrower evidence `GAP`.

The implementer added direct checker-address-to-`AWADDR` checks, two-cycle payload stalls,
IFU AW-first plus LSU AW-first/W-first acceptance, exactly-once channel scoreboards, B ordering,
and multi-cycle response owner stability. V2 accepted those closures and isolated the remaining
question to the complete deny-to-response-handshake AW/W quiet interval.

## V3 current-coverage review

- contract SHA-256: `862afc6585b0c37aca48e84bedf1bb787c9dedd96c335b3677f338030aff946c`
- result: one concrete evidence `GAP`.

V3 constructed a third stalled-response-cycle AW/W pulse that the earlier two-cycle rows would
not observe. The implementer responded with a deny-pending temporal monitor, READY delays
`0/1/2/3/5`, continuously asserted AW/W READY, and three compile-success variants that pulse AW,
W or AW+W in the third stalled-response cycle.

## V4 current-coverage review

- contract SHA-256: `6b88efd2fe47f23a358a36289d6266278a0bdf155cfb00794e0939fc1d79bad2`
- result: the third-cycle counterexample was closed; one finite-sample `GAP` remained.

V4 observed that delay five does not by itself prove delay six. Rather than extending a finite
delay list indefinitely, the implementer bound the complete production RTL state decode:
AWVALID/WVALID are true only in `S_WRITE_REQ` or `S_AD_UPDATE`; a WRITE deny enters `S_RESP`;
with response READY low, queued advance is disabled and `S_RESP` self-holds. A fail-closed static
cut that adds `S_RESP` to AWVALID is rejected.

## V5 current-coverage review

- contract SHA-256: `7a01e924e4f5c8af71e425417404473506981bceac9afd245b8817a8da775cf9`
- result: `PASS`, strictly for `PTW-PMP-G1` at the bound design ID.
- confidence: high; the conclusion follows by induction over `S_RESP` rather than finite-delay
  extrapolation.
- scope extension: none.

V5 explicitly separated AW/W quiet safety from response liveness, excluded downstream IFU
lane-owner/PC/`tval`, gate-level physical effects and PPA, and found no counterexample compatible
with the supplied complete state assignments and transitions. Reviewer prose was not used as
GREEN evidence; the canonical tests, variants, hashes and structural certificate are the gate.
