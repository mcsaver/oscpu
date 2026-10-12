# RV64 自治域与公共事务协议

本文定义当前工作区的团队开发边界。协议版本为 2，位定义以
[公共协议头](include/R64Protocol.vh)和[派发协议头](include/R64Dispatch.vh)为准；
[独立源码清单](domain-filelist.mk)定义每个端点实际需要编译的依赖。
全核装配见 [R64CoreTop](core/R64CoreTop.v)。下面的规范描述生产代码，不是待实现方案。

## 1. 团队和状态所有权

| 独立交付域 | 入口 | 唯一拥有的状态 | 对外合作 |
| --- | --- | --- | --- |
| 前端 | R64Frontend | 取指流、预测、指令FIFO、取指翻译及I-cache owner | 发布有序Fetch记录；接收consume及Recovery；请求PTE/读总线服务 |
| 指令生命周期 | R64Backend | Decode队列、Rename映射与free list、ROB、完成授权、恢复顺序 | 原子birth到执行域/LSQ；接收completion；发布退休候选、恢复计划 |
| 调度执行 | R64ExecutionDomain | IQ、PRF、唯一GPR/FPR busy scoreboard、RR holder、整数执行owner | 接受Dispatch birth；接收授权WB/undo；发出MEM/FP/Serial原生命令和带tag结果 |
| 浮点 | R64FpExecute | FP ingress、数值流水、完成队列 | command32、操作数、tag、信用、完成及Recovery |
| 精确控制 | R64Control | Commit事件、Serial事务、CSR/特权架构状态 | 退休候选→ready/Retire；发布Effect、redirect、上下文及失效 |
| 数据访存 | R64Memory / R64Lsu | LSQ身份、年龄、取消、地址/数据、依赖转发、外部事务租约 | reservation/bind、完成、store终端；内部调用翻译与物理服务 |
| 数据翻译服务 | R64DataTranslationService | 每lane四项token/protection账本、DTLB/walk、保护响应 | 不透明token请求/响应、PTE事务；不了解ROB或LSQ布局 |
| 物理访存服务 | R64PhysicalMemory | Split、CPU/PTE路由、D-cache、store响应来源解释 | 接收CPU token和aux source；输出带原身份的终端，连接读写总线 |
| 总线/平台 | R64AxiRead / R64AxiWrite / Fabric | AXI ID、AR/AW/W/R/B在途状态和设备事务 | 仅遵守总线及请求/终端合同，不解释ROB恢复 |

Backend 是生命周期域和执行域的装配入口，ExecutionDomain 可以单独编译运行，
不需要实例化 ROB 或 Rename。数值加法、编码解码、优先选择等纯逻辑 helper 可以共享；
其文件所在目录不代表其他团队可以读取该域的状态。

跨域只使用端口。CoreTop 不读取 ROB 数组或 Execution 私有计数来控制生产行为或验证授权。
生产域内断言留在 owner 处；跨域断言核对公开身份/事件。仿真 profile 可以观察内部层级，
但观察结果不反向影响 RTL。测试 oracle 只编入 testbench，不编入生产清单。

## 2. 网络组织和时序合同

这是一张有明确端点的同步事务网络：命令向服务流动，完成返回生命周期域，
Recovery/Retire/Effect 为有定义的事件或授权记录。各端点持有本地队列和状态。
Recovery、Memory Retire、Memory Effect 与 reuse 公告具有实际寄存边界；
原子 birth 所需的 Q 态资源 offer 保持单向发布，rank 选择归生命周期域本地所有。

共有三种端口语义，不能混用：

| 类型 | 转移边沿 | 阻塞时的义务 |
| --- | --- | --- |
| candidate + credit + fire，例如birth、RR→服务 | 上升沿 fire=1，且该lane有credit | fire前没有转移所有权；未接受候选允许重新选择，不能要求所有candidate永久稳定 |
| valid / ready，例如completion、翻译和物理响应、AXI | 上升沿 valid && ready | 已发布owner的身份和payload保持；仅协议明确允许的取消可撤销架构结果 |
| 同步事件，例如Recovery/Retire | 源发布边沿入本地 inbox，下一边沿消费 | 无ready，逐拍接收，按协议固定延迟交付；不撤销已接受的总线事务 |

请求信用只表达端点是否能接受这次转移，不表示指令已完成。完成与退休分开：
completion获得ROB授权并写回后，仍需等待Control接受退休。无有效owner时payload无语义。

### 身份和取消

- 完整tag由ROB slot与generation组成。架构WB由生命周期域认证；提前唤醒/供值由ExecutionOwners在本域核对完整tag、preg与命名空间，不再组合查询ROB。
- Service token 是调用者赋予的opaque identity。服务只回显，不推断ROB slot或年龄。
- 生产LSU用LSQ slot作翻译token，因此从request fire到response fire必须保留该slot及其完整ROB tag。
  tr_issued 标记租约；kill只使架构owner无效，不能提前FREE/reuse。
- 已取消翻译返回只排空一次，不发完成。未排空row继续贡献reuse_block。
- AXI、PTE、Tensor等已接受事务不能因流水kill丢失终端；取消架构结果与排空外部owner是两件事。
- reset清除本地owner；系统级reset必须同步重置对应外部服务。不能把运行中reset当成普通取消。

## 3. 公共记录

所有双lane向量以lane0放低位，lane1放高位。位宽参数N是ROB槽数，T是完整tag位数。
当前Core N=32、T=9，LSQ token宽5。

### Recovery：N+67 bit，当前99 bit

| 字段 | 位置 | 含义 |
| --- | --- | --- |
| candidates | N-1:0 | 预备取消集合；单独存在只是提示 |
| active | N | 本边沿选择性取消有效 |
| full_flush | N+1 | 全流水恢复，独立于选择性mask |
| redirect_pc | N+65:N+2 | 前端恢复地址 |
| redirect | N+66 | 地址有效，前端消费恢复 |

消费者的selective kill = candidates & active。不能把full_flush偷偷并入mask而破坏prepared-cancel合同。
CoreTop组合Control的精确flush/redirect和ROB的选择性计划；Control redirect优先。
FE只消费redirect及PC，FP/Execution消费flush和选择性mask，Memory还可用candidates做预备判定。
Control是精确flush的发起者，内部Serial直接消费其权威flush。

恢复发布 t0：ROB/WB/退休立即撤销错路资格；Backend 禁止新 birth。
Frontend、Execution、FP、Memory 及 Control 的选择性恢复分别进入 R64RecoveryInbox，
在 t1 消费本域事件。Backend 的 recovery_fence_q 在 t1 继续禁止 birth，t2 才可恢复；
尚未完成的 undo 仍可继续阻止分配。固定 fence 同样覆盖 full flush 和零 victim redirect，
防止迟到的 slot mask 或旧值误伤新 generation/preg。连拍事件逐条采样，不合并丢弃。
已接受的翻译、物理和总线事务继续排空，只撤销架构结果。

