# R4-S1.1 typed memory 叶模块 RTL 推导

> 范围仅限 `OooTypedPmaChecker`、旧 PMA compatibility leaf 与新的 typed classifier；本切片不接入 bridge、
> D-cache、SQ、backend 或 wrapper，也不改变单 memory owner 现状。

## 0. 接口契约冻结

- **握手**：两个模块都是无 `valid/ready` 的纯组合叶；`access_valid_i` 只资格化本拍输出，
  不持有事务。上游若要跨拍使用结果，必须在现有 final-PA owner 边界锁存。
- **stall/flush**：模块无状态，因此不产生 stall，也没有可被 flush/kill 的内部 owner。
- **异常序**：这里只形成 pre-target fault 事实，不宣告架构异常；后续 bridge/backend 仍须在
  精确 ROB owner 上提交。`fault_valid_o` 不能授权任何 target side effect。
- **访存序**：class 只描述类型，不放宽 store 的 ROB-head commit authorization，也不创建第二
  memory owner。CACHED/NC/IO ordering 差异由后续 consumer 实现。
- **恢复/单一真源**：PMA checker 是基础 region 类型真源；typed classifier 是 PBMT/PMA 唯一
  合并叶。Boolean compatibility output 只能由最终 typed output 派生。
- **跨模块时序**：本切片不把 typed 端口接入现有主干；因此不会把宽 region decode 接入
  request-ready、SRAM address 或 response-to-WB 组合回路。

## 1. 需求

1. `OooTypedPmaChecker` 对完整 byte range fail-closed，输出
   `attr_valid_o + class_o[1:0] + fault_o`；编码固定为
   CACHED=`00`、NC=`01`、IO=`10`、RSVD=`11`。
2. PMEM 必须优先于其重叠 PSRAM decode；PSRAM residual/SDRAM 为 NC；真实设备为 IO；
   default/stub/wrap/跨区为 DENY。
3. typed classifier 合并 PMA base class 与 leaf PBMT：`pbmt_valid_i` 表示 translated leaf 的
   PBMT 字段存在，和 `pbmte_i` 分离；Bare 为 0。
4. PBMTE=0 时任何非零 PBMT、PBMTE=1 时 PBMT=11 都形成 page fault；PMA deny 不能被
   PBMT 覆盖。基础 IO + PBMT-NC 必须得到 NC。
5. 所有 pre-target fault 或不一致 PMA 输入都输出 `attr_valid_o=0,class_o=RSVD`；fault 不得
   被编码成一个可路由 class。
6. 兼容 `cacheable_o/serialized_o/pbmt_fault_o` 仅从 typed 结果或 typed fault 派生。

非目标：不增加 token/epoch、request port、AGU、translation/data owner、cache admission 或
completion owner；不宣称 S2 双 memory owner。

旧 `OooPmaChecker` 在 S1.1 保持 P0 冻结字节与 SHA 不变；这是 live bridge 的 compatibility
边界。新的 typed PMA 独立登记、独立测试，S1.2 再把两个 bridge 实例原子迁移到 typed 真源；
在迁移前不把跨 PMEM/PSRAM 属性边界的新 deny 语义静默施加到 S0 live path。

## 2. 协议、状态机与不变量

### 2.1 协议

- 所有输出是当前输入的同拍纯组合函数；`access_valid_i=0` 时无 fault、无 attr，class poison。
- PMA `access_size_i=0` 防御性按 1 byte；first/last 必须由同一 region 完整覆盖。
- classifier fault 优先级为 PBMT/PTE page fault高于 PMA/access fault；二者均无 attr。

### 2.2 状态机

无状态寄存器、无 FSM、无复位状态。`clk/rst` 仅供 `OOO_ASSERT` 立即断言采样，不参与功能输出。

### 2.3 不变量

- I1：`attr_valid_o -> class_o inside {CACHED,NC,IO}`。
- I2：`!attr_valid_o -> class_o==RSVD`。
- I3：`fault_valid_o -> !attr_valid_o`，且 `page_fault_o -> fault_valid_o`。
- I4：PMA request 只有完整覆盖一个真实 region 才 `attr_valid_o=1`；否则 `fault_o=1`。
- I5：`cacheable_o == attr_valid_o && class_o==CACHED`；
  `serialized_o == attr_valid_o && class_o!=CACHED`。
- I6：PMA fault/attr 不一致、PMA RSVD 输入均 fail-closed 为 access fault；不得产生 attr。
- I7：PBMT reserved 即使与 PMA deny 同现也报告 page fault，class 仍为 RSVD。

## 3. 数据通路与 RTL 拓扑

1. **边界**：PMA 输入 PA/size/read/write，输出 base attr/class/fault；classifier 输入 PMA typed
   结果和 PBMT/PBMTE，输出 final typed result、fault 与 Boolean views。全部单时钟域组合返回。
2. **状态寄存器**：无。
3. **组合块**：PMA 并行完整覆盖比较器；priority class encoder；classifier PBMT legality、
   PMA legality、override mux、fault/attr qualification。
4. **FSM**：无。
5. **pipeline/ready-valid**：无；后续由 final-PA capture 寄存边界承接。
6. **控制优先级**：inactive > PBMT page fault > PMA/access deny > legal override/inherit。
7. **资源复制/共享**：region 每项为独立并行比较；单个 class priority encoder；classifier 为
   一个 2-bit override mux，不共享时序资源。
8. **可能关键路径**：`paddr/size -> last-address add -> region compares -> class encoder`；本切片
   不接入现有 ready/valid 回路。classifier 路径仅窄 PBMT decode + 2-bit mux。
9. **function 划分**：只保留小型纯组合 `region_full_cover` helper；无仲裁、握手、状态或 FSM
   放入 function。
