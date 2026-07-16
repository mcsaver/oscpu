# T4M：Sv39 翻译后 device owner

## 问题与反例

当前 `OooIntBackend` 用有效地址（VA）判断 `issue0_mem_mmio_w`；普通 load 若 VA 落在
PMEM 数值窗便可在非 ROB-head 时发往 MIQ。Sv39 PTE 却可把该 VA 映射到 PLIC/UART/virtio
等 device PA。`OooMemAxiBridge` 完成 DTLB/PTW 后才拥有最终 PA，旧 `S_LOOKUP` miss 路径会立刻
发 data AR。分支 ROB-walk 只把对应 MIQ LOAD 标成 killed，不向 bridge 发选择性 flush；即使
响应最终被静默丢弃，错误路径的 device read side effect 已经发生。

定向反例取 `VA=0x000000008c000000`（PMEM 数值窗）经 level-2 Sv39 leaf 映射为
`PA=0x000000000c000000`（PLIC）。身份映射不是合同，也不能修复此问题。

## 请求、翻译、owner 与恢复数据流

```text
IQ/reservation --VA分类--> request fire --> MIQ{ROB,killed}
                                      |
                                      v
                         bridge request station
                                      |
                    Bare / DTLB hit / PTW leaf
                                      |
                           final PA + PMP/PMA
                         /                    \
                 cacheable PMEM          physical device
                 S_LOOKUP/cache       S_DEVICE_WAIT (no AR)
                                               |
                 MIQ head killed --cancel------+-- release iff MIQ head is ROB head
                         |                              |
                    quiet response                 exact data AR
                         |                              |
                    MIQ silent pop                normal response

branch mispredict -> ROB walk -> MIQ killed bit (不产生 bridge 全局 flush)
trap/serial flush ---------------------> bridge global flush/drop
```

## 接口合同

| 信号 | owner | 含义 |
|---|---|---|
| `mem_req_device_release_o` | backend MIQ/ROB | MIQ head 有效、未 kill，且其 ROB tag 正是 ROB head；只授权 bridge 当前物理 device read 发 AR |
| `mem_req_device_cancel_o` | backend MIQ | MIQ head 已 kill；bridge 必须无 AR 地生成 quiet response，使 MIQ 静默回收 |
| 最终 device 分类 | bridge | 只以授权后的最终 PA 是否在 cacheable PMEM 窗决定；VA 分类仅保留为明显 MMIO 的早期排序提示 |

由于 bridge FSM 单事务且 response 与 MIQ 严格同序，当前 FSM request 与 MIQ head 是同一 owner。
release/cancel 不参与 request ready、DTLB/PTW、PMP/PMA、cache lookup 或普通 PMEM datapath。

## 状态与 flush 合同

- Bare/DTLB-hit read、PTW leaf read、A/D-update 后续 read 在最终 PA 非 PMEM 时进入
  `S_DEVICE_WAIT`；该态在 release 前 `ARVALID=0`。
- release 后按原 exact-read payload 发 AR；若 READY 低，转入既有 `S_READ_ADDR` 并遵守
  `MEM-AR-HOLD`。
- cancel 优先于 release；cancel 不发 AR，返回全零、无 error/page-fault 的 quiet response。
- global flush/drop 在等待态直接回 idle，不发 AR、不向 CPU 返回 response。
- 一旦 AR 已握手，总线无 abort，后续 flush 仍按既有 `S_READ_DATA` drain 合同吞响应。
- cacheable translated PMEM 仍直接进 `S_LOOKUP`，不等待 ROB head；不得把所有 Sv39 load 串行化。

## 性能与时序边界

只把最终 PA 为 device 的 read 延迟到 ROB head。translated PMEM 的 lookup/hit/miss 状态转移不变；
已是 ROB-head 的 device load 在 wait 判决后的下一拍即可发 AR，与旧 uncacheable lookup-miss 的
发射节奏同阶。新增两根 1-bit sideband 仅门控 `S_DEVICE_WAIT`，不进入现有关键地址/翻译/cache
组合锥。按任务约束不跑综合/STA，因此这里只给结构证据，不宣称 200 MHz 已由本子任务复验。

## 验证计划

1. RED：对 PTW leaf 的新 device 分流做最小旧逻辑 mutation（退回 `S_LOOKUP`），同一 TB 必须观察
   到 PLIC PA 的错误 AR 并失败。
