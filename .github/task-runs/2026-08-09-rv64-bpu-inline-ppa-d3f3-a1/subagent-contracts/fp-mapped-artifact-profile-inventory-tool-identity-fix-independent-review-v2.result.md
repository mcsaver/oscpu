# FP mapped artifact profile tool identity fix independent review v2

RV64 RTL 结论｜对象=`result-identity-v2.json`、detached validation receipt 与 BPU/FP artifact canonical-path validator｜周期/配置=5.0 ns、`mapped-5ns-fp-arith-production-children-inline-v1`、profile=`fp-arith-children-v1`｜TB/EDA 观测=只读复核；未运行 Python/测试/仿真/综合/OpenSTA｜范围=GAP

技术裁决：**FIX；BLOCK fresh run-id。** v2 已闭合完整 configuration ID 与短 profile 分离、旧 `d1edadb0…` 假绿的 superseded 追溯、result/schema/Registry/Registry-schema/generator/v2-contract 六项 path/size/SHA，以及 symlink、目录 alias、错误 basename 和 receipt-path 漂移拒绝。

剩余承重缺口：

1. generator 运行时 import 的 `npc/rv64/eval/ppa/tools/architecture_registry.py` 未进入 result 或 detached receipt；该依赖漂移不会让旧 receipt 失效。
2. artifact canonical-path 校验没有要求 `st_nlink == 1`，因此当前目录中 exact basename 的跨目录旧 artifact 硬链接可绕过 replay 门；定向测试未包含 hardlink mutation。
3. 本 review 合同未声明 production runner，无法独立闭合 runner 实际 `--out-dir` 是否满足 absolute canonical non-alias 条件。后续 review 必须把 runner 纳入只读范围。

已复算：`result-identity-v2.json` SHA-256=`bf64542a3b4a3e54cebe8e7f96aaf53e1aa96a25a05091fba72b2d91700de4d0`，detached receipt SHA-256=`572e5f0d8be3e9254ac14ae60f91d4d7a4f5fa392829ea6cdb3313aebeaeda1a`，receipt ID=`sha256:5fec56b10128a7e7fae2ed9ad1a29ac062d493a8667113aa8966d848e315941a`；六项 receipt 与现场 path/size/SHA 一致。旧 `result.json` 仍为 `d1edadb0…`/7903 B，新结果记录其 recorded/expected identity，未覆盖反例。

合同符合性：review 中一次 PowerShell→WSL alternation 引号失配，使 `|` 被 shell 解释并意外尝试 `basename`/不存在 token 命令；均立即 rc=1、无写入/残留。技术反例随后由合法 `sed/rg/sha256sum` 重新取得，但本节点形式状态仅 candidate-only，不能作为最终硬授权。

`unknowns`：真实 production FP artifacts/PPA 未测。`scope_extension_request`：v3 绑定 imported Registry tool、拒绝 hardlink，并在最终独立 review 中加入 production runner。合同 SHA-256=`0be1b6d0926d9433880f07e10ad74e3dc78507971daa34c7eee147e8cbe94704`。
