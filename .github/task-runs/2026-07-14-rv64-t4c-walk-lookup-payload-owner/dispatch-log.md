# Dispatch Log

| 时间 | 节点 | Agent | 动作 | 状态/证据 |
| --- | --- | --- | --- | --- |
| 2026-07-14 | `t4c-recon` | `/root/t4c_dcache_path` | 只读拆解 T4B fresh D-cache 地址路径 | completed；真实起点为 Xbar `rd_resp_valid_q[1]`，终点为 SRAM addr |
| 2026-07-14 | `t4c-contract` | `/root` | 冻结 owner/permission 分责、FSM 与不变量 | completed；见 task-report 与 bridge spec |
| 2026-07-14 | `t4c-implement` | `/root` | fixed-role walk payload owner | in-progress |
