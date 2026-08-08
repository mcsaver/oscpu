RV64 RTL 结论｜对象=`act4-current.json`、`layered-system-signoff-current.json`、ACT4 100-case manifest、冻结 `NpcSimTop`｜周期/配置=`f72e1fb4…` / `npc-rv64-ooo-current` / Ubuntu未运行｜TB/EDA 观测=100/100 PASS、每例唯一 `TOHOST PASS`、零失败断言、L0+L1+L2+L3合取PASS｜范围=PASS

- ACT4 清单为 51 I + 13 M + 32 Sv39 + 4 Svnapot = 100。生成库存101项仅排除 `priv/Sv/sv39_svnapot_not_supported_Smode`；UDB同时声明 `Sv39`、`Svnapot`，Sail配置二者 `supported: true`。
- a1 是有效负向反例：误纳“Svnapot不支持”payload 后出现 `TOHOST FAIL`，`act4-current.status` 为 `FAIL ... evidence_complete=0`。a3 改用实现匹配清单后，四项 Svnapot S/U及reserved-encoding payload均PASS。
- a3全部100个原始日志经 `rg -c` 均只有一次 `TOHOST PASS`；`TOHOST FAIL`、`BAD TRAP`、Verilator/RTL assertion模式检索无命中。`act4_current.py`还要求每例唯一 run-result marker、唯一tohost watch、正cycle/commit，并对重复terminal和断言marker提供定向变异测试。
- `inputs.before.json`与`inputs.after.json`同为 `26e7f54e…`；任务结果与canonical ACT4 receipt同为 `5a6acd5b…`。证据绑定设计ID `sha256:f72e1fb4…`、冻结模拟器 `sha256:8e426a68…`；`current_l1_binding()`重验L1结果、活跃输入、模拟器artifact，并要求构建日志同时含 `+define+OOO_ASSERT` 与 `--assert`。
- 默认合取固定为 L0/L1/L2/L3；L1必须同时含177 official、61 AM、0 DiffTest mismatch及ACT4 100项。checker每次重算canonical ACT4 receipt并拒绝缺失、99/100、错design-id或旧式无ACT4 receipt。分层任务副本与canonical receipt同为 `27bd975f…`；Ubuntu明确 `NOT_RUN`、非阻塞且不被此结论暗示。
- 边界反例：`act4-arch-run.sh`仅检查任一 `TOHOST PASS|HIT GOOD TRAP`，不保证terminal唯一或零断言，不能替代默认签核入口；当前policy未引用它，因此不影响本次默认链PASS。
- 未运行Python单测或新仿真：v2合同仅授权 `rg/sed/sha256sum`。结论基于现有a3原始日志、哈希、schema及定向测试源码；未发现非预期测试返回码。直接重哈希冻结二进制/读取其L1构建日志需扩展合同，但现有receipt已传递绑定二者。
- 置信度：高；范围仅限当前f72e ACT4/L1默认系统签核，不包含Ubuntu、综合、STA或PPA。

`scope_extension_request`: 无强制请求。全部工程命令已停止，并已归还唯一WSL shell ownership。
