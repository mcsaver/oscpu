# 500 MHz 架构实验：2026-10-12 修正版

本轮按用户纠正后的范围执行：**55 nm、TT／25°C、默认 1.2 V、core 500 MHz／2 ns 的本地架构实验**。当前综合默认已使用该 TT 配置；调整的是分析与验收口径，无须降低配置。SS、多角、P&R、功耗签核不作为本轮实验要求。

功能与架构要求继续保持：双发射 OoO、ISA/特权行为、精确异常、恢复、访存顺序、双 memory datapath、真实事务终端及原有 checker/workload 不放宽。本文只交付候选设计，不修改生产 RTL 或现状拓扑，不声明已实现频率/CPI/PPA 收益。

实际工作区为 `/home/lyg/PA/ysyx-workbench`，分支 `ai`；证据属于 2026-10-12 ECOS ICache 集成工作区，包含未提交变化。Architect 只读取架构资料与独立取证摘要，没有读取 RTL、原始库、综合网表或实现日志。

## 1. 当前推荐与前版修正

**撤回“必须将 ICache 降为 250 MHz 宏域”的主推荐。** 该结论此前由 SS 宏时序驱动，不适用于用户选定的 TT 实验。本轮先核对 TT 下现有宏的 2 ns 连续访问与真实读返回路径；只有实际 TT 预算不成立时，才选择增加返回流水、调整访问节拍或换宏。minimum period 小于 2 ns 只是必要条件，不能代替 clock→Q、way 选择、接收 setup/uncertainty 和实际负载的检查。

同时，**DCache 当前没有映射成真实 SRAM**。现有 cache 功能与事务合同需按用户的商业架构要求保持，其数据阵列宏化尚未落地。下一步必须把真实宏接口纳入架构判断，不能把当前标准单元读 mux 的面积与时序当作最终 SRAM DCache 的 PPA，也不应围绕这一过渡实现无限增加读流水。

已确认的保护→LSU→物理服务空直通长链仍值得切断。首个可复用的有界逻辑实验是：普通 cached CPU read 先经过既有 service request Q，再参加 DCache admission；它与后续数据阵列宏化可以衔接。是否继续增加保护结果寄存或 cache 内部边界，由 TT 实验和真实宏接口决定。

## 2. 当前证据与真实存储结构

### 2.1 TT 时序

| 当前事实 | 数值或机制 | 本轮解释 |
| --- | --- | --- |
| 目标约束 | 500 MHz／2 ns | 尚无这一目标下的新整核综合或 STA，不能声明已经达到 |
| 既有固定 ECOS 网表，TT 1.2 V／25°C | 200 MHz setup WNS −0.147 ns；180 MHz +0.408 ns；setup 交点约 194 MHz | 理想时钟、布局前的现有结果，不是 500 MHz 新综合预测 |
| TT 最差路径 | PMP config → 保护结果 → LSU 资格/描述符 → Split → Service 空读 → DCache tag 读结果 | PMP 状态控制当前访存，并非 CSR 指令本身读取 DCache |
| TT data arrival | 5.0606 ns；加旧 setup/uncertainty 后约 5.1473 ns | 中间经过带队列模块，但 worst path 走空状态直通，没有强制寄存边界 |
| 相邻路径 | TT top10 都到 DCache tag 读 Q，约 5.055–5.061 ns | 是同一路径族，不能代表修改后全核所有瓶颈 |
| ICG 异常 | 最小 ICG 直接驱动 1590 个 DFF 时钟脚、负载超表约 25 倍 | 独立的未 CTS 实现问题；其异常脉宽不能作为 CPU 天然频率上限 |

TT 原路径分段 arrival 差为：CSR clock→Q 0.1191 ns、共享 PMP decode 0.6573 ns、PMP 范围/优先级 0.7764 ns、LSU 资格/age/描述符选择 1.2096 ns、Split/对齐 0.5274 ns、Service 空读/payload 0.4633 ns、DCache 候选/index/阵列选择 1.3075 ns。它们是**原路径边界差**，不是切级后独立 stage 的最大延迟；新寄存器与新映射都会改变预算。

