# T3A current-top retry dispatch log

### [2026-07-13 01:42 +0800] `current-top-retry` - RUNNING

- `owner`: root。
- `action`: 在 RAW-I1 永久断言/负探针保护下，物理删除两路合法态不可达的 lane0→lane1
  current-result mux；冻结 A/B 输入身份并启动 dedicated fresh 200 MHz synthesis。
- `gate`: source 在 synth 期间冻结；先功能、后 fresh STA，任一 PPA/timing 硬指标无收益即回退。

### [2026-07-13 01:45 +0800] `parallel-review` - PASS

- `branch_packet_cut`: 109 loop 按 dispatch/PRF/long-op 族分类；完整 resolve packet register
  可切环，但 redirect/错误请求窗口 +1，且必须删除 dispatch 内二次 kill register。
- `wakeup_loop_cut`: 推荐 full-WB state update 与 EX/MEM-only same-cycle fast select/bypass 分离；
  保留 long-op 当拍 kill，不给 ALU/load 增加延迟。
- `loop_family_cutset`: 物理计数为 108 long-op feedback + 1 FP credit 真环；随机 gate cut point
  不是架构 cut。

### [2026-07-13 02:21 +0800] `fresh-synth` - PASS

- `command`: icsprout55 / 5ns / no flatten-share / same four blackboxes and hierarchy keep set。
- `result`: rc=0，post-map check 0 problems，1402.09s，peak 3628.65MiB；netlist
  68,150,669 bytes，SHA-256 `1b5250c7deaacc23...`。
- `structure`: old forward signal/arc family physical count=0；OooIntBackend local ABC lev 40→39，
  但 mapped area +851.76。

### [2026-07-13 02:24 +0800] `opensta-ab` - REJECT

- `result`: WNS `-10.001→-10.182ns`，TNS `-120125.49→-142389.47ns`，loops `109→142`，
  total power `0.118→0.120W`；top40 `1 fetch+39 MIQ → 1 fetch+39 FP exec1`。
- `review`: 结构删除真实但硬门禁全体逆向，不能以 RTL 行数或局部 level 改善接受。

### [2026-07-13 02:26 +0800] `rollback-and-archive` - PASS

- `action`: 用 `apply_patch` 精确还原生产文件；worktree 与 parent `OooIntBackend.v` hash 完全一致。
- `archive`: rejected B netlist/log/check/provenance 已压缩进 workspace `tmp/`；三层完整性校验 PASS。
- `handoff`: 下一图节点是 long-op source-class quarantine RED→GREEN，再 fresh synth 验证
  108 loops 是否消失；FP credit loop 独立处理。
