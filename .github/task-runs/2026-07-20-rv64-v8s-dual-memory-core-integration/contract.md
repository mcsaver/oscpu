# v8s/F2 canonical dual-memory integration contract

> Status: frozen for implementation. This contract authorizes an
> `architecture_checkpoint` until every focused hard gate and independent
> implementation review passes. DI-5, OOO-3, overall architecture, and PPA
> promotion remain RED/unqualified throughout F2 because final-PA SQ byte
> query/replay (F3), the 64-cycle IPC gate (F4), equal-capacity banking, and
> arch-stable PPA evidence are intentionally absent.

## 1. Scope and topology

F2 connects the two captured ordinary integer memory reservation owners already
present in `OooIntBackend` to two canonical memory banks. Each bank has its own
`OooMemInflightQueue`, complete expected tuple, bridge station/DTLB/D-cache/FSM,
response, drop, query, and residency face. `NpcCoreTop` replaces the single
`OooMemAxiBridge` instance with `OooDualMemBridgeWrapper`; the wrapper's F0
arbiter remains the only shared raw AXI miss fabric.

Compatibility is explicit: `ENABLE_DUAL_MEM` defaults to zero on reusable
backend wrappers so pre-F2 unit tests keep the v8p serialized contract. The
canonical `NpcCoreTop` path sets it to one through every hierarchy layer. A
source checker must reject a missing parameter handoff, an inactive canonical
setting, a lane1 tie-off, or any mem0/mem1 cross-connection.

F2 does not add a load queue, final-PA SQ alias query, split a cross-page access,
or permit an ordinary store to write memory directly. Existing precise
cross-page-misaligned handling locally terminates before either external bank.

## 2. Six interface contracts

### 2.1 Port, width, clock, reset, and identity

- Both memory faces carry the complete existing request/response/expected,
  tracker-query, station-query, drop, device release/cancel, residency, idle,
  and translate-active fields without truncation.
- Identity is the exact `{owner_kind[1:0], owner_token[4:0], mmu_epoch[1:0]}`
  transport tuple plus the tracker table's full `ProducerId` and the MIQ's ROB,
  destination, operation, address, and fault provenance payload.
- Each bank uses a distinct MIQ and a distinct ROB completion-open query. A
  response from one bridge never reads the other MIQ head or query result.
- All added state is in the existing synchronous active-high reset domain.
  Reset/flush clears both speculative MIQs and both reservation request views;
  already accepted non-killable physical writes remain bridge/SQ owners until
  their exact B/drop terminal under the existing bridge contract.

### 2.2 Request handshake and bank allocation

For each edge-old reservation owner, `bank_sel` is the captured canonical byte
effective address bit `addr[3]`. Sv39 preserves page-offset bit 3. The selection
and all request payload fields remain stable while selected valid is stalled.

The global reservation allocator is one combinational decision over both
owners:

1. local exception, failed SC, or full SQ forward is a local terminal and can
   never also receive an external bank grant;
2. ordinary LOAD/PROBE candidates with different `bank_sel` may both receive a
   grant;
3. candidates for the same bank grant only the smaller ROB distance from the
   edge-old ROB head; ties fail closed to terminal0 and are asserted unreachable;
4. a reservation consumes exactly on its own local terminal, request fire, or
   legacy-mode buffer handoff; F2 disables ordinary buffer handoff and never
   uses `terminal0.valid==0` as a terminal1 prerequisite;
5. all four consume masks `00/01/10/11`, both bank mappings, and single-bank
   backpressure are directed and asserted. No full+consume reservation refill is
   introduced.