因此 TT 下“最终保护结果 Q + Service request Q”的分段值得实验，但不能把原段简单相加后宣布 2 ns 闭合。尤其 DCache 最终采用 SRAM 后，clock→Q、写口和 pending-write 覆盖会改变后半段结构。

来源：[独立关键路径摘要](../../build/arch-500mhz-round1-evidence/timing/evidence.md)。前版 SS 数字仅作为历史背景：SS 1.08 V／125°C 的 setup 等效周期约 9.336 ns，宏 minimum period 约 3.47–3.66 ns、clock→Q 2.7020–3.3032 ns；**它们不驱动本轮 TT 候选选择或实验门槛**。

### 2.2 ICache 已宏化，DCache 尚未宏化

| 对象 | 当前已核实结构 | 不能据此推断的事项 |
| --- | --- | --- |
| ICache data | 8 KiB、2-way；显式接入两个真实 ECOS 256×128 宏，各属于一个 way；同时读同一 16 B sector 后选择 128 bit | 两颗是 ways，不是可以直接交替读的两个 banks |
| ICache tag/valid/LRU | 宏外状态 | data 已宏化不意味着所有 cache 状态都已宏化 |
| DCache data | 8 KiB、2-way、64 sets、64 B line；PA[3] 选 bank。四个 bank-way 各 256×64，逻辑上每个有同步 read 与独立 byte-enable write；当前综合前端已把四个数组转为寄存器 | 旧 README 的“四个 1R1W inferred memory”是旧证据，不是当前真实 SRAM 映射 |
| DCache tag | 每 way 64×52，逻辑 2R1W；当前经 memory_map 成 DFF/mux | data 和 tag 都没有全数组 reset，不能把未宏化归咎于全量 reset |
| 其它阵列 | 本轮尚无其真实 SRAM 映射证据 | 不能因为 RTL 声明数组，就把面积与访问时序按 SRAM 估算 |

“RTL 存储数组”“综合工具识别的 memory”“真实 SRAM 宏实例”是不同层次。真实宏化需要匹配的容量、端口、读延迟和写粒度，以及实际宏实例/映射、功能模型和 timing library。当前流程没有 SRAM memory_libmap/techmap，加载 SRAM library 只提供已实例化宏的 link、面积和 STA 信息；不会自动把任意数组换成宏。最终网表只有两个 ECOS SRAM，均属于 ICache。

现有 ECOS 256×128 型号是单个共址 1RW 端口、128-bit 整字写、无 byte mask；它不直接满足 DCache data 的 1R1W byte write，也不满足 tag 的 2R1W。同 bank 的两 way 同读，不同 bank 双 load 可每拍接受；每 bank 还有一项 pending write，真实成功 B/refill beat 产生逻辑写，下一拍落阵列，同地址按 byte 转发，数组写可与新 lookup 并存。这些真实功能差异解释了为何 ICache 的宏接入不能自动推广到 DCache。

DCache 当前事实由独立角色核对 `ecos-sram-20261012/sta/R64CoreTop-1000MHz/yosys.log:583–586` 与 `R64Dcache.v:430–437` 后摘要提供；映射流程来源还包括 `yosys.tcl:363–400,420–435`，端口来源包括 `R64Dcache.v:417–437,534–541` 及 `third_party/ics55_ecos_sram/README.md:8–19`。这些指针只作追溯，Architect 未打开实现材料。架构背景见 [LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md)。

### 2.3 ICache 周期与已有验证

当前宏 CLK 接 CPU clock；lookup-ready 或 refill-write 驱动访问，idle 也可能连续读。无延迟功能模型中 e0 接受/发起，e1 最早返回 hit，hot II=1。已有六个 ICache 配置、Frontend 域及十个 system DiffTest case 通过；七个热窗口各 768 instructions／384 cycles。来源：[ECOS 验证摘要](../../build/ecos-sram-20261012/validation/summary.json)。

