# V12A independent review

- conclusion: `BLOCK`
- scope: `pending-system-producer` V11U local semantic closure
- accepted evidence: exact `define.v` product/`OOO_ASSERT` projection, negative probe, current holder graph and design-id binding
- blocker: V11U declared ROB birth/exact-death and production-wrapper closure without byte-binding the complete compiled RTL input set; `OooRob.v`, pending-system control modules, and source-selection semantics were not all covered
- additional gap: `npc/rv64/testbench/Makefile` was exempted from live-SHA checking although it selects profile sources and overrides
- impact: top-level architecture remains `GAP`; `units_semantic_pass=44` must not be relied on until V11U compile-input closure is fail-closed
- required repair: bind normalized compiler argv/filelist plus every compiled RTL/TB input, reject Makefile/source-list drift, and add compile-success mutations for omitted ROB/control links
- shell ownership: returned

Reviewer contract: `subagent-contracts/v12a-semantic-rebind-review-v1.json`
