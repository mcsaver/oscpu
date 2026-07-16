# T4P VirtIO 同步 DMA / D-cache 一致性合同

> 状态：IMPLEMENTATION-FROZEN（2026-07-15）。本文件在 RTL 修改前冻结需求、事件、
> 优先级、flush、状态与时序边界；最终结论仍以修后动态 Linux 和 5 ns STA 证据为准。

## 1. 根因与证据边界

- `virtio_blk.c` 在一次 queue notify 的同步 DPI 调用内直接修改 guest PMEM：IN data、
  status、used element 和 used index 均绕过 RTL D-cache。
- 当前 D-cache 没有 DMA snoop。修前 cache-preload smoke 在 notify 前预热 status、used
  index、data，随后稳定得到 BAD TRAP code 7；status 轮询 10000 次均为 D-cache hit。
- 该反例**已证明 stale-hit 机制**，但没有单独证明 Linux 首次请求的 used index 当时
  必然 resident；“这就是本次 Linux hang 的完整动态因果链”必须由修后 Linux 越过
  `[vda]`、挂载 rootfs 并完成严格 guest gate 来闭环，禁止提前越级结论。
- 修前复现物已按 SHA256 归档到
  `tmp/2026-07-15-rv64-t4p-reset-syscon-linux/virtio-cache-preload-red/`。

## 2. 六项冻结合同

### 2.1 需求合同

1. 一次 virtio queue notify 内所有 host PMEM 写在 CPU 后继 load 可观察前必须使旧
   D-cache line 不可命中。
2. CPU→device 方向沿用现有 write-through D-cache + ordinary FENCE drain；本改动不
   改 AXI、PMP/PMA、Sv39、store precise-B 或设备 owner 语义。
3. 首版采用 full D-cache invalidate；当前 cache 无 dirty line，全清只产生 cold miss，
   不会丢 CPU 数据。

### 2.2 事件合同

- 生产者：`AxiVirtioBlk` 仅在地址 `0x050` 的 queue-notify AXI write 被聚合且同步 DPI
  处理返回后，产生完整一周期 `dma_dcache_invalidate_all_o`。
- 即使 DPI 返回错误也产生事件，因为失败前可能已经部分写 PMEM。
- 普通 virtio 寄存器写不得产生事件；事件不复用 IRQ、reset 或 MMU flush。
- notify 的 AXI B 与 virtio IRQ 在失效生效前保持不可见，下一拍再释放；因此 CPU/PLIC
  观察到完成时，D-cache valid 已在同一或更早时钟沿清零。
- 端口限定为“hart queue-notify 触发的同步 virtio DMA”合同，不承诺自主/异步 DMA。

### 2.3 优先级合同

- D-cache valid 更新优先级：`rst > dma invalidate-all > fill/store maintenance`。
- invalidate 与 lookup 判决同拍时 `lookup_hit_o=0`，不得经 hit-fusion 交付 stale data。
- invalidate 与 lookup issue 同拍：宏读可发生，但次拍 valid 已清，判 miss。
- invalidate 与 fill 同拍：SRAM 内容可写，valid 保持全 0。
- invalidate 与 RMW start/decision 同拍：保持既有 `rmw_pending/rmw_busy` 节拍和 1RW
  端口合同；valid 全清使数据不可见，不能复活 line。

### 2.4 flush / 顺序合同

- pipeline flush、checkpoint restore、MMU flush 都不得吞掉 DMA invalidate。
- bridge 不因 invalidate 改 `mem0_req_ready_o`、`stage_advance_w` 或 AXI owned-channel
  稳定性；唯一行为变化是旧 D-cache hit 转为 miss/refill。
- 当前唯一 DMA 由普通 MMIO store 触发；该 non-SC store 在到达设备前已由现有
  `OooIntBackend` store 路径清除 LR/SC reservation。因此当前合同无需另加 reservation
  clear。未来自主 DMA 必须另行加入 overlap/保守 reservation snoop，不能复用本结论。

### 2.5 状态合同

- `OooDataWordCache` 只清 `valid_q`；tag/data SRAM 不复位、不擦写，invalid entry 无语义。
- AxiVirtioBlk 增加一个一拍 notify-release 状态，锁存 DPI B response/IRQ；pending 时阻止
  新写入，先发 invalidate，再释放 B/IRQ，不允许丢失或重复响应。
- full invalidate 不占 1RW SRAM 端口，不改变 lookup/fill/RMW 四 owner 的互斥代数。

### 2.6 200 MHz / 关键路径合同

- 新增 lookup hit 末端单比特 mask，禁止把 DPI/设备组合逻辑直接接入 hit cone；事件必须
  先由 AxiVirtioBlk 寄存。
- 4096-bit `valid_q` 增加同步全清控制，属于 reset 同类高扇出控制；最终 RTL 必须重新做
  D-cache/bridge/top 的 fresh exact-5ns proxy STA，不能沿用 T4I 旧 netlist。
- 若 full-clear 造成 5 ns MISS，下一架构为 host 记录全部 DMA 写 index、RTL bitmap/FIFO
  逐 index 清除并在 drain 后释放 B/IRQ；不得退化成遗漏 IN `fread` 或 status/used 的单地址口。

## 3. 验证门

1. D-cache focused TB：全行失效、判决同拍 miss、lookup issue/fill/RMW start/RMW decision
   冲突矩阵，以及失效后新 fill 可重新 hit。
2. Bridge focused TB：stale line 在 S_LOOKUP 判决拍遇事件时不得融合，必须走 AXI refill。
3. 集成：cache-preload smoke 由 code 7 变 code 0；原 virtio smoke 保持 code 0；reset
   syscon poweroff/reboot/finisher 不回归。
4. Linux：至少越过 `[vda]`、EXT4/VFS root、Run init，并由严格 guest gate 验证 virtio
   block read、IRQ growth、自然 syscon poweroff。
5. 全量 module/lint/ISA/AM/benchmark 回归后，基于最终 RTL fresh synth + exact 5 ns STA；
   防伪审计必须绑定输入清单、netlist/报告哈希和 mutation negative。