这些是已有功能证据，不能代替 TT 真实 clock→Q 和 2 ns 返回时序。独立取证已确认标准单元 H7CL TT 1.2 V／25°C 与 SRAM tt1p2v25cctyp 匹配；生产使用 MARE=0。库表内时序如下：

| TT 宏项目 | 已核实范围 |
| --- | ---: |
| read clock→Q | 1.2311–1.5454 ns |
| write-through clock→Q | 1.2104–1.5257 ns |
| read minimum period | 1.5917–1.6980 ns |
| write minimum period | 1.5714–1.6962 ns |
| minimum high / low pulse | 0.1992–0.2041 / 0.4541–0.5644 ns |

上述 clock→Q 表的 slew 轴为 0.008/0.05/0.1/0.2/0.4 ns，Q load 为 0.005/0.02/0.05/0.1/0.3 pF。表内本征 period 允许继续做 2 ns 实验；名义 50% duty 的 1 ns high/low 也覆盖表内最小脉宽。**真实返回路径仍未测得 PASS**：按最大 read clock→Q，2 ns 剩 0.4546 ns，扣除原 50 ps uncertainty 后只剩 0.4046 ns，尚需容纳 FF setup、后级 logic/wire；实际 slew/load 仍需在同次 TT STA 中核对。

来源指针：标准单元选择 `yosys-sta/scripts/pdk/icsprout55.tcl:1`；宏库 `third_party/ics55_ecos_sram/ics55_ecos_sram_256x128_m4_ww/lib/ics55_ecos_sram_256x128_m4_ww_tt1p2v25cctyp.lib` 的 54（查表轴）、157（读弧）、220（write-through）、796（period/pulse）行，由独立取证核实。Architect 未读取原库。

ECOS 配置的完整 CoreMark/Dhrystone CPI 尚无同源基线，旧第二十批性能不能直接拼作新 A/B。

## 3. 有界实施路线

### 3.1 ICache：先保留 TT 单周期候选

保留 8 KiB、2-way、16 B packet、原单 refill 与现有取指协议。e0 发起、e1 最早消费是否成立，必须同时核对：

- TT 宏的真实最小周期、high/low pulse 及其 CEB 条件；
- 宏 clock→Q + 输出连线/负载 + way/响应选择 + 接收 setup/uncertainty 是否放得进 2 ns；
- 原始两 way data 与 tag/保护事实/顺序 owner 是否属于同一请求；
- 连续 lookup、idle 连续读、READ↔WRITE 和 refill 写入是否都符合上述条件。

若访问周期满足但返回组合链超限，优先比较**延迟返回、保持 II=1 的流水接收**；是否能实现仍取决于新捕获边沿、宏输出有效窗口与实际 timing，不能只加一个输出寄存器就宣称可行。只有 TT 的真实访问周期或相位/返回预算确实需要时，才考虑 4 ns 访问作为备选。

若启用 4 ns 备选，必须同时修改 launch cadence、result valid、owner 与 refill 调度；相关时钟按真实相位分析，不用虚假的 false/multicycle 例外。16 B／两个 core 周期在全 32-bit、无浪费直线流中恰好供两条指令/拍，没有额外带宽余量。宏周期变长的 CPI 代价须由完整程序计数判断。

### 3.2 DCache：先按真实端口合同完成宏适配选择

本轮下一步是按已核实的 data 1R1W／byte write、tag 2R1W 合同选择匹配宏或有界适配方案。原则是保留原 8 KiB、2-way、bank 组织和双 memory datapath 的功能合同，不把不同 bank 的双 load 悄悄退化为单通路。

不能用整字写覆盖未更新字节，也不能把现有 1RW 宏直接声明为原 1R1W。优先寻找匹配的宏接口；若采用现有宏，则先在一个 bank 范围论证冲突仲裁、RMW/写合并及 pending-byte forwarding 的 owner 和周期合同，测清读写冲突的代价，不默认把整个 DCache 串行化。保持真实成功 B 后的可见性、refill/invalidate、失败写、atomic 与原双 bank 吞吐要求；完成这一步后再决定最终读边界。匹配的其它宏型号和实际适配收益仍是 UNKNOWN，本轮不承诺未经实现的宏数量、面积或频率。