### 分支返回：候选与架构事件分开

Execution 发布 branch preview / resolve / mispredict 候选；已登记的 resolve/mispredict 记录只由本地 Q 态驱动，
不在输出端再次组合查询 Recovery。token 捕获边沿仍执行本域取消，已捕获的候选允许迟到返回。
ROB 根据当前有效 owner、完整 generation/tag 和匹配的预备 plan 接受事件，
Backend 只把 resolve_accept / redirect_accept 发布给 Frontend、预测训练、decode clear 和 birth fence。
raw redirect_pending 只是服务内部提示，不能冻结 ROB、生成 kill 或触发重定向。

已取消或旧 generation 的迟到候选丢弃；当前仍 live 且完整身份匹配的 mispredict 若缺少匹配 plan，
必须触发强断言，不能静默丢掉有效恢复。fullflush 优先于候选。undo 期间更老分支仍可接受并扩展回退；
同拍 younger preview 受已接受 kill 过滤。整个资格判断留在生命周期域，不把全局组合 kill 拉回 Execution。

### Effect：T+3 bit，当前12 bit

低T位为完整tag，bit T为present，T+1为memory permit，T+2为serial permit。
Control 发布两份独立记录，禁止用一个 tag 同时表示即时 Serial head 和已授予的 Memory owner：

- effect_o：即时 Serial head 身份及 serial permit，memory bit 固定为0。
- memory_effect_o：R64MemoryEffectLease 的寄存完整tag与许可，serial bit 固定为0。
  未完成的 LOAD/STORE/AMO head 在允许且没有恢复事件时获得租约；已经投机完成的 load 不再获授。
  从授予到匹配 head 完成候选出现，租约保持并计入 Commit irrevocable，包括物理请求背压。
  分支恢复、当前 permit 变化都不能撤销租约；fault completion 先释放租约，再进入精确 trap。
  head 变化或 full flush 不得静默清除有效租约，由断言核对。

SUCCESSOR_STORE_LEASE 开启时，Control 可以先保存相邻两条普通 store 的完整身份提示。
提示不授予许可；只有前序成功、实际单条退休、后序尚未完成、无恢复且许可有效的接受边沿，
才把后序完整 tag 安装为下一拍寄存租约。Trace 背压、前序错误和提示 tag 失配均不能交接；
旧租约已因完成而释放时也遵循相同的真实退休条件。后序同拍完成的 fault 不产生物理请求。

Memory 只消费寄存租约。tag 匹配须使用完整身份，不能只匹配槽号。
精确控制的本域 CSR/Serial 退休副作用仍在同一个架构接受边沿发生。

### Retire：2T+2 bit，当前20 bit

低2位为实际接受的fire，高2T位为lane0/lane1完整tag。
Control唯一裁决dense prefix、Serial独占、异常阻止和trace背压，
并向Memory广播这条accepted事件；Backend通过同一candidate & Control ready执行映射/ROB退休。
只有01或11表示普通接受前缀；候选11在ready=00期间仍可发布，不能把候选当成退休。
Memory 将 Retire 登记一拍，与本地 Recovery 同延迟消费，再释放已完成 store/AMO owner。
等待本地退休的 owner 继续贡献 reuse，不能根据 WB 或源端退休提前释放。

### MEM command：205 bit

| 绝对位 | 字段 | 语义 |
| --- | --- | --- |
| 63:0 | BASE | 已读出的基地址 |
| 127:64 | OFFSET | 符号扩展地址偏移；AGU归LSU |
| 191:128 | DATA | store/atomic数据，包括FPR store源 |
| 199:192 | FUNC | size[1:0]、unsigned[2]、保留[4:3]=0、store[5]、FP[6]、atomic[7] |
| 204:200 | AMO | ISA funct5；非atomic时不参与判断 |

R64_MEM_FUNC_* 宏是相对FUNC8的位号，其余R64_MEM_*范围是command绝对位置。
tag、LSQ slot、fire/credit由端口伴随command传输。先reservation，再按tag和slot绑定command；
reservation与ROB/执行域birth同边沿原子发生，不能部分占槽后等待其他域分配。

Memory 无条件发布两份 ranked FREE-Q offer：credit[0] 表示至少1槽、credit[1] 表示至少2槽，
slot0/slot1 是对应的互异空槽。输出不依赖 Backend want、当拍 retire、kill 或 response。
Backend 根据两条指令的 MEM 属性本地选择 rank，发出 fire、明确 slot、完整 tag、func、amo。
lane0 非 MEM、lane1 为 MEM 时，memory fire=10 合法且使用第一份 offer。
Memory 不再接收 decode want，只验证所接受事务与本周期 offer 一致。

Memory 的 reuse_block 来自寄存公告：下一状态为内部全部 owner 并集 OR 本边沿接受的 acquire slots。
acquire 与原子 birth 同边沿记入；release 可以保守晚一拍。flush 不清公告，内部 owner 转移不得存在空洞。
local_reuse & ~published_reuse 必须恒为0，由域内断言验证。

### FP command：32 bit

标准FP指令编码，tag和三个64-bit已读操作数随行。动态rounding/FS上下文是明确端口。
服务自行解码FP数值功能和持有终端；不消费整数派发记录或PRF读计划。

### Serial command：217 bit

| 位 | 字段 |
| --- | --- |
| 63:0 | 指令PC |
| 127:64 | 原始指令，Tensor pair时保留完整64位 |
| 191:128 | CSR/Tensor/SFENCE第一操作数 |
| 207:192 | SFENCE ASID，来自第二操作数低16位 |
| 215:208 | 退休kind枚举 |
| 216 | pair，精确定义为原指令长度8 byte |

Serial自行持有CSR query、Tensor外部事务、完成与退休状态。CSR read/RMW计算可以先完成，
实际写入、xRET、FENCE.I/SFENCE等效应必须等待匹配tag的退休。
发送端不得依据Serial内部状态推进生命周期。

### Completion与退休metadata

RESULT140：data[63:0]、exception[64]、cause[70:65]、tval[134:71]、fflags[139:135]。
META204：PC[63:0]、raw[127:64]、NPC[191:128]、length[195:192]、kind[203:196]。
同一tag的completion至多被接受一次；异常只通过精确head处理改变架构状态。
store已可见终端另有窄store_done协议（tag/error/tval），保留其与普通WB不同的生命周期。
真实 B 必须已经到达 LSU；STORE_RESPONSE_ELASTIC 开启时，空的窄终端槽可以直接发布此次
实际 B 接受所确认的 tag/error/tval。旧终端优先；ROB 未接受时按原协议登记并持有，关闭时全走登记路径。
ROB 仍核对完整 tag、当前未完成 ordinary head、非 writer/非 Serial，不能把请求发出当作完成。
接受窄终端的边沿可直接形成head退休候选：成功时可与已完成的下一条指令双退休；
错误时cause=7、tval随终端，阻止第二lane候选。候选仍不消费Control ready。
同一终端同时写入ROB完成数组，Trace背压或选择性恢复冻结时由数组接续持有；
resident head_exception证书仍只读取Q，避免引入精确flush反馈。

