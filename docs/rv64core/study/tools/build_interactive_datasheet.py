#!/usr/bin/env python3
"""生成单文件、离线可用的 RV64 Core 交互式 datasheet。

数据真源：

1. ``11-逐文件源码地图.md``：150 个 vsrc 文件的身份和教学解释；
2. Verilator ``NpcTop`` XML：真实 elaborated instance hierarchy；
3. 当前 ``npc/rv64/vsrc``：module、ANSI port 和 posedge 状态块；
4. 00–10 章中的 WaveDrom JSON：时序教学图；
5. WaveDrom 3.6.2 浏览器 runtime/skin：内嵌渲染，HTML 不依赖 CDN。

生成物 ``docs/rv64core/study/index.html`` 是可直接双击打开的单文件文档。
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from typing import Any


SCRIPT = Path(__file__).resolve()
STUDY_ROOT = SCRIPT.parents[1]
REPO_ROOT = SCRIPT.parents[4]
VSRC_ROOT = REPO_ROOT / "npc" / "rv64" / "vsrc"
NPC_MAKEFILE_PATH = REPO_ROOT / "npc" / "rv64" / "Makefile"
PRODUCT_DEFAULTS_PATH = (
    REPO_ROOT / "npc" / "rv64" / "configs" / "product-rtl-defaults.mk"
)
DEFINE_PATH = VSRC_ROOT / "include" / "define.v"
ATLAS_PATH = STUDY_ROOT / "11-逐文件源码地图.md"
CSS_PATH = SCRIPT.with_name("interactive_datasheet.css")
JS_PATH = SCRIPT.with_name("interactive_datasheet.js")
ELABORATION_SCRIPT_PATH = SCRIPT.with_name("generate_elaboration_xml.sh")
DEFAULT_XML = Path("/tmp/rv64-study-npctop.xml")
DEFAULT_WAVEDROM_DIR = Path("/tmp/rv64-wavedrom-3.6.2")
DEFAULT_OUTPUT = STUDY_ROOT / "index.html"

MODULE_RE = re.compile(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)")
POSEDGE_RE = re.compile(r"\balways(?:_ff)?\s*@\s*\(\s*posedge\b")
NONBLOCKING_TARGET_RE = re.compile(
    r"(?:^|;|\bbegin\b|\belse\b|:\s|\)\s+)"
    r"\s*(?P<target>[A-Za-z_][A-Za-z0-9_$]*)"
    r"\s*(?:\[[^\]\n;]+\])?\s*<=",
    re.MULTILINE,
)
WAVEDROM_RE = re.compile(r"```wavedrom\s*\n(.*?)\n```", re.DOTALL)
HEADING_RE = re.compile(r"(?m)^(#{2,4})\s+(.+?)\s*$")
ATLAS_ROW_RE = re.compile(
    r"^\|\s*`(?P<path>npc/rv64/vsrc/[^`]+)`\s*"
    r"\|\s*(?P<status>[^|]+?)\s*"
    r"\|\s*(?P<description>.*?)\s*\|\s*$"
)
MAKE_ASSIGNMENT_RE = re.compile(
    r"(?m)^(?P<name>[A-Z][A-Z0-9_]*)\s*(?:\?|:)?=\s*(?P<value>\S+)\s*$"
)

EXPECTED_STATUS_COUNTS = {
    "Top": 124,
    "Sim": 6,
    "Check": 3,
    "Catalog": 3,
    "Header": 9,
    "Doc/Build": 5,
}

CATEGORY_LABELS = {
    "bus": "SoC 总线",
    "cache": "缓存",
    "common": "事实 ABI",
    "control": "控制与恢复",
    "core": "集成与架构状态",
    "debug": "验证与观测",
    "decode": "译码",
    "execute": "执行",
    "frontend": "取指前端",
    "include": "全局定义",
    "memory": "访存 / MMU",
    "pipeline": "流水构件",
    "regread_bypass": "寄存器读取",
    "rename_allocate": "重命名与分配",
    "scheduling": "调度",
    "sim": "仿真集成",
    "sram": "SRAM",
    "writeback": "完成与退休",
    "root": "目录入口",
}


RICH_MODULE_META: dict[str, dict[str, Any]] = {
    "NpcTop": {
        "summary": "SoC 生产顶层：把 NpcCoreTop 的 IFU/LSU AXI 主口接入总线、CLINT、PLIC、UART、syscon 与默认从设备。",
        "features": [
            "生产系统的 elaboration 根；平台设备与 Core 在此汇合",
            "Core 与设备通过 AXI transaction 交互，不在此执行 OoO 调度",
            "中断 pending 与 Core 精确 trap 是两个不同时间域",
            "适合从 SoC 地址空间向下钻取，不适合作为指令生命周期起点",
        ],
        "boundary": "NpcTop 负责系统连接和平台副作用；指令身份、ROB 顺序与 speculative state 属于 NpcCoreTop 内部。",
        "invariants": [
            "设备侧 pending 不能直接等价为已发生 trap。",
            "错误地址必须由 default slave 结束 transaction，不能永久悬挂。",
            "Core/SoC AXI 握手一旦 handoff，内部 flush 不能撤回外部 transaction。",
        ],
    },
    "NpcCoreTop": {
        "summary": "完整 RV64IMAFDC 双发射乱序 Core 的集成边界，连接取指桥、双数据桥、LSU lane 适配、CSR 和 OoO 主体。",
        "features": [
            "RV64IMAFDC + Zba/Zbb/Zbc/Zbs，M/S/U 与 Sv39/PMP",
            "每周期最多 dispatch 两条、整数 issue 两条、全局 completion 两条、顺序退休两条",
            "独立 IFU AXI 与共享 LSU AXI 出口；数据侧内部为双 memory lane",
            "产品默认 OOO_CSR_QUEUE_HEAD=1：合法非 FP head0 CSR 走 ROB 队头提交，lane1/FP CSR 保留 pending full-drain",
            "提交、trap、exit、debug 与性能观测均在顶层形成稳定接口",
            "生产实例真实包含 OooDualMemBridgeWrapper，不采用旧文档的“未实例化”结论",
        ],
        "boundary": "NpcCoreTop 只做 Core 级集成。前端 packet、rename、IQ、ROB、LQ/SQ/MIQ 和 pending control owner 分别由子模块持有。",
        "invariants": [
            "取指与数据 AXI transaction handoff 后只能 drain，不能被 Core flush 撤回。",
            "完成结果与架构提交分离；commit 才允许更新体系结构可见状态。",
            "双 memory lane 并不等价为两条独立外部 AXI，总线 miss/PTW/write 最终共享仲裁出口。",
            "旧 README/filelist 只能说明历史演进，当前实例关系以 Verilator XML 和端口连接为准。",
        ],
    },
    "OooCoreTopGlue": {
        "summary": "OoO 微架构主体的粘合层，把前端、执行后端、双访存接入、控制域与最终 writeback/commit 接成完整 transaction 网络。",
        "features": [
            "直接包含 OooFrontend、OooExecuteBackend、OooControlPlane、双 OooMemoryAccess 与 OooWriteback",
            "跨子系统信号在这里汇合，但队列状态仍归各 owner",
            "full-flush request 与 apply 由独立 sequencer 明确分拍",
            "适合从顶层功能拓扑进入每个 OoO 子系统",
        ],
        "boundary": "该层负责跨子系统连接与少量边界寄存；不要把所有 wire 都解释成它拥有的状态。",
        "invariants": [
            "同一 transaction 的 identity、valid 和 payload 必须跨边界同步。",
            "控制 request 与 apply 不能画在同一相位。",
            "memory0/memory1 是两个具体实例，不能只用“×2”掩盖各自 owner 路径。",
        ],
    },
    "OooFrontend": {
        "summary": "取指 packet、RVC 拆分、预测、FIFO、head-time 分类、双槽 admission 和 redirect 接线的前端聚合模块。",
        "features": [
            "4-entry fetch-packet FIFO，每项原子携带最多两个 slot",
            "无 response→dispatch 组合 bypass，也无 full+pop look-through",
            "生产 DecodeStage 为 2 个；OOO_ASSERT reference 不属于额外生产 lane",
            "gshare/local 混合方向预测与 32-entry RAS",
            "redirect 后旧响应由 discard token 物理消费但禁止进入 FIFO",
            "产品默认下，head0_csr_inflight 在 CSR 离开 FIFO 后继续拥有 stop，直至 C0 commit/kill",
        ],
        "boundary": "前端决定哪些指令槽可见并形成 dispatch 候选；rename/ROB/IQ 资源真正分配发生在后端 dispatch 边沿。",
        "invariants": [
            "fetch response 必须先进入 packet FIFO，下一周期才由 registered head dispatch。",
            "mandatory pair 任一资源不足时不能偷偷拆分；只有显式 optional lane1 才允许 lane0 单独前进。",
            "redirect 更新 PC 的边沿与下一拍新 request 分离。",
            "旧 IFU response 不是用 data-side epoch 丢弃，而是 discard_fetch_rsp_q drain。",
        ],
    },
    "OooFetchAxiBridge": {
        "summary": "IFU transaction owner：持有 FPC/ITLB/PMP/PTW、A-bit 更新、packet cache 与 AXI 读写状态。",
        "features": [
            "精确 2-byte fetch frontier，支持 RVC 与跨 segment 取指",
            "4096×199 packet cache 采用同步 SRAM lookup",
            "ITLB/PTW/PMP 与硬件管理 A 位更新共享 IFU transaction 生命周期",
            "flush 后已发 AXI 请求继续 drain，旧响应由 discard owner 接收",
        ],
        "boundary": "该桥负责取指地址翻译、访问与返回；双槽语义和 head-time 合法性由 OooFrontend 处理。",
        "invariants": [
            "AXI AR handoff 后不能因 redirect 撤回。",
            "discard 状态必须消费恰好一个旧响应且不得入 FIFO。",
            "同步 cache lookup 的 request、context 与 hit/response 必须跨拍对齐。",
        ],
    },
    "OooFetchPacketFifo": {
        "summary": "4-entry fetch packet ring 与 registered head shadow 的状态 owner，保存双槽指令、预测和 fault provenance。",
        "features": [
            "容量单位是 packet，不是 8 个可独立调度的 instruction slot",
            "entry 原子携带 slot0/slot1 与共享 packet 身份",
            "registered head 形成清晰的 response/enqueue→dispatch 边界",
            "当前无 full+pop look-through 与 response bypass",
        ],
        "boundary": "FIFO 保存 packet 生命周期；head classify/dispatch gate 只消费 registered head view。",
        "invariants": [
            "full 时即使同拍 pop，也不承诺绕过式 enqueue。",
            "双槽 payload 与 valid/fault/prediction 必须原子更新。",
            "flush 清有效性，不能把旧 payload 误认成新 packet。",
        ],
    },
    "OooExecuteBackend": {
        "summary": "后端结构 wrapper，承接前端 dispatch 与控制/访存边界，内部下接 OooAluCoreSlice。",
        "features": [
            "名字中的 Execute 不代表单拍 EX；内部继续包含 decode、rename、IQ、ROB 与 FP/LSU",
            "保留 pending branch compare 与 OoO core slice 边界",
            "架构 GPR commit 修正在更内层 OooAluCoreSlice 汇合",
        ],
        "boundary": "该模块组织后端层次，具体调度、完成与队列 owner 位于更深子模块。",
    },
    "OooAluCoreSlice": {
        "summary": "聚合 OooAluDecodeBackend 与架构 GPR，连接 raw ROB commit、CSR commit-time 修正和最终退休。",
        "features": [
            "后端译码/重命名/执行与架构 GPR 的边界",
            "commit-time 数据修正只在顺序退休边界生效",
            "OooArchRegFile 只接受已授权的架构提交",
        ],
        "boundary": "物理寄存器 speculative result 与架构寄存器 commit value 在此附近分界。",
    },
    "OooAluDecodeBackend": {
        "summary": "两个 DecodeStage 与 OooIntBackend 的组合适配层；Decode→rename→resource-ready 没有独立流水寄存器。",
        "features": [
            "双路 DecodeStage 组合生成控制、立即数和寄存器索引",
            "dispatch fire 边沿才原子写 RAT/FreeList/Busy/ROB/IQ",
            "不能凭组合 valid 把指令描述成已经进入后端",
        ],
        "boundary": "该层组合准备 dispatch payload；真正状态所有权从 dispatch edge 开始。",
    },
    "OooIntBackend": {
        "summary": "整数 OoO 后端的主要汇合点：IQ/PRF、ALU、分支、MulDiv、CLMUL、LSU、FP、ProducerId 与 completion 在此相遇。",
        "features": [
            "整数 IQ 最多 issue 两条，但物理 issue lane 不是程序 lane",
            "early wake 只更新 IQ sticky-ready；PRF 读取仍是 stored-only",
            "执行结果通过 registered EX forwarding 和授权 completion 汇合",
            "ProducerId 为 generation + ROB index，完整 holder/live-mask 才构成安全合同",
        ],
        "boundary": "执行完成、物理寄存器可见、formal writeback 和按序 commit 是四个不同资格边界。",
        "invariants": [
            "普通 ALU 从 dispatch 到架构 GPR 更新的局部最短路径至少跨 3 个后续上升沿。",
            "晚到 completion 必须通过完整 ProducerId 和 live-mask 授权。",
            "分支 resolve 是控制/恢复事件，同时仍需对应 EX0 formal writeback 使 ROB entry 完成。",
            "physical issue0/issue1 不能解释成固定的程序 lane0/lane1。",
        ],
    },
    "OooDispatchBackend": {
        "summary": "重命名、FreeList、BusyTable、ROB 与整数 IQ 的原子 dispatch owner。",
        "features": [
            "双路资源许可、WAW/WAR 消除与 ProducerId 分配",
            "同拍 lane0 写、lane1 读时 lane1 必须看到 lane0 新映射",
            "dispatch fire 沿原子更新所有 speculative bookkeeping",
            "IQ 无 dispatch bypass，新 entry 下一周期才参与选择",
        ],
        "boundary": "组合 rename 候选只有在 dispatch fire 时才成为真实硬件状态。",
        "invariants": [
            "任一必需资源不 ready 时，mandatory pair 不能部分写入。",
            "lane0 未 fire 时，lane1 不得消费 lane0 的候选物理寄存器分配。",
            "RAT、FreeList、Busy、ROB 和 IQ 必须同生同灭。",
        ],
    },
    "OooIntIssueQueue": {
        "summary": "整数发射队列 owner，保存 uop、ProducerId、源就绪 sticky 状态并选择最多两条可执行项。",
        "features": [
            "新 dispatch entry 下一周期才参与 select",
            "early wake 改 sticky-ready，不把数据写入 PRF",
            "选择必须服从资源冲突、lane 能力与 strictly-younger kill",
        ],
        "boundary": "IQ 只决定执行资格；执行结果和 completion owner 属于后续 EX/long-op/LSU。",
    },
    "OooFpBackend": {
        "summary": "独立 FP RAT/FreeList/IQ8/PRF64、短流水、长迭代、raw wake、8-entry done FIFO 与 formal FPWB 的总 owner。",
        "features": [
            "FADD/FMUL/FMA 内部深度分别为 2/3/5，并统一对齐 metadata stage5",
            "FP div/sqrt 约 56 次迭代，busy 期间为单 owner",
            "raw result 可先写 FP PRF/wake，再进入 done FIFO 等待 formal FPWB",
            "架构 FPR 与 fflags 只在 commit 更新",
        ],
        "boundary": "FP 算完不等于 ROB done；done FIFO 的 formal writeback 是精确完成桥梁。",
        "invariants": [
            "ProducerId、destination、precision、rounding 与 fflags 必须穿过全部 FP 流水级。",
            "done FIFO 满或 formal FPWB 仲裁反压时，raw result 不能丢失或重复。",
            "branch kill 命中长操作 ProducerId 后，晚到 done 不得取得 completion 资格。",
        ],
    },
    "OooDualMemBridgeWrapper": {
        "summary": "两个 OooMemAxiBridge、两个 DTLB/D-cache 与共享 OooDualMemAxiArbiter 的生产包装层。",
        "features": [
            "数据侧两个 memory bank 可并行接收内部 transaction",
            "每 lane 具有独立 DTLB、PMP/PMA/classifier 与 write-through D-cache",
            "cache miss、PTW 和写 transaction 最终共享一条 LSU AXI 出口",
            "共享 arbiter 在 transaction 完成前锁定 owner",
        ],
        "boundary": "双 bank 是内部并行边界；不能外推为两个独立外部 memory system。",
        "invariants": [
            "共享 AXI owner 在 terminal 前不能被另一 lane 抢占。",
            "AW 与 W 可分离握手，不能假设同拍出现。",
            "flush 不取消已发 raw AXI，只改变返回结果是否仍有架构资格。",
        ],
    },
    "OooMemAxiBridge": {
        "summary": "单个 data-memory lane 的翻译、PMP/PMA、D-cache、PTW 与 AXI transaction owner。",
        "features": [
            "DTLB/PTW、typed PMA/classifier 与 direct-mapped D-cache",
            "Load/Probe 可被 kill；不可撤回 DRAIN transaction 继续到 terminal",
            "Store 使用分离 AW/W/B 通道，B response 才是写 terminal",
            "每个响应携带 owner kind/token/epoch，防止认错晚到 transaction",
        ],
        "boundary": "该桥负责物理访问和 terminal response；程序序 Load/Store 精确性由 LQ/SQ/ROB owner 共同约束。",
    },
    "OooMemoryAccess": {
        "summary": "Issue/response 侧 memory lane wrapper，连接请求 gate、LSU 变换、MIQ/LQ/SQ 与外部 bridge 接口。",
        "features": [
            "生产层次中有 memory0/memory1 两个具体实例",
            "请求、返回、owner token 与完成授权必须保持 lane 身份",
            "memory response 不直接等价为架构提交",
        ],
        "boundary": "该层连接内核访存队列与 bridge；AXI 物理协议属于 OooMemAxiBridge，程序序精确性属于 ROB/LQ/SQ。",
    },
    "OooStoreQueue": {
        "summary": "4-entry 程序序 Store owner：allocate/bind/fill/forwarding 后，只允许 SQ/ROB 双头匹配项发物理写。",
        "features": [
            "SQ entry 保存地址、数据、byte mask、ProducerId 与精确释放资格",
            "rob_head_launch_open 才允许程序序 Store 发起物理 transaction",
            "AW/W 可异步完成；B terminal 后才释放 SQ/ROB owner",
            "Store-to-load forwarding 在物理写之前提供年轻 Load 数据依赖",
        ],
        "boundary": "Store 不是“先退休、后台慢慢 drain”；B terminal 是精确完成链的一部分。",
        "invariants": [
            "只有 SQ head 与 ROB head 身份精确匹配时才能 launch。",
            "AW/W 均完成但 B 未返回时，Store 仍未 terminal。",
            "重复或 tuple mismatch response 不能释放 owner。",
        ],
    },
    "OooLoadQueue": {
        "summary": "16-entry Load 生命周期 owner，跟踪地址/执行/返回、依赖、kill 和 terminal。",
        "features": [
            "已 launch 后被 kill 的 Load 仍必须等待物理 terminal",
            "晚到 response 通过 ProducerId/owner token 授权或丢弃",
            "Load completion 与 ROB 顺序 commit 分离",
        ],
        "boundary": "LQ 持有 speculative load 身份；DTLB/cache/AXI 的具体物理访问由 memory bridge 处理。",
    },
    "OooRob": {
        "summary": "16-entry Reorder Buffer，保存程序序身份、done/exception、commit 与 walk/recovery 状态。",
        "features": [
            "全局最多接受两个 formal completion",
            "formal WB 边沿写 done，最早下一周期才可 commit",
            "最多顺序退休两条，commit1 受 head0/head1 异常和控制门约束",
            "产品默认下，head0 CSR 只等待 mem_idle，C0 单独提交并禁止同拍 commit1",
            "异常 entry 可从 head dequeue，但不写架构状态、不计 instret",
        ],
        "boundary": "ROB 是顺序可见性 owner，不计算执行结果；completion 授权来自执行/访存/FP 路径。",
        "invariants": [
            "不存在 formal WB→同拍 commit 旁路。",
            "commit1 不能越过未提交或异常的 commit0/head entry。",
            "queue-head CSR 不能等待 SQ empty/mem_retire_quiet，否则 younger Store 会与 ROB head 形成循环等待。",
            "generation 单独不足以阻止槽复用晚到结果；必须结合 live-mask/exact-open。",
        ],
    },
    "OooWriteback": {
        "summary": "收敛 formal completion、控制提交与 commit 输出，形成最终顺序退休边界。",
        "features": [
            "completion 与 commit 分层，保持精确异常",
            "控制提交 sequencer 把跨拍副作用变成 exactly-once 输出",
            "commit output mux 保证 winner 的 PC/inst/data/exception 同源",
        ],
        "boundary": "writeback 名称包含完成和退休接口，但只有 commit fire 才允许更新架构可见状态。",
    },
    "OooControlPlane": {
        "summary": "queue-head CSR 与 pending SYSTEM、trap/exit、stop/drain、flush、observable event 的聚合控制 owner。",
        "features": [
            "合法非 FP head0 CSR 走 queue-head C0/C1；lane1/FP CSR 与非 CSR SYSTEM 继续走 pending drain",
            "pending SYSTEM/trap/exit 等待 exact mem_owner_terminalized",
            "普通 FENCE 额外等待完整 mem_idle",
            "head0_csr_inflight 与 pending holder 分别保存两条互斥串行化路径的 owner",
            "trap > branch > direct 的平龄 redirect 优先级在独立 arbiter 收敛",
        ],
        "boundary": "控制域决定何时阻塞、排空和应用全局事件；普通 branch recovery 仍以 issue resolve/ROB age 为核心。",
        "invariants": [
            "ROB empty 不能替代 older memory holder 的 terminal。",
            "head0 CSR 的退休门只看 mem_idle；不得把 mem_retire_quiet/SQ empty 重新并入。",
            "request、apply、clear 与 no-repeat 必须按 C0/C1/C2 跨拍。",
            "已 handoff 的 memory/AXI transaction 不被 full flush 撤回。",
        ],
    },
    "OooCsrAccessRequestMux": {
        "summary": "CSR 访问选择器：区分 queue-head commit、pending CSR exact claim 与无副作用 legality probe，并形成 CsrFile 请求。",
        "features": [
            "head0_csr_commit = 产品宏开启的 commit0 CSR 且没有 pending exact claim",
            "queue-head 路在 C0 使用 commit0 instruction 与架构 GPR rs1",
            "lane1/head legality probe 与 main access 分开，probe 不得写 CSR",
            "pending CSR 用完整 ProducerId/PC claim seal，不能只凭全局 pending level",
        ],
        "boundary": "该模块选择/组织 CSR request，不保存 CSR 架构状态；状态写入由 CsrFile 在精确边界完成。",
        "invariants": [
            "queue-head 与 pending CSR commit 必须互斥，不能双写同一 CSR。",
            "commit-time old CSR value 才是架构 rd 数据，dispatch placeholder 不可直接提交。",
            "probe valid 不能成为 side-effect enable。",
        ],
    },
    "OooStopPendingSequencer": {
        "summary": "串行化 stop 的单寄存 owner，统一保存 pending holder lease 与 queue-head CSR inflight 生命周期。",
        "features": [
            "head0 CSR birth/inflight 使 stop 在 CSR 离开 FIFO 后继续保持",
            "head0 CSR C0 commit、exact pending CSR terminal、kill 或 reset 清 owner",
            "pending holder live 与 CSR exact lease 的保持优先级显式编码",
        ],
        "boundary": "它只保存“存在 serialization owner”这一位；具体 kind、ProducerId 与 payload 由 pending holder 或 head0 CSR owner 保存。",
        "invariants": [
            "head0_csr_inflight 且未被 kill 时，stop_pending 不得出现空洞。",
            "C0 commit 后必须释放 stop，否则新路径永远不能 dispatch。",
            "orphan stop 没有 live owner 时必须 fail-loud，不能永久冻结前端。",
        ],
    },
    "OooControlCommitSequencer": {
        "summary": "控制类伪提交与 serial-flush 的注册 owner；产品默认 head0 CSR C0 commit 在此变成 C1 单周期 serial_flush。",
        "features": [
            "head0_csr_commit 在当前边沿被采样，serial_flush_q 下一周期可见",
            "pending jump/system/branch 的 control commit payload 在同一明确优先级链中保存",
            "输出必须是一拍 terminal，不允许 level 重放",
        ],
        "boundary": "它产生注册控制提交/flush，不决定 queue-head CSR 的 mem_idle 资格；该资格由 ROB C0 门控。",
        "invariants": [
            "C0 head0_csr_commit 与 C1 serial_flush 必须一一对应。",
            "C2 serial_flush 必须回低，否则会重复 flush 已进入的新路径。",
            "控制伪提交不能与 raw ROB lane1 组合成越序架构效果。",
        ],
    },
    "OooControlEventApplySequencer": {
        "summary": "把 full-flush request 的 reason/kill-index 注册一拍后形成 apply 的时序 owner。",
        "features": [
            "request 与 apply 明确分拍",
            "reason、kill-index 和 valid 同步锁存",
            "exactly-once 需要检查 apply 后 clear 与 C2 no-repeat",
        ],
        "boundary": "该模块只负责事件应用时相；事件优先级和触发资格来自上游控制域。",
    },
    "CsrFile": {
        "summary": "机器/监管态 CSR、trap entry/exit、特权模式与计数器等架构状态 owner。",
        "features": [
            "M/S/U 特权状态、mstatus/sstatus、satp、tvec/epc/cause/tval",
            "queue-head CSR 在 C0 组合读取旧值并提交写副作用；pending CSR 仍由 full-drain 路授权",
            "CSR access、异常提交、中断与 xRET 存在明确同拍优先级",
            "mtime/irq 是输入条件，trap 只在精确边界更新架构状态",
            "fflags/frm 与浮点提交协同形成架构可见 FP 状态",
        ],
        "boundary": "CSR file 保存架构状态，但 pending/drain 与 redirect apply 生命周期由控制面持有。",
    },
    "AxiXbar": {
        "summary": "2-master/16-slave single-outstanding AXI 子集互连，读写通道独立仲裁并为 R 通道设置注册响应切片。",
        "features": [
            "每 slave round-robin 仲裁",
            "AR/R 与 AW/W/B 生命周期分离",
            "AW 与 W 分别 capture，禁止用单一 write-fire 简化",
            "R response 经过 registered slice 后返回 master",
        ],
        "boundary": "Xbar 负责总线 owner 与地址分发，不理解 ROB、ProducerId 或精确异常。",
    },
}


TRANSACTIONS: list[dict[str, Any]] = [
    {
        "id": "instruction-life",
        "title": "一条整数指令的一生",
        "shortTitle": "指令一生",
        "kind": "FETCH → DISPATCH → ISSUE → COMPLETE → COMMIT",
        "summary": "从取指 packet 到 rename/ROB/IQ，再到执行、formal completion 和顺序退休；展示“算完”与“架构可见”之间的资格链。",
        "initiator": "OooFetchAxiBridge / frontend request",
        "owner": "packet FIFO → IQ/ROB → EX holder → ROB head",
        "terminal": "commit fire；异常项只做精确 trap/dequeue，不执行普通架构写回",
        "backpressure": "FIFO、dispatch resource、IQ select、completion port 与 ROB head 均可插入保持周期。",
        "flush": "younger 指令可由 branch recovery/full flush kill；已 handoff 外部 transaction 继续 drain。",
        "architecturalEffect": "只有 ROB 顺序 commit 才更新架构 GPR/CSR 和 instret。",
        "phases": [
            {"module": "OooFetchAxiBridge", "event": "fetch request/response handoff", "edge": "AXI/FIFO valid-ready", "transfer": "packet"},
            {"module": "OooFrontend", "event": "registered head 分类与双槽 admission", "edge": "dispatch candidate", "transfer": "uop pair"},
            {"module": "OooAluDecodeBackend", "event": "组合译码与 rename 候选", "edge": "dispatch fire edge", "transfer": "renamed uop"},
            {"module": "OooDispatchBackend", "event": "原子写 RAT/FreeList/Busy/ROB/IQ", "edge": "posedge", "transfer": "IQ resident"},
            {"module": "OooIntIssueQueue", "event": "ready/资源满足后选择", "edge": "issue fire", "transfer": "issue packet"},
            {"module": "OooIntBackend", "event": "EX/long-op/LSU 产生授权 completion", "edge": "registered EX + arb", "transfer": "formal WB"},
            {"module": "OooRob", "event": "done 边沿后等待到程序序 head", "edge": "WB edge-old done", "transfer": "commit candidate"},
            {"module": "OooWriteback", "event": "顺序 commit 输出", "edge": "commit fire", "transfer": "architectural state"},
        ],
        "timingTerms": ["ADD commit", "dispatch", "ROB done"],
    },
    {
        "id": "fetch-packet",
        "title": "Fetch request、旧响应丢弃与 packet dispatch",
        "shortTitle": "Fetch packet",
        "kind": "IFU / FRONTEND",
        "summary": "取指请求经 ITLB/PMP/cache/AXI 得到 packet；response 先入 FIFO、registered head 下一拍 dispatch。redirect 后旧响应被物理消费但不入 FIFO。",
        "initiator": "OooFetchPcOutstandingSequencer",
        "owner": "fetch bridge outstanding → discard token 或 packet FIFO",
        "terminal": "有效 packet 入 FIFO；被 redirect 淘汰的旧 response 由 discard owner 消费",
        "backpressure": "fifo_count + outstanding 预留 credit；无 full+pop look-through。",
        "flush": "redirect 边沿更新 PC 并设置 discard；不能撤回已经 handoff 的 AXI AR。",
        "architecturalEffect": "取指本身不形成架构效果，只有后续 commit 才可见。",
        "phases": [
            {"module": "OooFetchPcOutstandingSequencer", "event": "选择 next PC / outstanding owner", "edge": "request fire", "transfer": "fetch PC"},
            {"module": "OooFetchAxiBridge", "event": "ITLB/PMP/cache/PTW/AXI 访问", "edge": "variable latency", "transfer": "packet response"},
            {"module": "OooFetchPacketDecode", "event": "RVC 长度与双槽/fault provenance", "edge": "combinational", "transfer": "slot facts"},
            {"module": "OooFetchPacketFifo", "event": "response enqueue 与 registered head", "edge": "posedge", "transfer": "head packet"},
            {"module": "OooFrontendDispatchGate", "event": "双槽 admission 与 pop", "edge": "dispatch fire", "transfer": "backend uops"},
        ],
        "timingTerms": ["discard", "FIFO", "request"],
    },
    {
        "id": "integer-completion",
        "title": "整数 issue、EX 反压与 formal completion",
        "shortTitle": "整数完成",
        "kind": "ISSUE / EXECUTE / WRITEBACK",
        "summary": "IQ 选择后把 producer 送入 registered EX；completion 端口繁忙时 EX holder 保持同一 ProducerId，formal WB 之后 ROB 才能在下一窗口退休。",
        "initiator": "OooIntIssueQueue",
        "owner": "registered EX holder / long-op FSM",
        "terminal": "authorized completion 被 ROB 接受",
        "backpressure": "completion port 不 ready 时 ex_valid 与完整 payload 保持。",
        "flush": "strictly-younger kill 使对应 holder 失去完成资格；不可误杀 older producer。",
        "architecturalEffect": "formal WB 只写 ROB done/PRF；架构 GPR 等到 commit。",
        "phases": [
            {"module": "OooIntIssueQueue", "event": "select + issue fire", "edge": "posedge capture", "transfer": "issue packet"},
            {"module": "OooIntBackend", "event": "registered EX / ALU result", "edge": "next-cycle EX", "transfer": "producer result"},
            {"module": "WBU", "event": "选择写回 payload", "edge": "completion ready", "transfer": "formal WB"},
            {"module": "OooRob", "event": "写 done 后等待 head", "edge": "posedge", "transfer": "commit candidate"},
            {"module": "OooArchRegFile", "event": "commit-time GPR update", "edge": "commit fire", "transfer": "architectural state"},
        ],
        "timingTerms": ["EX stage", "最短路径", "formal"],
    },
    {
        "id": "fp-completion",
        "title": "FP raw result、done FIFO 与 formal FPWB",
        "shortTitle": "FP 完成",
        "kind": "FLOATING POINT",
        "summary": "FP raw result 先写物理 FPR/wake，再进入 8-entry done FIFO；FIFO head 获得 formal FPWB 后 ROB 才 done，最后 commit 更新架构 FPR/fflags。",
        "initiator": "OooFpIssueQueue",
        "owner": "FP pipeline/iterator → done FIFO → ROB",
        "terminal": "formal FPWB 使 ROB done；架构 terminal 是 commit",
        "backpressure": "done FIFO 或 formal FPWB 仲裁繁忙时 holder 必须保持身份、结果与 fflags。",
        "flush": "branch kill 可取消未授权 younger FP producer；已淘汰晚到 done 不得写 ROB。",
        "architecturalEffect": "架构 FPR 与 fflags 在顺序 commit 更新。",
        "phases": [
            {"module": "OooFpIssueQueue", "event": "FP uop issue", "edge": "issue fire", "transfer": "FP issue packet"},
            {"module": "OooFpBackend", "event": "捕获 ProducerId/rounding/precision", "edge": "launch edge", "transfer": "pipeline metadata"},
            {"module": "OooFpArithGate", "event": "FADD/FMUL/FMA 对齐 stage5", "edge": "2/3/5 internal stages", "transfer": "raw result"},
            {"module": "OooFpPhysRegFile", "event": "raw PRF write + wake", "edge": "authorized raw edge", "transfer": "done FIFO entry"},
            {"module": "OooFpBackend", "event": "8-entry done FIFO 排队", "edge": "formal WB arbitration", "transfer": "FPWB"},
            {"module": "OooRob", "event": "ROB done / ordered head", "edge": "WB then later commit", "transfer": "commit"},
            {"module": "OooFpRegFile", "event": "架构 FPR/fflags 更新", "edge": "commit fire", "transfer": "architectural state"},
        ],
        "timingTerms": ["done FIFO", "FMA", "formal FPWB"],
    },
    {
        "id": "load",
        "title": "Load address、翻译、Cache/AXI 与 completion",
        "shortTitle": "Load",
        "kind": "LOAD / MEMORY",
        "summary": "Load 在 issue 后进入 LQ/MIQ，经过 DTLB/PMP/PMA 和 D-cache；miss 通过共享 AXI 返回。被 kill 的已发请求仍 drain，晚到结果只可被授权或丢弃。",
        "initiator": "OooIntBackend / LSU address generation",
        "owner": "LQ + MIQ lane + OooMemAxiBridge",
        "terminal": "匹配 owner token/ProducerId 的 response 被 completion 接受",
        "backpressure": "MIQ、LQ、bridge、D-cache miss arbiter 和 completion 端口均可反压。",
        "flush": "未 launch younger Load 可 kill；已 launch Load 保留 DRAIN owner 直到 terminal。",
        "architecturalEffect": "Load result 先写 PRF/ROB done，顺序 commit 后才成为架构状态。",
        "phases": [
            {"module": "OooIntBackend", "event": "LSU 形成地址/尺寸/owner", "edge": "issue/EX edge", "transfer": "memory request"},
            {"module": "OooLoadQueue", "event": "allocate + dependency/kill owner", "edge": "queue edge", "transfer": "lane request"},
            {"module": "OooMemoryAccess", "event": "MIQ lane admission", "edge": "valid-ready", "transfer": "bridge request"},
            {"module": "OooMemAxiBridge", "event": "DTLB/PMP/PMA/D-cache/AXI", "edge": "variable latency", "transfer": "tagged response"},
            {"module": "OooLoadQueue", "event": "token/ProducerId 授权 response", "edge": "terminal accept", "transfer": "completion"},
            {"module": "OooRob", "event": "formal WB then ordered commit", "edge": "two distinct edges", "transfer": "architectural state"},
        ],
        "timingTerms": ["Load", "response", "kill"],
    },
    {
        "id": "store",
        "title": "Store SQ/ROB 双头、AW/W 与 B terminal",
        "shortTitle": "Store",
        "kind": "STORE / MEMORY ORDERING",
        "summary": "Store dispatch 后进入 SQ；只有 SQ head 与 ROB head 精确匹配且 launch-open 时才发物理写。AW/W 可分离，B response 才授权 SQ/ROB 释放。",
        "initiator": "OooStoreQueue at SQ/ROB dual head",
        "owner": "SQ entry → memory bridge write owner",
        "terminal": "B 经 bridge 形成 response 后，completion 与 owner-lifetime 两条分支各自闭合",
        "backpressure": "launch gate、AW、W、B 与共享 AXI arbiter 都可独立等待。",
        "flush": "未 launch younger Store 可清除；已 launch 写 transaction 不可撤回，必须 drain B。",
        "architecturalEffect": "本设计把 B terminal 纳入精确完成链，不采用先退休后后台 drain 模型。",
        "phases": [
            {"module": "OooDispatchBackend", "event": "ROB/SQ allocate and bind", "edge": "dispatch fire", "transfer": "store owner"},
            {"module": "OooStoreQueue", "event": "地址/数据填充与 forwarding", "edge": "queue updates", "transfer": "head candidate"},
            {"module": "OooMemoryRequestGate", "event": "SQ head == ROB head && launch-open", "edge": "request fire", "transfer": "physical write"},
            {"module": "OooMemAxiBridge", "event": "锁存 write owner，向 arbiter 发 raw AW/W", "edge": "bridge request / raw AXI", "transfer": "raw AW/W + lane owner"},
            {"module": "OooDualMemAxiArbiter", "event": "锁定 lane owner，转发 AW/W 并路由 B", "edge": "owner held through B", "transfer": "lane B response"},
            {"module": "OooMemAxiBridge", "event": "B 回到锁存 owner，形成带 tuple/error 的 bridge response", "edge": "S_WRITE_RESP → S_RESP → rsp fire", "transfer": "rsp tuple + error/fault"},
            {"module": "OooIntBackend", "event": "exact tuple 匹配 MIQ/live tracker，恢复 PID 并分成两条闭合链", "edge": "mem_rsp_valid && mem_rsp_ready", "transfer": "formal WB + SQ terminal"},
            {"module": "OooRob", "event": "Store 精确完成并顺序前进", "edge": "terminalized edge", "transfer": "architectural order"},
        ],
        "timingTerms": ["Store", "AW", "B terminal"],
    },
    {
        "id": "branch-recovery",
        "title": "Branch resolve、redirect 与 younger recovery",
        "shortTitle": "分支恢复",
        "kind": "CONTROL / RECOVERY",
        "summary": "物理 issue0 分支在 EX 解析方向/target；mispredict 形成带 ROB age 的 recovery，redirect 单赢家后清 younger 状态，下一拍从新 PC 取指。",
        "initiator": "OooIntBackend branch resolve",
        "owner": "resolve packet → redirect arbiter → control apply / frontend sequencer",
        "terminal": "redirect apply 与各 owner 的 younger kill/walk 完成",
        "backpressure": "恢复事件有固定 owner/priority，不能被较年轻或平龄低优先级来源覆盖。",
        "flush": "只 kill strictly-younger；已发外部 memory/AXI transaction 继续 drain。",
        "architecturalEffect": "branch resolve 本身是控制事件；对应分支仍需 EX0 formal WB 后按序 commit。",
        "phases": [
            {"module": "OooIntIssueQueue", "event": "分支选择到物理 issue0", "edge": "issue fire", "transfer": "branch packet"},
            {"module": "OooIntBackend", "event": "比较、target、mispredict 与 EX0 formal WB", "edge": "registered EX", "transfer": "resolve facts"},
            {"module": "OooBranchResolveRecoveryGate", "event": "形成 ROB walk / untracked recovery", "edge": "combinational gate", "transfer": "redirect request"},
            {"module": "OooRedirectArbiter", "event": "按 ROB age；平龄 trap > branch > direct", "edge": "single winner", "transfer": "winner payload"},
            {"module": "OooControlEventApplySequencer", "event": "request reason/kill index 打拍", "edge": "C0 request → C1 apply", "transfer": "flush/apply"},
            {"module": "OooFetchPcOutstandingSequencer", "event": "更新 PC，旧响应进入 discard", "edge": "redirect edge", "transfer": "next-cycle fetch"},
        ],
        "timingTerms": ["redirect", "mispredict", "branch"],
    },
    {
        "id": "csr-queue-head",
        "title": "产品默认 head0 CSR：ROB 队头提交与 C0/C1 串行化",
        "shortTitle": "CSR 队头提交",
        "kind": "CSR / SERIALIZE AT RETIRE",
        "summary": "OOO_CSR_QUEUE_HEAD=1 时，合法非 FP head0 CSR 单发进入 ROB；inflight owner 持续阻止 younger，ROB 只等 mem_idle 后在 C0 单独提交，C1 应用 serial/full flush，C2 必须静默。",
        "initiator": "OooFrontend legal non-FP head0 CSR dispatch",
        "owner": "head0_csr_inflight + stop_pending → ROB head → CsrFile/control apply",
        "terminal": "C0 CSR commit/CsrFile request，随后 C1 apply；C2 不得重复",
        "backpressure": "IQ/completion/ROB head 与 mem_idle 可推迟 C0；不能等待 mem_retire_quiet/SQ empty。",
        "flush": "C0 后的 C1 serial/full flush 清 younger、恢复物理映射并从 commit next-PC 重取；已 handoff AXI 仍遵守 drain。",
        "architecturalEffect": "C0 写 CSR，并把架构旧 CSR 值作为 rd commit data；satp 等上下文变化在 flush/refetch 后生效。",
        "phases": [
            {
                "module": "OooFrontend",
                "event": "合法非 FP head0 CSR 单发，建立 inflight/stop owner",
                "edge": "dispatch fire / owner birth",
                "transfer": "CSR uop + PC/inst",
            },
            {
                "module": "OooDispatchBackend",
                "event": "原子写 rename/ROB/IQ，lane1 不与 CSR 同拍进入",
                "edge": "dispatch edge",
                "transfer": "ROB/IQ resident CSR",
            },
            {
                "module": "OooIntBackend",
                "event": "普通执行链产生 placeholder formal completion",
                "edge": "issue → registered EX → WB",
                "transfer": "ROB done candidate",
            },
            {
                "module": "OooRob",
                "event": "到达 head 后只等待 mem_idle，形成 C0 单提交/屏障",
                "edge": "C0 commit pregrant/fire",
                "transfer": "commit0 CSR + full-flush reason",
            },
            {
                "module": "OooCsrAccessRequestMux",
                "event": "用 commit0 instruction 与架构 GPR 形成 CSR request",
                "edge": "C0 combinational request",
                "transfer": "addr/funct3/rs1 + old CSR value",
            },
            {
                "module": "CsrFile",
                "event": "提交 CSR side effect；旧值覆写 commit0 rd data",
                "edge": "C0 architectural edge",
                "transfer": "new CSR state + architectural rd",
            },
            {
                "module": "OooControlEventApplySequencer",
                "event": "C0 typed request 打拍，C1 full-flush apply；serial-flush 分支并行",
                "edge": "C0 → C1 → C2",
                "transfer": "younger kill + frontend refetch",
            },
        ],
        "timingTerms": ["head0 CSR", "queue-head CSR", "C0 commit"],
    },
    {
        "id": "precise-trap",
        "title": "Exception、ROB head、CSR trap 与精确 redirect",
        "shortTitle": "精确异常",
        "kind": "TRAP / ARCHITECTURAL STATE",
        "summary": "异常事实随 ROB entry 保存；只有到达程序序 head、older memory owner terminal 后，控制面才授权 CSR trap entry 和 redirect。",
        "initiator": "ROB head exception / interrupt boundary",
        "owner": "ROB head → pending control owner → CsrFile",
        "terminal": "trap apply：CSR 状态与 target PC 在精确边界更新",
        "backpressure": "older ROB、memory holder、serialized owner 和 control apply sequencer 都可推迟 trap。",
        "flush": "trap kill younger speculative state；已 handoff memory/AXI 继续 drain。",
        "architecturalEffect": "异常项不做普通架构写回、不计 instret；CSR trap entry 更新 epc/cause/tval/privilege。",
        "phases": [
            {"module": "OooRob", "event": "异常 entry 到达 head", "edge": "ordered head", "transfer": "trap facts"},
            {"module": "OooPendingDrainResolveGate", "event": "等待 exact memory-owner terminal", "edge": "drain predicate", "transfer": "trap request"},
            {"module": "OooControlPlane", "event": "选择 trap / block backend", "edge": "pending owner", "transfer": "CSR request"},
            {"module": "CsrFile", "event": "写 epc/cause/tval/privilege", "edge": "trap commit edge", "transfer": "trap target"},
            {"module": "OooControlEventApplySequencer", "event": "reason/kill-index 下一拍 apply", "edge": "registered apply", "transfer": "full flush"},
            {"module": "OooFrontend", "event": "清旧 packet 并从 xTVEC 重新取指", "edge": "next-cycle request", "transfer": "new fetch stream"},
        ],
        "timingTerms": ["trap apply", "exception", "older trap"],
    },
]


TRANSACTION_PHASE_DATA: dict[str, list[dict[str, str]]] = {
    "instruction-life": [
        {
            "dataIn": "next PC、privilege/satp/PMP context、fetch request owner",
            "stateChange": "锁存 outstanding 身份；执行 ITLB/PTW、PMP、packet-cache 或 AXI 访问",
            "dataOut": "packet PC、64-bit instruction bytes、fault/tval 与预测 provenance",
            "guard": "request/response valid-ready、FIFO reserved credit；redirect 后旧响应只 discard",
        },
        {
            "dataIn": "fetch packet、packet PC、fault provenance 与 predictor metadata",
            "stateChange": "FIFO registered head 做 RVC 对齐、slot0/slot1 可见性和 head-time 分类",
            "dataOut": "最多两个 uop candidate：PC、instruction、预测与异常事实",
            "guard": "registered head 有效；mandatory pair 不能拆分；backend ready 才允许 pop",
        },
        {
            "dataIn": "两个 instruction candidate、logical rs/rd、PC 与 fault facts",
            "stateChange": "组合译码 opcode/imm/CSR/memory/FP intent，形成 rename/resource 候选",
            "dataOut": "decoded uop pair、logical register intent、control 与 exception metadata",
            "guard": "illegal/fault 分类与 lane1 admission 必须在 dispatch fire 前稳定",
        },
        {
            "dataIn": "decoded pair、RAT 映射、FreeList/Busy credit、ROB/IQ 可用项",
            "stateChange": "同沿分配 physical destination/ProducerId，并原子更新 RAT、FreeList、Busy、ROB、IQ",
            "dataOut": "带 ps1/ps2/pdest/ProducerId 的 IQ resident entry 与 ROB entry",
            "guard": "lane1 以前缀依赖 lane0；mandatory pair 资源不足时两条都不得 fire",
        },
        {
            "dataIn": "IQ resident uop、source-ready sticky bits、wakeup 与执行资源状态",
            "stateChange": "按年龄和终端能力选择 ready uop；dispatch entry 不做同拍 issue bypass",
            "dataOut": "issue packet：ProducerId、操作数 tag、执行控制与 immediate/PC",
            "guard": "全部源就绪、目标执行单元可接收，且 entry 未被 kill/recovery 淘汰",
        },
        {
            "dataIn": "issue packet、PRF/forwarding operands、ProducerId 与执行控制",
            "stateChange": "EX holder/long-op FSM 保存身份；计算结果并做 ROB exact-open 授权",
            "dataOut": "formal-WB payload：ProducerId、result、exception/metadata 与 wake",
            "guard": "completion slot ready、完整 ProducerId 仍 live；背压时 holder/payload 保持",
        },
        {
            "dataIn": "authorized formal-WB ProducerId、result 与 exception facts",
            "stateChange": "上升沿写 ROB done/data/exception；下一周期才从 edge-old done_q 判定 head",
            "dataOut": "按程序序排列的 commit0/commit1 candidate 与旧物理寄存器回收信息",
            "guard": "commit0 必须是 head；commit1 依赖 commit0 且两项异常/control gate 均允许",
        },
        {
            "dataIn": "ROB commit packets、control-commit/synthetic append 选择与 commit ready",
            "stateChange": "选择最终退休事件，并在合法提交边沿更新架构 GPR/CSR/trace 计数",
            "dataOut": "architectural state、retire trace、instret 与外部 commit observation",
            "guard": "异常项不做普通写回；lane1 仍以前缀依赖 lane0；control commit 可覆盖 core lane",
        },
    ],
    "fetch-packet": [
        {
            "dataIn": "当前 PC、redirect/direct action、fetch credit 与 outstanding 状态",
            "stateChange": "选择 next PC；request fire 后锁存 fetch PC owner，redirect 时建立 discard owner",
            "dataOut": "fetch request PC 与对应 outstanding identity",
            "guard": "无旧 outstanding 或已有合法 terminal；FIFO 预留 credit 足够",
        },
        {
            "dataIn": "fetch PC、privilege/satp/PMP context 与 outstanding owner",
            "stateChange": "执行 ITLB/PTW、PMP、A-bit、packet-cache/AXI 状态机并保存 fault provenance",
            "dataOut": "64-bit packet bytes、owner PC、fault/tval 与 response valid",
            "guard": "AXI handoff 后不可撤回；redirect 只让旧 response 在 terminal 时被 discard",
        },
        {
            "dataIn": "packet bytes、低位 PC、fault provenance 与跨包半字信息",
            "stateChange": "组合判定 RVC/32-bit 长度、slot 边界、跨包需求和逐槽 fault",
            "dataOut": "slot0/slot1 instruction、PC、长度、有效位与 fault facts",
            "guard": "跨包 32-bit 指令必须等后继 halfword 真实到达，不能凭旧 payload 拼接",
        },
        {
            "dataIn": "decoded packet slots、packet PC、predictor 与 fault metadata",
            "stateChange": "enqueue 到 4-entry packet FIFO；读侧只暴露 registered head",
            "dataOut": "稳定 head packet、occupancy/credit 与下一 packet 关系",
            "guard": "enqueue/dequeue 按真实 valid-ready；full+pop 同拍不提供 look-through",
        },
        {
            "dataIn": "registered head slots、backend resource-ready 与 pair 类型",
            "stateChange": "决定 lane0/lane1 admission、mandatory/optional pair 和 FIFO pop",
            "dataOut": "backend uop pair：PC、instruction、预测、fault 与顺序关系",
            "guard": "lane1 不得脱离 lane0；redirect/stop/flush 时禁止旧 head 继续派发",
        },
    ],
    "integer-completion": [
        {
            "dataIn": "IQ entry、source-ready/wakeup、执行资源 ready 与 ROB age",
            "stateChange": "选择可发射 entry，并在 issue edge 从 IQ 移除或压缩队列",
            "dataOut": "ProducerId、psource、pdest、ALU/branch/long-op control 的 issue packet",
            "guard": "全部源 ready、对应终端可接收，且 entry 未被 current kill 命中",
        },
        {
            "dataIn": "issue packet 与 PRF/EX-forwarding operands",
            "stateChange": "在 registered EX holder 保存完整 ProducerId/control；计算 ALU 或等待 long-op",
            "dataOut": "producer result、exception/control metadata 与 completion request",
            "guard": "EX holder 只能在 downstream 接受或 exact kill 时换 owner",
        },
        {
            "dataIn": "ALU/PC+4/imm/CSR value 与对应 ProducerId",
            "stateChange": "组合选择写回 value；completion authority 仍由 OooIntBackend 保持",
            "dataOut": "formal integer WB：ProducerId、64-bit result 与 wake",
            "guard": "ROB exact-open、completion slot ready；WBU 自身不是状态 owner",
        },
        {
            "dataIn": "authorized WB result、ProducerId 与可能的 exception",
            "stateChange": "写 done_q/data_q；head 只能在下一周期读取新 done 状态",
            "dataOut": "ordered commit candidate、pdest/old-pdest 与 architectural rd data",
            "guard": "无 WB→commit 同拍旁路；异常、older head 和 control gate 可阻塞退休",
        },
        {
            "dataIn": "合法 commit0/commit1 的 rd、data 与写使能",
            "stateChange": "提交边沿更新架构 GPR；x0/异常/无 rd 写入被抑制",
            "dataOut": "architectural GPR flat state 与 debug/retire observation",
            "guard": "只接受顺序 commit；formal WB 或 early wake 均不能直接写架构 GPR",
        },
    ],
    "fp-completion": [
        {
            "dataIn": "FP IQ entry、FP/GPR source-ready、rounding/precision 与 ROB age",
            "stateChange": "选择 oldest-ready FP uop，并从 IQ 形成单路 issue packet",
            "dataOut": "ProducerId、FP operands tag、operation、rm/format 的 issue packet",
            "guard": "source ready、FP issue stage ready，且 entry 未被 branch/full flush kill",
        },
        {
            "dataIn": "FP issue packet、FP PRF/GPR operands 与完整 ProducerId",
            "stateChange": "launch edge 锁存 operation、rounding、precision、destination 与 kill identity",
            "dataOut": "对齐到 arithmetic/convert/compare/long-op 单元的 operands + metadata",
            "guard": "目标执行单元 ready；metadata 必须与 datapath 同步跨越所有 pipeline stage",
        },
        {
            "dataIn": "FP operands、rm/format、ProducerId metadata pipeline",
            "stateChange": "FADD/FMUL/FMA 分别经历 2/3/5 内部级并统一对齐到 meta-stage5",
            "dataOut": "raw FP result、fflags、pdest 与原 ProducerId",
            "guard": "每级 valid/kill 对齐；不能把内部 latency 当 formal ROB completion",
        },
        {
            "dataIn": "authorized raw result、pdest、fflags 与 ProducerId",
            "stateChange": "写 speculative FP PRF 并广播 wake；并行形成 done-FIFO entry",
            "dataOut": "可供依赖者读取的 FPR value/wake，以及待 formal-WB 的 result metadata",
            "guard": "raw result 必须 exact-live；PRF 可见不代表 ROB 已 done 或架构已提交",
        },
        {
            "dataIn": "done FIFO head：ProducerId、result、fflags、destination metadata",
            "stateChange": "8-entry FIFO 保存已算完 owner；赢得全局 completion 仲裁后 dequeue",
            "dataOut": "formal FPWB payload 送 ROB，并保留 result/fflags provenance",
            "guard": "FIFO 非空、全局 WB slot ready、head ProducerId 仍 exact-open",
        },
        {
            "dataIn": "formal FPWB ProducerId、result/fflags 与 destination",
            "stateChange": "写 ROB done；到达程序序 head 后生成 FP commit packet",
            "dataOut": "ordered FP commit：architectural fd、value、fflags 与 old physical destination",
            "guard": "WB 与 commit 分属不同边沿；异常/older entry/control gate 可继续阻塞",
        },
        {
            "dataIn": "合法 FP commit0/commit1 value、fd 与 fflags",
            "stateChange": "提交边沿更新架构 FPR 和 accrued exception flags",
            "dataOut": "architectural FPR/fflags 与 retire observation",
            "guard": "只消费顺序 commit；raw PRF write、wake 或 done-FIFO enqueue 都不是架构提交",
        },
    ],
    "load": [
        {
            "dataIn": "memory uop、GPR operands、immediate、ProducerId、size/sign 与 privilege context",
            "stateChange": "LSU 组合形成 effective VA、访问尺寸、byte-lane 信息和 load identity",
            "dataOut": "Load request：VA、size/sign、ProducerId、LQ/owner metadata",
            "guard": "issue/EX owner exact-live；misaligned/illegal facts 与 request 同拍稳定",
        },
        {
            "dataIn": "Load request、ProducerId、program-order age 与 SQ dependency context",
            "stateChange": "分配 LQ entry，记录 launched/killed/terminal 状态和 store-order dependency",
            "dataOut": "带 LQ token/ProducerId 的 memory-lane request",
            "guard": "LQ 有空项；未 launch younger 可 kill，已 launch entry 必须保留到 terminal",
        },
        {
            "dataIn": "LQ lane request、VA/size、owner token/epoch 与 ProducerId",
            "stateChange": "MIQ lane valid-ready admission，保存 transport kind 与 exact identity",
            "dataOut": "稳定 bridge request：地址属性、operation 与 owner tuple",
            "guard": "MIQ/bridge ready；背压期间 request identity 和 payload 不得改变",
        },
        {
            "dataIn": "bridge request、satp/PMP/PMA context、SQ query 与 cache/AXI state",
            "stateChange": "DTLB/PTW/PMP/PMA 分类；D-cache lookup/hit 或共享 AXI miss transaction",
            "dataOut": "tagged load response：data/fault/tval + token/epoch/ProducerId",
            "guard": "翻译/权限通过；miss owner 获仲裁；已发 AR 后即使 flush 也必须 drain R",
        },
        {
            "dataIn": "tagged response、LQ entry、live owner tuple 与 ROB exact-open result",
            "stateChange": "校验 token/epoch/ProducerId，接受合法 terminal 或吞掉 killed late response",
            "dataOut": "authorized load completion：result、fault 与 ProducerId",
            "guard": "terminal identity 全匹配且 completion slot ready；stale/duplicate 不得写 ROB",
        },
        {
            "dataIn": "authorized load WB、result/fault 与 ProducerId",
            "stateChange": "先写 PRF/ROB done，后在独立程序序窗口生成 commit 或精确异常",
            "dataOut": "architectural rd update，或 trap facts；同时释放 LQ/physical owner",
            "guard": "WB→commit 至少跨 edge-old done 边界；异常 Load 不执行普通架构写回",
        },
    ],
    "store": [
        {
            "dataIn": "decoded Store、logical/physical sources、ProducerId 与 ROB/SQ credits",
            "stateChange": "dispatch edge 同时分配 ROB entry、SQ entry 并绑定程序序 identity",
            "dataOut": "Store owner：SQ index、ProducerId、地址源/数据源与 size",
            "guard": "ROB/SQ/IQ 资源齐备；pair admission 服从 lane 前缀语义",
        },
        {
            "dataIn": "Store owner、地址计算结果、store data、WSTRB 与 older-load query",
            "stateChange": "分别填充 address/data/classification，并维护 forwarding/order CAM facts",
            "dataOut": "SQ-head candidate：PA、data、WSTRB、class 与完整 owner identity",
            "guard": "只有完整地址/数据 entry 可成为 launch candidate；未 launch younger 可清除",
        },
        {
            "dataIn": "SQ head candidate、ROB head ProducerId 与 rob_head_launch_open",
            "stateChange": "组合核对 SQ head == ROB head 及 launch 资格，不提前改变架构状态",
            "dataOut": "physical write request：PA、size、data、WSTRB、owner tuple",
            "guard": "双头 exact match、无 fault、bridge ready；不采用“退休后后台 drain”",
        },
        {
            "dataIn": "physical write request、PMP/PMA/cache class 与 owner identity",
            "stateChange": "锁存 write owner；AW 与 W 独立握手并分别记录 aw_seen/w_seen",
            "dataOut": "送往共享 arbiter 的 raw AXI AW/W channel + lane-local write owner identity",
            "guard": "AW/W payload 各自在 ready 前稳定；任一 channel handoff 后不可被 flush 撤回",
        },
        {
            "dataIn": "lane0/lane1 raw AXI AW/W channel 与待选 lane owner",
            "stateChange": "共享出口锁定单一 lane owner，维护 AW/W seen 和 round-robin fairness",
            "dataOut": "下游 AW/W transaction；B response 按锁存选择返回原 bridge lane",
            "guard": "owner 从首个 address/data phase 保持到 B terminal，期间不能切换 lane",
        },
        {
            "dataIn": "原 lane B response 与 bridge 保存的 STORE {kind, token, mmu_epoch, fault_tval}",
            "stateChange": "B 拍锁存 error，进入 S_RESP；response snapshot 继续保持原 owner tuple",
            "dataOut": "mem_rsp：{kind, token, mmu_epoch, fault_tval} + error/page_fault；不携带 ProducerId",
            "guard": "B 在 S_WRITE_RESP 被接收；S_RESP 的 payload/tuple 必须稳定到 backend ready",
        },
        {
            "dataIn": "bridge response、MIQ head 与 owner tracker 的 kind/token/epoch→ProducerId live table",
            "stateChange": "先 exact-match tuple，再按 token 恢复 ProducerId/ROB；同拍申请 WB、SQ terminal 与 owner-terminal credit",
            "dataOut": "主完成链：ProducerId/ROB + error/cause/tval → formal memory WB；并置对应 SQ terminal",
            "guard": "tuple、MIQ head、live table 必须全匹配，且 WB/SQ/collector 三类 sink 都有 credit",
            "sidePath": {
                "label": "PARALLEL OWNER-LIFETIME BRANCH",
                "module": "OooMemOwnerTerminalCollector",
                "dataIn": "只携带 {kind, token, epoch} 的 exact terminal ingress",
                "stateChange": "去重并排队；dequeue 后由 OooMemOwnerTracker 释放同一 live owner",
                "dataOut": "owner credit / live-table entry 回收，不承载指令结果或异常 payload",
                "guard": "本分支没有 ProducerId、error、cause 或 fault_tval，也不向 ROB 提供完成数据",
            },
        },
        {
            "dataIn": "来自 OooIntBackend 主完成链的 ProducerId、formal WB exception/cause/tval 与 SQ terminal 状态",
            "stateChange": "formal WB 标记 ROB done/exception；到程序序 head 后 commit 并释放 SQ，或产生精确异常",
            "dataOut": "architectural memory order 前进、SQ/ROB owner 回收与 retire observation",
            "guard": "必须先闭合 bridge response 主完成链；异常 Store 不做普通退休，younger commit 被阻断",
        },
    ],
    "branch-recovery": [
        {
            "dataIn": "ready branch IQ entry、source operands、predicted direction/target 与 ProducerId",
            "stateChange": "age/select 选择分支到 physical issue0，并从 IQ 移除对应 entry",
            "dataOut": "branch issue packet：PC、imm、operands、prediction 与 ProducerId",
            "guard": "branch 只能占可解析的 issue0；source ready 且 entry 未被 older recovery kill",
        },
        {
            "dataIn": "branch issue packet、operands 与 prediction metadata",
            "stateChange": "registered EX 计算 condition/target/mispredict；并形成对应 EX0 formal-WB",
            "dataOut": "resolve facts：actual taken/target、mispredict、ROB age/PID 与 branch WB",
            "guard": "resolve query exact-open，且必须与 EX0 完整 ProducerId coherent",
        },
        {
            "dataIn": "resolve facts、ROB head/tail age 与 direct/untracked recovery context",
            "stateChange": "组合生成 strictly-younger kill boundary、ROB walk 请求与 redirect payload",
            "dataOut": "带 reason、target PC、kill index/age 的 redirect request",
            "guard": "只允许 live branch 控制 younger；分支自身和所有 older owner 保留",
        },
        {
            "dataIn": "trap/branch/direct 多源 redirect request 与各自 age/priority",
            "stateChange": "组合选择最老 request；同 age 按 trap > branch > direct",
            "dataOut": "单一 winner：target PC、reason、kill index 与 source identity",
            "guard": "同周期只能有一个 winner；较年轻或低优先级来源不得覆盖",
        },
        {
            "dataIn": "winner redirect reason、target、kill index 与 full/local flush 类型",
            "stateChange": "C0 request 打拍，C1 产生对齐的 apply/flush 与 recovery metadata",
            "dataOut": "backend kill/walk apply、frontend redirect 与 checkpoint action",
            "guard": "request/apply 跨一个寄存边界；字段必须与原 winner 保持一致",
        },
        {
            "dataIn": "redirect apply、target PC 与当前 IFU outstanding/discard 状态",
            "stateChange": "边沿更新 PC；旧已发 response 转入 discard，清理旧 packet 可见性",
            "dataOut": "下一周期的新 fetch request stream",
            "guard": "旧 AXI response 仍物理消费但不得 enqueue；新 request 不与 redirect 同拍发出",
        },
    ],
    "csr-queue-head": [
        {
            "dataIn": "registered head 的 instruction/facts、CSR legality、FP-CSR 分类与 backend ready",
            "stateChange": "仅合法非 FP head0 CSR 以单发 fire 离开 FIFO；锁存 head0_csr_inflight 并建立 stop owner",
            "dataOut": "lane0 CSR uop、PC/next-PC/instruction；lane1 valid 被压低",
            "guard": "产品 OOO_CSR_QUEUE_HEAD=1；非法 CSR 转 trap，lane1/FP CSR 仍走 pending/full-drain",
        },
        {
            "dataIn": "CSR decode/rename facts、ROB/IQ/PRF/FreeList credit 与 lane0 fire",
            "stateChange": "dispatch edge 原子分配 ProducerId、ROB entry、目的物理寄存器与 IQ resident 状态",
            "dataOut": "带完整 ProducerId 的 resident CSR；dispatch 后 inflight/stop 继续封住 younger",
            "guard": "所有必需资源同拍 ready；CSR 必须单发，不能让 lane1 部分写入后端状态",
        },
        {
            "dataIn": "resident CSR、source operand 与 dispatch-time placeholder CSR data",
            "stateChange": "按普通 issue/registered EX/formal-WB 链把 ROB entry 标记 done；真正旧 CSR 值不在此定案",
            "dataOut": "ROB done 与 placeholder physical result",
            "guard": "formal completion 仍须 full-ProducerId exact-open；commit-time 会用架构 CSR 旧值覆写 rd",
        },
        {
            "dataIn": "edge-old ROB head/done、commit permit 与 mem_idle",
            "stateChange": "mem_idle=0 时保持 head；满足后形成 C0 full-flush pregrant、commit0_fire，并禁止 commit1",
            "dataOut": "commit0 PC/inst/next-PC/ProducerId 与 CSR_COMMIT typed control reason",
            "guard": "只等待 mem_idle，不等待 mem_retire_quiet/SQ empty；后者会与 younger Store 形成循环死锁",
        },
        {
            "dataIn": "C0 commit0 instruction、架构 GPR rs1、pending CSR exact-claim seal 与 CsrFile 组合读值",
            "stateChange": "选择 queue-head CSR request，计算 addr/funct3/rs1 与读改写条件",
            "dataOut": "CsrFile access request、head0_csr_commit、old CSR read value 与 satp/context 写提示",
            "guard": "必须是 core_commit0 CSR 且没有 pending-system exact claim；probe 端口绝不能产生副作用",
        },
        {
            "dataIn": "C0 CSR request、当前 CSR/privilege/PMP 状态与 commit0 destination",
            "stateChange": "同一架构边沿应用 CSR 写；旧 CSR 组合值覆写 commit0 rd data，而非采用早期 placeholder",
            "dataOut": "新 CSR/privilege state、正确架构 rd value、retire observation",
            "guard": "异常时不做普通 CSR/GPR side effect；satp 等上下文变化必须与后续 flush/refetch 配套",
            "sidePath": {
                "label": "PARALLEL SERIAL-FLUSH BRANCH",
                "module": "OooControlCommitSequencer",
                "dataIn": "C0 head0_csr_commit pulse",
                "stateChange": "serial_flush_q <= head0_csr_commit，在下一拍形成单周期注册脉冲",
                "dataOut": "C1 core_serial_flush，驱动 core-local flush / commit block / frontend stop",
                "guard": "从 CsrFile 的 C0 architectural commit 边沿分出；必须与 typed C1 apply 对齐，C2 回到 0",
            },
        },
        {
            "dataIn": "C0 CSR_COMMIT reason、kill index、commit next-PC 与 serial-flush request",
            "stateChange": "typed-event sequencer 在 C1 输出 full-flush/apply，清 younger、恢复 rename/phys 状态并释放 inflight/stop owner",
            "dataOut": "C1 frontend redirect/旧 response discard；C2 新路径继续且 apply/request 均为 0",
            "guard": "C0/C1 字段同源且 exactly-once；已 handoff AXI 不撤回，C2 任何重放都属于错误",
        },
    ],
    "precise-trap": [
        {
            "dataIn": "ROB head entry 的 exception/cause/tval/PC 与 interrupt boundary facts",
            "stateChange": "按程序序确认异常位于 head，并阻断普通 commit1/younger side effects",
            "dataOut": "precise trap facts：epc、cause、tval、privilege context 与 kill boundary",
            "guard": "所有 older entry 已完成；异常项不写架构目的寄存器且不计 instret",
        },
        {
            "dataIn": "trap facts、backend drained、memory live-holder/terminal 状态",
            "stateChange": "计算 exact drain predicate，等待不可撤销 memory owner 全部 terminalized",
            "dataOut": "可执行的 trap request 与 backend stop/drain witness",
            "guard": "ROB empty 不能替代 memory terminalized；已 handoff AXI 必须先 drain",
        },
        {
            "dataIn": "drained trap、pending SYSTEM/exit/IRQ 与优先级 facts",
            "stateChange": "pending owner 保存并选择唯一 architectural control event，阻断新 backend work",
            "dataOut": "CSR trap request：cause、epc、tval、delegation/privilege facts",
            "guard": "older trap/serialized owner 优先；同一 transaction 只能产生一次 apply",
        },
        {
            "dataIn": "CSR trap request、当前 mstatus/sstatus、delegation 与 xtvec",
            "stateChange": "提交边沿写 xepc/xcause/xtval/privilege/status，并计算 trap target",
            "dataOut": "trap target PC、new privilege 与 architectural CSR state",
            "guard": "请求已在精确边界授权；非法/重复 pending 不能二次写 CSR",
        },
        {
            "dataIn": "trap target、reason、kill index 与 CSR side-effect witness",
            "stateChange": "注册 reason/kill-index，使 C0 request 在 C1 形成一致的 full-flush apply",
            "dataOut": "全局 younger kill、checkpoint action 与 frontend redirect apply",
            "guard": "apply 字段必须来自同一 request；C1 clear 后 C2 不得重复 terminal",
        },
        {
            "dataIn": "full-flush/redirect apply、xTVEC target 与旧 FIFO/outstanding 状态",
            "stateChange": "清旧 packet/预测上下文；旧已发 fetch response 标记 discard",
            "dataOut": "从 xTVEC 开始的新 fetch packet stream",
            "guard": "新 request 从下一周期开始；旧外部 response drain 但不进入新路径",
        },
    ],
}


def enrich_transaction_phases(transactions: list[dict[str, Any]]) -> None:
    """Attach explicit data-flow facts to every curated transaction phase."""

    transaction_ids = {transaction["id"] for transaction in transactions}
    detail_ids = set(TRANSACTION_PHASE_DATA)
    if transaction_ids != detail_ids:
        raise ValueError(
            "transaction data-flow 覆盖不匹配："
            f"transactions={sorted(transaction_ids)} details={sorted(detail_ids)}"
        )
    required = {"dataIn", "stateChange", "dataOut", "guard"}
    for transaction in transactions:
        details = TRANSACTION_PHASE_DATA[transaction["id"]]
        phases = transaction["phases"]
        if len(details) != len(phases):
            raise ValueError(
                f"{transaction['id']}: phase={len(phases)} "
                f"data-flow={len(details)}"
            )
        for index, (phase, detail) in enumerate(zip(phases, details, strict=True), 1):
            missing = required.difference(detail)
            if missing or any(not detail[key].strip() for key in required):
                raise ValueError(
                    f"{transaction['id']} phase {index}: "
                    f"data-flow 字段缺失 {sorted(missing)}"
                )
            phase.update(detail)


def base_module(name: str) -> str:
    """去掉 Verilator 参数化派生模块 ``__...`` 后缀。"""

    return name.split("__", 1)[0]


def relative_repo_path(path: Path) -> str:
    return path.resolve().relative_to(REPO_ROOT.resolve()).as_posix()


def file_category(path: str) -> str:
    parts = Path(path).parts
    try:
        index = parts.index("vsrc")
    except ValueError:
        return "root"
    return parts[index + 1] if len(parts) > index + 2 else "root"


def normalize_description(text: str) -> str:
    """保留少量 inline Markdown，去掉 Markdown link 的 URL。"""

    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def parse_atlas() -> list[dict[str, str]]:
    text = ATLAS_PATH.read_text(encoding="utf-8")
    begin = "<!-- FILE_ATLAS_BEGIN -->"
    end = "<!-- FILE_ATLAS_END -->"
    if text.count(begin) != 1 or text.count(end) != 1:
        raise ValueError("FILE_ATLAS_BEGIN/END marker 必须各出现一次")
    body = text.split(begin, 1)[1].split(end, 1)[0]
    rows: list[dict[str, str]] = []
    for line in body.splitlines():
        match = ATLAS_ROW_RE.match(line)
        if match:
            rows.append(
                {
                    "path": match.group("path"),
                    "status": match.group("status").strip(),
                    "description": normalize_description(match.group("description")),
                    "category": file_category(match.group("path")),
                }
            )
    if len(rows) != 150:
        raise ValueError(f"atlas row 数不是 150：{len(rows)}")
    counts = Counter(row["status"] for row in rows)
    if dict(counts) != EXPECTED_STATUS_COUNTS:
        raise ValueError(
            f"atlas 身份计数不匹配：actual={dict(counts)} expected={EXPECTED_STATUS_COUNTS}"
        )
    return rows


def strip_verilog_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.DOTALL)
    text = re.sub(r"//.*", "", text)
    return text


def extract_sequential_targets(text: str) -> list[str]:
    """Return de-duplicated nonblocking-assignment LHS names in source order.

    This is a learning aid, not a Verilog elaborator.  Restricting matches to
    statement boundaries avoids treating relational ``<=`` expressions as
    state assignments.  Array indices are intentionally collapsed to their
    owning register name.
    """

    clean = strip_verilog_comments(text)
    return list(
        dict.fromkeys(
            match.group("target") for match in NONBLOCKING_TARGET_RE.finditer(clean)
        )
    )


def find_balanced(text: str, start: int, opening: str = "(", closing: str = ")") -> int:
    if start >= len(text) or text[start] != opening:
        raise ValueError(f"expected {opening!r} at {start}")
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char == opening:
            depth += 1
        elif char == closing:
            depth -= 1
            if depth == 0:
                return index
    raise ValueError(f"unbalanced {opening}{closing}")


def module_port_text(text: str, module_name: str) -> str:
    clean = strip_verilog_comments(text)
    match = re.search(rf"\bmodule\s+{re.escape(module_name)}\b", clean)
    if not match:
        return ""
    cursor = match.end()
    while cursor < len(clean) and clean[cursor].isspace():
        cursor += 1
    if cursor < len(clean) and clean[cursor] == "#":
        cursor += 1
        while cursor < len(clean) and clean[cursor].isspace():
            cursor += 1
        if cursor >= len(clean) or clean[cursor] != "(":
            return ""
        cursor = find_balanced(clean, cursor) + 1
    while cursor < len(clean) and clean[cursor].isspace():
        cursor += 1
    if cursor >= len(clean) or clean[cursor] != "(":
        return ""
    end = find_balanced(clean, cursor)
    return clean[cursor + 1 : end]


def split_top_level_commas(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    round_depth = 0
    square_depth = 0
    brace_depth = 0
    for index, char in enumerate(text):
        if char == "(":
            round_depth += 1
        elif char == ")":
            round_depth -= 1
        elif char == "[":
            square_depth += 1
        elif char == "]":
            square_depth -= 1
        elif char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth -= 1
        elif char == "," and round_depth == square_depth == brace_depth == 0:
            parts.append(text[start:index])
            start = index + 1
    parts.append(text[start:])
    return parts


def port_group(name: str) -> str:
    lower = name.lower()
    if lower in {"clk", "clock", "rst", "reset", "rst_n", "reset_n"} or lower.startswith(
        ("clk_", "rst_", "reset_")
    ):
        return "clock_reset"
    if "axi_" in lower or lower.startswith(
        ("arvalid", "arready", "araddr", "rvalid", "rready", "awvalid", "wvalid", "bvalid")
    ):
        return "axi"
    if any(key in lower for key in ("fetch", "ifu", "packet", "bpu", "ras")):
        return "fetch"
    if any(key in lower for key in ("dispatch", "issue", "rename", "busy", "free_count")):
        return "dispatch"
    if any(
        key in lower
        for key in (
            "mem_",
            "memory",
            "load",
            "store",
            "lsu",
            "dcache",
            "tlb",
            "pmp",
            "pma",
            "owner_token",
        )
    ):
        return "memory"
    if any(
        key in lower
        for key in ("commit", "retire", "complete", "writeback", "wb_", "rd_data", "rd_en")
    ):
        return "completion"
    if any(
        key in lower
        for key in (
            "flush",
            "kill",
            "redirect",
            "branch_resolve",
            "pending",
            "drain",
            "stop",
            "halt",
            "exit",
            "trap",
        )
    ):
        return "control"
    if any(
        key in lower
        for key in ("csr", "priv", "irq", "mtime", "mstatus", "satp", "fflags", "frm")
    ):
        return "privilege"
    if any(key in lower for key in ("debug", "trace", "observable", "count_o")):
        return "debug"
    return "other"


def parse_ports(text: str, module_name: str) -> list[dict[str, str]]:
    block = module_port_text(text, module_name)
    if not block:
        return []
    result: list[dict[str, str]] = []
    direction = ""
    width = ""
    for raw_token in split_top_level_commas(block):
        token = " ".join(raw_token.split())
        if not token:
            continue
        direction_match = re.search(r"\b(input|output|inout)\b", token)
        if direction_match:
            direction = direction_match.group(1)
            token = token[direction_match.end() :].strip()
            token = re.sub(r"^(?:wire|reg|logic|signed|unsigned)\b\s*", "", token)
            width_match = re.match(r"(\[[^\]]+\])", token)
            if width_match:
                width = width_match.group(1)
                token = token[width_match.end() :].strip()
            else:
                width = ""
            token = re.sub(r"^(?:wire|reg|logic|signed|unsigned)\b\s*", "", token)
        if not direction:
            continue
        name_match = re.search(r"([A-Za-z_][A-Za-z0-9_$]*)\s*(?:=\s*.+)?$", token)
        if not name_match:
            continue
        name = name_match.group(1)
        result.append(
            {
                "name": name,
                "direction": direction,
                "width": width,
                "group": port_group(name),
            }
        )
    return result


def scan_sources(
    atlas_rows: list[dict[str, str]],
) -> tuple[dict[str, dict[str, Any]], list[dict[str, Any]]]:
    module_defs: dict[str, dict[str, Any]] = {}
    files: list[dict[str, Any]] = []
    for row in atlas_rows:
        source_path = REPO_ROOT / row["path"]
        text = source_path.read_text(encoding="utf-8", errors="replace")
        match = MODULE_RE.search(text)
        module_name = match.group(1) if match else None
        file_info: dict[str, Any] = {**row, "module": module_name}
        files.append(file_info)
        if not module_name:
            continue
        if module_name in module_defs:
            raise ValueError(
                f"module {module_name} 同时定义于 "
                f"{module_defs[module_name]['source']} 和 {row['path']}"
            )
        ports = parse_ports(text, module_name)
        group_counts = Counter(port["group"] for port in ports)
        clean_text = strip_verilog_comments(text)
        module_defs[module_name] = {
            "name": module_name,
            "source": row["path"],
            "status": row["status"],
            "description": row["description"],
            "category": row["category"],
            "posedgeBlocks": len(POSEDGE_RE.findall(clean_text)),
            "sequentialTargets": extract_sequential_targets(text),
            "ports": ports,
            "portGroups": {
                group: group_counts.get(group, 0)
                for group in (
                    "clock_reset",
                    "axi",
                    "fetch",
                    "dispatch",
                    "memory",
                    "completion",
                    "control",
                    "privilege",
                    "debug",
                    "other",
                )
            },
            "instances": [],
            "parents": [],
            "children": [],
            "timingIds": [],
            "rich": RICH_MODULE_META.get(module_name, {}),
        }
    return module_defs, files


def parse_hierarchy(
    xml_path: Path, module_defs: dict[str, dict[str, Any]]
) -> tuple[list[dict[str, Any]], str, str]:
    root = ET.parse(xml_path).getroot()
    cells = root.find("cells")
    if cells is None:
        raise ValueError(f"{xml_path}: 缺少 <cells>")
    root_cell = cells.find("cell")
    if root_cell is None:
        raise ValueError(f"{xml_path}: 缺少根 cell")

    instances: list[dict[str, Any]] = []
    node_by_id: dict[str, dict[str, Any]] = {}
    parent_types: dict[str, set[str]] = defaultdict(set)
    child_types: dict[str, set[str]] = defaultdict(set)

    def walk(cell: ET.Element, parent: str | None, depth: int) -> None:
        instance_id = cell.attrib["hier"]
        raw_module = cell.attrib["submodname"]
        module_name = base_module(raw_module)
        node = {
            "id": instance_id,
            "instance": cell.attrib["name"],
            "module": module_name,
            "rawModule": raw_module,
            "parent": parent,
            "children": [],
            "depth": depth,
            "source": module_defs.get(module_name, {}).get("source", ""),
        }
        instances.append(node)
        node_by_id[instance_id] = node
        if module_name in module_defs:
            module_defs[module_name]["instances"].append(instance_id)
        if parent:
            parent_node = node_by_id[parent]
            parent_node["children"].append(instance_id)
            parent_types[module_name].add(parent_node["module"])
            child_types[parent_node["module"]].add(module_name)
        for child in cell.findall("cell"):
            walk(child, instance_id, depth + 1)

    walk(root_cell, None, 0)
    for module_name, module_info in module_defs.items():
        module_info["parents"] = sorted(parent_types[module_name])
        module_info["children"] = sorted(child_types[module_name])

    soc_root = root_cell.attrib["hier"]
    core_candidates = [
        node["id"] for node in instances if node["module"] == "NpcCoreTop"
    ]
    if len(core_candidates) != 1:
        raise ValueError(f"期望恰好 1 个 NpcCoreTop 实例，实际 {core_candidates}")
    return instances, core_candidates[0], soc_root


def heading_before(text: str, position: int) -> str:
    candidates = [match for match in HEADING_RE.finditer(text, 0, position)]
    return candidates[-1].group(2).strip() if candidates else "WaveDrom 时序"


def normalize_binary_holds(wave: str) -> str:
    """把重复显式二值电平转换为 WaveDrom 的保持符，避免伪毛刺。"""

    normalized: list[str] = []
    active_level: str | None = None
    for token in wave:
        if token in {"0", "1"}:
            if token == active_level:
                normalized.append(".")
            else:
                normalized.append(token)
                active_level = token
        else:
            normalized.append(token)
            if token != ".":
                active_level = None
    return "".join(normalized)


def normalize_wave_fields(value: Any) -> Any:
    """递归规范 WaveJSON，同时保留 group/edge 等其他字段。"""

    if isinstance(value, dict):
        return {
            key: (
                normalize_binary_holds(item)
                if key == "wave" and isinstance(item, str)
                else normalize_wave_fields(item)
            )
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [normalize_wave_fields(item) for item in value]
    return value


def timing_module_hints(chapter_name: str, title: str, diagram: dict[str, Any]) -> list[str]:
    prefix = chapter_name[:2]
    defaults = {
        "00": ["PipeStageReg", "OooFrontend", "OooIntBackend"],
        "01": ["NpcCoreTop", "OooCoreTopGlue", "OooRob", "OooWriteback"],
        "02": [
            "OooFrontend",
            "OooFetchAxiBridge",
            "OooFetchPacketFifo",
            "OooFetchPcOutstandingSequencer",
            "OooFrontendDispatchGate",
        ],
        "03": [
            "OooAluDecodeBackend",
            "OooDispatchBackend",
            "OooRenameMap",
            "OooFreeList",
            "OooBusyTable",
            "OooIntIssueQueue",
            "OooRob",
        ],
        "04": [
            "OooIntBackend",
            "OooIntIssueQueue",
            "OooMulDivUnit",
            "OooClmulUnit",
            "OooBranchResolveRecoveryGate",
        ],
        "05": [
            "OooFpBackend",
            "OooFpIssueQueue",
            "OooFpArithGate",
            "OooFpLongOpGate",
            "OooFpDivIter",
            "OooFpSqrtIter",
        ],
        "06": [
            "OooMemoryAccess",
            "OooLoadQueue",
            "OooStoreQueue",
            "OooMemInflightQueue",
            "OooMemAxiBridge",
            "OooDualMemAxiArbiter",
            "OooDataWordCache",
        ],
        "07": ["OooRob", "OooWriteback", "OooArchRegFile", "CsrFile"],
        "08": [
            "OooControlPlane",
            "OooControlEventApplySequencer",
            "OooPendingDrainResolveGate",
            "OooRedirectArbiter",
        ],
        "09": ["NpcTop", "NpcAxiBus", "AxiXbar", "AxiClint", "AxiPlic"],
        "10": [
            "NpcCoreTop",
            "OooFrontend",
            "OooIntBackend",
            "OooFpBackend",
            "OooMemoryAccess",
            "OooRob",
            "OooControlPlane",
        ],
    }
    hints = set(defaults.get(prefix, []))
    signal_names = " ".join(
        str(signal.get("name", ""))
        for signal in diagram.get("signal", [])
        if isinstance(signal, dict)
    )
    text = f"{title} {signal_names}".lower()
    keywords = {
        "fifo": ["OooFetchPacketFifo"],
        "redirect": ["OooRedirectArbiter", "OooFetchPcOutstandingSequencer"],
        "discard": ["OooFetchPcOutstandingSequencer", "OooFetchAxiBridge"],
        "dispatch": ["OooDispatchBackend", "OooFrontendDispatchGate"],
        "rename": ["OooRenameMap", "OooDispatchBackend"],
        "issue": ["OooIntIssueQueue", "OooFpIssueQueue"],
        "fma": ["OooFpArithGate", "OooFpBackend"],
        "fpwb": ["OooFpBackend", "OooRob"],
        "load": ["OooLoadQueue", "OooMemAxiBridge"],
        "store": ["OooStoreQueue", "OooMemAxiBridge"],
        "aw": ["OooMemAxiBridge", "OooDualMemAxiArbiter"],
        "commit": ["OooRob", "OooWriteback", "OooArchRegFile"],
        "head0 csr": [
            "OooFrontend",
            "OooRob",
            "OooCsrAccessRequestMux",
            "OooStopPendingSequencer",
            "OooControlEventApplySequencer",
            "CsrFile",
        ],
        "head0_csr": [
            "OooFrontend",
            "OooRob",
            "OooCsrAccessRequestMux",
            "OooStopPendingSequencer",
            "OooControlEventApplySequencer",
            "CsrFile",
        ],
        "trap": ["OooControlPlane", "CsrFile"],
        "irq": ["AxiClint", "AxiPlic", "CsrFile"],
    }
    for keyword, modules in keywords.items():
        if keyword in text:
            hints.update(modules)
    return sorted(hints)


def parse_timings() -> list[dict[str, Any]]:
    timings: list[dict[str, Any]] = []
    for markdown_path in sorted(STUDY_ROOT.glob("[0-9][0-9]-*.md")):
        text = markdown_path.read_text(encoding="utf-8")
        for match in WAVEDROM_RE.finditer(text):
            diagram = normalize_wave_fields(json.loads(match.group(1)))
            if not isinstance(diagram, dict) or "signal" not in diagram:
                continue
            title = str(diagram.get("head", {}).get("text") or heading_before(text, match.start()))
            timing_id = f"wave-{len(timings) + 1:02d}"
            signals: list[dict[str, Any]] = []
            for raw_signal in diagram.get("signal", []):
                if not isinstance(raw_signal, dict):
                    continue
                signals.append(
                    {
                        "name": str(raw_signal.get("name", "")),
                        "wave": str(raw_signal.get("wave", "")),
                        "data": raw_signal.get("data", [])
                        if isinstance(raw_signal.get("data", []), list)
                        else [str(raw_signal.get("data", ""))],
                    }
                )
            timings.append(
                {
                    "id": timing_id,
                    "title": title,
                    "chapter": markdown_path.name,
                    "chapterHref": markdown_path.name,
                    "wave": diagram,
                    "signals": signals,
                    "moduleHints": timing_module_hints(markdown_path.name, title, diagram),
                }
            )
    if len(timings) != 38:
        raise ValueError(f"期望 38 个 WaveDrom，实际 {len(timings)}")
    return timings


def bind_timings(
    module_defs: dict[str, dict[str, Any]],
    timings: list[dict[str, Any]],
    transactions: list[dict[str, Any]],
) -> None:
    for timing in timings:
        for module_name in timing["moduleHints"]:
            if module_name in module_defs:
                module_defs[module_name]["timingIds"].append(timing["id"])
    chapter_fallback = {
        "instruction-life": "01-",
        "fetch-packet": "02-",
        "integer-completion": "04-",
        "fp-completion": "05-",
        "load": "06-",
        "store": "06-",
        "branch-recovery": "08-",
        "csr-queue-head": "07-",
        "precise-trap": "07-",
    }
    for transaction in transactions:
        terms = [term.lower() for term in transaction.pop("timingTerms", [])]
        matches = []
        for timing in timings:
            haystack = " ".join(
                [
                    timing["title"],
                    timing["chapter"],
                    *[signal["name"] for signal in timing["signals"]],
                ]
            ).lower()
            if any(term in haystack for term in terms):
                matches.append(timing["id"])
        if not matches:
            prefix = chapter_fallback[transaction["id"]]
            matches = [
                timing["id"]
                for timing in timings
                if timing["chapter"].startswith(prefix)
            ]
        transaction["timingIds"] = matches[:4]
        transaction_modules: list[str] = []
        for phase in transaction["phases"]:
            transaction_modules.append(phase["module"])
            side_path = phase.get("sidePath")
            if isinstance(side_path, dict) and side_path.get("module"):
                transaction_modules.append(side_path["module"])
        transaction["modules"] = list(dict.fromkeys(transaction_modules))


def source_fingerprint(paths: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.as_posix().encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def product_configuration() -> dict[str, str]:
    assignments = {
        match.group("name"): match.group("value")
        for match in MAKE_ASSIGNMENT_RE.finditer(
            PRODUCT_DEFAULTS_PATH.read_text(encoding="utf-8")
        )
    }
    required = {
        "NPC_PRODUCT_RTL_CONFIG_SCHEMA",
        "OOO_CSR_QUEUE_HEAD",
        "OOO_TERMINAL_HOLDER_ASSERT",
    }
    missing = required.difference(assignments)
    if missing:
        raise ValueError(
            "产品 RTL 默认配置缺少字段：" + ", ".join(sorted(missing))
        )

    define_text = DEFINE_PATH.read_text(encoding="utf-8")
    fallback_match = re.search(
        r"(?m)^\s*`define\s+OOO_CSR_QUEUE_HEAD\s+(?P<value>\S+)\s*$",
        define_text,
    )
    if not fallback_match:
        raise ValueError("define.v 缺少 OOO_CSR_QUEUE_HEAD fallback")

    queue_head = assignments["OOO_CSR_QUEUE_HEAD"]
    fallback = fallback_match.group("value")
    if queue_head not in {"1", "y"} or fallback not in {"1", "1'b1"}:
        raise ValueError(
            "当前 CSR 队头事务要求产品默认与 define fallback 均开启："
            f"product={queue_head} fallback={fallback}"
        )

    return {
        "schema": assignments["NPC_PRODUCT_RTL_CONFIG_SCHEMA"],
        "source": PRODUCT_DEFAULTS_PATH.relative_to(REPO_ROOT).as_posix(),
        "defineFallbackSource": DEFINE_PATH.relative_to(REPO_ROOT).as_posix(),
        "OOO_CSR_QUEUE_HEAD": queue_head,
        "OOO_CSR_QUEUE_HEAD_FALLBACK": fallback,
        "OOO_TERMINAL_HOLDER_ASSERT": assignments[
            "OOO_TERMINAL_HOLDER_ASSERT"
        ],
        "activeCsrPath": (
            "合法非 FP head0 CSR → ROB queue-head；"
            "lane1/FP CSR 与非 CSR SYSTEM/trap → pending full-drain"
        ),
    }


def ensure_elaboration_fresh(xml_path: Path) -> None:
    inputs = [
        NPC_MAKEFILE_PATH,
        PRODUCT_DEFAULTS_PATH,
        VSRC_ROOT / "filelist.mk",
        *sorted(
            path
            for path in VSRC_ROOT.rglob("*")
            if path.is_file() and path.suffix in {".v", ".sv", ".vh", ".svh"}
        ),
    ]
    xml_mtime = xml_path.stat().st_mtime_ns
    stale_inputs = [
        path for path in inputs if path.stat().st_mtime_ns > xml_mtime
    ]
    if stale_inputs:
        newest = sorted(
            stale_inputs, key=lambda path: path.stat().st_mtime_ns, reverse=True
        )[:5]
        details = ", ".join(
            path.relative_to(REPO_ROOT).as_posix() for path in newest
        )
        raise ValueError(
            "NpcTop XML 早于当前 elaboration 输入，拒绝生成旧层次。"
            "先运行 tools/generate_elaboration_xml.sh。较新的输入："
            + details
        )


def script_safe_json(payload: Any) -> str:
    return (
        json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
        .replace("&", "\\u0026")
        .replace("<", "\\u003c")
        .replace(">", "\\u003e")
    )


def read_vendor_file(path: Path) -> str:
    if not path.is_file():
        raise FileNotFoundError(
            f"缺少 WaveDrom vendor 文件：{path}\n"
            "先下载 https://registry.npmjs.org/wavedrom/-/wavedrom-3.6.2.tgz "
            "并解压到 /tmp/rv64-wavedrom-3.6.2"
        )
    text = path.read_text(encoding="utf-8")
    if "</script" in text.lower():
        raise ValueError(f"{path}: 含 </script，不能直接内嵌")
    return text


def build_payload(
    xml_path: Path,
) -> dict[str, Any]:
    ensure_elaboration_fresh(xml_path)
    product_config = product_configuration()
    atlas_rows = parse_atlas()
    module_defs, files = scan_sources(atlas_rows)
    instances, core_root, soc_root = parse_hierarchy(xml_path, module_defs)
    timings = parse_timings()
    transactions = json.loads(json.dumps(TRANSACTIONS, ensure_ascii=False))
    enrich_transaction_phases(transactions)
    bind_timings(module_defs, timings, transactions)

    missing_instance_modules = sorted(
        {instance["module"] for instance in instances}.difference(module_defs)
    )
    if missing_instance_modules:
        raise ValueError(
            "实例树中的 module 没有 vsrc 定义映射："
            + ", ".join(missing_instance_modules)
        )
    if not all(transaction["timingIds"] for transaction in transactions):
        raise ValueError("存在未绑定 WaveDrom 的 transaction")

    fingerprint_paths = [
        ATLAS_PATH,
        xml_path,
        NPC_MAKEFILE_PATH,
        PRODUCT_DEFAULTS_PATH,
        SCRIPT,
        CSS_PATH,
        JS_PATH,
        ELABORATION_SCRIPT_PATH,
        *sorted(STUDY_ROOT.glob("[0-9][0-9]-*.md")),
        *sorted(path for path in VSRC_ROOT.rglob("*") if path.is_file()),
    ]
    payload = {
        "meta": {
            "title": "RV64 Core Interactive Technical Reference",
            "documentId": "RV64CORE-TRM-001",
            "revision": "Rev. D",
            "snapshotDate": date.today().isoformat(),
            "sourceFingerprint": source_fingerprint(fingerprint_paths),
            "elaborationSha256": hashlib.sha256(xml_path.read_bytes()).hexdigest(),
            "waveDromVersion": "3.6.2",
            "fileCount": len(files),
            "moduleCount": len(module_defs),
            "instanceCount": len(instances),
            "timingCount": len(timings),
            "transactionCount": len(transactions),
            "statusCounts": dict(Counter(file["status"] for file in files)),
        },
        "coreRoot": core_root,
        "socRoot": soc_root,
        "productConfig": product_config,
        "categories": CATEGORY_LABELS,
        "instances": instances,
        "modules": module_defs,
        "files": files,
        "transactions": transactions,
        "timings": timings,
    }
    return payload


def html_document(
    payload: dict[str, Any],
    css_text: str,
    app_js: str,
    wave_skin: str,
    wave_runtime: str,
    wave_license: str,
) -> str:
    if "</script" in app_js.lower():
        raise ValueError("interactive_datasheet.js 含 </script，不能直接内嵌")
    data_json = script_safe_json(payload)
    license_text = html.escape(wave_license)
    core_root = payload["coreRoot"]
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <meta name="description" content="当前 RV64 双发射乱序 Core 的交互式模块层次、transaction、时序与 150 文件技术参考。">
  <meta name="generator" content="build_interactive_datasheet.py">
  <title>RV64 Core Interactive Technical Reference</title>
  <style>
{css_text}
  </style>
</head>
<body data-font-scale="large">
  <!-- RV64_INTERACTIVE_DATASHEET_BEGIN -->
  <header class="topbar">
    <div class="brand">
      <div class="brand-mark" aria-hidden="true">RV</div>
      <div class="brand-copy">
        <p class="brand-title">RV64 Core Technical Reference</p>
        <p class="brand-subtitle">Interactive module datasheet</p>
      </div>
    </div>
    <div class="global-search">
      <label class="sr-only" for="globalSearch">搜索模块、实例、信号、transaction 或源文件</label>
      <input
        id="globalSearch"
        class="search-input"
        type="search"
        autocomplete="off"
        placeholder="搜索模块 / 实例 / 信号 / transaction / 源文件"
        aria-controls="searchResults"
        aria-autocomplete="list"
      >
      <span class="search-hint" aria-hidden="true">/</span>
      <div id="searchResults" class="search-results" role="listbox" hidden></div>
    </div>
    <div class="top-actions">
      <button id="menuButton" type="button" class="action-button menu-button" data-menu-open aria-controls="sidebar" aria-expanded="false">目录</button>
      <button id="fontScaleButton" type="button" class="action-button font-scale-button" data-font-scale-control aria-label="当前字号：大；点击切换字号">字号 大</button>
      <button type="button" class="action-button" data-copy-link>复制深链接</button>
      <button type="button" class="action-button" data-print>打印 / PDF</button>
    </div>
  </header>
  <div class="app-shell">
    <aside id="sidebar" class="sidebar" aria-label="实例、事务和源码导航">
      <div class="sidebar-head">
        <p class="sidebar-kicker">Progressive hierarchy</p>
        <div id="navTabs"></div>
      </div>
      <div id="sidebarBody" class="sidebar-body" role="tabpanel"></div>
    </aside>
    <button type="button" class="sidebar-overlay" data-sidebar-close aria-label="关闭导航"></button>
    <main id="mainContent" class="content">
      <noscript>
        <article class="datasheet">
          <div class="document-ribbon">
            <span>RV64CORE-TRM-001 · NO-JAVASCRIPT OVERVIEW</span>
            <span>{html.escape(payload['meta']['revision'])}</span>
          </div>
          <header class="datasheet-header">
            <div>
              <p class="part-kicker">RV64 OOO CORE</p>
              <h1 class="part-title">NpcCoreTop</h1>
              <p class="part-subtitle">启用 JavaScript 可展开完整实例树、搜索 {payload['meta']['fileCount']} 个 vsrc 文件并查看 {payload['meta']['timingCount']} 幅 WaveDrom。当前仍可使用下面的普通链接阅读静态讲义。</p>
            </div>
          </header>
          <div class="datasheet-body">
            <section class="section">
              <h2 class="section-title"><span class="section-number">1.0</span>TOP-LEVEL MODULES</h2>
              <ul>
                <li>OooFetchAxiBridge — IFU / MMU / ICache / AXI</li>
                <li>OooDualMemBridgeWrapper — LSU / MMU / DCache / AXI</li>
                <li>OooLsuAxiLaneAdapter — 双 memory lane 数据通道适配</li>
                <li>CsrFile — CSR、特权态、中断状态</li>
                <li>OooCoreTopGlue — OoO 微架构主体</li>
              </ul>
            </section>
            <section class="section">
              <h2 class="section-title"><span class="section-number">2.0</span>STATIC STUDY MANUAL</h2>
              <p><a href="README.md">打开 RV64 Core 源码学习讲义目录</a></p>
              <p><a href="01-全局拓扑与指令一生.md">全局拓扑与指令一生</a></p>
              <p><a href="10-时序反压与WaveDrom.md">时序、反压与 WaveDrom</a></p>
              <p><a href="11-逐文件源码地图.md">150 个 vsrc 文件地图</a></p>
            </section>
          </div>
        </article>
      </noscript>
    </main>
  </div>
  <div id="toast" class="toast" role="status" hidden></div>
  <div id="liveStatus" class="sr-only" aria-live="polite"></div>
  <!-- RV64_INTERACTIVE_DATASHEET_END -->
  <script id="rv64-data" type="application/json">{data_json}</script>
  <script id="thirdPartyLicense" type="text/plain">{license_text}</script>
  <script>
{wave_skin}
  </script>
  <script>
{wave_runtime}
  </script>
  <script>
{app_js}
  </script>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--top-xml", type=Path, default=DEFAULT_XML)
    parser.add_argument("--wavedrom-dir", type=Path, default=DEFAULT_WAVEDROM_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    if not args.top_xml.is_file():
        print(f"[interactive-build] missing XML: {args.top_xml}", file=sys.stderr)
        return 2
    try:
        payload = build_payload(args.top_xml)
    except (OSError, ValueError, ET.ParseError) as exc:
        print(f"[interactive-build] ERROR: {exc}", file=sys.stderr)
        return 2
    css_text = CSS_PATH.read_text(encoding="utf-8")
    app_js = JS_PATH.read_text(encoding="utf-8")
    wave_skin = read_vendor_file(args.wavedrom_dir / "skins" / "default.js")
    wave_runtime = read_vendor_file(args.wavedrom_dir / "wavedrom.min.js")
    wave_license = read_vendor_file(args.wavedrom_dir / "LICENSE")

    output_text = html_document(
        payload, css_text, app_js, wave_skin, wave_runtime, wave_license
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output_text, encoding="utf-8")

    print(f"[interactive-build] output={relative_repo_path(args.output)}")
    print(f"[interactive-build] files={payload['meta']['fileCount']}")
    print(f"[interactive-build] modules={payload['meta']['moduleCount']}")
    print(f"[interactive-build] instances={payload['meta']['instanceCount']}")
    print(f"[interactive-build] transactions={payload['meta']['transactionCount']}")
    print(f"[interactive-build] wavedrom={payload['meta']['timingCount']}")
    print(f"[interactive-build] bytes={args.output.stat().st_size}")
    print(
        "[interactive-build] source_sha256="
        f"{payload['meta']['sourceFingerprint']}"
    )
    print("[interactive-build] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
