# 第 10 章：时序、反压与 WaveDrom 图册

## 10.1 时序分析的三个层级

### 功能周期

transaction 在哪个边沿被接收、保存、完成、退休。WaveDrom 最适合表达这一层。

### 组合时序

两个寄存器边界之间的逻辑深度，例如 IQ select→PRF→ALU→stage input。需要综合和 STA
才能得到真实 delay。

### 物理时序

包含 floorplan、真实 SRAM、CTS、SPEF、OCV、IO delay。当前讲义不提供物理签核结论。

不要看到“这里画一拍”就认为 200MHz 一定满足；也不要看到组合逻辑长就猜它一定跨两拍。

## 10.2 WaveDrom 约定

本讲义的图使用严格 JSON：

- `p`：clock；
- `0/1`：低/高；
- `.`：保持前一状态；
- `x`：无效/不关心；
- `=`：一段有效数据；
- 每个 pulse 代表逻辑事件，不默认固定绝对延迟。

读图时先找 `fire`，再找哪一个 valid/state 从该边沿开始拥有 transaction。

## 10.3 Fetch miss 与 outstanding

当前 IFU 主要维护单 outstanding request。cache/TLB miss 后，response 未回来前不能用同一
owner 接纳另一个不相关 fetch；redirect 则会把旧 response 标成 discard。

```wavedrom
{
  "signal": [
    {"name": "clk",             "wave": "p.........."},
    {"name": "fetch_req_valid", "wave": "010........"},
    {"name": "fetch_req_ready", "wave": "010........"},
    {"name": "outstanding",     "wave": "0.1....0..."},
    {"name": "ITLB miss",       "wave": "0.10......."},
    {"name": "PTW busy",        "wave": "0..1..0...."},
    {"name": "AXI response",    "wave": "0....10..."},
    {"name": "packet_valid",    "wave": "0.....10.."}
  ],
  "head": {"text": "fetch miss：outstanding owner 覆盖 TLB/PTW/AXI 全寿命"}
}
```

## 10.4 Redirect 与晚到 fetch response

```wavedrom
{
  "signal": [
    {"name": "clk",              "wave": "p........."},
    {"name": "old outstanding",  "wave": "01....0..."},
    {"name": "redirect",         "wave": "0.10......"},
    {"name": "discard_old_rsp",  "wave": "0.1...0.."},
    {"name": "old AXI rsp",      "wave": "0...10..."},
    {"name": "FIFO enqueue old", "wave": "0........."},
    {"name": "new PC request",   "wave": "0....10.."}
  ],
  "head": {"text": "redirect 后旧响应可到达总线，但必须被 discard，不能入 FIFO"}
}
```

这类设计不能简单“取消 AXI request”，因为 AXI address 已 handoff 后 slave 仍会返回。
正确做法是保留 owner/discard 状态并吃掉旧 response。

## 10.5 FIFO 反压

fetch packet FIFO 满时：

- 不再接收会溢出的 packet；
- 当前实现不做 full+pop look-through；同拍 pop 只让下一周期重新产生 credit；
- head packet 必须保持；
- PC/outstanding 不应为未被接纳的 packet 提前前进；
- redirect/flush 可以清 entry，但清理优先级要高于普通 enqueue/dequeue。

```wavedrom
{
  "signal": [
    {"name": "clk",          "wave": "p......."},
    {"name": "FIFO full",    "wave": "01..0..."},
    {"name": "rsp_valid",    "wave": "0.1...0."},
    {"name": "rsp_ready",    "wave": "0...10.."},
    {"name": "rsp_payload",  "wave": "x.=...x.", "data": ["packet P"]},
    {"name": "dequeue",      "wave": "0..10..."},
    {"name": "enqueue P",    "wave": "0...10.."}
  ],
  "head": {"text": "FIFO 满时即使本拍 pop，也到下一拍才接收被反压的 response"}
}
```

## 10.6 双 dispatch 的局部接受

两条 slot 不总是一起 dispatch，但首先要区分 mandatory 与 optional：

- lane0 普通、lane1 普通且资源够：双 fire；
- lane0 普通、lane1 普通且构成 mandatory pair：第二份资源不足时两条都停；
- lane0 普通、lane1 明确 optional：允许只接 lane0；
- lane0 普通、lane1 barrier：lane0 前进后，lane1 由 control pending capture，而不是
  假设 packet FIFO 自动重组一个新 head；
- lane0 branch/system/fault：lane1 不可越过；
- lane0 本身不接受：lane1 通常不能越过。

```wavedrom
{
  "signal": [
    {"name": "clk",            "wave": "p......"},
    {"name": "slot0 valid",     "wave": "01....0"},
    {"name": "slot1 mandatory", "wave": "01....0"},
    {"name": "resource pairs",  "wave": "x=..=x.", "data": ["1", "2"]},
    {"name": "dispatch0 fire",  "wave": "0...10."},
    {"name": "dispatch1 fire",  "wave": "0...10."},
    {"name": "head pop",        "wave": "0...10."}
  ],
  "head": {"text": "mandatory pair：资源只有一份时两条都停，资源齐备后原子双 fire"}
}
```

当前 `OooFetchPacketSeedMux` 只保留 clear 语义，旧 packet-seed dataplane 已删除；不要用
历史命名推导一个不存在的“lane1 回填 FIFO”路径。

## 10.7 completion-to-wakeup

producer 在 C2 获得 completion，dependent IQ source 同拍或下一拍变 ready；是否能在同一
周期直接 issue 取决于 wakeup/select/PRF bypass 的组合边界。

