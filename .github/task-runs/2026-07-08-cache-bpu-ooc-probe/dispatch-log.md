# 派发日志：cache/BPU OOC 综合失败根因定位

| 节点 | 动作 | 结果 |
| --- | --- | --- |
| recall | DB load yosys-sta.md + fp-arith-internal-cones task-report，确认已有方法(OOC probe)与模块级定位链 | 方法复用，无重复实验 |
| coarse×3 | BPU/FetchPacketCache/DataWordCache 单模块 coarse OOC (timeout 300) | 3/3 PASS 秒过（$mem_v2 未展开） |
| full×3 | 同三模块 full stdcell OOC (100MHz, timeout 600) | BPU PASS 282.9s/80968 gates/1.26GB；两 cache timeout 卡 ABC blif 提取 |
| 容量扫描 | 两 cache INDEX_W=8/10 (STA_VERILOG_DEFINES) | fetch iw8 PASS 522.7s(贴边)/iw10 timeout；dcache iw8/iw10 均 timeout(结构问题非容量) |
| RTL 阅读 | fetch cache 位宽账本 + mmu_flush 驱动链 | satp_q 恒真匹配=纯死重(64/200bit)；pc_q 8 组合读口；dcache 双读视图+移位+byte-merge |
| record | task-report.md + yosys-sta/project-status memory (DB update-stored --refresh-shim) | 见 task-report |

时间：2026-07-08 11:52 ~ 13:05（综合实验串行，本机 WSL2）。
