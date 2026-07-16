# RV64 200MHz T4D：PLIC priority/threshold 3-bit WARL

## 基本信息

- `task_id`: `2026-07-14-rv64-t4d-plic-priority-warl`
- `task_slug`: `rv64-t4d-plic-priority-warl`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `in-progress`
- `owner`: `/root`
- `started_at`: `2026-07-14`

## 任务目标与边界

- `source_request`: 持续优化 RV64 架构，直到完整功能且 exact 5.000ns STA 达到 200MHz。
- `goal`: 用 PLIC 合法 WARL 位宽删除 32-bit priority/threshold 比较树，不增加 AXI 或 claim/complete 拍数。
- `scope`: `AxiPlic` priority/threshold/五级 winner-priority 宽度、PLIC TB、契约/变异、回归与 fresh STA。
- `out_of_scope`: 不改 claim ID、pending/enable/in-service 位图、tie-break、AXI owner、外部 IRQ 寄存拍或 source 数量。

## fresh 根因证据

- T4C exact 5ns：WNS/TNS=`-0.05/-0.61ns`、loops=0，top40 全部位于 `u_plic_axi`。
- start `_54747_`=`threshold_s_q[29]`（36/40），`_54717_`=`threshold_m_q[31]`（4/40）。
- endpoint `_54584.._54614`=`pending_q[1..31]`；`_54615.._54645`=`in_service_q[1..31]`。
- 公共锥：threshold 比较 → 五级 winner tree → M/S claim ID → AXI claim-read fire → 动态 bit 解码 → pending 清零/in-service 置位。
- 该路径不是已寄存的 `external_irq_o`，不能再靠 IRQ 出口打拍处理。

## 接口契约冻结

1. **握手**：AXI-Lite AR/R、AW/W/B 握手与 claim-read side effect 拍不变；不增加寄存 stage。
2. **WARL**：priority/threshold MMIO 字段仍为 32-bit，默认实现只存低 `PRIORITY_BITS=3`；高 29 位写忽略、读零。
3. **仲裁**：priority 0 永不候选；必须严格大于 context threshold；高 priority 胜，相同 priority 保持低 source ID 胜。
4. **claim/complete**：claim 仍同拍返回组合 winner，并在该沿清 pending/置 in-service；complete 仍按原动态 ID 清 in-service并处理 level re-pend。
5. **写 strobe**：实现位仍逐 byte 遵守原 `WSTRB` merge；只写未实现高 byte 不改变低 3 位。
6. **平台功能**：Linux 只使用 priority 0/1 与 threshold 0/7；现有 TB 使用 0..7，均逐位保留。DTS 未声明更宽 priority。

## RTL 推导与自审

- 新增参数 `PRIORITY_BITS=3`，合法配置范围 1..32；默认平台最大 priority/threshold 为 7。
- `priority_q`、`threshold_m/s_q`、五级 winner-priority 数组全部改为该宽度；claim ID 和全部状态位图不动。
- 读口以 32-bit zero-extension 返回；写口先按原 32-bit WSTRB merge，再截取实现低位，故参数化到 32 时仍保持旧行为。
- 不新增状态、端口、pipeline 或 CPI；只缩短 candidate 比较及五级 `>` 数据宽度。
- 3-bit 足以精确保留仓库所有声明/验证的软件值；`>7` 属 PLIC 允许实现定义、仓库从未承诺的扩展优先级。

## 节点概览

| 节点 | 状态 | 成功标准 |
| --- | --- | --- |
| `t4d-recon` | completed | cell→RTL、公共锥、软件位宽需求均有证据 |
| `t4d-contract` | completed | WARL/握手/claim/complete/tie-break 契约冻结 |
| `t4d-implement` | in-progress | 宽度参数化、read-zero/write-ignore、TB marker |
| `t4d-negative` | pending | source audit 与 default=32/高位保留变异转红 |
| `t4d-regression` | pending | PLIC focused/full module/lint/style/contract 全绿 |
| `t4d-fresh-sta` | pending | fresh netlist exact 5ns；旧 threshold 高位 start 消失 |

## 父目标状态

- T4D 尚未实现；200MHz 父目标保持开放。
