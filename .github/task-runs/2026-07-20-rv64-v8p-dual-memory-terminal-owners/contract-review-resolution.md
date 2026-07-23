# v8p contract-review resolution

The independent self-contained/no-tools review returned `gap`.  No RTL had
been edited.  The contract and normative spec were revised before entering RTL
stage 1.

| Review gap | Resolution frozen in the revised contract |
| --- | --- |
| G01 atomic side effects | Dual-valid tracker allocation is one atomic package; current-current dual issue/capture/alloc fires are Boolean-equivalent and single-credit creates no birth. |
| G02 ready DAG/fall-through | Pair-ready allowed-root set is closed; downstream ready and same-edge consume/free are forbidden; capture has no request/local terminal. |
| G03 two-bank/two-AGU shell | Each bank captures distinct sources/data; both AGU results must coexist under bank0 stall; raw inputs are perturbed in the test. |
| G04 packed age | Packed IQ index is the strict total age order; oldest two are selected and bank1 reads edge-old bank0 valid with no consume/kill look-through. |
| G05 identity conservation | Existing memory lease spec remains normative; v8p evidence adds immutable full-PID/token mapping across capture, handoff, terminal and release. |
| G06 cancellation | Collector ingress is an always-capturing lossless token mask, not a ready sink; non-STORE clear is same-edge collected, STORE stays SQ-qualified. |
| G07 SQ dual bind | Bind0/1 require exact onehot, mutual exclusion and bank/PID/ROB/token association; dispatch SQ allocation makes miss unreachable and immediate assertions fail fast. |
| G08 matrix/special classes | All 15 keys are enumerated; coverage derives from accepted ctrl identity; AMO/LR/SC/FP memory have explicit negative admission tests. |
| G09 mutations | Added alloc0-only birth, one-AGU/copy, special-memory, crossed/one-sided bind and same-edge age-bypass mutations with four-part activation records. |
| G10 provenance | Each mode has a complete content-addressed manifest; collaboration-contract hash remains separately named and cannot bind design evidence. |
| G11 publication | Only DI-3 may change; same-digest DI-4/OOO-1/OOO-2 must be rerun, while DI-5/OOO-3/overall/PPA remain RED. |

The revised topology is now eligible for an independent re-review.  A pass is
still required before any production RTL edit.

## Second-review collector gap

A second no-tools reviewer asked how two simultaneous non-STORE cancels remain
lossless when dequeue has only two ports.  The revised contract now freezes the
actual collector topology: seven parallel ingress decoders write a 32-token
pending bitmap and metadata bank; dequeue width limits drain rate, not ingress
capacity.  Because tracker live tokens and pending bits share the same finite
32-token domain, a legal not-yet-pending cancel always has its own empty bit,
and a full pending set implies no additional legal reservation owner exists.
The verification plan now includes seven-lane ingress, dual-cancel, stalled
dequeue and mutation-negative conservation evidence.
