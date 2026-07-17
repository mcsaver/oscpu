# S2-G1 exact-owner-provenance companion errata

> Status: `active companion ruling / implementation_RED`.
>
> This file does not modify or replace the hash-bound architecture/PPA
> contracts, the typed memory ABI, the frozen completion definition, or the
> frozen pre-RTL derivation.  It records the resolution of an ambiguity found
> during independent focused-review before the affected implementation may be
> called GREEN.

## 1. Bound inputs retained unchanged

| Input | SHA-256 at ruling time |
| --- | --- |
| `npc/rv64/design/specs/ooo-memory-typed-abi.md` | `18a01675f2d38fcda6d9d73c498754af02ac920973aa6f6874cea78a71e57e1a` |
| `s2-g1-exact-owner-provenance-completion-definition.md` | `47d7a4304d5dbf6895cc5e3cec9f12440f8f5c48f42232f21276b6c2aa795568` |
| `s2-g1-exact-owner-provenance-rtl-derivation.md` | `4f92076274d35a087174cf0b56681e81bba1b729d3a9eb10452d639b1ae1e5c9` |

The original files remain the source records.  This erratum is a derived
adjudication and is not allowed to erase their wording or provenance.

## 2. Ambiguity and precedence

The pre-RTL derivation section 0.1 says that an identity-mismatched response
transport may be "drain/pop" while architectural side effects are exact-match
gated.  Read as an MIQ dequeue, that conflicts with typed ABI section 9.2:

```text
response pop only targets the exact head owner
```

The typed ABI is the higher-priority semantic contract.  The word `pop` in the
derivation therefore applies only to consumption of the registered bridge/AXI
response transport item; it does not authorize consuming the MIQ owner entry.

## 3. Implementable ruling

For a registered bridge response and the registered MIQ head:

```text
transport_fire = response_valid && response_ready
identity_match = kind_match && token_match && epoch_match
payload_echo_match = fault_tval_match
miq_pop = transport_fire && identity_match
architectural_side_effect = transport_fire && identity_match && !effective_kill
architectural_fault_tval = captured_miq_or_sq_fault_tval
```

- `response_ready` remains independent of all tuple equality and may drain a
  mismatched transport item without creating a ready/valid loop.
- An identity mismatch must not dequeue or rewrite the MIQ head, must not free its token,
  and must not cause WB, SQ fill/terminal, cache fill/maintenance, or an
  architectural fault.
- `OOO_ASSERT` must terminate on every non-vacuous mismatch.  A nonkill STORE
  mismatch is always fatal.  A non-assert build remains fail-closed with the
  MIQ owner retained for explicit recovery; it must not fabricate completion.
- For an exact response coincident with kill, transport and MIQ accounting
  still complete exactly once, but `effective_kill` suppresses all
  architectural side effects.
- `fault_tval` is provenance payload, not part of the 9-bit owner identity.
  Bridge/request/response/SQ copies must still hold and echo it exactly, and an
  echo mismatch is an immediate contract assertion.  Architectural fault and
  SQ provenance always use the capture-time MIQ/SQ copy, never a response echo,
  live VA, PA, ROB tag, or CSR reconstruction.  This removes a 64-bit equality
  comparator from the normal completion gate without weakening precise-fault
  semantics.  It relies on the separately verified bridge invariant that each
  accepted transport owner produces exactly one terminal event; a token is not
  reusable until that terminal.

## 4. Evidence consequences

The earlier MIQ evidence that treated `mismatch -> count becomes zero` as PASS
is invalid and must not be cited.  Replacement focused evidence must prove:

1. exact tuple response consumes exactly one MIQ head;
2. kind, token, and epoch mutations each drain the transport stimulus while
   preserving MIQ count and the complete head tuple;
3. each identity mutation independently reaches a fatal assertion in an assert
   build; an independent `fault_tval` echo mutation must also assert, while a
   non-assert build consumes the exact 9-bit owner and sources tval only from
   the retained capture-time copy;
4. response-ready/transport acceptance is independent of tuple equality;
5. empty/stale response is a non-vacuous contract-negative;
6. exact response plus kill pops/frees once and produces no target side effect;
7. source manifests bind RTL, every positive/negative testbench, the runner,
   and this erratum.

Until those facts are GREEN, the MIQ leaf and all enclosing R4-S1-ID claims
remain RED.  This ruling does not change the architecture gates, does not
qualify timing or power, and does not create an architecture-feasible seed.
