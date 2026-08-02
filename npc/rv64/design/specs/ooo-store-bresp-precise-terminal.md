# T4N plain-store late-B precise terminal

> 状态：2026-07-14 已实现并完成 StoreQueue、IntBackend、MemAxiBridge focused 验证。

## 1. Root cause 与目标

旧 plain-store 流程在 probe success 时就向 ROB 写 done；store 随后先退休，再由 SQ 后台
`pretrans+nokill` 落存。这个协议无法把设备运行时 `B SLVERR/DECERR` 归还给已经释放的 ROB
owner，只能打印警告，也使“真实写已发”“B 已完成”“架构提交”三个事件坍缩。

T4N 将 store terminal 后移到真实写的聚合 B：probe success 只填 SQ，ROB owner 保持到 B；
B 取得 formal-WB credit 后产生唯一 completion，下一拍 ROB commit 才释放 SQ。

## 2. 三事件状态机

```text
dispatch alloc
     |
     v
SQ allocated --probe success--> filled{VA,PA,data,strb}
     |                              |
probe fault                         | physical SQ head == ROB head
     |                              v
     +------ terminal       physical request fire (pretrans+nokill)
                                    |
                              request_sent (owner stays)
                                    |
                              aggregate B + WB credit
                                    v
                                 terminal
                                    |
                              ROB commit/release
                                    v
                                  free SQ
```

三个事件不可互换：

1. `req_fire` 只置 `request_sent`，不得减 SQ count；
2. `terminal` 来自 local plain-store exception、probe fault 或 physical B，只置 terminal，
   仍不得释放；local exception 使用 memory reservation 的真实 ROB tag，覆盖 translated
   SD/FSW/FSD page-end misalignment，且绝不形成 bridge request。SQ 提供两个独立 terminal
   CAM 端口，因为 older B/probe terminal 与 younger local exception 可同拍且 tag 不同；禁止
   用单 tag mux 丢事件，也禁止用 response→issue-ready backpressure 串行化；
3. `release` 只允许 physical SQ head、ROB head、terminal owner，才减 count/推进 head。

成功 probe 不产生 formal WB；因此 store 在实际 B 前绝不具备提交资格。

V13P 允许的唯一时序缩短发生在 aggregate B 已经真实到达之后：若 backend 的
formal-WB 与 SQ terminal sink 同拍均有 credit，bridge 可以在 B 拍
直接呈现 response；若任一 sink 无 credit，必须捕获进既有 `S_RESP` 并保持。两条路径都以
同一个 aggregate B 为 terminal，且 ROB 仍只从下一拍 registered done 退休。该规则不是
AW/W early complete，也不允许 B 拍 station advance 或同拍 ROB commit。

这里的 plain-store DRAIN 不进入 `OooMemOwnerTerminalCollector`：DRAIN 在 B 拍经
`sq_response_terminal_w` 写 SQ terminal，STORE owner 继续保留到 registered ROB commit
之后，再由 `sq_owner_release_mask_w` 释放。collector 仍服务普通 response/drop 等既有
终端来源，但不是本条 DRAIN direct/fallback 握手的第三个 credit sink。

## 3. 地址与异常所有权

- SQ 同时保存 original VA 与 probe 返回 PA；前递/歧义查询面使用 VA，真实写只使用 PA。
- translated mode 禁止 VA alias 不安全的 store-to-load forwarding，沿用 blind ordering。
- physical write 的 `SLVERR`/`DECERR` 均形成唯一 `EXC_STORE_ACCESS_FAULT`（cause 7）；
  `tval` 必须是 original VA，而不是 PA/MIQ request address。
- `OKAY` 同样形成一次无异常 store WB，使 ROB done；三种 B outcome 都只 pop 一次 MIQ。
- `mem_rsp_ready` 对 B 必须读取 formal-WB credit；credit 不足时 bridge response 原地保持。
- aggregate B 可先由 bridge 无条件接收；所谓“原地保持”包括把当前 B 的 error 与 exact
  active owner 原子捕获到 `S_RESP`。只有 `response_valid && response_ready` 才形成 backend
  formal WB；ready 足够的 B 拍 direct fire 与随后 `S_RESP` fire 必须严格互斥。

### 3.1 final-PA 双查询组合契约

