RV64 RTL 结论｜对象=`rebind-act4-v1/result.json`、NpcSimTop 与 ROI `COUNTERS_FINAL`｜周期/配置=CoreMark 5262868/3183617，Dhrystone10000 9751462/4250000，stats-on×3/stats-off×1｜TB/EDA 观测=ACT4 100/100、checker 30 tests OK、计数守恒与 fail-closed 闭合；未新增仿真/综合/STA｜范围=PASS

- 身份与哈希：
  - reviewer contract：`53b640fc5d60ca8b03120fcbb22b1d5592d75195b5ef23be6eb0faf0594788c1`
  - design_id：`sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`
  - versioned result：`460fffbd42bd3824984c821120151f42a0062164475811725204d4582086ce32`
  - ARCH_STABLE：`a80f88a4215e34fdf2b064eae993d0242c8649339b8387007e680eb45d7a8325`
  - baseline contract：`0ea7a7f2b9846d598ecacae09d0b7f24393eb550610b845d7e665dc3df77bf83`
  - NpcSimTop 绑定保持 `8e426a6863652fd42f195d000e56e4626e918a9abac4ae7c30cde9549308fd2e`；CoreMark/Dhrystone 镜像保持 `a7117f…`/`56c6f0…`。
  - 原 `result.json` 与 `published-f72e-v1.json` 仍同为 `a4d4ffe075e34f5375e20ed40b92518499862a11d3df5c30e57419826dfa1e2b`，未改写。

- ACT4/rebind 边界：`arch-stable-current.json` 记录 ACT4 `npc-rv64-ooo-current` 为 100/100、DiffTest mismatch=0。新旧性能 payload 的 NpcSimTop、配置、镜像、八份原始日志 SHA、ROI 数值及 counter signatures 均未漂移；变化集中在 ARCH_STABLE、baseline/measurement/amendment/policy 和 manifest/postflight receipt 身份。当前任务目录的临时 result SHA 为 `2516c026…`，与 versioned result 的差异仅是 manifest 路径；两处 manifest 内容 SHA 均为 `f11c611d…`。

- 计数守恒：
  - CoreMark：`10525736 = 2×5262868`，且 `3183617 + 7342119 = 10525736`；cycle 主分区 `2003880+11156+3032989+214843=5262868`。
  - Dhrystone：lane1→lane0 端点修正后 `19502923 = 2×9751462−1`，且 `4250000+15252923=19502923`；cycle 主分区 `2700038+10945+6850464+190015=9751462`。
  - 两 workload 的 memory lifecycle、request detail、head-not-complete 嵌套和均精确；unknown/overflow/invalid_events 均为 0。

- stats-off：CoreMark 与 Dhrystone 分别仍为 `5262868/3183617`、`9751462/4250000`；`complete=0 available=0 conservation=0`，所有 cycle/slot 桶为 0。stats-off NpcSimTop 实测 SHA 为 `9df21c10…`，与 stats-on 二进制不同。

- fail-closed：原 task status SHA `c26de83a…` 内容为 `PASS`；command status SHA `afe73dd5…` 的 preflight、stats-on/off、manifest、precheck、postflight、bind、build、verify、cleanup 均为 RC=0；cleanup SHA `802005c1…` 记录 `build_tree_absent=true`、删除 `230242517` bytes。

- 反例检查：当前 `checker-regression.log` SHA `8fa509c5…` 记录 30 项全通过，覆盖旧 ARCH_STABLE/review 重绑、重复 raw-log 路径、日志篡改、非位精确计数、stats-off counters 意外可用、stats-on/off 周期漂移、坏 postflight、cleanup 漂移及 PPA scope expansion。

- 解释边界：本次是对原 fresh execution 不可变日志的 checker replay，不是 ACT4 后重新跑了 benchmark。日志跨 receipt 复用是显式且由相同 design_id、NpcSimTop、镜像、配置及 SHA 绑定支撑；不得将其表述为新的性能复测。checker/review-test 源文件哈希相对原审查有变化，当前 30 项回归覆盖了 rebind 语义，因此“仅身份变化”限定于 RTL/仿真输入与性能 payload，不代表工作流源码逐字节不变。

- unknowns：未建立全局 workload 代表性、完整因果 CPI、全局整数/FP issue-slot、队列 occupancy 或合格 PPA；合同外 NpcSimTop/镜像本体未直接读取，仅依据 ARCH_STABLE、合同、manifest 三重 SHA/size/path 绑定。`scope_extension_request=none`。置信度：高（性能 payload、计数和闭合证据）；对合同外 workflow 本体逐字节等价不作声明。

[PERFORMANCE-BASELINE-INDEPENDENT-REVIEW][APPROVE_PERF_BASELINE] design_id=sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42 result_sha256=460fffbd42bd3824984c821120151f42a0062164475811725204d4582086ce32
