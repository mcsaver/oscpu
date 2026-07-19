# PPA-R2 frontend II=1 candidate

## 结论

本目录保存一份只改 frontend hit throughput 的候选补丁。它把当前同步单口 FPC 的命中稳态从固定 `II=3` 改为 `II=1`：初始请求在 H0 发读，H1 返回旧请求的命中响应，并可在同一边沿接受 successor、发起下一次同步读。

这不是 200 MHz 已闭合声明。补丁已通过隔离 RTL 定向回归与组合环 lint，但仍必须用 fresh synthesis/OpenSTA 在 5.000 ns 下验证下面列出的 fast recurrence。当前没有运行 Linux boot。

## 审计与补丁基线

- canonical HEAD（审计时）：`31e90c679`
- staged tree：`2083764ab3ef5259cc8d030689c8e2a24b46eb9f`
- staged anonymous snapshot：`30b41844b2e53bc998836ab9bc90fad82519a74b`
- 历史刀 F：`0a98a8805c44349ea1387a9e8b7ec91d80281784`
- 历史 T3J：`30f34cffc4a1a882feb501471945e62e3a0cb2f8`

补丁基于 anonymous snapshot，内容只涉及：

- RTL：`npc/rv64/vsrc/frontend/OooFetchAxiBridge.v`
- RTL：`npc/rv64/vsrc/cache/OooFetchPacketCache.v`
- 定向测试：`npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv`

canonical 的 RTL/testbench 未被本隔离任务直接修改。

## 当前为什么是 II=3

snapshot `30b4184` 的固定命中路径是：

```text
request/replacement fire
  -> S_CACHE_READ
  -> S_LOOKUP
  -> S_RESP
```

精确锚点：

- Bridge `:452-466`：只有 `S_CACHE_READ` 同时打开 physical read 和 semantic lookup。
- `:789-810`：`S_CACHE_READ` 无条件进入 `S_LOOKUP`。
- `:813-848`：`S_LOOKUP` 只把命中/fault 落到 response q。
- `:618-629`：只有 `S_RESP` 对外给 valid/payload。
- `:1062-1070`：响应 replacement 重新进入 `S_CACHE_READ`。

所以每个命中响应之间固定隔两拍，steady-state initiation interval 是 3。

## 候选微架构

| 周期/状态 | 旧请求 | successor |
| --- | --- | --- |
| H0 / request fire | state-preopened SRAM 对 live PC 发同步读；candidate 与 ITLB/PA 同边沿注册 | 无 |
| H1 / `S_CACHE_READ` | SRAM Q、FPC tag shadow、candidate、ITLB q 对齐；fast hit 可组合响应 | old rsp fire 与 new req fire 同边沿；保持 H1 |
| H1 stall | cache payload 落现有 response q；old candidate 原子转入 exec；进入 `S_RESP` skid | 不接受 |
| H1 miss/fault | old candidate 原子转入 exec；进入当前 exact slow FSM | 不接受 |
| `S_RESP` replacement | 已注册 old response 消费 | 同边沿预读 successor；下一拍直接 H1 |

关键合同：

```verilog
read_window = state == S_IDLE ||
              state == S_CACHE_READ ||
              state == S_RESP;
semantic_lookup_issue = fetch_req_fire;

fast_hit = lookup_hit_no_snoop &&
           !invalidate_valid_i &&
           registered_translation_permission_ok &&
           conservative_fast_pmp_ok;
```

`S_LOOKUP` 编码保留给 wave/XMR，但 production transition 不再进入。

FPC 的 `paging/priv/satp/pc/index` shadow 改为每拍采样；`dec_en_q` 仍是唯一 semantic decision qualifier。dummy read/context 没有 accept 时不可见。这把 `req_fire` 从宽 context CE mux 移除，不改变 cache-visible 语义。

## 历史提交只借鉴了什么

### `0a98a8805`

它证明 fast response/turnover/skid 能把 CoreMark CPI 从提交记录中的 `1.633` 降到 `1.207`：

- Bridge `:474-485`：`S_LOOKUP` hit 组合响应，hit+ready 同拍 request-ready。
- `:565-601`：hit+successor 留在 lookup；无 successor 回 IDLE；stall 落 `S_RESP`。
- `:827-846`：`S_RESP` 同拍 replacement。