### 3.3 保护与请求链：可复用的 Service Q 切片

先让普通 cached CPU read 完整登记到 service request Q，再参与 DCache bank/index/读请求选择。capture 内容包括 PA、size、mask、操作属性、data（适用时）与 opaque token；宽 payload 和 owner 必须一起推进，不能只延迟 valid 或数据的一半。

保留双 lane、原仲裁顺序、本地 Q 信用、ready/valid 背压和唯一 owner。接收到服务 Q 不表示完成，更不等于 AXI 已发出。prepared store 的数据镜像不能因此变成有副作用的 owner；head/effect 许可、真实 B 终端、错误返回与精确 trap 继续保持。已取消的 accepted 请求仍排空，LSQ slot/tag 不能提前复用。

若该切片后保护/LSU 路径仍主导 TT，再试最终保护结果寄存；保存同次采样的 token、PA、权限/fault/cause/tval，避免驻留事务被后续 PMP 更新重新解释。PMP 单独预解码只覆盖原 TT 路径约 13%，而普通 PMP 写没有现成全访存 drain 保证，不作为本轮主方案。

## 4. 无论采用何种存储时序都保持的合同

- Stream 总预约信用仍为四份：`request-holder + accepted-owner + packet ≤ 4`。新增 source/raw/返回槽只是同一 owner 的阶段容器。live 响应变成 packet 不释放总信用；stale 只在真实响应握手后释放。
- data、tag/valid 快照、保护 mask、错误与顺序 owner 一起保持；背压不能改变已呈现 packet，fault/uncached 不得越过更老事务。
- redirect 由 Stream 标记 stale，ICache 不删除已接受命令、raw 或 refill；FENCE.I/DMA invalidate 的 poison 覆盖所有新增保持阶段，晚 fill 不能恢复旧 tag valid。
- cached refill 的八个真实 64-bit R beat 形成四个 128-bit sector；RREADY 受真实暂存/未写容量约束。若宏写延后，最后 R beat 不等于最后物理写完成。
- 正常成功 refill 等实际写全部完成且无 error/poison，才安装 tag valid 并成功返回。error/poison 仍产生一次原语义终端，只排空实际 AXI/写入或作废欠账，不能等待被取消或不存在的“四次成功写”。
- DCache 保留逐字节转发、写入冲突、失败 B 不更新有效数据、load/store 年龄约束、split、AMO/LRSC 和不可取消外部事务排空。修改周期不能绕过这些条件。

## 5. 本轮最小验证与结果口径

1. **先做匹配接口的有界实验**：ICache 的 TT 返回预算、DCache 的实际宏接口适配、Service Q 断链各自使用直接相关 directed/断言检查；不为了本轮构造完整多角候选矩阵。
2. **取得同配置 TT／25°C／1.2 V 的新综合与布局前 STA**：目标 2 ns，观察路径是否断开、瓶颈是否迁移，确认实际 SRAM 实例/面积计入。setup、hold、pulse 如有失败照实报告；不把已知 ICG 过载混作数据路径根因，也不把 focused setup 改善写成物理签核。
3. **联合修改后验证功能与程序代价**：执行受影响的原有功能检查及所需完整核/DiffTest 范围，保持原 oracle；用同一 ECOS 配置、同一完整 CoreMark/Dhrystone 输入与计数区间比较 cycles/retired/CPI。附与改动直接相关的等待原因即可。
4. **结论限定为本轮 TT 实验**：相同 workload/config/tool/constraints 下比较 correctness、周期与 TT timing。未运行的 SS、P&R、activity power 不成为本轮额外门槛，也不被宣称已通过。

本轮交付是修正后的设计方向和可执行合同。生产拓扑在实际实现与验证后更新；当前没有新的 500 MHz PASS 或 PPA promotion 结论。
