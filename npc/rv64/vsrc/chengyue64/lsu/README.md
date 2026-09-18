# 原生 Load/Store 子系统

本目录属于 RV64 RTL 重建路径，未例化旧 Ooo LSU/cache。集成入口为
`R64LoadStore`，CPU 指令接口对接 `R64Backend` 的 MEM admission 与两路
`R64_RESULT_W=140` 完成接口。独立模块默认 18 项 LSQ；当前核心经
R64Memory 实例化 20 项，并启用 HEAD_AUTHORIZED_QUERY=1、PREPARED_CANCEL=1。
当前模块实例、旁路、队列深度与控制连接见 [LSU拓扑网络](TOPOLOGY.md)。
下面的历史测量保留各自的配置与范围。子系统具有
两个翻译通道、双 lane 物理 descriptor 队列、带源占用保护的转发查询队列、每lane两槽的转发结果队列与一个可旁路物理holder、响应元数据队列、2×2 深独立完成 FIFO，以及 8 KiB/2-way/64 B
物理读缓存。

`R64LoadStore` 只是连接本目录原生实现的结构入口，外部仍提供两个真实
`R64Translation` 和每通道 response owner 对应的 PMP/PMA 检查。未把翻译 oracle
测试当作整核验证。

## 拓扑方案的联合迭代与整核评估（2026-09-07）

本轮在上一轮CPU/PTE配对、未知IO屏障的基线上实现：

- 普通load descriptor只保存93bit有效字段，去掉64bit store data；prepared特殊请求仍保留157bit。
- query出队时读取已寄存winner并捕获forward_q/mask；每lane一个physical_hold保存未被物理接口接受的
  完整descriptor/tag，空时旁路。先捕获后等待可释放store源引用；mem_issued仍仅由真实物理握手置位。
- full-forward结果改为每lane两槽，和物理holder提供独立出口容量，缓解两类出口的相互阻塞；
  某类出口填满后仍可能传回query HOL，没有任意槽重排。
- 六来源完成仲裁在实际capture后轮转，避免持续raw流始终压后fault/forward。
- 已登记dead、身份匹配、已发出的普通对齐RAM load可以不占raw队列地接收并丢弃返回。
  写、原子、IO、非对齐、辅助请求没有借用这个排空路径，owner仍保持到响应握手。
- Dcache保留一个慢owner；普通cached读的READ/REFILL期间允许另一bank且不同set的cached普通读前进。
  第二miss在原bank stage等待；写/原子、同set、同bank、invalidate/poison保持排他条件。

新定向入口为 lsu-network-matrix 和 tb_r64_dcache_overlap；pin矩阵增加压力以继续验证尚未捕获的
winner引用。旧late-IO容量fixture已更新为当前未知属性发布规则，并用修复前RTL验证能够拒绝年轻发布。
新增r64_core_lsu_contention.S通过真实三级4KiB页表、A/D更新、双数据流与store测试CPU/PTE共享服务。

同源基线/候选的完整软件、CoreMark、CPI、整核综合及1ns STA结果统一见
[综合评估](../../../../../tmp/rv64-lsu-network-complete-20260907/REPORT.md)。
下面的分轮数据保留其原始配置与测量时间，不代表最新联合候选的结果。

## CPU/PTE bank 配对与未知属性发布边界（2026-09-07）

当前 Service 在选中辅助读后，允许用 CPU lane1 的普通 cached load 替代同 bank 的
CPU lane0 cached load，与辅助读组成异 bank 配对；CPU0缺席时也可使用CPU1。
CPU0为store/atomic/NC请求，或辅助操作为CAS/写时不借此越过。调整只发生在入队捕获前，
已保持的cache请求不换owner，CPU1的token与完整payload一起送入Service lane1。
round-robin辅助选择、各辅助busy/返回保持与原队列深度不变。

实际PtePort×3、Service、8KiB Dcache测试中，同一24组/72次混合读的ROI累计
144→120拍，同bank配对冲突24→0；PTE请求到返回累计120拍不变。
无辅助竞争的异bank热流保持200拍连续双接收与3拍Service返回延迟。
这组PTE请求使用真实保护端口；并未运行完整Sv39 walker或整核CPI基准。

普通load在bind后、NEW/TRANSLATING期间继续阻挡年轻query发布，直到收到成功的RAM
属性响应；同拍成功RAM响应可立即解除该屏障，保留双普通load翻译直入。
延迟IO与同拍IO响应两种反例已由定向测试关闭；未知期间可继续准备，但不能发布年轻query。