`query[01]` 是无状态、无反压的当拍组合接口。每路输入携带 load 的完整
`ProducerId`、final PA、typed class 与低位连续 byte mask；输出必须且只能是
`allow/forward/replay` 之一。该接口不读取同拍 SQ release 形成 credit，也不反向参与
dispatch/issue ready，因此不能产生 response→request 或 release→allocation 组合环。

每个 older、valid、non-terminal SQ entry 的字节关系按以下等价硬件定义：

```text
delta = store_base_pa - load_base_pa
aligned_store_mask/data = shift(store_mask/data, delta), |delta| < STRB_W
overlap = load_mask & aligned_store_mask
```

store 起点在 load 之后时左移，store 起点在 load 之前时右移；距离大于等于
`STRB_W` 时 overlap 为零。只有 overlap 字节可以更新 coverage/forward data。entry
按 physical SQ head→tail 遍历，因此后遇到的、程序序更年轻但仍 older-than-load 的 store
必须覆盖先前同字节数据。多个 store 可以合并为完整 coverage；存在 overlap 但 coverage
不完整时 replay，禁止 memory-read 后再拼接。未 fill、typed attr 非法、零 store mask 或
class mismatch 均 fail closed 为 replay；terminal store 不再参与 ordering。IO 采用强顺序：
只要存在任意 valid、older、non-terminal SQ entry，IO query 不得越过它；任意 older IO store
也不得被更年轻的 query 越过，因此该两类情况不以地址 overlap 为前提，均 replay。

四态仿真同样属于该组合契约。若 SQ physical head，或潜在参与 entry 的 valid、程序序年龄、
terminal、fill、PA、typed class、byte mask、被 overlap 选中的 data 任一事实未知，必须把该
entry 视为 ordering poison 并 replay；不得依赖 Verilog 普通 `if` 把 X 当作 false 而乐观
allow/forward。已知 invalid、younger 或 terminal entry 的其它 payload 不参与判决。

该查询锥不得推断 latch、组合环或任何跨拍状态。RTL 可以把历史的
`ENTRY_COUNT × STRB_W × STRB_W` 全字节地址比较阵列等价改写为每 entry 的有界
offset、mask 对齐和 `STRB_W` 路 byte-enable mux，但不得改变上述字节级结果或双 query
独立性。

## 4. 请求仲裁与顺序

请求源先形成独立 eligibility，再由显式单热 grant 选择：

```text
SQ physical head > AMO write > buffered request > issue reservation
```

SQ grant 必须优先于 younger buffer/issue。失败的 younger issue 不得谎报 request fire；若 one-entry
buffer 为空，可在同拍把 reservation owner 转入 buffer。MIQ 的 DRAIN entry 使用真实 store ROB tag，
使 B response、WB、SQ terminal 三者身份一致。`request_sent` 阻止任何重复真实写。

SQ precommit eligibility 还必须显式满足 `!flush_i && !checkpoint_restore_hold_w`。raw checkpoint
request 立即进入 admission hold，故 `grant_sq=req_valid=req_fire=miq_push=0`，不会产生“SQ 置
`request_sent`、MIQ push 被恢复丢弃”的半生命周期。

若 request 到达前 physical store 或 AMO write 已完成 bank0 `req_fire`，该完整 `ProducerId` 从 request
fire 到 lane0 ROB retirement 持有不可撤回 write lease。restore 保持 pending，既有 B response、formal
WB、精确 lane0 commit 与 SQ release 继续推进；lane1 commit 被阻塞，所有新 dispatch/issue/request
仍被冻结。只有 lease、SQ `request_sent` 与 DRAIN owner 全部清空，`checkpoint_restore_apply_w` 才产生
一次 backend-wide 破坏性恢复脉冲。该 apply 同步恢复 Dispatch/ROB/IQ/rename、PRF、FP、execution
stages、MIQ/retry、SQ/LQ，并经 control flush sequencer 广播到两个 memory request gate。

## 5. forwarding、branch 与 global flush

- request fire 与 B 后 SQ owner 都继续参与 load ordering/forwarding，直到 ROB release。
- branch flush 只清比分支 boundary 年轻的程序序后缀；ROB-head physical owner 必须存活。
- global flush 可以清 speculative/probe-fault entry，但不得清已接受的 physical owner。
  `T4N-SQ-GLOBAL-NUKE` 是承重断言：若 global flush 与 live `request_sent` owner 重叠，除非同拍
  terminal release，否则立即报错。这个断言不是恢复机制，防御性 survive 逻辑只避免静默破坏。
