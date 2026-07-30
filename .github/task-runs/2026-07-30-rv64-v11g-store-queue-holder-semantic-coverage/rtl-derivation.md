# V11G StoreQueue holder cycle derivation

| Event | Edge-old qualification | Edge-new holder state |
|---|---|---|
| allocation | `alloc*_valid_i && alloc*_ready_o && !flush_valid_i` | each accepted slot captures the full ProducerId, sets `valid_q`, and starts with `owner_valid_q=0` |
| owner bind | old valid, unbound entry; exact full ProducerId and ROB-index CAM | captures independent `{kind, token, epoch}` and makes the owner tuple resident |
| fill | exact ROB plus resident owner tuple | updates payload/fill state only; both identities remain unchanged |
| request fire | physical head, filled typed entry, exact ROB-head full P | sets `request_sent_q`; ProducerId and owner tuple remain resident |
| B/probe terminal | exact ROB plus resident owner tuple, including bind bypass | sets `terminal_q`; neither holder dies |
| ROB release | physical head, exact full P, old/current terminal | clears `valid_q` and `owner_valid_q`, emits one token bit, advances head |
| selective flush | inclusive circular-age prefix plus any request-sent entry | clears both valid domains only for the younger suffix |
| global flush | request-sent entries survive defensively | speculative owners die; accepted physical owner remains |
| terminal+release+flush | terminal bypass authorizes release; survive count subtracts released head | leaves no ghost entry or count |
| bind+terminal+release | bind CAM feeds terminal and token-mask bypasses | same-edge local terminal releases the exact newly bound token once |

The reference model maintains head, tail, count, valid, full ProducerId,
owner validity/tuple, fill, request-sent, and terminal state.  Expected state
is updated only from the testbench stimulus and the declared edge schedule.
`dut.*_q` is used solely for equality and X-knownness checks.
