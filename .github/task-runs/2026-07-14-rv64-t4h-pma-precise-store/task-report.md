# RV64 T4H：静态 PMA 前置的精确 plain-store access fault

## 基本信息

- `task_id`: 2026-07-14-rv64-t4h-pma-precise-store
- `status`: completed_subslice
- `profile`: npc-dev
- `parent_goal`: active；动态设备 B error 与当前 RTL 的 5ns STA 仍待处理/签核
- `updated_at`: 2026-07-14 +0800

## Root cause 与数据流

plain store 的 probe 原先只做 Sv39 翻译与 PMP。Bare、DTLB hit 或 PTW leaf 得到 PA 后，没有检查
该 PA 是否落入当前 `NpcTop` 的真实实现窗口；因此 default/空壳地址会让 probe 成功、SQ fill、ROB
退休，随后 `pretrans+nokill` drain 绕过翻译/PMP并写到 `AxiDefaultSlave`。B `SLVERR` 到达时
指令已经退休，只剩 `[SQ-DRAIN-ERROR]` 警告，无法形成精确 store access fault。

既有 probe-error→formal-WB→ROB exception 链本身正确：cause=7，`tval` 保持原 VA。缺口位于 probe
成功之前的最终数据 PA authorization，而不是后端 trap 编码。

## 实现

- 新增组合叶模块 `OooPmaChecker`，按当前 `NpcTop` 真实 xbar 首命中地址图 fail closed；
- 允许 CLINT、PLIC、UART、virtio-blk、PSRAM、legacy-MMIO、SDRAM，拒绝接
  `AxiDefaultSlave` 的空壳/default 窗口；名义 SRAM 因被更高优先级 PLIC 完整覆盖而按 PLIC 允许；
- 以扩展位宽检查完整 byte range，地址回绕、跨 region 与未映射均 fault；
- Bare/DTLB-hit direct path 与 PTW leaf path 都在成功 probe、data AR/AW/W、D-cache/DTLB
  side effect 前检查；deny 返回 `rsp_error=1,page_fault=0`；
- `pretrans` drain 不在退休后重新生成异常，`MEM-PMA-PRETRANS` 断言证明其 PA 属于同一静态允许图；
  direct/walk deny 另由 `MEM-PMA-DIRECT`、`MEM-PMA-WALK` quiet-response 断言约束。

## 验证证据

- PMA checker + bridge：2/2 PASS，见 `evidence/pma-bridge-v2/summary.txt`；
- Bare default-gap probe 与 Sv39 leaf→ChipLink-stub probe 均返回 access fault，且无 data
  AR/AW/W；
- 后端真实 SD 指令定向：probe error 产生 cause=7、原 VA `tval`，`sq_fill=0`、`sq_drain=0`，
  见 `evidence/backend-v1/summary.txt`；
- mutation-negative：checker 强制 allow、direct deny bypass、walk deny bypass 三个缺陷 3/3
  被拒绝，runner 为 `evidence/run-t4h-mutation-negative.py`。

## 实现者 / 审查者结论

- 实现者：当前静态地址图的 default/空壳 plain store 已从退休后 B error 转为退休前精确
  store access fault，且没有通过“drain 后补 trap”破坏精确状态。
- 审查者：PMA 只能预测 region-level 静态可达性。设备内部未实现 offset 或运行时状态产生的
  B `SLVERR` 仍可能在退休后到达；要覆盖全部动态写错误，必须让 ROB 持有 store owner 直到 B，
  或定义无副作用的设备 write-probe ABI。本切片不得越级声明“所有 store 总线错误均精确”。
- 新增 PMA 比较锥后的 200MHz 必须用当前 RTL fresh synthesis/STA 重验；旧 17ps 裕量不可复用。

## 剩余工作

父目标仍需审计 LSU standard split 与 physical wrapper `ARSIZE`，再跑全模块、官方/特权、
CoreMark、最新 5ns STA、e2e/strict guard 和独立审查。