候选只复用了这三分支语义，没有恢复它的旧权限、AXI 或 8B fetch 实现。

### `30f34cffc`

它证明 physical read window 与 semantic accept 可以分离：

- Bridge `:401-420`：read window 为 `IDLE|RESP|LOOKUP`，semantic lookup 为 `fetch_req_fire_w`，live tuple 驱动读地址。
- `:533-550`：no-snoop fast response、flush 压 ready。
- `:675-715`：fusion、无 successor、stall/invalidate 精确降级。
- `:717-739`：fixed-4B PMP reject 只关闭 fast path，继续 exact-2B slow path。
- `:923-945`：`S_RESP` 预开读窗并同拍接 successor。
- FPC `:110-113`：`sram_en=lookup_read_en||write`，dummy read 不产生 semantic decision。
- FPC `:153-168`：exact hit 覆盖两拍 invalidate；no-snoop hit 必须由使用方叠加全局 `!invalidate_valid`。

T3J 的历史 STA 曾报告 ready/fire 到 payload SRAM enable 为 `-9.377 ns`；因此候选 read-enable 只允许由 registered state 产生，绝不能重新依赖 hit/ready/fire。

## 绝不能带回的旧块

不要从 `0a98a8805` 整块恢复：

- `:260-263` 的 `pmp_active ? checks : allow`；它会绕过 S/U + 空 PMP 的 default-deny。
- `:291-294,:487-496` 的 direct-miss lookup 直接驱动 ARVALID/ARADDR。
- `:387-401` 的 ITLB→PMP 未注册组合链。
- `:603-642` 的 fixed-4B PMP reject 直接成为整包 access fault；reject 必须只降级到 exact-2B slow path。
- `:760-798` 的 8B R0/R1/`first_beat_q` 拼包；它破坏 exact 2B frontier、RVC 跨页和 fault provenance。
- flush 清事务 owner、撤回 AXI channel 或丢 A-update 的逻辑。
- FPC `sram_en=lookup_en||write`。
- fast arm直接使用含 decision-window snoop 地址比较的 `lookup_hit_o`。

不要从 `30f34cffc` 整块恢复：

- 单套 fire-gated `{pc,paging,priv,satp,svpbmt}` owner bank。
- `:675-702` replacement 对宽 owner 与全部 scratch 的同拍写入。
- `:297-312` ITLB→PMP 未注册组合链。
- `:552-555` 的 `ARVALID && !mmu_flush_i`；flush 不能撤回已呈现、被反压的 AR。
- 未经 `S_WALK_CHECK` 注册 PTE address/PMP decision 就进入 PTW AR。
- 动态 `walk_pte_addr_w` 直接成为 A-update AWADDR。
- response-to-dispatch bypass、FIFO full+pop ready look-through、branch-prefetch target 组合进 request PC。
- 多个 frontend outstanding。第一刀保持 single outstanding。

## 保留的 T4A/T4T 正确性

候选保留并由现有回归覆盖：

- fixed-role candidate/exec 与 candidate→exec 原子交接；
- request-fire ITLB/PA 注册边界；
- slow owner 在 PTW/PMP/AXI、response stall、flush、A-update 期间不变；
- 每级 PTW 的 registered `S_WALK_CHECK`；
- exact 2B frontier、跨页翻译、successful-prefix/fault-suffix split `{0,2,4,6}`；
- WALK/FETCH AR valid-until-fire 与 DROP/DRAIN；
- A-update AW/W/B 独立握手与 sticky `ad_drop_q`；
- PTE WRITE PMP；
- 无 response-to-dispatch bypass；
- response credit 只读 registered FIFO occupancy；
- simultaneous rsp-fire+req-fire 后 outstanding 仍为 1。

T4T 的 D-cache tag-mask/RMW/macro 边界不在本补丁 RTL scope 内；正式 promotion 仍须复跑 T4T macro-boundary，确认 tag mask tie-high、RMW tag owner 与 1RW 合同没有漂移。

候选有意放松旧 T3R 的“valid/payload 只能由 `S_RESP/q` 驱动”结构规则；同步单口 SRAM 要达到 II=1 必须允许 H1 fast arm。其功能内核仍保留：single outstanding、旧响应只在 fire 后换 owner、stall payload 稳定、无重复 response。

