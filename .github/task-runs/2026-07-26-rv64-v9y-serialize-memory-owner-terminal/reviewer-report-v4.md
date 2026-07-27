# V9Y mutation-provenance review

## Verdict

`PASS`

Object/configuration: refreshed
`evidence/acceptance-mutations/summary.json`,
`OooIntBackend.mem_owner_terminalized_o`,
`OooMemOwnerTerminalCollector.ingress_accept_o`,
`V8W_MEMORY_RECOVERY_FOCUSED`, and `OOO_ASSERT=0`.

The refreshed summary exactly matches the live files:

- `OooIntBackend.v`:
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`
- `OooMemOwnerTerminalCollector.v`:
  `9fe9715767ed3a3f6ac3b00ebec7a3450cfd76df4eef313e4c0293cc39d988ff`
- `tb_ooo_int_backend.sv`:
  `6c86fbe71f7d686d86e97b30d53555bbf23a1288e3925b53e11c08f96acacf7b`

All three assertion-disabled, compile-success RTL variants were rejected:

| Mutation | Expected oracle | Result |
| --- | --- | --- |
| raw ingress used as transfer authority | wrong-epoch holder remains unterminated | rejected |
| collector exported raw valid | wrong-epoch raw ingress is not accepted | rejected |
| production predicate guarded by `OOO_ASSERT` | active holder is not terminalized | rejected |

Each run reached VVP simulation and ended with the expected failing
testbench oracle; the nonzero make result was not a compile failure.

The functional result is PASS and the architecture result is 9/9 GREEN under
the same design ID:
`sha256:3c933ec82fd17c6038335f9208b496cacfb755dfd10b9e419c73f276b5e2a428`.

This verdict inherits the V3 independent RTL review and closes only the V9Y
memory-owner terminalized subrange. Pending architectural trap, seven-kind
serialized exactly-once completion/retirement, `SERIALIZE-G1`,
architecture-stable, Linux flag-on, and PPA remain open.

Contract SHA-256:
`7b5819ed8a4e0ff5bee89196250af6946b5425ae87032c064e738b58f3cb056e`.
The reviewer modified no file, left no process, and returned WSL command
ownership.