2. GREEN：VA 在 PMEM 窗、PA 在 PLIC 的 PTW 首次访问在 release 前无 AR；cancel 后 quiet 回收。
3. wrong-path/flush：DTLB-hit device wait 中 global flush 也无 AR/ghost response。
4. live owner：DTLB-hit device 只有 release 后发一次 exact-size AR并正常返回。
5. non-regression：既有 translated PMEM DTLB/cache-hit focused case 保持无需 release。

## 审查者检查表

- 反例必须真实跨越 VA/PA 分类，不能用 identity map。
- 检查三条最终 read 入口（direct、PTW leaf、A/D continuation），不得只修一条。
- release 必须绑定 MIQ head 与 ROB head；killed owner 不得靠 global flush 猜测。
- cancel/flush 周期以及 release 前不得出现 data AR；AR fire 后不得违反 AXI hold/drain。
- 普通 translated PMEM 不得进入 wait；测试通过不得越级声称全量或 200 MHz closure。

## 实施与证据

- GREEN：`evidence/green/logs/tb_ooo_mem_axi_bridge.log` 为 PASS；包含
  `[T4M-POSTTRANSLATE-DEVICE] cancel+flush quiet, live owner exact AR`。同一任务覆盖：
  PTW 首访 release 前无 PLIC AR、killed cancel quiet response、DTLB-hit wait 中 global flush
  无 AR/ghost response、live release 后 `PA=0x0c000004/ARSIZE=word` 单次 exact read；紧随其后的
  既有 `sv39_dtlb_and_paddr_cache_hit` 继续通过，证明 translated PMEM 未被 owner wait 串行化。
- RED：`run-red-mutation.sh` 只把 PTW leaf 的 T4M 分流退回旧 `S_LOOKUP`；
  `evidence/red/logs/tb_ooo_mem_axi_bridge.log` 按预期 FAIL，并同时记录
  `[CHECK-FAIL] T4M translated device waits without AR` 与
  `[T4M-OLD-LOGIC-LEAK] wrong-path AR addr=000000000c000004`。runner 自检结果在
  `evidence/red-mutation-run.log`。
- backend 合同：`evidence/contract/logs/tb_ooo_int_backend.log` PASS，`OOO_ASSERT` 构建；
  release/cancel 的 MIQ/ROB provenance 断言启用。
- 顶层贯通：`evidence/top/logs/tb_ooo_sv39_boot.log` PASS，覆盖
  `OooIntBackend → ... → OooCoreTopGlue → NpcCoreTop → OooMemAxiBridge` 新端口编译与 Sv39
  启动定向。日志中的 IFU dangling write-channel warning 为该既有 TB 的输入悬空，不涉及 T4M。
- `git diff --check` 对本任务 RTL/TB/spec/task-run 范围通过。
- strict guard：已运行 `scripts/agent-e2e.sh --guard --guard-mode strict`，结果记录于
  `evidence/guard-strict.log`。门禁因共享工作树累计 `changed_paths=4478`，要求与本任务无关的
  `am-kernels` 证据以及全量 `npc-dev` profile 而失败；本子任务明确禁止全量/综合，且不得替其他
  并行任务补写 memory/profile，因此采用显式豁免。T4M 自身的 bridge RED→GREEN、backend 合同、
  顶层 Sv39 三组 focused evidence 均已独立生成。

## 实现者/审查者切换

实现者结论：三条最终 read 入口均完成物理分类；device wait 在 release/cancel/global-flush
三种终止路径下有明确 owner，且普通 PMEM 状态机未改。

审查者反例复核：重点检查了“branch ROB-walk 不产生 bridge global flush”“站内下一请求与 MIQ
head 同拍 pop/advance”“release 后 ARREADY stall”“A/D continuation 使用锁存 PA”四个容易假绿的
交叠。当前 bridge 单 FSM、in-order response 与 MIQ request/fire 双射使 sideband owner 成立；
release 只在等待态门控组合 AR，若 stall 则边沿转入既有 registered `S_READ_ADDR`，继续由
MEM-AR-HOLD 保证。未发现需要扩大 scope 的冲突。剩余风险是本子任务按约束未跑全量、综合/STA，
因此只交付功能/结构证据，不声称 200 MHz closure。