### Fetch与Dispatch

FetchTranslation 的 BARE_RESPONSE_CAPTURE 仅在无旧 lookup/walk、原 response tail 有 Q 信用时，
将实际接受且已知为 Bare 的请求直接写入原 response owner，省去 lookup owner 的一拍。
有效特权仍按原 access/MPRV/MPP 规则决定；Bare 保留完整 PA、PBMT=0、needs_ad=0，
不新增翻译 fault，cause 字段仍保留原 access 编码。已有 response 顺序保留，满 response Q
仍可按原信用接收第三个 lookup owner；invalidate 禁止新接受，所有既有 owner 有序排空。
后续 FetchProtection/PMP/PMA/ICache 接受及访问错误路径保持完整，Bare 不代表物理访问许可。
ICache 的 HIT_RESPONSE_EMPTY_FLOW 仅以同步 lookup Q 的真实成功 hit 数据与同 owner 保护 mask
穿过空 response 槽；旧 response Q 优先，受阻时存入原 response Q，之后 invalidate 不能改变已呈现的 packet。
miss、翻译 fault、全保护拒绝和 uncached 仍走原返回路径。Stream 的 PACKET_EMPTY_FLOW 在 packet Q
为空且有实际非 stale response owner 时，直接把该 response 及 owner PC/plan 交给 Align；
Align 未接受就存原 packet Q。仅旧 packet count 可产生 pop；actual response 只释放一次原 owner，
redirect 和 stale drain 继续按原规则执行，rsp_ready 仍只依赖已登记 owner。

Fetch公开canonical33={encoding legal, RV32 canonical instruction}以及control35。
control从低到高为class3、rd_write1、rd_fp1、src_fp3、src_used3、function8、
flags4、retire_kind8、argument_kind3、legal1。它们是静态编码事实，
不能包含在前端提前判定的动态权限。PC/raw/length/predictedNPC/fault及tval作为伴随字段，
生命周期域在接受时应用动态上下文。consume表示实际从有序窗口移走的条数。

Dispatch218定义在R64Dispatch.vh：PC64、ARG64、CMD64、LEN4、FUNC8、FLAGS8、CAUSE6；
class、目的preg、三个源preg/used/fp、完整tag和已预留LSQ slot随birth传输。
ARG按类别为ALU/访存立即数、分支预测NPC、CSR立即数，或异常tval；
CMD为规范32-bit指令，8-byte扩展保留64位；FUNC按class取明确操作枚举；
FLAGS为word、op1-PC、op1-zero、op2-ARG、exception及保留位。
旧R64Uop.vh只作为兼容include，没有第二套定义。
下游MEM/FP/Serial服务收到的是各自命令，不再解释Dispatch。

Fetch argument_kind是构造Dispatch.ARG的公共规则：0→0；1→符号扩展I立即数；
2→符号扩展S立即数；3→符号扩展U立即数；4→predicted NPC；5→零扩展rs1编码作为CSR zimm。
fetch/illegal异常覆盖ARG为tval，并置exception，关闭目的写入与源使用。

| Dispatch class | FUNC解释 |
| --- | --- |
| ALU | R64Dispatch.vh的R64_F_*枚举 |
| BRANCH | 0/1/4/5/6/7为BEQ/BNE/BLT/BGE/BLTU/BGEU，8为JAL，9为JALR |
| MDU | 0..7为M扩展funct3（MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU）；9/10/11为CLMUL/CLMULR/CLMULH；word由FLAGS给出 |
| MEM | 与MEM command的FUNC8相同；AMO funct5由CMD[31:27]取得 |
| FP | 数值操作由CMD32决定 |
| SERIAL | R64_K_*退休kind；具体CSR/Tensor编码由CMD决定 |


## 4. 执行域协议

busy只有Execution.Scoreboard一份，Rename只负责map/free。
优先级为reset/fullflush > birth置busy > undo reclaim清busy > 授权WB清busy。
GPR x0恒ready，FPR f0是普通物理寄存器。WB消息必须已经通过生命周期域身份认证，
Execution不重复猜测generation。Issue的deferred初始化、当拍WB/ALU wake和RR真实供值在域内闭合。

ExecutionOwners 在 birth 保存写目的指令的完整 tag、preg 和 GPR/FPR 属性；
只在匹配身份的已认证 WB 或本地 Recovery 时终结。ALU early wake 与旁路只查本地表，
不再存在 fast_query → ROB → fast_accept 的生产组合往返。它只授权投机供值；
不会设置 ROB done、不会替代架构 WB。仿真可通过只读 audit 与 ROB 核对，不能反馈到生产路径。
源恢复到本地交付的窗口内，架构 WB 已由 ROB 撤销，birth/reuse fence 防止污染新身份。
head/barrier/serial-active/release是生命周期域发布的排序事实，不是执行域读取ROB数组。
reclaim通知被undo释放的目的preg，不能任意清除其他活跃目的的busy。

### 执行域内部提前调度与晚到操作数

Issue的调度promise与真实ready分别保存。普通ALU在实际issue_fire、无异常、目的GPR preg非零时，
可对已有IQ项及同拍birth发布目的preg的调度promise。它只允许匹配的整数source0/source1提前进入RR，
不改变Scoreboard busy、不写PRF、不设置ROB done，也不保证固定拍数后必能执行。FPR、第三源和x0不使用promise。
ExecutionDomain将Execute的EARLY_ALU_WAKE设为0，只关闭当拍接受事件；Issue promise和RR LATE_OPERANDS
仍由域参数EARLY_ALU_WAKE控制。ALU已登记token、成为head及驻留head旁路继续可用，
覆盖错过promise才birth的消费者。不能把此设置解释为关闭整个提前调度机制。

IQ→RR的issue_src_pending_o / in_src_pending_i为6位，每lane三个源；置位表示该源凭promise获得调度资格，
尚未取得正常ready事实。它随原issue_fire、源preg、完整tag和LSQ slot接受，属于执行域内部接口；
Dispatch及跨域MEM/FP/Serial ABI不变。

RR两个ingress和四个terminal分别保存源preg、pending/resolved和捕获值。旧PRF内容或ginit不能解除pending。
合法值可在输入接受、物理读出、ingress等待和terminal等待期间捕获；同拍转移必须保留同owner的单拍WB。
等待的消费者只占RR位置，Execute实际fire前不占FU。

四路原始ALU/WB数据、preg和已认证valid每拍共同登记为arrival history。
256-bit宽数据和24-bit preg不以IQ选择、in_fire或当前授权控制D；4-bit valid保存已有qualified mask，
不能用raw resident替代，也不能下一拍再向已离开的来源重新认证。当前IQ源地址仅登记入ingress，不在准入边沿匹配history。

