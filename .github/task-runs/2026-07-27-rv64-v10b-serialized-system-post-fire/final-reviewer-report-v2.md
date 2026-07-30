# V10B serialized SYSTEM post-fire final review v2

## 标准化裁决

`APPROVED_FOR_CURRENT_SCOPE`

RV64 RTL 对象为 `OooPendingSystemSequencer` 八类 canonical kind、
`mmu_flush_o → OooFetchPacketCache/OooDualMemBridgeWrapper` 及 V3
证据；周期为 C0 terminal → C1 clear → C2 no-repeat，CSR 另覆盖
enqueue → exact ProducerId/PC Ccommit。现有 Icarus 证据为 3 个 baseline
PASS、14/14 个可编译负向 RTL 版本被动态拒绝、module-current-v3
113/113 PASS。审查节点未重跑仿真、综合或 STA。

审查绑定的 current design-id 为：

`sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`

## v1 反证项复核

- 真实 `npc/rv64/vsrc/frontend/OooFetchAxiBridge.v` 已进入 v2 合同并完成
  源码复核。
- WFI、A-coherence、Debug/trigger、SFENCE/SINVAL 四份 cohort exclusion
  及 architecture debt ledger scope hash 已绑定 current design-id。
- V3 的 17 个 case 均记录 `testbench_path` 与 `testbench_sha256`，并与
  当前四个 testbench 文件逐项相符。
- `fencei-reason-to-serial` 版本在 typed-reason checker 失败后，
  `[V10B-SYSTEM-MIXED]` 也由 `tb_errors` 门控为 FAIL；最终
  `[RESULT] FAIL status=1`，不存在局部 PASS marker 假绿。

## 八类 bounded transaction 裁决

| kind | 周期/副作用边界 | 裁决 |
| --- | --- | --- |
| CSR | enqueue 后保持 ProducerId lease；仅 exact PID+PC commit 写 CSR、产生 `CSR_COMMIT/NONE` redirect 并清 holder/stop；SATP 写产生注册 MMU pulse | PASS |
| ECALL | C0 selected trap-ex 与 TRAP redirect；C1 写 xEPC/xCAUSE/xTVAL 并清 owner；C2 不重复 | PASS |
| XRET | C0 real MRET/SRET request 与 XRET redirect；C1 更新 privilege/mstatus、产生 control commit 并清 owner | PASS |
| WFI | cohort 定义的 immediate-resume：C0 SERIAL redirect；C1 control commit 与 owner/stop clear；零 CSR/trap/MMU | PASS |
| SFENCE_FAMILY | 四种编码归一为同一 kind；C0 SFENCE redirect/raw MMU source；C1 control commit、注册 MMU 与 clear | PASS |
| FENCEI | C0 FENCEI redirect/raw MMU source；C1 control commit、注册 MMU、FPC clear 与 owner clear | PASS（组合证据） |
| FENCE | C0 额外等待完整 `mem_idle_i`；SERIAL redirect；C1 control commit/clear；零 CSR/trap/MMU | PASS |
| IRQ | C0 selected trap-irq 与 TRAP redirect；C1 写选中 trap record 并清 owner；C2 不重复 | PASS |

最强被拒绝反例为切断
`OooFetchPacketCache.clear_i(mmu_flush_i)`：该版本编译成功，但出现
stale response、无 AXI refetch 并返回旧 instruction packet，typed marker
和最终结果均为 FAIL。

## 证据范围与未知项

- FENCE.I 由 production MMU pulse、`NpcCoreTop` 静态连线和 fetch bridge
  动态 consumer test 组成 bounded 组合证明；它不是单一 full-core
  self-modifying program，也不证明 D-side store visibility 或 Linux。
- 本轮没有形式穷举；dual D-side 主要是拓扑/静态合同复核。
- `npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json` 仍绑定旧
  design-id 和 111-module inventory，属于 full-core currentness GAP。
- `SERIALIZE-G1` 仍为 P1/OPEN；simulation exit、Linux terminal、
  architecture-stable、综合/STA/power/PPA 均未关闭。

## 审查节点状态

- contract SHA-256：
  `47102bd84f587b9ff99e3d4edd63d66b7404fb829d0e232e828183a0e30a8420`
- 审查节点只读，未修改文件。
- Windows→WSL 唯一工程命令 lane 已明确归还主节点。