同约束局部STA中，Service setup slack由−0.370313变为−0.357756ns，单元面积增加8.151%；
LSU修复后setup由−0.862424变为−0.900504ns。两者均仍未达到1GHz，不能把定向周期收益
当作整核时序闭合。实现、逐端点组结果和复验见
[本轮报告](../../../../../tmp/rv64-lsu-service-pair-20260907/REPORT.md)。

## 数据与责任边界

- Backend 每拍发出 0/1/2 个 dense MEM admission fire；ready 来自已寄存的空项。
  每项只保留 tag、VA、PA、store data/mask、function/AMO、属性和状态。
  不复制 PC、完整 uop、RESULT/TVAL 阵列。异常 tval 从已有 VA 重建；非对齐物理错误另带 3-bit 失败片段偏移。
- 两个 Translation 分别有 4 深顺序 owner FIFO。响应即使已经被 kill，也必须消费；
  没有已接受翻译的 dead entry 可以释放，已接受的必须排空。输出
  `tr_owner_access_o` 是每 lane `{execute,write,read}`，`tr_owner_size_o` 是字节数；
  它们与该 lane 的当前翻译 response owner 对齐。SC 只请求写权限，LR 只读，其余 AMO
  请求读和写。
- FS=Off 在 admission 时以非法指令拒绝 FP load/store，优先于地址未对齐，不产生翻译/物理事务。
  输入 `fp_enable_i` 来自 mstatus.FS!=0；非法 tval 默认0，root可从ROB META恢复原始16/32-bit编码。
- Store 可提前计算地址、数据并以 `ad_update=0` 探测权限和 PA；需要 A/D 更新时，
  到 ROB head 获得 `effect_allow_i` 后重翻译。普通 load 可以更新 A。
- 物理地址已知的 older store 按字节向 load 转发，重叠字节选最年轻的 older store。
  未知 PA 或仍需 A/D 重走的 older store、AMO、IO 和非对齐 owner 构成顺序屏障；MMIO/AMO/store 只在 head 授权。
  完全转发的 load 不访问物理服务，部分转发在物理 response 时合并。
- 成功的普通对齐 load 翻译，在没有 older ordering owner 和 older barrier、无需 A/D
  重走且属性非 IO 时，可以直接进入有 Q credit 的 forward query。年轻 ordering owner
  不影响该资格；当前 owner 必须同时满足 !store_w 与 !atomic_w，LR 仍走 head 特殊路径。
  已存在的 descriptor 与 lane0 prepared offer 优先。已知 PA 的 older store 即使不再是
  barrier，也必须经过原转发流程，不能用仅检查 older_barrier 的条件代替。
- 普通 load 的物理响应被元数据队列接收时立即释放 LSQ 项；元数据队列与完成 FIFO 保留完整 ROB tag。
  每个输出 lane 的 stalled head 固定在该 lane，kill 只移除相应 tag。
  因此 LSQ 生命周期不再延长到 canonical WB 接受。
- 已授权写/AMO/IO 完成成功后保留 RETIRE owner，直到 `commit_fire/tag` 精确匹配。
  B 错误等异常完成已排空后允许同步 trap 清除；未知结果或成功可见未提交期间，
  root 必须延迟异步 trap。授权后的 head 在 IRQ drain 中必须仍可继续执行。
- `reuse_block_o` 包括 LSU 在飞 owner 和未发送的完成 FIFO tag，阻止有限 ROB generation
  复用产生 ABA。Tensor 自己的 ROB owner 仍由 root 额外 OR 到 backend reuse mask。
- `idle_o` 同时要求 LSU、完成 FIFO、片段 owner、共享服务和 cache 为空，供 FENCE/序列化控制使用。

共享服务通用默认AUX=4；当前CPU核心使用AUX=3，分别供I walker和两个D walker使用，当前入口不含Tensor。
辅助端口每客户端最多 1 个事务，并独立保存返回结果。物理请求 op 为
READ=0、WRITE=1、compare-and-OR=2；CPU AMO=3，`amo` 保持指令 funct5，其中 2/3 为 LR/SC。
辅助方必须在提交请求前完成正确有效权限的 PMP/PMA 检查；页表访问有效权限为 S。
拒绝的辅助请求必须由 root 形成对应 owner 的错误响应，不能丢失事务。

## 2026-09-07：按 owner 年龄决定翻译直入