Bank0 additionally owns the existing ordered singleton sources with unchanged
priority: SQ physical drain, AMO write phase, and LEGACY AMO/LR/SC. Bank1 accepts
ordinary LOAD/PROBE only. The AMO singleton may launch only when both MIQs are
empty. Singleton launch has atomic priority over both ordinary banks: an
edge-old AMO/LR/SC launch candidate blocks ordinary grant in that same cycle,
and `amo_launch_fire -> !(ordinary_fire_b0 || ordinary_fire_b1)`. While LEGACY
is live, ordinary admission on both banks is closed. The B/final-response release
cycle still observes edge-old LEGACY live and therefore cannot admit an ordinary
request until the following cycle; no release-edge look-through is allowed. A
physical write is legal only from SQ drain or the existing authorized LEGACY
path.

### 2.3 MIQ, response, terminal, and WB handshake

- `request_fire[bankN]` and `miqN_push` are cycle-exact and carry identical
  address and owner tuple. A token cannot be resident in both MIQs.
- Each bridge is per-bank in-order; only the matching MIQ head may pop. A wrong
  tuple drains transport according to the existing bridge/backend poison rules
  but cannot pop accounting or create architectural/cache/SQ side effects.
- Each MIQ entry ends in exactly one response terminal or exact bridge drop;
  response and drop for one token are mutually exclusive.
- A single global allocator first removes edge-old EX0/EX1 occupied WB slots,
  then grants mem0 before mem1 only when one slot remains. With two slots and two
  distinct exact-open responses it grants different slots to both. No response
  independently interprets a nonzero free count as ownership.
- A memory response may fire only when every required sink is available:
  exact terminal-set admission, its unique WB grant when it creates formal WB,
  and its SQ terminal grant when it is a store fault/B terminal. Successful
  store probe fill needs no WB but does need its unique SQ fill port.
- Same-ProducerId dual response is asserted unreachable by no-live-reuse and
  cross-bank residency exclusion. If observed, only the higher-priority raw
  response may claim WB; the other drains to exact terminal/error handling and
  never silently writes a second time.

### 2.4 Stall/ready DAG

Allowed directions are:

```text
reservation Q/payload -> bank select/age allocator -> bankN request valid
bankN request ready -> bankN request fire -> miqN push
bridgeN response Q + miqN/tracker/ROB-open Q
  -> global terminal/SQ/WB allocator -> bridgeN response ready
  -> exact response fire -> unique WB/SQ/collector effects
```

Forbidden directions include response ready into either request valid, mem0
ready into mem1 valid, a live contender into the other bank's payload, terminal
collector dequeue ready into reservation pair capture, and bridge/F0 state into
the other bridge's cache-hit request admission.

### 2.5 Flush, kill, recovery, and memory side effects

- Reservation update order remains `reset/global restore > selective kill >
  consume > capture > hold` independently for both owners.
- A killed ordinary request cannot form WB, SQ fill, SQ terminal, cache update,
  or wakeup. Its MIQ/bridge/tracker identity remains resident until exact
  response/drop terminal; full ProducerId reuse remains fenced by the global
  holder census.
- Response/flush, request-fire/flush, terminal/flush, and later PID recycle are
  directed races. Kill qualification wins architectural side effects even when
  an edge-old ROB query was open.
- Ordinary store requests are probes only. Probe success fills exactly one SQ
  entry through one of two fill ports. Probe fault and physical B are SQ
  terminals; successful probe is not a ROB terminal.
- Two existing SQ terminal CAM ports are globally allocated across up to two
  non-backpressurable local store exceptions and two backpressurable response
  terminals. Local events have priority; responses receive only the remaining
  distinct port(s), and their ready reflects that grant. Thus no response/local
  mux can overwrite a different store owner.
- SQ physical writes remain ROB-head authorized, execute at most once, and are
  routed through bank0. The F1 authorized-B peer-maintenance sideband clears the
  peer cache's affected valid line(s) in the same visibility event; it has no
  ready/ack and must not be reconstructed from request or raw BVALID.

### 2.6 Source of truth

