# RV64 V13I IntIssueQueue survivor-map

## Result

`OooIntIssueQueue` normal compaction 已由动态 `write_i` source scan 改为 packed entry state、
平衡 remove-prefix 与每个目的槽固定 `d/d+1/d+2` source mapping。端口、队列容量、dispatch/issue
latency、selector/owner、full ProducerId、sticky wake、count、reset/flush/kill 更新全序保持不变。

独立终审裁决：`APPROVED_DEVELOPMENT_CHECKPOINT`，`promotion_eligible=false`。

## Functional evidence

- 37 个 popcount≤2 remove mask 与 5 个 append 组合：PASS。
- source1 selector 负向扰动命中独立 scan reference 的 VALID/PAYLOAD marker，并以非零返回结束。
- `tb_ooo_dispatch_backend`、`tb_ooo_int_backend`、`tb_ooo_alu_decode_backend`：3/3 PASS。
- 当前设计：module 113/113、official 177/177、AM 61/61、DiffTest mismatch=0。
- 证据：`evidence/functional/`、`evidence/full-core-module-attempt1/`、
  `evidence/full-core-functional-attempt1/`。

## Local PPA evidence

配置为 `OooIntIssueQueue`、200 MHz、flatten=1、share=0；Yosys、OpenSTA 和 H7CL liberty SHA-256
均记录在 `evidence/ppa/local-v13i/summary.json`。

| Metric | V13G | V13I | Delta |
| --- | ---: | ---: | ---: |
| coarse cells | 4,385 | 1,442 | -2,943 |
| mapped cells | 33,284 | 29,354 | -3,930 |
| mapped area | 74,917.64 | 66,764.88 | -8,152.76 (-10.8823%) |
| sequential area | 19,293.12 | 19,293.12 | 0 |
| 5 ns worst positive slack | +2.406632185 ns | +2.485146284 ns | +0.078514099 ns |

两侧 synthesis check 均为 0 problems；TNS/WNS violation count 均为 0。

## CPI evidence

相对冻结 V13H，CoreMark 为 `5,485,583 cycles / 3,218,532 commits / CPI 1.704`，Dhrystone
为 `10,844,882 / 4,260,665 / CPI 2.545`；cycles、commits、CPI 均精确零差，只裁决
CPI-neutral。两侧 design-id 与四份 benchmark 日志 SHA-256 见
`evidence/functional/cpi-neutral.json`。

## Retention and cleanup

source snapshot、仿真日志、stat/check、OpenSTA config/top-40、当前设计功能 cohort、合同与独立
终审已保留。49 个可再生 `.vvp`、netlist、RTLIL/structural JSON、debug build 与 raw Yosys console
共 `288,836,652` bytes 已删除；结果见 `cleanup-result.json`。删除的中间物不能直接恢复，但可由冻结
源码、工具/liberty 哈希和配置重建。

## Remaining scope

full-core mapped synthesis、full-core STA、qualified power、新完整系统事务均为 NOT_RUN；局部
ideal-clock OpenSTA 不证明全核 200 MHz。下一单机制候选为 R3.4 ALU terminal
true-by-construction，保持 dynamic capability steering 与现有 capability assertions。