## Redirect 与 invalidate

Bridge 没有 branch-redirect 输入，因此定向 TB 只能直接验证 `mmu_flush` 在 H1 fast hit 上同时取消旧 response 与 successor request；测试名称明确标为 flush proxy，不把它冒充 branch redirect。

真正的 direct/resolve/pred-taken redirect 防火墙仍位于 `OooFrontend/OooFetchFlowControl`：

- redirect/taken 拍阻断顺序 request；
- response drop/FIFO clear 优先；
- `fetch_rsp_ready` 只依赖 registered FIFO/outstanding/flush 类状态；
- bridge ready 不依赖 request valid/PC，因此没有 ready-valid 组合环。

invalidate 覆盖：

- issue-window 同址 invalidate：`lkp_inv_q` 阻止 hit；
- decision-window 同址 invalidate：exact hit kill 后 slow refetch；
- decision-window异址 invalidate：全局关 fast fusion，但 exact hit 落 `S_RESP` skid；
- fast arm不包含 snoop 地址比较。

## 组合环与 5 ns 风险

Verilator 未报告 `UNOPTFLAT`。结构上没有组合环，因为 `Sram4096x199` 的 Q 是 clocked output；闭环包含时钟边沿：

```text
old SRAM Q -> response/decode/next PC -> new SRAM address D
     -> clock -> next SRAM Q
```

需要 fresh STA 单列以下路径：

1. SRAM Q/tag/PMP → fast rsp-valid → FlowControl rsp-fire → successor semantic accept。
2. SRAM Q/payload → RVC length → packet next PC → RequestMux → FPC SRAM address D。
3. SRAM Q → branch classify/BPU → pred-taken/control-stop → req-valid。
4. SRAM Q → decode/static facts → FIFO entry D。
5. state-preopened dummy read 带来的 SRAM dynamic toggle/power。

若第 2 条不能在 5 ns 闭合，普通插拍会退化成 II=2。下一步应采用 predecoded length/control sidecar，或 fixed-block fetch + assembly queue；不能把 SRAM read-enable 接回 fire，也不能恢复组合 bypass/多 outstanding。

## 隔离验证结果

补丁从 anonymous snapshot 的干净 detached worktree `/tmp/ysyx-ppa-r2-frontend` 重新 `git apply` 后，以标准 `npc/rv64/testbench/Makefile`、`-DOOO_ASSERT` 运行：

- PASS `tb_ooo_fetch_axi_bridge`
  - 32 个连续 H1 response+successor 双 fire；
  - fast stall→`S_RESP` skid；
  - `S_RESP` replacement→下一拍 H1；
  - invalidate 两个窗口；
  - H1 `mmu_flush` cancellation proxy。
- PASS `tb_ooo_fetch_packet_cache`
- PASS `tb_ooo_fetch_axi_access_attrs`
- PASS `tb_ooo_fetch_page_end_fault`
- PASS `tb_ooo_fetch_access_footprint`
- PASS `tb_ooo_fetch_axi_bridge_xbar`
- PASS `tb_ooo_fetch_flow_control`
- PASS `tb_ooo_fetch_request_mux`
- PASS `tb_ooo_fetch_pc_outstanding_sequencer`
- PASS Verilator lint-only；只有既有 unused-signal warning，无 `UNOPTFLAT`。
- PASS canonical `git apply --check`、isolated worktree apply、`git diff --check`、reverse apply check。

未运行：

- fresh whole-core synthesis/OpenSTA 5.000 ns；
- CoreMark 性能/CRC/commit 对比；
- Linux boot；
- qualified power；
- T4T D-cache macro-boundary 回归。

## 使用

从上述 baseline 内容执行：

```bash
git apply --check   .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2-frontend/frontend-ii1-candidate.patch

git apply   .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2-frontend/frontend-ii1-candidate.patch
```

正式合入前必须把 fresh 5 ns STA、CoreMark CPI/CRC/commits、全 module regression 和 T4T macro-boundary 作为 promotion gate，不得仅凭本目录的定向 PASS 宣称 200 MHz。

