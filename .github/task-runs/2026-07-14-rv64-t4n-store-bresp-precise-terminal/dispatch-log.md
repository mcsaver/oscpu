# Dispatch log

- 2026-07-14：bounded brief 使用 `npc` profile，冻结 T4N/T4M owner 与 flush 边界。
- 2026-07-14：RED 证明旧 SQ 在 physical request fire 时提前释放。
- 2026-07-14：实现 SQ 三事件、backend B terminal/单热仲裁，StoreQueue 首个 GREEN。
- 2026-07-14：从 backend 最早失败修正旧 helper 的 probe-success 即 commit 假设，backend GREEN。
- 2026-07-14：新增 VA!=PA B error、two-store priority、T4M admission 与 B outcome bridge 定向。
- 2026-07-14：combined focused 3/3、RTL style、scoped diff-check PASS；strict guard 留给 root。
- 2026-07-14 reviewer：ROB head1 exception、SD/FSD local terminal、checkpoint restore SQ fire 三个
  定向 RED 共 39 个失败，定位到 ROB/SQ terminal/request grant 三个结构根因。
- 2026-07-14 reviewer：首次修复后审查发现 B response 与 local exception 同拍的单 terminal tag
  mux 反例；改为双 CAM 端口，并用 missing-hit/same-tag 两个 mutation 证明断言非真空。
- 2026-07-14 reviewer：最终 ROB/StoreQueue/MIQ/IntBackend/MemAxiBridge 5/5、style、lint、
  scoped diff-check PASS；全量/综合/strict/commit 按本节点授权未运行。
