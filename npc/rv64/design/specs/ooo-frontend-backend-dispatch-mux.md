# OooFrontendBackendDispatchMux Spec

## Scope

`OooFrontendBackendDispatchMux` owns the pure combinational source selection
between front-end/pending control sources and the two dispatch ports of
`OooAluCoreSlice`.

The module does not allocate ROB/IQ entries, update rename state, create or
clear pending owners, or change ready/valid timing. It only preserves the
legacy priority mux and fire predicates.

## Inputs

- Dispatch source valid facts:
  - branch prefetch dispatch
  - pending system CSR dispatch
  - normal front-end packet dispatch
  - direct branch/JAL/RET dispatch
  - lane1 barrier replay
  - pending jump dispatch
  - pending memory dispatch
  - return-continuation/branch-target/fallthrough lane1 append attempts
- Source payloads from fetch packet head, fetch response decode, branch
  prefetch buffer, pending system/jump/memory state, return-continuation state,
  branch target cache, and direct return target.
- `dispatch0_ready_i` from the backend dispatch port.

## Outputs

- `core_dispatch0/1_valid_o`
- `core_dispatch0/1_pc/next_pc/inst_o`
- `core_dispatch0_csr_rdata_o`
- `core_dispatch0_fire_o`
- `jump_dispatch_fire_o`
- `mem_dispatch_fire_o`

## Priority

Dispatch0 payload priority:

1. Branch prefetch buffered packet
2. Branch prefetch same-cycle response packet
3. Pending system CSR
4. Pending jump
5. Pending memory
6. Direct RET next-PC override
7. Current head slot0 packet

Dispatch1 payload priority:

1. Branch prefetch buffered packet
2. Branch prefetch same-cycle response packet
3. Return-continuation
4. Branch target append
5. Direct RET next-PC override
6. Current head slot1 packet

## Invariants

- Pending jump and pending memory fire only when their dispatch source is valid
  and backend dispatch0 is ready.
- Dispatch0 fire is `core_dispatch0_valid && dispatch0_ready`.
- Dispatch0 CSR read data is nonzero only for pending system CSR dispatch.
- Branch fallthrough append only asserts dispatch1 valid; its payload remains
  the current head slot1 payload, matching the legacy parent expression.
