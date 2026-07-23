# V9G IFU-AXI-G1 当前设计证据合同

## 工程范围

工作对象是授权的本地 RV64 Verilog/SystemVerilog 双发射 OoO 处理器工程。操作只覆盖本地
RTL、规格、testbench、Icarus/Verilator 等 EDA 工具与生成证据；不使用网络、远程主机、
账号、凭据或第三方服务。

本切片只裁决 OooFetchAxiBridge 的 PTE A 位更新写事务与 AxiXbar 写响应 owner 生命周期。
生产 RTL 仅在动态证据证明合同不成立时才允许修改；当前规范入口已经证明 focused 3/3、
module 109/109 与 compile-success RTL verification variant 18/18，因此本轮实现是 TB、
证据重建、当前 design_id 绑定和架构账本加固，生产 `.v` 不变。

## Stage 0 接口合同

| 合同 | 冻结内容 |
| --- | --- |
| interface | OooFetchAxiBridge 的 IFU AXI AW/W/B 端口、mmu_flush_i、fetch request/response；AxiXbar 的 master/slave 写端口 |
| handshake | AWVALID 与 WVALID 各自保持到自身 ready fire；B completion 只在两 channel accepted 且 BVALID/BREADY fire 时成立 |
| transaction | state_q 是整笔 PTE A-update write owner；aw_done_q/w_done_q 是独立 accepted 位；ad_drop_q 只拥有旧 fetch 语义 |
| recovery | mmu_flush_i 不是 AXI reset；只 sticky-drop 旧 fetch 语义，同时承认当拍 AW/W/B fire，并在完整 B completion 后回 IDLE |
| timing | S_AD_UPDATE 内无新 fetch、fetch response 或 AR；payload 在 channel stall 与 repeated flush 期间稳定；本切片不修改生产时序结构 |
| parameter | 当前 XLEN、AXI id/len/size/burst、PTE 8B write、现有 M_COUNT/S_COUNT 配置；不扩大到其它配置 |

写 owner 的建立边界是寄存后的 `state_q == S_AD_UPDATE`。若 `mmu_flush_i` 到达时旧状态仍为
`S_WALK_R`/PTE read owner，则普通读侧 flush/drain 分支优先，不建立 A-update write owner；
只有已经进入 `S_AD_UPDATE` 的事务才适用本合同的 AW/W/B 必达排水。该边界避免把相邻的
PTW read-owner 取消语义混入 IFU-AXI-G1 写 owner 声明。

## Owner 与数据流

1. S_WALK_R 的合法 A=0 leaf 捕获 walk_pte_addr_q 与 ad_pte_q，然后进入 S_AD_UPDATE。
2. OooFetchAxiBridge 以 state_q、aw_done_q、w_done_q 保存写事务进展，以 ad_drop_q 保存
   flush 后的架构语义处置。
3. AxiXbar 分别捕获 master AW/W，获得 slave owner 后独立发送 AW/W，并在 exact slave
   B fire 时释放 wr_active_q 与 wr_master_busy_q。
4. IFU B owner 释放后，已经排队的后续 master 必须以精确地址、数据和 B response 到达 slave。

## 定向验证矩阵

- AW-first、W-first、flush 与第一笔 AW/W fire、两 channel 均未接受、两 channel 已接受等待 B。
- flush 与最后 AW+B 同拍、flush 与最后 W+B 同拍、flush 与 AW+W+B 全同拍、flush 与 B error 同拍。
- repeated flush、AW/W backpressure、AWADDR/WDATA 稳定、BREADY 保持。
- drop 期间 fetch/response/AR 静默，drop completion 忽略 BRESP；非 drop B error 保留 access fault。
- bridge+xbar 延迟 B、IFU owner release、后一 master exact payload 与 response 进展；通用
  AxiXbar 另覆盖 BVALID 在 BREADY=0 下保持两拍、不得提前释放 owner，以及 AW-first/W-first。
- 18 个 branch-local 本地 RTL 验证变体均须编译成功，并由各自指定动态 oracle 拒绝；变体
  elaboration、源/变体哈希、临时路径归一化与生产源码前后哈希由证据生成器独立重建。

## 声明边界

规范入口为 `make -C npc/rv64 check-ifu-axi-flush-drain`。通过只允许把 IFU-AXI-G1 标成
当前 design_id 下 CLOSED。full-core ARCH_STABLE 仍受其它
P0/P1、holder census、同源功能 aggregate 与 freeze input 阻塞；PPA 保持 UNQUALIFIED，
promotion_eligible=false。本切片不声明完整 ISA、Linux、物理 200 MHz 或 PPA 改善。