R64Lsu 对每个 owner 共享归约 older_q & ordering_w，两条翻译响应 lane 使用同一组结果，
随后在原 one-hot 响应事件上检查资格。本次没有增加寄存状态、改变握手或修改 query pin。
独立回归入口为：

~~~sh
make -C npc/rv64/testbench/chengyue64 TESTS=tb_r64_lsu_owner_bypass run
~~~

新 TB 默认采用 20 项、两个生产开关为1、EARLY_STORE=1；已纳入默认 TESTS。
相同刺激的原版/修改版 RTL A/B 中，老 load 遇到年轻 store 时，翻译响应到物理接受
由4拍变为1拍；没有年轻 store 时仍是1拍。older store 完整/部分转发、当前 LR/AMO/IO、
未绑定 older owner、已解析 IO、A/D、双响应、kill 和满 query 回退通过。
CORE_MODE=0 的20项及 CORE_MODE=1 的18项也通过。它使用受控翻译与物理模型，
实际系统另跑了 R64SystemTop + NEMU 的 program/sv39/sdtrig 普通及 stalls 共6项。

同20项配置的局部 LSU、icsprout55 TT、1ns pre-layout STA：
全局 setup slack 从 -0.891821ns 改善到 -0.804082ns，仍未闭合；
query payload/control 分组分别回退约11.8ps/12.5ps，因此不能宣称每条路径都改善。
详见工作区 tmp/rv64-lsu-owner-bypass-20260907/REPORT.md 的面积、约束和原始日志。

该早期实验曾发现问题：ordinary older load 已 bind 但 IO 属性未返回时，原 barrier 可能暂时消失。
这一窗口已由上方“CPU/PTE bank 配对与未知属性发布边界”中的后续修复关闭。
本次原版与修改版均复现；这里的“未绑定屏障”和“已解析 IO 屏障”通过，不能替代对该窗口的验证。
本次保留原 barrier 语义，未据局部通过宣称完整 IO 顺序或全局 CPI 已闭合。

## Descriptor 输入与有效发布分离

2026-09-07 的局部重构将 descriptor data/tag/age 输入从最终 take/kill/credit 门控中拆出。
已寄存的 mslot 只做一次 one-hot 解码，复用 R64LsuMetaRead 平衡读取元数据和年龄行；
tag 直接来自 mtag Q。descriptor_s_take / descriptor_queue_fire 及队列 valid、credit、
kill/flush、source_birth 年龄清除保持原样。空槽预写内容可以变化，仅发布的有效事务拥有语义。

tb_r64_lsu_descriptor_payload 用旧门控生产者驱动影子队列，逐拍比较有效 tag/data/age
和全部队列控制，覆盖双lane、full/hold、同拍出入、kill有credit、flush和代际复用。
该测试已加入默认TESTS；前两轮旁路与精确pin的定向回归继续通过。

20项生产参数、icsprout55 TT、1ns的局部STA：descriptor data/tag端点从-0.331932ns
改善为+0.249544ns，映射面积下降2.068%；age端点回退108.629ps，全局setup从
-0.856255ns变为-0.862424ns，回退6.169ps，hold仍为-0.036661ns。
这是局部数据路径/面积收益与其他路径回退的取舍，未达到1GHz闭合，也未证明整核CPI改善。
详细实现比较与日志在 tmp/rv64-lsu-descriptor-payload-20260907/REPORT.md。

## 预准备 store 与窄终端完成

普通自然对齐 RAM store 可以在成为 ROB head 前，把已完成 PA/权限检查且无需 A/D 更新的
最老候选索引与完整 tag 保存到可取消寄存器。它仍属于原 LSQ READY 项，未占用外部 owner，也不
发出请求；只有 tag 与当前 head 完整匹配且 `effect_allow_i` 有效，才选择到空闲物理
lane0。原有两个 load holder 保持独立，kill/flush 移除候选，LSQ/ROB 代际保护继续有效。
该候选不新增一套 store data 队列，不改变 Q-only `issue_credit_o` 与 Backend 预留契约。

经过合法物理 admission 的普通对齐 RAM store 携带一个 fast-terminal 位，Service 保留
该位，辅助请求强制0；MemorySplit 的所有片段也强制0。Dcache 在真实 B 握手时更新驻留
cache、释放物理 owner，并把 token/error 送入 LSU 单项终端寄存器，不再重复经过
DELIVER、cache response、宽完成 FIFO。MMIO、AMO/LRSC、非对齐片段、辅助事务走原返回路径。