- probe fault 未发真实写，仍可被 older branch/global trap 正常 squash。
- global flush 与 checkpoint request/hold 都禁止新的 SQ physical request；checkpoint request 不提前清除
  已发射 owner，accepted apply 才进入 backend/memory recovery。已在飞 DRAIN response 与 global flush
  同拍时，MIQ 仍必须先兑现 response pop，再执行 DRAIN keep-set 压缩。

## 6. T4M post-translate device 交叠

translated younger load 在 older SQ filled entry 或 older MIQ PROBE 存在时 blind block。由于 T4N
让 SQ owner 跨 request/B/commit 常驻，VA 看似 PMEM、PA 实为 device 的 younger load 不会先进入
bridge `S_DEVICE_WAIT`，从而避免单 FSM/MIQ 与 older store 相互等待。store write/B/commit/release
完成后，load 才可发请求；若 bridge 最终分类为 device，再由 MIQ-head==ROB-head sideband release。

该规则不全局串行化 PMEM load：没有 older store 时，translated cacheable PMEM 仍沿原并发路径。

## 7. 验证合同

- `tb_ooo_store_queue`：VA/PA 分离、head 双匹配、request/B/release 三事件、at-most-once、
  two-store physical order、branch survive、global speculative squash、release+dual-alloc、
  terminal+release+flush 事件代数。
- `tb_ooo_int_backend`：probe no-WB、delayed B、WB-credit stall、VA!=PA B error cause7/tval VA、
  SQ priority/no false fire、two-store order、T4M older-store admission、SD/FSD page-end local
  terminal、older normal + younger store fault exception-lane0-only、checkpoint restore no-fire；
  `V8S_DUAL_MEMORY_FOCUSED` 还覆盖 delayed-OKAY B、raw restore/error-B 同拍及 AMO write 的
  request/hold/apply drain，精确计数 physical request、B/formal-WB、lane0 commit、SQ release 与 apply。
- `tb_ooo_mem_axi_bridge`：OKAY/SLVERR/DECERR 各自唯一 held response，ready stall 下稳定；既有
  post-translate device cancel/release 与 translated PMEM case 继续通过。
- `OOO_ASSERT`：request/grant one-hot、request at-most-once、commit-before-terminal、B-credit、
  B→unique-WB、exception-lane0-only、restore/flush SQ grant mask、local store exception terminal、
  双 terminal 各自唯一 CAM hit/同拍 tag 互斥、branch survival、global nuke、T4M admission、
  checkpoint hold 零新 owner、write lease 精确 ROB head、apply 前零不可撤回 owner及 pending 时 lane1
  零退休。

本切片提供功能与结构证据；未单独运行综合/STA，不据此宣称 200 MHz 已重新 closure。

## 8. R4-S0 最终属性与 cache 终结语义

SQ owner 从 probe success 起保存 `{original_va, final_pa, final_cacheability, data, strb}`。
`final_cacheability` 由翻译、权限、PMA 与 leaf PBMT 全部完成后的唯一分类点产生；physical
drain 必须原样携带，不能因 final PA 落入 PMEM 而把 PBMT NC/IO 重新升级为 cacheable。

聚合 B 的 cache 维护真值冻结如下：

| owner/class | aggregate B | D-cache 动作 |
| --- | --- | --- |
| 普通 CACHED store | OKAY | 允许 2 拍 RMW write-update；miss no-allocate |
| 普通 NC/IO store | OKAY | 若 final PA 可能有 PMEM alias，失效本行；cross-line 同时失效 p1 |
| 任意普通 store | SLVERR/DECERR | 保守失效 alias；不得 RMW，因为 split 前 beat 可能已部分生效 |
| HW A/D update | 任意 terminal | valid-only 失效，不占 RMW 两拍窗口 |

精确异常仍由同一 SQ/ROB owner 在 B 后产生，cache maintenance 不能提前释放 owner，也不能
把 B error 改写为成功。S0 尚未区分 NC 与 IO ordering：两者暂沿保守 serialized 路径；S1
typed class 后，NC 可在物理 CAM PASS 后按 RVWMO 执行/forward，IO 则必须 ROB-head、禁止
forward/replay/speculative target。所有 store 不论 class 仍只允许 ROB-head 精确授权产生外部写。
