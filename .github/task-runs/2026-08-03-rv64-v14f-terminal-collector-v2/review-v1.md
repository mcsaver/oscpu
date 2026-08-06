# Independent review v1

RV64 RTL 结论｜对象=`npc_systemd_transaction_evidence.py`、`check-npc-systemd-guest.sh` 与 A2/A3 双日志 receipt｜周期/配置=`strict-v2`、`natural-poweroff`、A2/A3 systemd 回放｜TB/EDA 观测=静态源码/定向测试复核及真实日志 SHA-256 对照；合同未授权执行 Python 测试｜范围=GAP

Confirmed:

- contract SHA-256 `7820613471d0611a74c93ff81f82a3b4bd34a18150dd81c8f5bd992807bae0ae` matched;
- `INVALID_EVIDENCE > FAIL > PASS`, non-deduplicated event counts, console/NPC order, PC/cycles/commits mirror and canonical verifier were present;
- A2 was stage/terminal/top PASS; A3 was stage/top FAIL and terminal PASS;
- A2/A3 embedded console/NPC hashes matched the frozen logs;
- one simulator invocation and assertion-before-timeout-before-cycle-budget ordering were statically present.

Counterexamples/GAPs:

1. Immediate simulator exit `124` was indistinguishable from a real GNU timeout; the old test only exercised immediate exit.
2. Evidence output could alias simulator/parser/rootfs inputs and be deleted by preclear; the old test only covered evidence=console.
3. Console stats and NPC duplicate/order/value/init-path negative matrices were incomplete.
4. Assertion tests did not exercise representative V9Q, S2, V10D and generic regex branches.
5. Offline receipts correctly carried `snapshot.producer_closed_proof=false`; a host-created receipt needed an explicit post-process-return binding.

Shell ownership was returned. The reviewer requested a new verification contract before executing tests.
