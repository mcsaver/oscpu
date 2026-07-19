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

## 3. 地址与异常所有权

- SQ 同时保存 original VA 与 probe 返回 PA；前递/歧义查询面使用 VA，真实写只使用 PA。
- translated mode 禁止 VA alias 不安全的 store-to-load forwarding，沿用 blind ordering。
- physical write 的 `SLVERR`/`DECERR` 均形成唯一 `EXC_STORE_ACCESS_FAULT`（cause 7）；
  `tval` 必须是 original VA，而不是 PA/MIQ request address。
- `OKAY` 同样形成一次无异常 store WB，使 ROB done；三种 B outcome 都只 pop 一次 MIQ。
- `mem_rsp_ready` 对 B 必须读取 formal-WB credit；credit 不足时 bridge response 原地保持。

## 4. 请求仲裁与顺序

请求源先形成独立 eligibility，再由显式单热 grant 选择：

```text
SQ physical head > AMO write > buffered request > issue reservation
```

SQ grant 必须优先于 younger buffer/issue。失败的 younger issue 不得谎报 request fire；若 one-entry
buffer 为空，可在同拍把 reservation owner 转入 buffer。MIQ 的 DRAIN entry 使用真实 store ROB tag，
使 B response、WB、SQ terminal 三者身份一致。`request_sent` 阻止任何重复真实写。

SQ precommit eligibility 还必须显式满足 `!flush_i && !checkpoint_restore_i`。两种 flush 都会
清 MIQ；若 restore 拍允许 SQ fire，SQ 会置 `request_sent` 而同拍 MIQ push 被 flush 臂丢弃，形成
永久无 response owner。故 restore/flush 拍 `grant_sq=req_valid=req_fire=miq_push=0`，下一拍 owner
原样恢复请求资格。

## 5. forwarding、branch 与 global flush

- request fire 与 B 后 SQ owner 都继续参与 load ordering/forwarding，直到 ROB release。
- branch flush 只清比分支 boundary 年轻的程序序后缀；ROB-head physical owner 必须存活。
- global flush 可以清 speculative/probe-fault entry，但不得清已接受的 physical owner。
  `T4N-SQ-GLOBAL-NUKE` 是承重断言：若 global flush 与 live `request_sent` owner 重叠，除非同拍
  terminal release，否则立即报错。这个断言不是恢复机制，防御性 survive 逻辑只避免静默破坏。
- probe fault 未发真实写，仍可被 older branch/global trap 正常 squash。
- global flush/checkpoint restore 组合拍禁止产生新的 SQ physical request；已在飞 DRAIN response
  与 global flush 同拍时，MIQ 必须先兑现 response pop，再执行 DRAIN keep-set 压缩。

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
  terminal、older normal + younger store fault exception-lane0-only、checkpoint restore no-fire。
- `tb_ooo_mem_axi_bridge`：OKAY/SLVERR/DECERR 各自唯一 held response，ready stall 下稳定；既有
  post-translate device cancel/release 与 translated PMEM case 继续通过。
- `OOO_ASSERT`：request/grant one-hot、request at-most-once、commit-before-terminal、B-credit、
  B→unique-WB、exception-lane0-only、restore/flush SQ grant mask、local store exception terminal、
  双 terminal 各自唯一 CAM hit/同拍 tag 互斥、branch survival、global nuke 与 T4M admission。

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
