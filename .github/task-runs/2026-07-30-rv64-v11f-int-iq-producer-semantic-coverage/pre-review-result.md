# V11F integer IQ ProducerId pre-review

RV64 RTL 结论｜对象=`OooIntIssueQueue.producer_id_q`｜周期/配置=edge-old Q，`GEN_W=1/current`｜TB/EDA 观测=静态逐沿审查与 V8L/V11E source-bound artifact；未新跑仿真｜范围=GAP

## Decision

- H1: current production RTL preserves full ProducerId through accepted birth, hold, compaction, dual issue, memory pair pop, selective recovery, flush and reset.
- H2: no reachable production defect was found inside the IQ-I6 legal-input contract.
- H3: existing V8L evidence is insufficient. It has one direct IQ mutation (`int_iq_fire_dies_early`) and does not independently cover full-P birth, hold, compaction, handoff or raw identity knownness.
- Production `OooIntIssueQueue.v` does not require a change in V11F.

## Required closure matrix

The directed oracle must derive an eight-entry expected list from accepted stimulus, never from `producer_live_mask_o` or DUT raw Q. It must cover:

1. dirty-state reset;
2. lane0/lane1 dual birth with non-zero generation bits;
3. READY-low and recovery hold;
4. single fire plus accepted replacements;
5. dual terminal fire;
6. memory pair READY-low then atomic pop2;
7. ROB-index wrap selective recovery with head 14 and boundary 15;
8. nonempty flush and reset;
9. full-P X injection with `OOO_ASSERT` disabled.

Compile-success RTL variants must exercise full-P capture, lane identity, compaction, issue carriers, raw-index projection, regular/pair death, recovery boundary, flush/reset, edge-old mask timing and raw identity knownness. Every negative simulation must compile with `OOO_ASSERT` disabled and fail through the independent TB marker.

## Scope boundary

`kill_valid_i && dispatch*_valid_i` can lose an accepted append because ready remains combinational while the sequential kill branch ignores normal append. This combination is explicitly forbidden by IQ-I6 and is not a V11F production defect. Natural reachability of kill/flush transaction barriers belongs to the upstream dispatch/backend integration scope and is not promoted here.
