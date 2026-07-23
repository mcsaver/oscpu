# V9I IFU-ACCESS-G1 当前设计证据合同

## 工程范围

本切片只重新裁决本工作区 RV64 双发射 OoO 核的 `IFU-ACCESS-G1`：instruction fetch 的
物理访问范围、EXEC PMP、AXI
RRESP、ARSIZE/ARPROT、`ARPROT[2]` instruction 属性的 default-slave 选择和 lane1 instruction
page/access-fault owner 必须在
当前 design-id 下形成同一套可判别证据。历史结果只提供合同与反例，不能替代 current-source
动态证明。生产 RTL 仅在当前设计不满足合同且 root cause 已定位时才允许修改。

## 冻结 transaction 与 owner 合同

| 合同 | 冻结内容 |
| --- | --- |
| instruction footprint | 两条指令真实长度 `L0,L1∈{2,4}`，`N=L0+L1∈{4,6,8}`；instruction data 只按 offset `0,2,...,N-2` 发 2B read，不能访问 `[N,8)` tail |
| translation/frontier | successful halfword 才能提供 C/32 长度；第二页只在下一必需 halfword 跨页时翻译；首个失败 frontier `F∈{0,2,4,6}` 后不得有年轻 PMP check、instruction AR 或 cache fill |
| PMP/RRESP | 每个 instruction AR 前必须对相同 PA、相同 2B footprint 做 EXEC PMP；PMP deny 不发 AR；RRESP 只属于当前 halfword并停止年轻访问；cache 固定窗口 deny 只能退回 exact slow path，不能直接制造架构 fault |
| response ABI | success 为 `(OK,OK,split=4)`；fault 为 `(OK,cause,split=F)`；V9H `IFU-FETCH-G2` 继续负责 bridge→decoder byte provenance，本合同验证 physical-access owner |
| AXI attributes | instruction data=`ARSIZE=2B, ARPROT=exec`；PTW PTE read=`ARSIZE=8B, ARPROT=data`；地址/size/prot 在 slave backpressure 时由已锁存事务 owner 保持 |
| AXI `ARPROT[2]` slave selection | instruction read 命中 UART/CLINT/PLIC/virtio 等 `SLAVE_EXEC_MASK[decoded]==0` 的窗口时，`AxiXbar` 在设备观察到 ARVALID 前选择 default error slave；同地址、`ARPROT[2]==0` 的 LSU data read 保持既有设备路径 |
| sized local DPI | instruction narrow read 只验证/读取声明的 `nbytes`，并按地址 byte lane 放置；PTW 8B 与 LSU low-window 兼容控制保持 |
| lane1 precise owner | ordinary 或 predicted-NT/actual-NT branch 后的 lane1 PF/AF 在更老 head0 之后进入 pending trap；predicted-NT/actual-taken 必须 squash；predicted-taken lane1 poison 不得建立 fault owner；伪 default ACCESS 无真实 fetch-fault provenance 时不得冒充 arch trap |

## 必须动态区分的反例族

- C/C、C/32、32/C、32/32 的 exact 2B AR 地址/数量以及 `[N,8)` poison noninterference。
- F=0/2/4/6 的 PMP deny 与 RRESP fault：frontier 前缀精确、frontier 后无年轻 instruction AR。
- B=2/4/6 与 N=4/6/8 的 page-cross 条件；`N<=B` 不得只因固定 8B window 启动第二页 walk。
- M-mode cache fill 后切到 S-mode、全零 PMP config 必须 default-deny；固定窗口 checker 拒绝而 exact C/C 可执行时必须 slow-path success。
- instruction/PTW 的 `ARSIZE/ARPROT` 与两拍以上 `ARVALID && !ARREADY` 周期内的
  `ARADDR/ARSIZE/ARPROT` 保持；instruction 属性选择 default slave 时 UART 无 AR handshake，并保留
  `ARPROT[2]==0` 的 LSU data read 正控制。
- lane1 PF/AF 的 ordinary、predicted-NT correct/wrong direction、predicted-taken poison 与 pseudo-default ACCESS 矩阵。
- 编译成功的负向 RTL 变体至少改变 footprint stop、second-page condition、PMP default-deny、RRESP
  stop、ARSIZE/ARPROT、`ARPROT[2]` default-slave 选择、lane1 capture/barrier/squash/provenance
  中的一条可区分 source edge；等价变体不得计数。

## 成功条件与声明边界

- canonical command 固定为 `make -C npc/rv64 check-ifu-access`。
- focused module tests、PMEM 尾界 2B 读取边界 oracle、动态派生 module aggregate、fail-closed evidence
  unit tests 和 current-source 编译成功负向 RTL 变体全部 PASS；结果绑定完整 production RTL design-id。
- 通过只允许把 `IFU-ACCESS-G1` 从 `STALE_EVIDENCE` 重绑为 current-design `CLOSED`。
  `IFU-TVAL-G1`、`PTW-PMP-G1`、LSU 标准 split transaction、外部物理 wrapper 对 ARSIZE 的消费、
  full-core architecture freeze 与正式 PPA promotion 均保持独立。