顶层窄完成端口为 `store_done_valid_o/ready_i/tag_o/error_o/tval_o`，tag 含完整 ROB 代际。
它在真实 B 后才有效，保持直到接收；其输入 credit 只由终端Q是否为空决定，因为单head
副作用约束下无需同拍consume/replace，不形成ROB ready到AXI B的组合路径；普通 store 无 rd/fflags，错误 cause 固定7，tval 为原始
VA。Backend/ROB 的专用 head 完成入口由其 owner 负责接入，仍须核验有效 tag、普通 store
身份和未完成状态，只有该真实结果可令指令完成。成功 store 的 LSQ RETIRE/effect owner
保持到真正 commit；错误在外部完整排空后允许同步 trap 清除。未接收的窄完成 tag 也加入
reuse mask。仿真断言拒绝取消仍有不可撤销外部事务或成功可见但尚未退休的 store。

`EARLY_STORE=1` 为生产默认；0 仅用于同 TB 的结构 A/B 和保留独立宽完成协议 fixture。
下面为加入物理 descriptor 寄存边界之前，同一个 coupled TB 的16条预准备 store ROI；历史结果不代表当前所有流水级的延迟：

| 配置 | head 到完成接收累计 | 每 store |
| --- | ---: | ---: |
| EARLY_STORE=0 | 144 cycles | 9 |
| EARLY_STORE=1 | 96 cycles | 6 |

此直接 ROI 测得3拍：预选省1，B后的 DELIVER/cache response/宽 FIFO 路径改为终端Q省2。
整核另预测省掉通用 WB 的1拍，必须由真实 Backend/ROB 集成仿真核验。两配置512条 hot load
仍均为266拍。该 TB 的定向前导病例在配置1额外覆盖prepared kill、同slot新代际、B长时间
hold、窄完成背压、B错误待接收时flush，故两次总完成数不相同，A/B只比较明确ROI。

新增状态主要为候选valid/index/tag、终端valid/tag/error/tval与少量事务标志。潜在2ns风险是
head比较→物理slot选择→LSQ payload mux，以及B token→tag/tval读取→终端Q；本次保留真实
寄存边界，尚须同源 mapped STA 判断，不由周期仿真宣称时序已经达标。

## 年龄选择与转发流水

所有空项、翻译、普通 load、head 特殊操作、异常和预准备选择通过
`R64LsuSelect` 的有界平衡树完成。普通 load 的两个结果来自同一 top-2 树；
特殊操作只占 lane0，lane1 仍可取独立 load。barrier 也使用平衡最小年龄归约，
不再把两次18项优先选择和逐字节转发串接到同一个完成寄存器。

转发查询只读取已选中的 `mslot_q`，不会读取新选择结果，也不会经过 prepared
store 的物理出口选择。每个已知 PA store 的匹配结果由8个字节共享；每个字节的
youngest 选择携带年龄和 byte data 经过 `R64LsuYoungestByte` 平衡树，避免选出
index 后再接宽数据 mux。

完整转发由两个独立 terminal holder 接收 canonical tag 与 RESULT，接收时释放
原 LSQ 项。terminal 保持到 CQ 接收，允许同拍消费并补入，因此稳态仍支持双完整
转发；kill、reuse mask 和 idle 包括该层 owner。它将 PA match/byte select 与
CQ 的六源选择和 front/skid 路径分开。部分转发数据在真实物理握手时保存，物理返回
再合并。独立 cache hit 不增加寄存边界；完整转发相对最初单拍选取路径增加两拍，
相对仅把查询移到 mholder 的中间候选增加一拍。

较老 store 成功 B 后更新 coherent cache；尚未捕获的转发 probe 在 source 退休后
可转为真实物理读取。已被 terminal 接收的 tag/data 则由该 terminal 负责保持，
不再依赖 source LSQ 项。测试覆盖 CQ 满、另一物理响应被阻塞、source store
在 B 成功后退休的交叉情况。

prepared store 已给出 valid 时即占用 lane0 的真实 holder credit，直到接受或明确
kill；年轻 load 选择与翻译直入都检查同一个 credit，不能替换一个未握手的 offer。
`tb_r64_lsu` 以 `EARLY_STORE=1 +prepared-hold` 单独验证这一点；RTL 另逐lane断言
整个物理 payload/tag 在 ready=0 时保持。

首个平衡候选的局部 flatten 映射包含 LSU、选择 helper 与完成 FIFO。同2ns目标、
icsprout55 TT库，ABC 延迟3.899ns；局部STA仍有4.372ns arrival/−2.423ns slack，
最差路径从 kill 经 prepared PA 选择和 forwarding 到 CQ。该测量只用于定位下一
处分段，不能视为2ns达标，也不是最新转发 terminal 版本的PPA。原始证据在
`tmp/rv64-lsu-balanced/`；最终 mapped setup/hold 与完整核心回归由实际同源运行裁决。

