# V13Q store-B error/backpressure verification contract

## Classification and boundary

- goal work classification: `verification`
- lightweight agent-flow execution profile: `development`
- secondary intent: close the real-backend V13P correctness GAP
- production RTL: read-only; no V13Q production RTL delta
- current decision: `VERIFICATION_PASS_WITH_DECLARED_GAPS`
- promotion effect: none; V13P remains `NOT_ELIGIBLE_PPA_PENDING`

This slice tests the existing aggregate-B response fusion through the real
`OooDualMemBridgeWrapper -> OooIntBackend -> OooStoreQueue/OooRob` path.  It
does not introduce another CPI mechanism and does not change the V13P RTL.

Production source binding:

- `OooMemAxiBridge.v` SHA-256:
  `86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348`
- `OooIntBackend.v` SHA-256:
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`

The final focused rerun additionally writes a pre/post-stable critical source
manifest covering bridge, wrapper, dual-memory arbiter, backend, SQ, MIQ,
owner tracker/collector, ROB, TB/include and Makefile.  Its SHA-256 is
`51f6e627586e8e40093aaef4df9bc7f7f30c1315ae24a88a306731e10480b139`.

## Falsifiable hypotheses

- H1: direct SLVERR and DECERR B terminals each produce exactly one DRAIN
  response fire, formal WB, SQ terminal, MIQ pop and registered exception
  commit; the exception is cause 7 and `tval` is the untranslated store VA.
- H2: when both formal-WB slots are occupied by real ALU writebacks, aggregate
  B still handshakes at the bridge, the response is captured in `S_RESP`, and
  no DRAIN side effect occurs until formal-WB credit returns.
- competing explanation: a test can appear green by observing global events,
  keeping VA equal to PA, never proving BREADY, or ending before a duplicate
  terminal becomes visible.

## Frozen cycle contract

- `C_B` is the edge with aggregate `BVALID && BREADY`.
- `C_F` is the edge with the target DRAIN `miq_drain_rsp_fire_w`.
- direct-ready requires `C_F=C_B`.
- fallback requires `C_F>C_B`; the accepted B payload and exact owner are held
  in `S_RESP`, and target WB/SQ-terminal/MIQ-pop counts remain zero before
  `C_F`.
- target store commit is forbidden at `C_F`; in the isolated head-ready case
  it first appears from registered ROB state on `C_F+1`.
- STORE owner release occurs through the SQ release mask at the commit edge,
  not through `OooMemOwnerTerminalCollector`.

All exactly-once counters are edge-qualified.  MIQ pop is additionally
filtered by `miq_head_drain_w`, so the earlier Sv39 probe transaction cannot be
counted as the store terminal.

## Directed implementation

- `tb_ooo_int_backend.sv` adds a parameterized real-backend matrix:
  SLVERR direct, DECERR direct and SLVERR with one genuine dual-ALU WB wave.
- Every case runs a real Sv39 root-leaf translation.  VA `0x4000_09xx` maps to
  physical AXI address `0x8000_09xx`, making original-VA checks
  source-sensitive.
- The fallback case proves both WB slots are occupied, proves aggregate B
  handshake, then checks the `S_RESP` snapshot before credit returns.
- The acceptance edge checks exact owner, formal WB, cause 7, original VA,
  one SQ terminal, one DRAIN-specific MIQ pop and collector suppression.
- The following cycle checks registered exception commit and the C0 trap
  barrier.  Three quiet cycles reject duplicate response/WB/terminal/pop or
  commit events.
- The two younger ALUs intentionally remain before architectural recovery; an
  explicit external C1 flush then removes them.  The TB does not silently
  relabel this recovery as store-exception retirement behavior.
- The focused Make target compiles with `OOO_ASSERT` and the existing real
  wrapper source cohort.
- `run-v13q-backend-error-bp-focused.sh` removes stale receipts/logs before
  execution, verifies the declared PASS markers, compares the critical source
  manifest before and after simulation, and atomically installs its PASS JSON.
  Receipt staging is inside the final evidence filesystem and the EXIT trap
  removes only the hidden staging directory.

## Oracle-development corrections

Two early development attempts were diagnostic TB failures, not production
RTL regressions:

1. The first counter counted the earlier translation/probe MIQ pop.  It was
   replaced by a DRAIN-qualified pop counter.  The fallback case also exposed
   that younger ALUs legitimately remain until C1 recovery; the test now
   observes that state and applies an explicit flush.
2. A proposed second consecutive dual-WB wave did not obtain lane-1 dispatch
   credit and therefore did not prove a second stall cycle.  It was removed
   rather than weakening readiness checks or claiming a multi-cycle result.

The final PASS log overwrote the shared focused-log pathname, so these early
raw logs are not claimed as retained artifacts.  Their failure cause and
correction are retained here and in the agent-flow decision trace.

## Result and bounded claim

The three positive cases pass under the real wrapper/backend path.  Three
compile-success negative RTL variants are independently rejected:

- store access-fault cause changed to load access-fault cause;
- formal-WB `tval` changed from original SQ VA to translated MIQ PA;
- backend response-ready changed to ignore formal-WB credit.

Independent review found that the first mutation driver could retain an old
`result.json` if a later rerun stopped before producing new evidence.  The
driver now deletes each old result and runtime log before reconstruction,
installs each receipt atomically only after its runtime rejection marker, and
writes a separate suite PASS receipt only after all three variants complete.
Its staging directory is inside the same task-run evidence filesystem; the
cross-filesystem `mv` counterexample raised during review is closed.

V13P focused direct/fallback/drop tests and V8X backend recovery also remain
PASS.  No assertion was removed or weakened, and no duplicate terminal was
hidden.

Remaining GAPs are explicit: fallback holds for one blocked cycle only;
asymmetric SQ-terminal credit saturation is not directed; store-exception
commit-ready delay is not directed; DECERR is not separately sent through the
fallback snapshot.  Some lifecycle counters are global but remain valid in
this isolated one-target-store matrix; a concurrent-owner extension would
require token/ROB-qualified counters.  The three-cycle quiet window rejects
bounded duplicates, not an unbounded temporal property.  These bounds do not
invalidate the three closed V13Q claims and do prevent promotion-level
overstatement.
