# RV64 T3D：FP completion → integer IQ 跨域同拍 select 拆环

## 基本信息

- `task_id`: 2026-07-13-rv64-t3d-cross-domain-wakeup
- `status`: completed (structural slice); parent timing goal remains active
- `profile`: npc-dev
- `base_commit`: eb9bd3b28（叠加 T3B/T3C 工作树）
- `trigger`: T3C admission RED转绿后，full Verilator 暴露 FP wake/branch kill SCC 分支
- `parent_goal`: active；完整功能与 physical 200 MHz 未闭合

## 目标

让 FP execution completion wake0 对 integer IQ 的 FP-store 数据源只做 sticky ready，consumer
最早下一拍 select；FP load wake1 保留同拍快路。不动整数 EX/MEM fast wake、不动 FpIssueQueue
self/int wake，也不注册 kill。

合同与周期真源：`npc/rv64/design/specs/ooo-cross-domain-wakeup.md`。

接受门禁：旧版 RED 真实失败；focused/93/full build/FP与AM回归全绿；fresh OpenSTA 中该环族为0。

## 交付证据与裁决

- resident FP-store 在 execution wake0 的 N 拍旧 RTL 错误发射；GREEN 为 N 不发、
  N 沿 sticky、N+1 发，FP-load wake1 同拍快路保留。
- dispatch collision、compaction、kill survivor 与 `[IQ-FP-WAKE-STICKY-ONLY]` 负探针通过；
  93/93 module、full Verilator、AM/FP/official 177 与 CoreMark10 通过。
- T3B/C/D fresh 中 FP completion→integer IQ→branch kill 环族为 0；剩余 16 环属
  checkpoint capture，后由 T3E 清零。
- T3D 切点保留；合并候选 WNS/TNS 仍为 `-16.37/-273561.75 ns`，父目标
  保持 active。T3E fresh 证明反向 integer→FP 跨域路径也需独立切断，由 T3F
  契约接管。