每个新ingress在既有read_select_w（valid Q且尚未读）窗口只使用一次同龄历史，且只对pending整数源匹配。
H为历史命中时，effective_pending=P&~H、effective_resolved=R|H，H命中值优先于下一拍当前到达；
当前到达只能解决 effective_pending 仍置位的源。历史与当前集合都以 WB1、WB0 为最高优先级；
可选真值观察与 ALU head 使用固定 lane 优先级，多个合法命中值必须一致。
本地保存和transfer必须使用同一组effective状态和值：terminal受阻也在首次read边沿保存历史值，
后续不能反复查询已被其他事件覆盖的共享history。非pending、FPR、第三源和x0仍走原合同。

同拍transfer/refill由旧source Q和旧history服务旧owner，新in_fire最后初始化新owner的原pending及resolved=0；
NBA后的新history与新owner在下一次首次read配对。共享历史不新增owner，reset/flush清ingress valid和pending/resolved，
使未关联或未初始化的历史不可被消费。共享历史容量为通道数乘以 (64+PREG_W+1)，不新增 owner 或流水边沿。

ALU_TOKEN_BYPASS 开启时，两条 token lane 使用实际 ALU 已登记的运算结果或 branch link 值；
token 完整 tag、birth 类型与目的 preg 经 ExecutionOwners 认证，不以 token 的存在替代数值正确性。
RR_COMPLETE_ADMIT 在实际 IQ→RR 接受、原 ingress 为空、terminal 有 Q 信用且所有使用的非 x0
整数源均有已认证实际 head/token/Memory 公告/WB 数值时，直接捕获到原 terminal。
完整 tag、payload、LSQ slot、当前输入预解码控制和实际数值同时捕获；pending 与旧 forwarding 选择清零。
只允许 ALU/MEM，排除 branch、FP 源和第三源；任意缺值、旧 ingress 或满 terminal 均走原 ingress。
不借用同拍 pop/Execute ready，不重复执行物理读；实际 WB 保持数值捕获最高优先级，冲突断言不变。
RR_ADMIT_GPR_READ 进一步允许 canonical ready（IQ 传来的 used source pending=0）的源复用原 GPR 读口。
每 lane 的两口地址只由 ingress_valid Q 选择：旧 ingress 保持优先，空 lane 才读取当前输入地址。
实际公告/WB 数值优先于 PRF；pending 源没有真实数值时仍回退等待，ginit 只保留原未初始化读零语义，
不提供 ready 资格。端口数、FP 分配和 Q 信用不变，所有值在原 terminal 捕获后才进入 Execute。

MEM_TERMINAL_CURRENT 开启时，MEM terminal 的 pending 整数源可用当拍已认证的 resident head/token
实际数值解除；所有源真正齐备并获 Execute/LSU bind 接受后才 fire。下游受阻仍捕获到原 RR Q。
WB 和 Memory 公告仍先落 RR Q，FPR 仍走原读出；只允许提前生成地址/数据，不产生访存副作用许可。
terminal 实时 ALU 宽值选择可使用已驻留 head 或 token Q、目的 preg Q 及固定 lane 优先级。alu_bypass_resident_i表示Q驻留，
alu_bypass_valid_i表示当前身份认证；后者只控制所选值能否解除pending，不通过kill/flush重选宽数据。
固定选择未认证时等待，后续本地捕获的合法值也可解除等待。WB先进入RR本地late_data Q，
不直接组合供给 pending terminal 的算术输入；可选 Memory 最终值同样先进入本地捕获或 history。
同一live preg多个合法值必须相等，优先级不能使冲突合法化。移位量由最终B操作数生成。

flush清除pending/resolved；选择性取消仍遵守RR owner、Execute准入与本地Recovery规则。
新owner重用RR位置时重新初始化源状态，迟到值不能复活旧owner。
全局WB认证仍可控制本地RR捕获，但路径在RR寄存器终止，不穿透当拍ALU数值计算。

### Memory 最终值公告与 load 调度提示

Memory 发布两路 resolved_value={valid, full tag, data64}；这是一条无 ready、无 ack 的非 owning 公告。
数值来自原 LSU 完成仲裁选出的真实最终结果，已包含符号扩展、分拆及部分 store forwarding 合并。
异常不公告。resident valid 与 CQ 接受信用、IQ/RR ready 无关，背压期间允许重复同值公告。
EARLY_PHYSICAL_VALUE 开启时，实际被 raw response ingress 接受的成功、存活、对齐普通整数 load
可补充空公告槽；数值使用已发布且不可重写的 forwarding 快照完成逐字节合并与原 load_value 格式化。
R64ValueNoticeMerge 优先保留原完成仲裁的 occupied candidate，当前 kill、异常或 credit
均不能重选该槽宽数据。只有未被 resident candidate 占用的槽才可按 lane 顺序补充真实响应值。
补充失败只丢失提前观察机会，原 raw ingress、CQ 和 WB owner 继续提供后续完成；不新增重试或确认。
公告不清 LSQ、不消费完成、不写 PRF、不设置 ROB done；规范完成继续沿原握手独立发生。

ExecutionOwners 用完整 tag 和当前 birth 的 ordinary integer load 类型、非零目的 GPR 认证公告。
WB transport 实际捕获也可发布 load scheduling promise；这只改变调度资格，不等同于可读 PRF。
IQ 的真实 ready、promise 和当拍已认证真值命中分别处理；凭后两者进入 RR 的源必须携 pending，
直到 RR 捕获对应真值，或后续规范 WB 到达才解除。新 birth 和重用槽不得继承旧数值或 pending。

### RR到Execute的两类数值就绪

生产ExecutionDomain在RR和Execute同时启用SPLIT_VALUE_VALID，通用模块默认值为0。
两条有效通道对应同一个terminal_select，其tag、class、payload、LSQ slot及全部操作数完全相同：

| 通道 | 有效条件 | 可参与的实际接受 |
| --- | --- | --- |
| out_valid_o → in_valid_i | 所选owner存活，所有pending已经在RR本地Q中解除 | MEM、MUL、DIV、CLMUL、FP、Serial的live、年龄仲裁和fire |
| out_local_alu_valid_o → in_local_alu_valid_i | 所选owner为ALU/分支；本地Q或当前认证的驻留ALU值已齐 | 两路ALU及双分支的年龄竞争 |

Execute对两通道执行相同的reset/flush/cancel检查。共享资源不把local valid合并回live、priority或实际fire；
in_ready_o只把实际接受结果返回RR，RR在本地用两条valid与该确认消费一次owner。
Q_ONLY_TERMINAL使此确认不组合穿过RR形成ingress信用。