```wavedrom
{
  "signal": [
    {"name": "clk",             "wave": "p......."},
    {"name": "producer result", "wave": "0.10...."},
    {"name": "WB fire",         "wave": "0.10...."},
    {"name": "IQ src_ready",    "wave": "0..1...."},
    {"name": "select dependent","wave": "0..10..."},
    {"name": "PRF/bypass data", "wave": "x..=x...", "data": ["value"]},
    {"name": "dependent issue", "wave": "0..10..."}
  ],
  "head": {"text": "completion 广播清 busy/唤醒，dependent 使用 PRF 或 bypass"}
}
```

若 select 与 wakeup 组合在同拍，可能形成长路径；若打拍，则多一周期但时序更易收敛。
必须看实际 `always` 边界和 STA，不凭波形决定。

当前整数路径还区分 `early_wakeup` 与 formal WB：early wake 只写 IQ sticky-ready，
不清 Busy、不写 PRF、不写 ROB；紧邻 dependent issue 的值来自 registered EX packet
forwarding。formal WB 才更新 PRF/Busy/ROB。把两者合成一个 “completion” 脉冲会少画
一个真实 owner。

## 10.8 stage register 的 ready 公式

对单 entry elastic stage，常见：

```text
ready_o = !valid_q || ready_i
```

含义：

- 当前为空，可接新项；
- 当前有项但下游本拍会取走，也可同拍替换；
- 当前有项且下游不 ready，则保持 payload。

kill/flush 通常优先清 `valid_q`；如果同拍既 kill 旧项又有新输入，必须由规格决定能否接纳
新项，不能让两个 always 分支各写一次 valid。

## 10.9 多 owner completion 反压

```wavedrom
{
  "signal": [
    {"name": "clk",         "wave": "p........."},
    {"name": "EX0 valid",   "wave": "01..0...."},
    {"name": "MEM0 valid",  "wave": "01...0..."},
    {"name": "FP valid",    "wave": "01....0.."},
    {"name": "WB0 grant",   "wave": "010......"},
    {"name": "WB1 grant",   "wave": "010......"},
    {"name": "third hold",  "wave": "0.1..0..."},
    {"name": "later grant", "wave": "0...10..."}
  ],
  "head": {"text": "三个 producer 同拍完成、只有两个 slot：第三个 owner 必须保持"}
}
```

不能只保存 result 而丢 ProducerId/flags；也不能让未获 grant 的 owner重复 pulse。
不同 producer 的保持位置不同：EX 结果住在 elastic stage，MulDiv/CLMUL 住在 RESP，
FP formal token 住在 done FIFO，memory 结果住在 response/terminal holder。全局仲裁器
只授予资格，不替每个来源保存被拒的 payload。

## 10.10 Memory bank 与共享 miss 反压

不同 bank hit 可以双 completion；不同 bank 同时 miss 会在 miss arbiter 排队；同一 bank
的两条 request 更早就在 IQ/MIQ 处串行。

学习时分三层画：

1. issue→MIQ bank admission；
2. MIQ→bridge station；
3. bridge hit response 或 raw AXI owner。

把三层压成一根 `mem_ready` 很容易漏掉 transaction 实际住在哪里。

## 10.11 Serialized control 的 C0/C1/C2

exactly-once 时序固定问三拍：

- C0：terminal 条件满足，raw action 只出现一次；
- C1：时钟沿后 holder/stop 清除，架构 side effect 已落地；
- C2：没有新 capture 时 raw action 不得重复。

如果只看最终 sticky `trap_valid/exit_valid`，无法区分 C0 是一次还是连续三次 pulse。

## 10.12 Flush priority

同拍可能有 enqueue、dequeue、completion、commit、branch kill 和 global flush。每个 owner
都应有单一 next-state priority。例如概念上：

```text
reset
> global/terminal flush
> branch younger kill
> accepted completion/commit
> enqueue/dequeue
> hold
```

不同 module 的具体优先级可以不同，但必须：

- 覆盖所有同拍组合；
- 避免一个寄存器在两个 always block 被写；
- old/new view 明确；
- assertion 与实现使用同一 phase。

## 10.13 组合长路径的常见来源

这颗 Core 可能出现的长链：

- IQ wakeup/select → PRF/bypass → ALU → completion arbitration；
- branch compare → redirect arbitration → frontend PC/ready；
- SQ forwarding compare → load data select → completion；
- D-cache hit → load extract → FP/int wakeup；
- ROB head/serialized drain → CSR/trap/flush → frontend run gate；
- AXI ready → bridge ready → MIQ/IQ ready 回传。

优化时不能直接“随便插一拍”。插拍会改变：

- ready/valid 协议；
- ProducerId holder census；
- branch recovery latency；
- load/store ordering；
- precise exception phase；
- completion slot 竞争。

必须先冻结接口契约，再用 testbench/回归/综合/STA共同验证。

## 10.14 当前能说和不能说的时序结论

能说：

- RTL 中哪些 owner 在时钟沿保存；
- 哪些 payload 遇反压必须保持；
- 哪些 transaction 需要 C0/C1/C2；
- 哪些路径存在组合依赖。

不能仅凭讲义说：

- 当前工作区一定达到 200MHz；
- 某条路径一定是 STA worst path；
- SRAM macro 的真实 setup/hold；
- flush/replay 所有交叉场景已动态覆盖；
- Linux 长跑不会出现晚到 owner 问题。

这些需要与当前 design-id 同源的 lint、testbench、DiffTest、综合和 STA 证据。

## 10.15 本章检查点

1. valid 等待 ready 时，为什么 payload 和 owner 都必须保持？
2. redirect 后为什么不能要求外部 AXI“撤回”旧读地址？
3. 同拍三个 completion、两个 slot 时第三个 producer 应住在哪里？
4. 插入一级寄存器为什么会影响 ProducerId holder census？
5. sticky terminal output 为什么不能证明 raw action exactly-once？
