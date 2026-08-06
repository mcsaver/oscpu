# Independent verification v2

RV64 RTL 结论｜对象=`npc_systemd_transaction_evidence.py`、`check-npc-systemd-guest.sh` 与 A2/A3 receipt｜周期/配置=`strict-v2`、`natural-poweroff`、host-timeout 0.1s 定向激励、冻结日志回放｜TB/EDA 观测=两组 Python 测试 42/42 PASS；A2 stage/terminal/top PASS；A3 stage/top FAIL、terminal PASS｜范围=PASS

The independent verifier closed all five v1 counterexamples:

1. A real GNU timeout returns GAP/124; an immediate simulator exit 124 returns ordinary wrapper failure/1 and is not labelled wall-clock timeout.
2. Simulator, firmware, parser and hard-linked input aliases are rejected before preclear and before the single simulator launch.
3. Console stats and NPC event duplicate/order/PC/cycles/commits/init-path negatives are observed.
4. Representative V9Q, V9R, S2, V10D and generic assertion regex branches pre-empt clean-exit, timeout and cycle-budget classifications.
5. Host receipts set `snapshot.producer_closed_proof=true` only after the simulator pipeline returns; the canonical verifier rejects a missing flag binding with rc=3. Offline A2/A3 receipts remain explicitly false.

Commands returned: transaction tests 21/21 PASS, guest wrapper tests 21/21 PASS, A2 verify rc=0 PASS/PASS/PASS, A3 verify rc=0 with required FAIL and terminal PASS. No full RTL system simulation was rerun. WSL shell ownership was returned and no background process remained.

Residual boundary: the timeout distinction depends on the tested GNU `timeout --verbose` diagnostic contract. This task proves the local evidence collector and host wrapper, not whole-core architecture correctness or PPA.
