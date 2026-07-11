# Context Brief

- `objective`: 当前声明范围内功能完整，并最终实现 200 MHz 物理时序闭合
- `method`: code/report-first baseline audit + superpowers brainstorming
- `db_command`: `python3 scripts/github_index_db.py brief "rv64 200MHz timing WNS critical path frontend high fanout complete function regression" --profile npc-dev --max-tokens 2600`
- `profile_suggestions`: npc-dev, rv64-linux, yosys-sta, verilator-tapeout, difftest
- `current_function`: official 177/177；AM 58/59；至少 3 个 module TB 假绿；current Difftest/Linux evidence 不新鲜
- `current_timing`: 10 ns WNS −5.35 ns；最差 arrival 15.32 ns；5 ns 必须正式重综合
- `default_scope`: Linux-capable single-hart RV64IMAFDC+Zb；H/V/multihart/NMI/full-debug 范围外
- `default_timing`: pre-layout 5 ns milestone + post-layout 200 MHz final signoff
