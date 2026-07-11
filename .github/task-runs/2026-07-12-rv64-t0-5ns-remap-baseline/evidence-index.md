# Evidence index

大体积综合/STA 产物保留在被忽略的 build 目录；本 task-run 只登记路径、大小、SHA-256 与可复核锚点，不复制原始报告正文。

## 当前目标驱动产物

| 产物 | 字节 | SHA-256 | 用途 |
|---|---:|---|---|
| `npc/rv64/build/sta/NpcTop-200MHz/yosys.log` | 758881610 | `29e2efa87f0db5af92732aaea552bc0b934d8cfc3caad4a64e2e5ae171bb5b6d` | 修复后 200 MHz 目标驱动重映射日志 |
| `npc/rv64/build/sta/NpcTop-200MHz/NpcTop.netlist.v` | 68073061 | `5369c7e49c2b9af05d242dbcb558eca798f595d30f34bd0a8f6abe0fc1908c4e` | 修复后映射网表 |
| `npc/rv64/build/sta/NpcTop-200MHz/NpcTop.opensta.rpt` | 1270520 | `14aed86819089c43b375567fa463858e62cf9230d182246fbbb0cb3277b4e0c4` | 5 ns OpenSTA、40 条 max path、WNS/TNS 真源 |
| `npc/rv64/build/sta/NpcTop-200MHz/NpcTop.opensta.pwr` | 754 | `3507cae60ed2ba97d0569cf84ae78a54ffaebbee5dfc7d952cdbf0cf9269434e` | OpenSTA 诊断性 power 输出，不作功耗结论 |
| `npc/rv64/build/sta/NpcTop-200MHz/abc.sdc` | 41 | `651d740188ddb19c58fded2ec4185871ff23a1f453af22dc3f44583503743e7c` | ABC 通用 drive/load 约束；不含 delay target |
| `npc/rv64/build/sta/NpcTop-200MHz/sta.log` | 4089193 | `69cd7d64e508ba56a1dbe0c12d11cd425e496cf666b19ca24154cb324851b1e0` | iEDA 600 s 有界尝试；停在 data backward propagation，无报告 |

## 修复前产物（仅历史诊断）

| 产物 | 字节 | SHA-256 | 限定 |
|---|---:|---|---|
| `npc/rv64/build/sta/NpcTop-200MHz/yosys.pre-target-contract.log` | 759156235 | `2d9378145c3642e6f9d681d45725136c485148a537d98ea53c4fb8ea3951f344` | 自定义 ABC 脚本未消费 `{D}`，不是 5 ns 目标驱动映射 |
| `npc/rv64/build/sta/NpcTop-200MHz/NpcTop.netlist.pre-target-contract.v` | 68051104 | `b86e95408d172f150f06485ffe82b560a1f1d6e508d2ead731de178437be39a6` | 上述无目标映射网表 |
| `npc/rv64/build/sta/NpcTop-200MHz/NpcTop.opensta.pre-target-contract.rpt` | 1159469 | `4d45426337d667c6e758d638f4cf5eac59087b8801ce63b4496963febf87fb54` | 旧 `-12.63 ns` 诊断；不可决定 T1 排序 |

## 机器可复核锚点

```text
Current 5 ns OpenSTA report:
  Startpoint: .../u_int_backend/u_store_queue/_6266_
  Endpoint:   .../u_int_backend/u_mem_inflight_queue/_7490_
  arrival:    20.709 ns
  required:   4.971 ns
  slack:      -15.739 ns
  tns max:    -196567.73
  wns max:    -15.74

Current Yosys mapping:
  ABC: + &nf -D 5000.0 occurrences: 105
  End of script: 1404.66 s
  peak RSS: 3650.20 MB
  top mapped area: 1571023.440000
  final check: Found and reported 0 problems

Delay-target source of truth:
  yosys.log executed command: &nf -D 5000.0
  abc.sdc: drive/load only; no 5000 ps setting

iEDA bounded attempt:
  final logged phase: data bwd propagation start
  NpcTop.rpt / NpcTop.pwr: not produced
```

同一综合命令尾部的通用宏边界、iEDA netlist compatibility、BPU placeholder、fetch SRAM、DCache SRAM 与 FP macro placeholder 检查均通过。该检查集合证明网表合同，不把 iEDA 未完成运行表述为 STA 通过。