## 普通 RAM 非对齐访问

`R64MemorySplit` 在 LSU 和共享服务之间提供单个共享慢路径。自然对齐的双 lane 请求与
响应直接旁路，不增加流水寄存器。非对齐请求先等待已接受的 CPU 物理事务排空，再保存
一个原始 token、地址、旋转后的 store data、3-bit 片段计数和 load gather，逐字节发出
合法的 size=0 AXI 访问。cacheable 与 NC RAM 都支持跨 8 B、64 B，bare 地址也支持跨
4 KiB；IO 与 LR/SC/AMO 保持非对齐异常。

输入 `translate_active_i` 在 admission 时使用：当前 Sv39 且有效数据权限非 M 时为1。
有效权限由 root 依照 MPRV/MPP 计算。此时普通非对齐跨 4 KiB 在翻译前拒绝；同页只需
一个翻译，完整原始 access/size 仍由 root 对原始 PA 范围做 PMP/PMA 检查，不缩成单字节
规避保护。IO 判定在翻译/属性响应后完成，不发出物理访问。

非对齐请求在 ROB head 授权，阻挡年轻内存请求；对齐 fast path 和翻译直入路径都遵守
该屏障。非对齐 store 不参与原有单 word forward，直到真实 commit 后年轻 load 才读取，
防止跨 word 数据被截断转发。原始 store data 用旋转保存跨 word 尾部字节。load gather
在最后片段后一次性完成符号扩展或 FP NaN boxing。