非ALU若仍有pending整数源，即使当拍首次获得认证值，也先捕获到本地Q，下一边沿才允许实际接受。
已有登记源的请求不增加等待。MDU/FP head无FU容量或仍有pending Q时，允许已有受限escape选择后排ALU；
后排不得是分支/MEM/Serial，选择、供值及消费必须使用同一owner。被越过的head保留至其真正接受或取消。
非法指令及取指异常在Decode、owner birth前归入ALU，Execute不再按异常位临时改写class。


## 5. 翻译和物理服务协议

DataTranslationService每lane保留四项已接受token，信用不能借当拍response释放的容量。
两lane可独立前进；每lane响应保持接受顺序。response任意背压时token和结果一起保持。
invalidate可以使TLB失效，但不能删除已接受request的token。
LSU请求被取消后仍负责消费响应并结束租约；服务无需kill端口。

SATP、privilege、mstatus、PBMT、access随translation request接受；
PMP范围/权限在后续DataProtection接受时取样。
调用方必须让仍存活的访存与PMP上下文修改按架构顺序执行，不能假设request已快照所有PMP状态。
当前由ROB/Serial退休顺序保证这一点。已取消事务仍可用后续上下文完成排空，因为不再提交结果。

Dispatch reservation建立canonical LSQ owner；新owner的forward_mask初始化为0，宽forward数据不必清零。
实际 bind 在完整 slot/tag 和存活检查后登记 VA/数据等信息。BIND_TRANSLATION_BYPASS 开启时，
普通对齐整数 load 且未启用访存触发器，可在同一接受边沿把不透明 slot/tag 和保护信息送入有 Q 信用的
translation_queue；旧 NEW/A-D 请求优先。唯一 admit 事件同时把 canonical owner 置为 TRANSLATING。
BIND_TRANSLATION_EMPTY_FLOW 关闭时，VA 写原 canonical Q，下一拍队列输出才读取它；未获队列信用及特殊访问保留原 NEW 选择路径。空路径开启时的同沿接受和 store 热绑定见第十七批合同。
实际tr_valid && tr_ready才建立tr_issued租约；触发器、对齐、权限、取消与响应排空规则保持完整。

转发快照的数值预写与有效字节发布分别由query occupied Q与query_take管理。
取消可留下无效宽数据；新的reservation必须独立初始化掩码，prepared store不能借用上一代owner的转发有效性。

Bare数据请求在有效权限（含MPRV/MPP）确定后、没有更老lookup owner且outcome有信用时，
直接捕获到outcome Q；否则保留原lookup排队。旧lookup优先，walk身份不可被覆盖。
PMA/PMP、地址范围溢出、poison和服务token账本仍完整执行。
DataProtection 的 EMPTY_FLOW 允许空槽直接交付完整保护结果；旧 Q 结果优先，受阻则捕获全部事实。
TRANSLATION_QUERY_BYPASS 只让已有无更老顺序依赖证书的普通整数 load 穿过空 query lane；
旧 query、physical holder、prepared route 保持优先。仅真实 physical fire 取消 query 入队，
否则完整 descriptor 进入原队列。trans_end 是该边沿唯一状态事件，不能与 mem_start 重复记账。
RESPONSE_DESCRIPTOR_BYPASS 让未获上述 direct-query 路径的成功普通整数 load，在旧 mholder/READY
选择均不占 lane 且 descriptor 有 Q 信用时，直接用真实 translation response PA/class 与 canonical
slot/tag/func/mask/older-age 创建原 load descriptor；已知更老 store 仍走原 query 字节匹配和最年轻来源选择。
新的 descriptor 与旧选择路径互斥；特殊访问、fault、A/D、未对齐或没有信用时保留 READY 回退。
trans_end 独占状态更新，不能重复创建 descriptor 或 physical owner。

PhysicalMemory 的 Service 对普通 cached CPU read 启用 CPU_READ_EMPTY_FLOW：
原仲裁已用 Q 容量接受的请求可穿过空物理 lane，aux 配对后的实际来源决定 payload。
Cache ready 不参与 direct valid；受阻时进入原 Q。aux、store、atomic 和不可缓存请求保持原路径。
Dcache 的 HIT_RESPONSE_EMPTY_FLOW 使用真实 lookup Q 中的 token、命中与 SRAM 数据；
旧返回 Q 优先，空槽可在下一接受边沿交付命中结果，受阻则捕获原返回 Q。
只有实际返回接受才省去返回 Q owner；miss、fault、atomic 和真实 B 完成规则不变。
Dcache 的 FAST_STORE_DETACH 仅在普通 cached fast store 的写命令和写数据都已被传输端接受后，
把完整 address/token/strb/fast 与已有 way/hit/poison/data 一同交给唯一 store-active B owner。
该边沿释放原 bank lookup stage，允许同 bank、不同 set 的 cached load 继续接受、命中或 refill。
新的 load 必须同时满足 slow read/refill owner 和 store B owner 的 bank/set 排除规则。
真实 B 只更新独立 store descriptor 对应的缓存字节、mutation 和返回 token，不能清除已复用的 load stage。
B 与 refill 同 bank 写端口冲突时保留原 B 优先/暂停该 read beat；nonfast store 保留原 stage，避免共享返回 Q 双生产。
该结构不接受第二个 store，不提前 B、错误或架构完成。
STORE_COMMAND_EMPTY_FLOW 允许实际接受的普通 cached store 在本沿分别提交完整命令和数据。
00/10/01 进入 WRITE，仅补未接受通道；11 进入 BRESP。此时 lookup 元数据尚未登记，
不能创建 detached descriptor。下一拍真实 B 优先完成；未发生 B 接受才从原 lookup 建立唯一 store owner。
同 word LR reservation 在实际直通接受时清除，不能因跳过 WRITE 或 B 错误遗失清除语义。
其他访问、命令/数据背压、真实 B 错误和缓存更新规则不变。


普通对齐cached store可以提前将完整prepared payload和opaque identity镜像到物理服务。
镜像只做数据准备，可覆盖；不建立owner、不占请求Q、busy、idle或取消应答。
identity由调用方提供完整tag和slot，服务只比较相等，不解释年龄。
只有本地head lease授权后的真实CPU请求匹配镜像、赢得原仲裁、且两lane请求Q都空时，
cache才可直接接受镜像Q。无匹配或cache背压时，原请求Q正常接受一次，不要求重试。
LSU使用query occupied Q而非取消后的valid选择宽payload；真正物理fire才迁移owner。
D-cache普通cached store可在请求接受边沿直接进入WRITE并登记tag读；
成功B后才更新正确驻留way，错误B保留缓存数据并返回精确终端。
Split子写仍保持逐次B响应和错误偏移聚合。

PhysicalMemory内部解释CPU/PTE source，D-cache store终端在服务内部校验来源再回送CPU token。
LSU无需知道cache source高位，也不接触D-cache内部idle/hint。
普通idle、drain_idle、irrevocable有不同用途：没有可执行指令不代表所有外部owner已排空，
外部事务排空也不意味着允许跳过精确退休。

