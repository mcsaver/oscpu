# V11G dispatch log

1. Main node generated and validated
   `subagent-contracts/v11g-store-queue-holder-pre-review.json`.
2. Contract SHA-256:
   `154d7ac6cf6a03352ddaff393d03af8f8e2c81cf47a40bc8bbf8305cdad257f8`.
3. Main node explicitly transferred the sole Windows-to-WSL shell ownership.
4. The independent reviewer used only contract-listed read-only commands,
   returned H1 with blocker count 0, stopped all commands, and returned shell
   ownership.
5. Main node implemented verification-only evidence and preserved production
   RTL.
6. Main node generated and validated
   `subagent-contracts/v11g-store-queue-holder-final-review.json`.
7. Final-review contract SHA-256:
   `60ae84f5ea0a1b09a337ec6f71f2d0a284cc9f1f9e59f7a3eaca5780cc888dd5`.
8. Main node transferred the sole Windows-to-WSL shell ownership for the
   read-only final review.
9. Independent reviewer returned bounded APPROVE with blocker count 0,
   stopped all commands, and returned shell ownership.
10. Main node is publishing architecture observation, memory/DB, strict
    guard, identity, and commit-gate evidence without changing production RTL.
11. ARCH_STABLE observation returned the expected 51 PASS / 2 GAP set with
    zero V11G-specific new failures.
12. The first task-specific `npc-dev` run preserved a blocked bounded-recall
    result; after storing V11G project/NPC memory, the second run completed
    all five nodes without relaxing recall.
13. Scoped strict guard passed. Full-worktree strict guard retained only the
    shared `rv64-linux` missing-evidence GAP.
14. Final identity passed, 351 raw evidence assets were indexed, and the
    mixed-origin commit gate prohibited staging or committing this round.
