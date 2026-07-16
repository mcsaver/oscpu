# RV64 T4G：跨页取指 faulting portion 的精确 tval

## 基本信息

- `task_id`: 2026-07-14-rv64-t4g-fetch-fault-tval
- `status`: completed_subslice
- `profile`: npc-dev
- `parent_goal`: active；完整功能与当前 RTL 的 5ns STA 尚待最终回归
- `updated_at`: 2026-07-14 +0800

## Root cause

取指桥已经在响应中保留第一个失败 halfword 的 packet offset `F`，decoder 也使用 `F` 判断错误
属于 slot0 还是 slot1；但 response→FIFO 边界没有保存 fault address。FIFO 只保存 slot PC，lane0
与 lane1 最终都把指令起始 PC 当作 `tval`。

确定性反例是从 `...0ffe` 开始的 32-bit 指令：低半字成功、`...1000` 上半字 fault。`xEPC`
应为 `...0ffe`，`xTVAL` 应为实际 faulting portion `...1000`；旧路径错误地得到
`xTVAL=...0ffe`。

## 实现

- `OooFetchPacketDecode` 在 packet response 边界计算 `fault_tval = rsp_pc + resp0_bytes`；
- `OooFetchPacketFifo` 将该 64-bit 字段与 packet/resp 原子入队、出队和 wrap；
- `OooFrontend`、`OooCoreTopGlue`、`OooControlPlane` 只传递该 owner 字段；
- `OooPendingDispatchArbiter` 与 `OooPendingLane1CaptureGate` 的 fetch fault 都消费同一
  `head_fetch_fault_tval`，非 fetch fault 的既有 `tval` 路径不变。

计算放在 response/FIFO 边界，而不是 pending trap 尾部，避免在控制关键路径上新增一次 64-bit
加法；同时 packet-level owner 保证 lane0/lane1 不会各自重新推导出不同地址。

## 验证证据

- focused module chain：7/7 PASS，见 `evidence/focused-v2/summary.txt`；
- bridge→decoder page-end 真链：F=2/4/6 三种 faulting offset 全部 PASS，见
  `evidence/page-end-v1/summary.txt`；
- FIFO direct/ring/wrap、lane0、lane1 pending/capture/drain owner 均有定向覆盖；
- mutation-negative：decoder 丢 offset、FIFO 退回 slot PC、lane0 PC fallback、lane1 PC fallback
  四个缺陷均被拒绝，runner 为 `evidence/run-t4g-mutation-negative.py`。

## 实现者 / 审查者结论

- 实现者：`F` 从桥响应穿过 decoder/FIFO/control 到 trap capture，`xEPC` 与 `xTVAL` 的职责已
  分离；测试覆盖真实跨页响应而非仅手工注入最终信号。
- 审查者：该证据关闭的是已知 faulting-portion provenance 缺口，不等于所有 IFU physical
  access 边界已经完成；且新增 FIFO 字段后的 200MHz 结论必须以当前 RTL fresh STA 为准。

## 剩余工作

父目标仍需全模块/官方/特权/CoreMark 回归、最新 frozen synthesis + exact 5ns STA、e2e/strict
guard 与独立审查。