## 6. 各团队的开发与联调入口

1. 先确定本域拥有的状态和公开字段，按上述record及fire语义实现。
2. 本域测试用mock peer驱动公开端口；取消、背压、generation/token复用是必测边界。
3. 只编本域source closure，再在集成中检查原子birth、统一退休和precise trap。
4. 改公共位布局或事件语义时同时更新协议头、生产端点、mock/oracle投影和合同测试。
   域内结构可以独立替换，不要求其他团队配合内部信号命名。

在Ubuntu工作区执行：

    make -C npc/rv64/testbench/chengyue64 domain-lint
    make -C npc/rv64/testbench/chengyue64 domain-run
    make -C npc/rv64/testbench/chengyue64 domain-lint-execution
    make -C npc/rv64/testbench/chengyue64 domain-lint-translation

domain-lint分别elaborate八个端点，只用各自显式依赖，采用整核相同严格lint/断言设置。
domain-run 编译十个独立测试，不携带全核filelist；除 RecoveryInbox、MemoryEffectLease、ExecutionOwners、ResponseIngress 四个边界合同外，还覆盖：
Execution、Control、TranslationService、FP、Frontend及LSU网络。
测试源与规则见 [domain-tests.mk](../testbench/chengyue64/domain-tests.mk)。
集成检查继续使用既有模块回归、system-run、system-throughput；它们不能替代独立端点背压测试。

## 7. 结构验收与验证边界

实际消除的组合依赖包括：全局 Recovery → Memory/FP/Frontend 内部控制；
Control 当前 head/effect → LSU 副作用选择；Execution → ROB → Execution 提前供值查询；
LSU 内部多 owner 并集 → ROB 槽复用；Backend want → Memory lane-rank → Backend birth；
incoming response/kill → 完成宽 payload 选择。

LSU 的 R64LsuResponseIngress 每 lane 三个固定槽，物理握手时同时登记完整tag、raw payload和live。
捕获后的下一边沿即可进入完成队列；无新信息的独立分类等待已删除。
物理输入不能组合旁路至完成队列，数据选择仍只读取驻留Q。
六源 R64LsuCompletionArbiter 只按 registered occupied 和 RR 状态选择宽 payload；
live/kill 只决定是否发布完成，允许第二个物理端口独立 fire=10。
取消的普通 RAM load 在 ingress 满时可走只读已登记 dead 状态的 discard 终端，绝不成为完成旁路。

这些边界不意味着所有本域组合路径已满足目标周期；真实综合和 STA 仍要检查本域仲裁、
地址/数据通路、时钟门控和 I/O 路径。验证须使用新 RTL 模型，包含域合同、整核 DiffTest、
软件与 L2 all；Tensor/NPU 和 L3 排除。旧版周期一致性/STA 不能作为本轮重构的测试结果。

前端 BUNDLE_EMPTY_FLOW 与 TOKEN_EMPTY_FLOW 各自保持旧 owner 优先和 Q-only 信用。
空队列可把上游本次实际捕获的完整 owner 送入有寄存容量的下一级，成功才省去本级入队；
受阻时原样保存 raw/length/fault/tval/plan、canonical、prepared 控制和本沿 old-Q 预测表快照。
原 Align capture 仍独占消费和 barrier；RAS 仍仅由唯一 result_capture 推进。
两项同时启用只缩短 Align→Result 的无等待路径，Result owner、部分消费和恢复语义不变。


### 首次查询调度、分支完整值接收和后继 store 许可（第十三批）

INIT_CURRENT_READY 使用 birth 同沿登记的 IQ row、src/fp 和固定查询口身份，在下一沿直接消费 Scoreboard 的寄存 ready。effective_ready 同时用于选择和 pending 输出；promise 或实际数值通知不被当作 PRF ready。原有效位、年龄、资源、串行依赖、取消和实际接受协议保持不变，独立 accepted-birth ledger 检查完整身份。

RR_COMPLETE_BRANCH_ADMIT 依赖完整值接收和 native payload，只在旧 ingress 空、terminal 有寄存信用、全部整数源具有真值时，把分支写入原 terminal。B/J/I 立即数与分支控制来自本次 canonical 指令；Execute 的分支仲裁、PC+LEN、JALR bit0 和恢复权威保持原有归属。

ORDINARY_SUCCESSOR_STORE_LEASE 以当前 ROB 寄存的头两项为候选，允许 NORMAL/BRANCH/LOAD/STORE 前驱。在实际单退休、无恢复且副作用许可有效时，为未完成的非串行、非写寄存器 STORE 登记下一拍 lease。它不依赖前拍 hint，不提前授权年轻物理访问；真实 B 错误、load 错误、Trace 背压和取消仍阻止后继外部副作用。

三个参数在通用模块默认关闭，在 CoreTop 显式开启。原 IQ 零发射和实际 Execute 统计口径不变；reason3 的初始化等待分类仅在 INIT_CURRENT_READY 关闭时适用。


### 写传输的空队列路径（第十四批）

R64AxiWrite 的 CMD_EMPTY_FLOW 仅投影实际接受的内部 command；旧 AW descriptor 与旧 W stage 优先，命令信用仍只来自寄存容量。AW 和首 W 各自发生真实握手才省去对应捕获，受阻时保存在原队列。W 不依赖 AWREADY；FIRST_W_CAPTURE=0 保持原 W 路径。B 仍须匹配已存在的 busy owner 和实际 AW/W 完成，当前新命令不能冒充 B owner。参数关闭时包括无效载荷在内的输出保持原寄存来源。

R64AxiFabric 的 AW_EMPTY_ADMIT 在 AW skid 为空时，把本次实际接受的完整 descriptor 交给原 owner admission。地址范围、对齐、页界、burst、重复 ID 与队列容量检查使用同一个 effective descriptor；失败则捕获原 skid。外部 AW/W 继续由寄存 owner/mask 驱动。

WRITE_B_EMPTY_FLOW 只在 B holder 为空时发布现有 terminal 或实际收到的最后一拍 Lite B。候选优先级与原仲裁相同，当前末 B 的错误与此前累计错误按原 OR 规则合并。上游阻塞时捕获 holder，完成接受时只释放对应完整 owner；下游 BREADY 保持原寄存资格，不依赖上游 READY。坏描述符当前终结仍走原捕获。

三个参数在通用模块默认关闭，Core writer 和 Platform fabric 显式开启。真实端点 B 响应时序、成功条件和错误处理不变。

N2 的 LOAD 前驱包含非原子 MMIO load。ROB 退休与 Memory 本地退休相隔一拍；只有 RETIRE/effect、翻译和物理事务已排空、完整 tag 匹配实际 local retire 的 store/MMIO load 在这一沿离开 ROB-live 模年龄参考。下一沿仍强制检查 alive/effect 已清零；错误 generation、无 local retire 或未排空都不能获得该参考排除。该补充仅改变仿真检查范围，不改变功能 RTL。

