# V13P independent reviewer result

## Review v1

- contract SHA-256:
  `a652f1d5b1e507403aa02b0154f5193081e200e3ec548c17385e2148481538a2`
- bridge-local direct/fallback/drop correctness: `PASS`
- static backend lifecycle confidence: medium/high
- counterexample: plain-store DRAIN bypasses terminal-collector credit;
  therefore the original “formal-WB + SQ terminal + collector” three-sink
  description was false.
- original cross-module directed proof: `GAP`
- CoreMark: directional single-pair observation only
- mapped PPA/STA: `GAP`

## Review v2 scope extension

- contract SHA-256:
  `350efed8ebf24508aa276328ed8e2358b82cddd27678d222c11a3750dc413cdd`
- real `OooDualMemBridgeWrapper` -> `OooIntBackend` directed lifecycle:
  `PASS`; the task does not force internal DUT signals and its marker matches
  the B/formal-WB, registered commit and SQ release cycle boundaries.
- three independent compile-success mutations: `PASS`; each binds current
  bridge SHA, reaches simulation and is detected by a distinct oracle.
  Their variant SHAs begin `6b1fa7` (duplicate), `46c223` (fallback error
  snapshot) and `586edd` (killed-B exposure); each result records `make_rc=2`.
  Runtime assertion/check markers prove compilation completed, although the
  driver does not store a separate compile return code.  The fallback variant
  proves BRESP snapshot sensitivity, not every owner/data/tval field.
- DRAIN/collector spec correction: `PASS`, consistent with RTL and directed
  TB observation.
- new correctness or fake-green counterexample: none found.
- remaining directed GAP: the real-backend test covers OKAY/direct-ready only;
  SLVERR/DECERR cause7/tval and WB-slot/SQ-terminal/C0 backpressure matrices
  remain bridge-local or untested across the full backend.
- Yosys comparison: reviewer stopped before field-by-field completion at the
  main agent's bounded-return request; independent audit remains `GAP` and the
  result stays diagnostic-only.

The reviewer returned unique WSL shell ownership before main-agent commands
resumed.  This review does not grant PPA promotion.