一个原始物理 owner 始终保持到最终聚合响应；kill 后逐字节排空已接受的普通 load，
不写回且不提前释放 ROB reuse。成功 store 继续保持 RETIRE/irrevocable 到 commit。
遇到 B/read 错误停止后续片段，返回原始 VA 加失败字节 offset；较早成功 store 字节已经
可见，不能回滚，错误指令完整排空后可同步 trap。规范允许此类非对齐 store 的部分可见，
且非零 tval 指向失败部分，见
[RISC-V Machine 规范](https://docs.riscv.org/reference/isa/priv/machine.html)。

字节片段经相同物理 cache/service，保留 CPU/PTE/Tensor 一致性与 LR/SC 失效语义，
辅助事务可以在片段间执行。非对齐访问不承诺原子性，也不宣称每拍双宽；该保守慢路径
以固定少量状态换取对齐热点的面积和周期边界不变，未来可用对齐的最大合法片段替代，
但必须保留完整保护、错误 offset 和 owner 生命周期。

## 缓存与外部错误语义

缓存按 PA bit 3 选择两个数据银行，每银行每 way 单同步读口、单 byte-enable 写口。
每条线 8 个 64-bit beat，两个 bank 各保存交错的 4 个 word。命中可每拍接受两个异 bank
load；同 bank 冲突保留未接受的 producer。标签每 way 为双读单写。同 line 的双 bank 冷 miss 在首个 owner 完成时刷新未完成 lookup，共享该 fill，防止同 tag 双 way 重复驻留。当前只有一个 read/refill owner；普通 cached store 在等待 B 时另有独立 owner，保留其 bank stage 以及 way/hit/data/poison。只允许另一个 bank、不同 set 的 cached load 先行，仍然只有一个读 miss，不是多 MSHR。

采用 write-through：B 成功后更新已经驻留的 word，失败保留原缓存数据；写 miss 不分配。
非缓存属性的 PA 别名写也检查、更新驻留 cache line。失败 refill 预先清 victim valid，
不会把已覆写 data 继续挂在旧 tag；invalidate 中的 refill 排空响应而不重新置 valid。

独立回填与成功 B 更新若在不同 bank，可同拍使用两份真实写口；同 bank 时保留 R beat，
只在 R handshake 推进回填数据、计数和 install。B 错误不更新缓存；store completion 的 token、
错误与背压仍独立保持。直接冲突与完整读回测试见 tb_r64_dcache_split_owner。

CPU 与 PTE 访问共用缓存物理服务；CAS/AMO 从读到 B 全程排他，不能与独立 store owner 重叠。
LR reservation 也保存在 D-cache，避免 LSU 预判 SC 与辅助写之间的竞态；任何匹配写尝试、
成功 mutation 或 flush 都可使其失效。SC 在真正取得物理 owner 时检查 reservation。

保留任意外部 B 错误时的精确异常，需要阻止年轻有副作用写在旧 B 未知前对外可见。
因此本候选只有一个写 owner，store 吞吐受 AXI B 延迟限制。没有假定平台 RAM 写永不报错，
没有新增异步 machine-check；不能据此声称所有 store 流也可达到 IPC 2。
失败 SC 的隐式 D bit 更新属于 ISA 未指定行为，SC 仍完成权限检查，见
[RISC-V Zalrsc 规范](https://docs.riscv.org/reference/isa/_attachments/riscv-unprivileged.pdf)。

## 当前直接证据与边界

测试源现位于 [testbench/chengyue64/modules/](../../../testbench/chengyue64/modules/)，下表所述既有日志位于 `../../../build/rebuild/lsu/`：

| 测试 | 可观察结果 |
| --- | --- |
| tb_r64_dcache | 887 请求/响应，400 拍双宽命中，45 写事务；全部 9 种 AMO 的 D/W、LR/SC、CAS、B 错误、字节写、PA 属性别名、失败 replacement、invalidate/refill |
| tb_r64_lsu | 544 完成，含 PA alias forward、部分字节合并、A/D/head/IO 授权、错误 trap、翻译/物理 kill drain、WB 背压 |
| tb_r64_lsu_select | N=18/32；空集、onehot、4096 deterministic 随机向量与独立线性选择 oracle |
| tb_r64_lsu_completion | 两 lane 分别保持、skid/full credit、kill head/tail、flush、非对称消费 |
| tb_r64_lsu_memory | CPU store→walker CAS→CPU hit 一致；Tensor 写打破 LR；辅助错误路由、4 个独立 stalled response |
| tb_r64_lsu_misaligned | 143 完成，216 字节写、207 读事务；cached/NC 全 offset、跨 word/line/page、FP、片段错误地址、部分 store 可见、head/commit 屏障、kill drain、AW/W 背压 |
| tb_r64_lsu_coupled | 真实 LSU+Service+Dcache，570 完成（默认早准备/窄完成）；512 条独立异 bank hot load 为 266 cycles、稳态 2/cycle |

同一个 512-load ROI、同 TB/工具/翻译 oracle、同真实 Service/Dcache：

| LSU 候选 | 项数 | cycles | 含填充/排空 IPC |
| --- | ---: | ---: | ---: |
| 每 entry RESULT→DONE→WB holder | 16 | 392 | 1.306 |
| 直接完成 FIFO + 简单 load 翻译直入 holder | 16 | 297 | 1.724 |
| 同上 | 18 | 266 | 1.925 |
| 同上 | 20 或 32 | 266 | 1.925 |

基线源码仅保留在 build 的 `R64Lsu-entry-result.v`，没有进入生产 filelist。
旧基线与候选前导功能病例可能因转发时点产生不同物理请求数；比较范围是相同 512-load ROI，
不是前导病例总 cycles。新完成 FIFO 把每项宽 RESULT 状态变为 4 条完成记录；18 项覆盖真实
注册流水的 9 拍 owner 窗口，32 项在该 ROI 没有收益。root 可在真实整核翻译/工作负载和 PPA
证据上裁决其他深度，不能把这张表当整核 CPI。

`tb_r64_lsu +bad-owner` 必须非零退出并匹配
`R64Lsu physical response without owner`。`tb_r64_lsu_coupled +bad-store-flush` 必须非零退出并匹配成功可见store被取消断言。
所有六个正向 test 的实际命令均使用
`iverilog -g2012 -DR64_ASSERT -I .../backend`，然后 `vvp`；
`.v` 文件另经 `iverilog -g2001` elaboration，整个 `R64LoadStore` 经 Verilator
`--lint-only -Wall -DR64_ASSERT` 检查。

`dcache-memory.json/log` 是 Yosys `proc; opt; memory_dff; memory_share; memory_collect`
后的端口检查：4 个 256×64 data bank-way 均 1R1W，两个 64×52 tag way 均 2R1W。
这是 inferred memory 端口结构证据；后续 LSU 单模块映射与完整核时序是独立证据，不能据此推断 cache SRAM 宏的物理 PPA。

真实双 Translation/PMP/PMA、三 walker、AXI 平台与 ROB/CSR 集成由 root 维护。
完整核适用非 OS 回归与同源综合/STA 的资格以 root 对应 frozen closure 为准；
下面的局部架构 A/B 不替代整核回归结果。

## 1 GHz 时序重构中的局部证据

当前主设计点为 icsprout55 TT、1 ns。年龄由 admission 更新的 18×18 older_q
关系矩阵保存，选择和每 byte 最近 store 查询分别由 R64LsuOrderSelect、
R64LsuForwardByte 做并行关系判定及平衡数据归并。矩阵对每对 live owner
与真实 ROB age 的一致性断言贯穿直接仿真和两个完整基准。取消在选择末端抑制，
不在当拍杀掉赢家后重新折叠整个选择树；因取消带来的一个调度气泡是允许的。

物理请求经过两个固定 lane 的 descriptor 队列，每 lane front+skid，保存 canonical
tag、LSQ slot、PA、数据和访问属性。上游 credit 只由 back 占用寄存器产生，
cache ready 和完整转发计算不能反传到新请求选择。简单翻译命中可直接捕获 descriptor，
一般 READY 请求经过选择 holder；普通 store 的完整 payload 在 head 前准备，
只有 head/effect_allow 授权后才能进入物理 descriptor。已接受外部 owner 仍保留
到响应排空，成功副作用还需保留到真实 commit。descriptor、转发 terminal 与 CQ
各自阻止其 canonical ROB slot 提前复用。

LSU issue_credit_o 是三位 min(Q态FREE, 6)，没有当拍释放信用；Backend 必须扣除
Issue 接收到真正 LSU admission 之间所有未入队 owner 的 reservation，不能把
饱和值当实际剩余数。局部状态/tag 更新为 18 个独立控制器，普通事件互斥，kill
最终覆盖可撤销 owner，已发 translation/physical owner 按实际响应排空。

独立 frozen System closure 保持 Backend、前端、Fabric、数值模块完全一致，
只替换 LSU 所需源码。CoreMark 与 Dhrystone 均使用相同镜像、NEMU DiffTest，
分别固定退休 3,218,537 / 4,260,670 条：

| 局部版本 | CoreMark cycles | Dhrystone cycles | 状态 |
| --- | ---: | ---: | --- |
| balanced 前、已有窄 store 完成 | 6,914,293 | 11,150,694 | 完整 DiffTest PASS |
| v4：关系矩阵、转发 terminal | 6,916,861 | 11,150,911 | 完整 DiffTest PASS |
| v6：增加物理 descriptor 边界 | 7,148,078 | 11,702,654 | 完整 DiffTest PASS |
| v7：局部状态控制器、晚取消 | 7,148,078 | 11,702,654 | 完整 DiffTest PASS；隔离 Backend 保持 credit4 |
| v8：响应元数据捕获，LSQ即时释放 | 7,427,402 | 11,768,447 | 完整 DiffTest PASS；credit4 |
| v9：descriptor 年龄旁带、格式化移到转发Q后 | 7,427,402 | 11,768,447 | 完整 DiffTest PASS；credit4 |
| v10：winner Q与源数据读分级 | 7,428,801 | 11,768,405 | DiffTest PASS；完整转发控制仍反馈宽队列 |
| v12：物理发起在匹配Q之后，普通热路径旁路 | 7,492,166 | 11,829,053 | DiffTest PASS；micro33条/274拍 |

v6 简单依赖 load-chain 与旧版同为 33 条/267 cycles；双 bank hot load ROI
同为 512 条/266 cycles。普通 store 16 条定向 ROI 从 96→112 cycles，新增授权
寄存级每 store 多一拍；未用提前退休掩盖该代价。

v5/v6 映射均明确 SYNTH_LOAD_FF=20（ABC 单位 fF）、STA 输出负载0.02pF，
input max/min=.4/0ns、output max/min=.4/0ns、input transition=.05ns。
当前 iEDA 版本必须用四条分别带 -setup/-hold 与 -rise/-fall 的
set_clock_uncertainty 才真正应用50ps。此前仅写裸0.05的报告没有生效，
只能保留为历史诊断，不能当50ps资格结果。

| 映射版本 | ABC最终delay ns | 总cell面积（lib单位） | 数据setup最差slack ns |
| --- | ---: | ---: | ---: |
| v5 关系矩阵转发 | 1.97460 | 173,939.92 | −1.546 |
| v6 descriptor | 1.81104 | 186,349.24 | −1.245 |

两个版本均明确未达到1GHz。v6 数据最差为 flush→state D，arrival2.161ns；
CQ/FWD terminal 也仍需分段。ICG enable 在 iEDA 的 clock_gating_default 组
另有负余量；该组是否继承50ps正在由 root 查明，不能省略或屏蔽检查。
原始源、命令、hash、映射和报告保存在 tmp/rv64-lsu-balanced 对应版本目录；
v6 源为当前局部状态重构的可回滚点。

历史 v13 的匹配阶段把每 byte 的 winner onehot、完整转发标记和物理 descriptor
共同保存到最终物理队列，再读取被引用的源数据。完整转发在该队列之后进入完成
holder，不访问物理服务；部分转发在真实物理请求接受时捕获所选字节，下一拍及之后
到达的物理响应与已捕获字节合并。匹配/选择不再反馈同拍物理发起和原 descriptor 出队。

没有 ordering owner 的成功普通翻译，以及已准备好的普通 head store，直接进入最终
物理队列，省去不需要的匹配级。已有 descriptor 优先，旁路只使用 Q 态空位，不会替换
已经向物理服务保持的请求。全都强制经过额外匹配级的 v11 反例让18项coupled流降为
512条/296拍；采用上述旁路的 v12/v13 恢复512条/267拍，普通窄store16条ROI恢复112拍。
生产 v13 另将唯一head的special候选由年龄树改为onehot编码，并断言候选最多一项。
完整冻结旧Backend的 v12 基准已经PASS；v13生产组合集成由root独立验证。

query 只保存 load 访问范围内的 byte winner，未访问 byte 的 winner 清零，源 slot pin
取这些已保存 winner 的并集。无匹配源、仅命中未访问字节的源、被年轻 store 完全覆盖的源，
不再随 query 长背压持续占槽。真正仍被引用的已提交 store 保持 PINNED，同时清 alive/effect，
直到 query 捕获数据后才释放 LSQ/ROB reuse。

descriptor 捕获之前仍使用保守源保护，因此 commit/query capture 同拍时，无匹配源可以
暂时进入一拍 PINNED；下一拍释放。2026-09-07 的20项生产开关定向A/B中，普通无匹配源
提交后保留125拍变为0拍，同拍capture用例130拍变为1拍；多源/部分转发仍保留必要引用。
这些是受控背压下的槽位收益，未测整核CPI或本补丁STA。

make -C npc/rv64/testbench/chengyue64 lsu-query-pin-matrix 运行无匹配、未访问字节、
被覆盖源、必要源、多源及commit/capture六种模式。测试还在query停留时复用释放槽和ROB代际，
并检查最终load数据。详细A/B保存在 tmp/rv64-lsu-query-pin-opt-20260907/REPORT.md。
descriptor 的 older 位图在每次 source slot 新 allocation 时清除相应位，防止旧
物理slot关系被错误用于年轻的新 owner；可变年龄旁带不属于需要保持的物理请求 payload。

顶层 ROB 的取消是年轻 suffix 或 full flush；局部实现仍接受独立 load 的任意取消，
但撤销较老 store 必须同时撤销其年轻 memory consumer。显式断言和
tb_r64_lsu +bad-store-cancel 负例约束该合同，不能保留已转发的年轻指令再假装撤销源。
已有独立 load kill 激励未删除或弱化。

tb_r64_lsu -Ptb_r64_lsu.DEPTH=2 +metadata-hold 验证8个被WB阻塞的canonical结果
跨越仅2个LSQ槽的反复复用；tb_r64_lsu_coupled +source-pin 验证真实commit与winner
捕获同拍、full/partial源数据、WB阻塞期间源slot复用以及fullflush。
tb_r64_lsu +fast-response 使用最早下一拍物理响应检查转发字节与响应合并边界。

时序主资格工具已改为本地 OpenSTA，保留 iEDA 作为交叉诊断。相同网表/库/约束下
v8 OpenSTA发现setup约−1.22ns和hold−36.7ps；v9为setup−1.1646ns/hold−36.7ps；
v10为−1.2409ns/−36.7ps，v12为−1.2478ns/−36.7ps，仍全部FAIL。
v12的最差Q→D已移到state→调度选择/编码/取消→state反馈，arrival1.9364ns；后续继续按真实路径重构。
hold短路径是raw error/offset输入直达D，不能用放宽input min或RTL假buffer掩盖。
iEDA的ICG组未实际扣除50ps，不能用该组原报告作为资格。
仅保留当前调试映射和一个必要比较基线；过时大网表、ABC/obj/vvp已按用户要求删除，
历史简要日志与结果仍保留。最新有效源清单按真实RTL_FILES生成，不把导出的flat网表
误记为RTL source。