### 翻译响应与逐字节转发查询（第十五批）

RESPONSE_FORWARD_QUERY 在通用 Memory/LoadStore/LSU 默认关闭，CoreTop 显式开启。
已有 descriptor 的 registered occupied 独占 matcher，包含本沿被取消但仍占用的 owner；
lane0 的 prepared payload 也保留优先。空 matcher 才可选择当前翻译响应对应的完整 canonical
身份、PA 和已登记 older 位图，并复用原逐字节最年轻 store 选择网络。

只有真实成功的普通对齐整数 load 翻译响应、无旧 ordering barrier、具有原 query Q 信用，
且没有其他 direct/C1 owner 时才能发布新 query。全匹配、部分匹配和无匹配均先保存到原 query Q；
不增加翻译响应到物理服务的新直通。trans_end 仍唯一驱动该 owner 的状态转换。
实际入队保存的 byte winners 并集同时参与本沿 source pin，成功完成 store 与精确 local commit
同拍时仍保留被引用字节，直到消费者读完。source slot 新 allocation 继续清除旧年龄关系。

真实 Berror 同拍时，只要新 query 的实际 winner 包含错误 source，就禁止该次入队并回落原路径；
被更年轻 store 完全覆盖的错误 source 不属于实际 winner，不阻止独立 query。
此 guard 只保护本次新引用；已有 resident 引用由 LSU 本地 source pin 保护。
取消、错误、无信用与背压都不改变宽 payload 的占用者选择，也不借本沿 pop 信用。

定向开关/取消/持有矩阵覆盖 full/partial/no-match、同沿 source commit、tag/slot 复用、
双 lane 和精确错误 source。局部翻译响应到 query 捕获 1→0 拍，到物理接受 2→1 拍，
全转发 canonical completion 4→3 拍；整核收益仍以固定自然终止程序和真实 DiffTest 为准。

### 错误 store 的引用生命周期

实际 live narrow store 的 Berror 结束外部/effect 所有权，并照常发布原错误 completion。
若仍有 descriptor/query 引用其字节，源行转入 PINNED，alive/effect 清零而字节保留；
最后一次引用读取或取消后才恢复 FREE。错误完成队列背压不影响该本地存储责任。
这使 source 存储安全不再依赖 Core 在错误后的下一沿阻止新 birth；Core 的精确异常、
恢复接收和年轻副作用约束仍独立保留。原子与其他响应类型沿用各自既有生命周期。

独立 LSU 公开接口反例覆盖 Berror、延迟恢复和新槽分配：旧实现允许复用仍被引用的源槽，
新实现禁止该复用并允许使用其他真正空闲槽。引用自然读完后还验证源槽再利用和最终 load 数据；
整核检查保留 run_i 到恢复/引用排空，实际 B、trap、Memory 本地 flush 延迟不变。


### 双退休后的 store 寄存许可（第十六批）

DUAL_RETIRE_STORE_LEASE（N3）在 ROB/Backend/Control/MemoryEffectLease 通用模块默认关闭，
CoreTop 在 Backend 与 Control 显式开启。跨域只增加 pair_store_candidate_valid 和
pair_store_candidate_tag[8:0]；ROB 保留 owner、META 和代际的唯一事实源，
Control 拥有退休接受与 lease，Memory 拥有物理请求。该候选不是许可或新的事务 owner。

ROB 以 head+2 的第三个驻留项产生候选。完整 tag 只来自已登记 generation 与 slot；
有效性要求至少三项、该项是未完成、无异常、非写寄存器、非串行的普通 STORE，
且没有 freeze、有效 kill 或该项本沿真实 completion。META_W 小于 204 时有效性固定为零。
同沿第三条 birth 不属于驻留候选；过时代际的 WB 不能取消当前 owner 的资格，
真正接受的成功或错误 WB 均使本沿候选无效。

Control 保留 N1/N2 的单退休路径，新增路径只接受 retire_fire=11 的真实稠密前缀。
两条前驱均须属于 NORMAL/BRANCH/LOAD/STORE，非串行且无异常，第一条 tag 必须匹配
当前 canonical head，同时原 effect_allow 有效、无 recover/full flush。
候选只选择下一拍 lease 的 D 输入，不改变本拍 Memory 的寄存授权。
lease 安装、完成清除及普通 head 授权的原优先级保持不变；下一拍断言核对新 lease 与真实
新 ROB head 的完整 tag。IRQ pending 保留现有精确排空语义，不额外阻挡已驻留的合法退休。

未绑定 store 可以持有 lease，但仍须等待真实 bind、翻译及原物理请求条件。
Trace 背压、旧 store 实际 Berror、第三条同沿 fault、后缀恢复与全 flush 均不能越过上述条件。
定向真实 ROB→Control→LSU→PhysicalMemory→AXIWrite 链中，
已准备好普通 store 的双退休到物理接受从 2 拍降为 1 拍。
该局部延迟不代表所有双退休周期均可节省，也不替代完整程序零发射与 DiffTest/L2 验收。

### 绑定时的翻译接受与方向预测配置（第十七批）

BIND_TRANSLATION_EMPTY_FLOW 与 BIND_STORE_TRANSLATION 在通用 LSU/LoadStore/Memory 默认关闭，
CoreTop 默认开启。前者只在旧 translation holder 的 occupied Q 为空时，把原仲裁已接受的
普通对齐整数 bind 候选交给翻译服务；旧 holder 即使正在被取消也保留载荷优先权。
VALID、候选选择和 Q 信用不依赖翻译 READY。真实接受才省去入队；受阻时 slot/tag、保护信息
进入原队列，VA 写原 canonical 行，下一拍继续同一请求。tr_issued 在 bind 初始化之后按
真实服务接受设置，不能因 bind lane 与翻译 lane 不同而丢失租约；响应仍由原服务延后一拍返回。

后者允许普通对齐整数 store 使用同一热绑定路径。这里只提前翻译地址，不能产生物理写入许可；
store 的 A/D 更新仍要求原 head/effect 授权。非 head store 遇到需要 A/D 更新时保留 head replay，
FP、atomic、unaligned 和 trigger 访问保留原路径。取消、错误、响应排空和完整 tag 认证不变。
独立配置测试覆盖服务背压、lane 重映射、Sv39/PMP/MPRV fault、真实 A/D CAS 和 token 复用。

方向表使用 DIRECTION_INDEX_W 参数，通用 Predictor/Frontend 默认 8，Core 默认 10；
索引始终来自 PC 的对应低位。DIRECTION_COLD_STRONG 在通用模块默认关闭，Core 默认开启，
只在无效行首次训练时按实际方向初始化为 11/00；后续仍使用原两位饱和计数器。
查表与捕获仍观察训练前的旧 Q，已持有的预测 token 不受随后训练影响。