| Fact | Sole source | Forbidden substitute |
| --- | --- | --- |
| reservation payload and bank | captured reservation Q and its canonical byte address bit 3 | raw IQ/PRF input, dispatch lane, bridge lane |
| same-bank age | ROB distance from edge-old head | terminal number, token number, fixed lane priority |
| request owner | selected reservation or explicit SQ/LEGACY singleton Q | address bit alone, live priority after fire |
| response owner | bank-local MIQ head plus exact bridge tuple | other MIQ, response-ready, F0 owner bit |
| full architectural identity | owner tracker token table and full ProducerId generation | raw ROB index, truncated PID |
| WB ownership | one global two-slot allocator | per-response free-count predicate |
| store authority | `OooStoreQueue` exact entry and ROB-head launch authorization | ordinary probe, cache hit, bridge lane |
| terminal lifetime | 32-token lossless collector pending set plus MIQ/bridge/SQ residency | fixed-depth ingress FIFO assumption |
| peer visibility | authorized local B maintenance event and peer D-cache valid clear | invented ack, AW/W fire, raw BVALID |

## 3. Lossless terminal-set proof obligation

The collector is a per-token 32-bit pending set, not an ingress-depth FIFO.
F2 expands the parallel ingress census to include both response sources and all
four bridge drops while retaining reservation, buffer, and AMO-cancel events.
On one edge it validates every ingress against the same edge-old tracker table,
rejects reserved/nonlive/mismatched/pending/dequeue-same-edge/duplicate tokens,
and ORs every pairwise-distinct accepted token into `pending_next`.

Required assertions and mutation targets are:

- every legal ingress tuple is exact-live and all valid ingress tokens in a
  batch are pairwise distinct;
- `pending_next == (pending_old & ~dequeue_fire_mask) | accepted_ingress_mask`;
- accepted count equals the popcount of the accepted token mask and cannot
  exceed the number of edge-old live, nonpending tokens;
- both response candidates receive separate collector admission when their
  tokens differ; duplicate-token candidates are both rejected and fatal;
- dequeue stalls never lose metadata and every admitted token frees exactly
  once.

Because all live owners already occupy unique tracker tokens, a legal new
terminal always has its own not-yet-pending bit. No source performs an
independent shared-free-count test and no terminal pulse is backpressured by a
fictional finite ingress queue.

## 4. Canonical hierarchy and evidence boundary

The following faces must remain independent at every layer:

```text
NpcCoreTop
  OooCoreTopGlue
    OooExecuteBackend
      OooAluCoreSlice
        OooAluDecodeBackend
          OooIntBackend
```

Required evidence before F2 completion is considered:

1. release and `OOO_ASSERT` directed simulation with asymmetric request and
   response sentinel tuples;
2. different-bank LL same-cycle canonical request fire and same-cycle formal
   WB/ROB completion with two free credits;
3. reverse bank mapping, same-bank older selection including a real ROB-index
   wrap boundary, independent request and response backpressure, terminal1-only
   consume, two edge-old EX completions occupying both WB slots followed by
   dual-response hold/recovery, flush races, dual store probe
   fill/fault, SQ/LEGACY exclusion, and empty-MIQ AMO-launch versus dual ordinary
   request competition with no release-edge look-through;
4. full-top elaboration/lint and a fail-closed source checker proving two MIQs,
   two ROB-open queries, two wrapper lanes, parameter enable propagation, exact
   hierarchy wiring, residency union, and cross-bank residency exclusion;
5. compile-success semantic mutations for bank tie-off/swap, age inversion,
   duplicated MIQ head/query result, double WB slot, terminal overwrite,
   response/drop duplication, flush-to-WB escape, ordinary-store direct write,
   singleton launch-gate removal, and canonical wrapper removal;
6. a fresh aggregate with pre/post closure hashes and architecture evidence that
   keeps DI-5/OOO-3/overall/PPA RED.

Until all six groups pass under one closure, the only permitted status is
`architecture_checkpoint`; no F2-complete or performance claim is authorized.