DIRECTION_COMMIT_TRAIN 是经过定向验证的可选配置，当前 Core 默认关闭，方向表继续按原
已认证 resolve 更新。开启时 Backend 用 ROB slot/generation 保存非 owning 的方向事实，
仅真实退休产生两路无 READY 公告；同一表项的双退休按 lane0→lane1 顺序折叠。
indirect target、RAS 与架构 redirect 仍使用原路径。invalidate 同时清除表和边界上的待发公告，
未退休记录保留；公告不会阻塞退休、恢复或槽位复用。两个组合短程序均以关闭该选项略快，
故没有把单独实验中较少的误预测数当成启用依据。

### 登记后统一应用的后缀恢复（第十八批）

BATCH_SUFFIX_ROLLBACK 在 ROB、Rename、ExecutionDomain/Scoreboard、Backend 通用模块默认关闭，
Core 默认开启。ROB 是后缀成员集合及 rename 描述符的唯一来源：实际接受且 fulltag 匹配的
kill 仍在原边沿发布，立即取消年轻 ROB valid/done，并把 victim mask 与年龄起点登记。
被取消行的 rename 元数据在恢复期间仍属于这个集合，不能因 valid 已清零而丢弃。

下一没有新 accepted kill 的沿产生一次 batch_apply。跨模块记录包含 mask、年龄起点和
逐行 {pold, pnew, arch[4:0], fp, write}，其中 descriptor 宽度为 7+2*PREG_W；
它不是新的事务 owner。Rename 对固定物理行并行解码，按登记 head 将有效行分成
head 及其后的区间和回绕区间，用平衡选择树给每个架构寄存器选择循环年龄最老 victim
的 pold；各物理目的另以并行归约释放所有 victim 的 pnew，同一架构寄存器的中间
WAW 目的也须释放。该组合表达不改变 batch_apply、取消优先级和恢复所需拍数。
GPR x0 不参加，FPR f0 与物理 FPR 0 按正常资源处理，committed map 不变。

Rename 同时输出精确的 GPR/FPR reclaim 位图，Execution 的 Scoreboard 在同一 apply 沿清 busy，
不再经过 RecoveryInbox。原 source fence、本地取消接收、LSQ/Serial reuse block 与迟到 WB 的
fulltag 认证保持。恢复期间禁止新 birth 和 retire，但合法较老 WB、真实 store 终端仍可完成。

若 actual older kill 与 apply 同沿到达，整批 apply 延期，原 mask 与新 suffix 合并；
失配 generation 的 raw kill 不得延期。fullflush 丢弃 pending batch，沿用原 committed-map 恢复。
旧串行模式及原逐拍 oracle 保留；新的独立 birth ledger 按年轻到年老逐条撤销后比较
map、committed map、free 与 busy，避免把 DUT 的 winner 网络当作参考模型。

### 早期块目标表的容量（第十八批）

FTB_INDEX_W 在 FetchStream/Frontend 通用模块默认 5，Core 默认 7，对应 32/128 项。
只重新分配原 PC[24:4] 签名：index=PC[FTB_INDEX_W+3:4]，
tag=PC[24:FTB_INDEX_W+4]，不改变高地址别名策略、每块一个 offset/target 或训练优先级。
请求仍捕获旧 Q 的 68 位 plan，已经接受的请求、packet、Token 与 Result 不读取后来的表状态。
Frontend 的 pending_source 索引同步扩宽；跨块 selected_next 修正仍使用原计划来源。

容量配置不增加 owner、取消应答、READY 反馈或新的恢复生命周期。定向 5/7/8 配置覆盖高行
repair、替换后的持有快照、跨块指令与原 32 项逐拍等价；较少的表冲突只有在完整程序
周期和实际执行改善时才构成收益。

### 驻留串行退休资格与独立写响应资格（第二十批）

ROB 新增 serial_retire_candidate_o，经 Backend/CoreTop/Control 直接交给 Commit。
该单 bit 是与原 commit_tag lane 0 配对的同拍资格，不保存身份、不创建 owner、不使用 READY：
!freeze && count!=0 && valid[head] && done[head] && !exception[head] && serial[head]。
Commit 只加入原 active（无 reset、待处理 event、recover）与 Trace lane 0 ready，
再沿原 serial_commit/tag 接口授权 Serial；普通 retire_fire、异常投影和双退休逻辑保持。
独立开发的 Commit/Control mock 必须显式提供其原 lane 0 的同一资格，不能悬空或以
当前 Serial result-valid 替代。生产路径由 ROB 的驻留状态提供，测试中检查新资格等于
原 commit_valid0 && !commit_exception0 && commit_serial0，以及实际 serial_commit 等式。

窄 store_done 接受在原协议中要求 !serial[head]，故普通 store 的当拍完成不能改变串行
退休资格。Serial 仍以 held full-tag 匹配和登记 retire_effect 在原退休边沿产生 CSR、
xRET、FENCE.I/SFENCE 效果；新资格不提前写回，不绕过 Trace 背压、恢复或精确异常。

AXIWrite 对 B owner 的资格使用 busy/b_seen 及已完成 AW/W 状态；需要同拍完成时，
只检查驻留 AW descriptor 和 W stage 的真实握手。新 cmd 只能占用 free client，
与 B 要求的 busy client 互斥，因此当前新命令的空通道直通不参与旧 B 资格。
旧 AW／末拍 W 与 B 同拍完成、B 空队列直通、错误与响应背压均保留。

Dcache 的 direct_store 直接表达原 IDLE、无 store_active、empty、无特殊等待/失效/复位
及输入有效且为 cacheable store 的接受条件。通用 ready 的 overlap 分支仅接受 load，
不再进入新 store 命令的资格锥；原通用 ready/take、load overlap、owner 状态和接受边沿不变。
上述表达调整均不增加寄存器或流水等待，物理效果仍由原 owner 和真实接受边沿约束。

本轮核查的公开设计参考：[BOOM ROB/Commit](https://docs.boom-core.org/en/latest/sections/reorder-buffer.html)
把驻留 valid/busy/exception 与 head 提交条件分别描述；
[Chipyard BufferParams](https://chipyard.readthedocs.io/en/latest/tilelink-diplomacy-reference/widgets/#tlbuffer)
明确说明 flow 会组合连接 valid、pipe 会组合连接 ready。
由此用于本核的设计判断是：模块和队列边界自身不足以保证时序隔离，空槽直通应限制在
确实属于同一事务的资格范围。本批的具体等价条件来自本核的 free/busy 与非 Serial store
不变量；本核仍保留原真实 B 返回、精确异常和退休协议。

[BOOM v2 论文](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2017/EECS-2017-157.pdf)
第 3 节根据实际综合及布局布线结果定位 issue-select、rename 和 register-read 路径；
论文也报告增加延迟后部分工作负载 IPC 降低。用于本阶段的经验是将真实关键路径分析与
完整程序周期同时验收；本批仅改组合表达和资格边界，以保留已达到的吞吐结果。
