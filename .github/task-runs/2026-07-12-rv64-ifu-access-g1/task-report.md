# RV64 IFU-ACCESS-G1：精确取指 footprint / PMP / lane1 fault owner

## Basic information

- `task_id`: 2026-07-12-rv64-ifu-access-g1
- `status`: scoped-complete / fresh-STA-reviewed
- `base_commit`: b1b1156db
- `profile`: npc-dev (+ linux-device/nemu only if sized DPI/platform coverage requires it)
- `parent_goal`: active; complete function + physical 200MHz
- `updated_at`: 2026-07-13 01:28:29 +0800

## Root causes

This is one correctness boundary with four coupled failures, not four symptom patches:

1. **Footprint owner is guessed before length exists.** The bridge reads exact-address 8B and predicts
   the second page with `PC+7`; fixed two-word PMP and RRESP therefore include unused tail bytes.
2. **Size metadata dies at the slave boundary.** Master ARSIZE exists, but xbar slave ports and DPI
   reads have no size; a nominal narrow request would still read/validate 8B.
3. **PMP/cache eligibility is not the architecture fault owner.** `pmp_active=0` bypasses S/U default
   deny; conversely fixed-word rejection can overreject a valid C/C packet and must fall back to exact
   slow path rather than becoming an architectural fault.
4. **lane1 fault visibility is destroyed downstream.** predicted-not-taken branch + lane1 PF/AF is
   suppressed by PairGate and then popped as NOP; access cause is filtered again by the pending arbiter.

## Frozen fetch contract

Let successful instruction lengths be `L0,L1 ∈ {2,4}` and `N=L0+L1 ∈ {4,6,8}`.

- Instruction-data transactions use 2B halfword fault granularity: offsets `0,2,...,N-2`,
  `ARADDR=translate(PC+offset)`, `ARSIZE=3'd1`, `ARPROT[2]=1`.
- A prefix must succeed before its length is read. No translation, PMP check or AR may occur at
  `offset>=N`; the second virtual page is translated iff `N>B`, never merely because `8>B`.
- Every data AR is preceded by an EXEC PMP check using exactly the same PA and 2B size. A PMP fault
  emits no AR. The first failing halfword frontier `F∈{0,2,4,6}` stops younger accesses.
- RRESP belongs only to that halfword. The response ABI is a successful prefix / fault suffix:
  no fault => `resp0=OK,resp1=OK,split=4`; first fault at F => `resp0=OK,resp1=fault,split=F`.
  Decoder support for split=0 is required; the G2 bridge nonzero assertion must be deliberately revised.
- Packet fill stores only the successful `N` bytes and deterministic-zero tail; cross-page packets remain
  uncached. Hit throughput remains one packet/cycle.

## Cache fast-path contract

- `raw_hit && fixed-word checker0 grant && checker1 grant` is a conservative sufficient fast-hit gate.
- Any conservative rejection falls back to exact halfword slow path; it cannot directly raise a fault.
- PMP check always runs, including all-zero config. M-fill→S/no-PMP same-PC must fault, never hit OK.

## AXI/platform contract

- ARSIZE and ARPROT are stored with address/owner and remain stable under slave stall through
  bridge→NpcAxiBus→AxiXbar→NpcTop→AxiDpiSlave.
- PTW PTE read is `ARPROT=data, ARSIZE=8B`; instruction halfword is `exec,2B`.
- IFU instruction narrow reads use standard aligned byte lanes; the bridge extracts by address lane.
  PTW data reads remain aligned 8B. The existing LSU data-read ABI deliberately remains exact-address /
  low-window in this slice because it emits non-AXI cross-lane single beats (for example offset5,size4);
  a permanent control must prove that behavior is unchanged until a separate LSU split-transaction slice.
  Sized DPI validates and reads exactly `nbytes`, never an implicit internal 8B word for IFU/PTW.
- `SLAVE_EXEC_MASK` redirects instruction reads targeting non-executable devices to the existing default
  error slave; UART/CLINT/PLIC/virtio must never observe IFU ARVALID. LSU data controls are unchanged.

## lane1 precise-owner priority

| head0 case | lane1 fault result |
| --- | --- |
| head0 fault/arch-trap/system/exit | head0 wins; lane1 absent |
| JAL/JALR/stop | wrong-path lane1 ignored |
| branch predicted taken | `slot1_valid=0`; ignore, refetch on mispredict |
| branch predicted NT, actual taken | capture pending then squash; no trap |
| branch predicted NT, actual NT | branch retires first; pending PF/AF traps next |
| ordinary head0 | head0 first; pending PF/AF traps next |

## RED matrix

- footprint: C/C offsets 0,2; C/32 and 32/C offsets 0,2,4; 32/32 offsets 0,2,4,6; tail poison cannot fail.
- RRESP: fault at 0/2/4/6 maps by actual L0/L1; unreachable younger AR is forbidden.
- page crossing: B={2,4,6}, N={4,6,8}; second-page halfwords exactly `max(0,N-B)/2`.
- PMP: boundary halfword deny; M-fill→S/no-PMP; cached C/C with only first4B allowed must slow-path OK.
- lane1: ordinary + PF/AF; pred-NT correct/wrong direction; pred-taken poison; false default ACCESS control.
- firewall: IFU→UART/default-error; PTW data8; instruction exec2; LSU control.

## Implementation order

1. Make the old RTL dynamically RED with permanent tests and exact controls.
2. Carry size/prot through xbar/slave and implement sized DPI + execute firewall.
3. Replace the miss path with a registered halfword `CHECK→AR→R` loop; never make RDATA→length→AR a
   same-cycle combinational chain.
4. Fix PairGate/DispatchGate/Arbiter owner priority.
5. Focused/module/assertion/lint/build, Difftest-ON AM, official/PMP/Sv39, CoreMark and fresh 5ns STA.

## Explicit non-claims

- G2 remains CLOSED only for bridge→decoder page-fault provenance.
- IFU-TVAL-G1, PTW-PMP-G1, LSU/device ordering and physical 200MHz remain OPEN until separately proven.

## Bus / device firewall reconnaissance and RED

### Current end-to-end trace

| Hop | ARSIZE | ARPROT | Current consequence |
| --- | --- | --- | --- |
| `OooFetchAxiBridge` | port exists, but hard-wired `3'd3` | port exists, but hard-wired `3'b100` | instruction is exact-address 8B; PTW is incorrectly tagged execute |
| `NpcCoreTop` | direct pass-through | direct pass-through | no loss here |
| `NpcTop` core side | direct into `NpcAxiBus` | direct into `NpcAxiBus` | no loss before bus wrapper |
| `NpcAxiBus` master side | packed into `m_arsize_w` | packed into `m_arprot_w` | both reach `AxiXbar` master port |
| `AxiXbar` | **discarded in `unused_axi4_meta_w`** | captured in `rd_prot_q` and held with owner/address | slave ABI has no size; address decode ignores execute permission |
| `NpcAxiBus` slave side | no port | `s_axi_arprot_o` exists | size provenance ends at xbar |
| `NpcTop` slave/external side | no vector/port | external PSRAM/SDRAM/legacy/virtio ports have prot; UART/CLINT/PLIC do not consume it | device reads cannot reject instruction accesses |
| `NpcSimTop -> AxiDpiSlave` | no wire/input | forwarded to three DPI slaves | DPI chooses `npc_ifetch` vs `npc_mem_read`, but both read a fixed host word |
| `dpi.c -> paddr.c` | no argument | converted to `NpcBusAccess` kind | `npc_in_pmem()` requires 8 bytes and `host_read_word()` reads 8 bytes regardless of requested transfer |

Device decode is first-match over the NpcTop 16-slave map. UART=`0x1000_0000/4KiB` (index 3),
CLINT=`0x0200_0000/64KiB` (index 0), PLIC=`0x0c00_0000/64MiB` (index 1), and default
is index 15 with mask zero. Therefore an IFU address in UART/CLINT/PLIC reaches the real device before
the fallback default. This is not only an error-code mismatch:

- UART `AR fire -> Uart.reg_read_valid_i`; offset 0 asserts `rbr_read_fire_w` and pops RX.
- PLIC claim-address read clears `pending_q[id]` and sets `in_service_q[id]`.
- CLINT reads return OK rather than instruction access fault (no destructive read state, but still executable-MMIO leakage).
- `AxiDefaultSlave` already returns `RRESP=2'b10`; it is the correct no-side-effect sink.

### Frozen compatibility exception

The bus knife must not silently convert existing LSU cross-line reads to standard AXI narrow-lane
semantics. `OooMemAxiBridge` intentionally emits one exact-address, low-justified window read for a
cross-line data access; such a request may cross an 8-byte data-bus boundary. This slice therefore freezes:

- IFU instruction read: 2B, standard address-selected byte lanes; fetch bridge extracts with `ARADDR[2:0]`.
- IFU PTW read: aligned 8B, data access.
- LSU data read: current exact-address / low-justified window ABI remains unchanged in this slice.

The latter is a local compatibility extension, not a claim that the LSU cross-line request is signoff-quality
AXI4. A future LSU split-transfer knife may remove it; this slice must keep functional behavior cycle/data
equivalent.

### Dynamic old-RTL RED and control

- `tb_ooo_fetch_axi_access_attrs.sv`: old RTL compiles and runs to exactly **2 RED**:
  instruction `ARSIZE got=3 expected=1`; PTW `ARPROT got=4 expected=0`. Instruction address/prot,
  PTW address/size, and two-cycle stalled address/size/prot hold controls are green.
- `tb_axi_exec_firewall.sv`: old RTL compiles and runs to exactly **5 RED**:
  default route absent, UART route present, UART access pulse present, response OK rather than error,
  and seeded RBR byte popped. The LSU data read to UART remains routed, observed, data-tagged and OK.
- `tb_ooo_mem_axi_bridge.sv`: added offset=5,size=4 exact-address/low-window passthrough control;
  focused runner is **1/1 PASS** on old RTL.

The two RED tests are deliberately not in `TESTS` until the production implementation lands, so the current
module regression remains truthful rather than being permanently red. They must be registered in the same
patch that turns them green.

### Minimal implementation ABI

1. `AxiXbar` adds `SLAVE_EXEC_MASK` (default all ones for generic compatibility) and slave `s_arsize_o`.
   Read target is address-decoded once, then an `ARPROT[2] && !SLAVE_EXEC_MASK[target]` result is redirected
   once to `DEFAULT_SLAVE`. Capture `rd_size_q` beside owner/address/prot/id; output address/size/prot only
   from those transaction registers while slave AR is stalled. Writes are unchanged.
2. `NpcAxiBus` carries the execute mask parameter and `s_axi_arsize_o`. `NpcTop` supplies an allowlist for
   memory-like windows only: SRAM, MROM, flash, PSRAM, SDRAM and chiplink-memory; UART, CLINT, PLIC,
   virtio, GPIO, PS2, VGA, chiplink-MMIO and legacy-MMIO are non-executable. Default remains the error sink.
3. `NpcTop` exports read size for PSRAM/SDRAM/legacy-MMIO/virtio; `NpcSimTop` wires size to each DPI slave.
   Internal devices may ignore size, but execute reads never reach them because of the xbar firewall.
4. `AxiDpiSlave` validates `ARSIZE<=3`, converts it to `nbytes=1<<ARSIZE`, and passes nbytes into DPI.
   `npc_paddr_read_sized(addr,nbytes,...)` validates/reads only that PMEM range and zeroes unrequested bytes;
   the legacy `npc_paddr_read()` remains an 8B wrapper for monitor/debug callers. For execute reads, the
   low-justified DPI result is placed into address-selected lanes; for data reads, retain the LSU low-window
   compatibility ABI frozen above.
5. The fetch bridge changes PTW metadata immediately (`data+8B`). Instruction metadata changes to `exec+2B`
   only together with the halfword gather FSM; changing size on the old one-read packet path would truncate
   packets and is forbidden.

### Exact production/test file order

1. Bus metadata/firewall: `vsrc/bus/AxiXbar.v`, `vsrc/bus/NpcAxiBus.v`,
   `vsrc/core/NpcTop.v`; update `tb_axi_xbar.sv` and `tb_ooo_fetch_axi_bridge_xbar.sv` for the new size port,
   execute-mask routing, and slave-stall hold.
2. Simulation range contract: `vsrc/sim/NpcSimTop.sv`, `vsrc/sim/AxiDpiSlave.sv`,
   `csrc/dpi.c`, `csrc/include/memory/paddr.h`, `csrc/memory/paddr.c`; add a Verilator+DPI focused test
   whose guarded host buffer proves exec sizes 1/2/4/8 touch exactly nbytes and whose data offset5,size4
   case preserves low-window layout.
3. Fetch transaction owner: `vsrc/frontend/OooFetchAxiBridge.v` plus its spec/assertions and the separate
   footprint RED matrix; only this step enables instruction `ARSIZE=1`.
4. Register `tb_ooo_fetch_axi_access_attrs` and `tb_axi_exec_firewall` in
   `testbench/Makefile`, then run focused tests, full module suite, contract/style/lint/build and core regress.

## Current implementation (2026-07-13)

### Exact fetch owner

- `OooFetchAxiBridge` miss path is now a registered 2B frontier loop over offsets 0/2/4/6.
  Each successful halfword is inserted into a zero-initialized packet; only successful prefixes may
  determine C/32 length. No translation/PMP/AR is issued at offset `>=N`.
- Second-page translation starts only when the next required halfword crosses the page. Raw response
  is canonical success `(OK,OK,4)` or fault `(OK,cause,F)`; PMP/page-walk/RRESP all stop younger AR.
- Two fixed 4B PMP checkers are only a conservative cache fast gate and always run. A rejection falls
  back to exact slow path; M-fill→S/no-PMP cannot bypass default-deny. A=0 leaf is exact-PMP checked
  before the visible PTE write side effect.
- Cross-page packets remain uncached. Exact successful packet fills deterministic-zero tail.

### Bus/platform and device firewall

- `AxiXbar` stores read size/prot beside owner/address/id and exposes `s_arsize_o`; slave stall is driven
  only from these registers. `NpcAxiBus/NpcTop/NpcSimTop` carry the field to DPI/external ports.
- IFU PTE walk is data+8B; instruction data is execute+2B. `AxiDpiSlave` places IFETCH low-window data
  into standard address-selected AXI lanes; LSU data keeps the explicitly frozen low-window extension.
- `SLAVE_EXEC_MASK=16'h6a84` permits only SRAM/MROM/FLASH/PSRAM/SDRAM/CHIPLINK_MEM. Non-executable
  device hits are redirected before arbitration to default error, so UART/CLINT/PLIC/virtio never see
  IFU ARVALID. Sized IFETCH never falls through MMIO.
- `npc_paddr_read_sized` validates and reads only the declared PMEM byte count. A real
  AxiDpiSlave→dpi.c→paddr.c guard-page test proves PMEM-end 2B success and fixed-8B negative SIGSEGV.

### Lane1 precise fault owner

- PairGate no longer destroys pred-NT branch lane1 PF/AF merely because head0 is a branch;
  predicted-taken still suppresses it through `slot1_valid=0`.
- DispatchGate turns pred-NT+lane1-fault into a barrier so the branch enters ROB first. Pending arbiter
  filters pseudo default ACCESS only when `head_fetch_fault1_i=0`; true AF provenance survives until
  branch resolution. actual-taken squashes it; actual-NT traps after the older branch.

## RED/GREEN evidence

- Historical bridge `b1b1156db` through the permanent runner: exact **34 RED**; poison4,
  decoded-F0 controls4 and N>B walk-presence8 stay green. The corrected standard-lane v2 evidence is
  canonical; the earlier v1 directory is superseded.
- Current footprint matrix: footprint4/poison4/RRESP12/walk12/PMP6 all green. It checks F=0/2/4/6,
  no fault-frontier or younger AR, exact paged addresses/counts, M-fill→S default-deny and conservative
  reject→exact C/C success.
- Second-page A=0 adds two real Sv39 paths: normal prefix→AW/W/B→same-L0 re-walk→one remaining 2B AR,
  and AW-first+flush→complete W/B(error consumed)→silent owner release.
- `tb_ooo_ifu_lane1_fault_owner` old RTL has 5/9 fault-owner rows RED; current matrix is green.
- Attribute old RTL has 2 RED; execute firewall old RTL has 5 RED. Current xbar stall test mutates
  master address/size/prot for three cycles while the slave payload remains fixed.

## Current validation

- focused module integration: **8/8 PASS**.
- permanent module suite: **93/93 PASS**.
- assertion non-vacuity: HOLD/SPLIT-RANGE/SUCCESS-SPLIT/FAULT-ABI **4/4**, each target marker=1,
  total ERROR=1, done=1, production source hashes unchanged.
- dynamic sized DPI suite: four IFETCH lanes, data low-window/PTW8/invalid-size/R stall plus real guard:
  `AXI_DPI_SIZED_SUITE_PASS`.
- structural: RTL style PASS; check-contract current=60 baseline=59; Verilator 5.051 lint PASS;
  current Difftest-OFF performance-config build PASS with the workspace Verilator 5.051. A literal
  PATH build first selected system Verilator 5.020 and rejected the existing `PROCASSINIT` lint code;
  this environment mismatch is recorded separately and was not patched around in RTL.
- Difftest-ON fresh build + AM **59/59** + official RV64GC/bitmanip/rv64mi/rv64si **177/177**,
  underlying core-regress `overall_rc=0`. The outer validation shell returned 127 only after completion
  because its restore hook used one extra `../` for `conf`; `.config` had already been copied back and
  was immediately sync-configured with the corrected path. Restored `.config/autoconf.h/auto.conf`
  SHA-256 exactly match the pre-run triplet.
- CoreMark Difftest-OFF, 10 iterations: crcfinal=0xfcaf, GOOD TRAP,
  **2,913,259 cycles / 3,218,573 commits / CPI 0.905 / CoreMark/MHz 3.503**. Versus G2 baseline
  2,852,201 cycles this is +61,058 (+2.14%); the 7,463 cold packet misses now pay exact halfword
  transactions. This is recorded as a correctness cost, not hidden as cycle-exact performance.
- Fresh target-driven synthesis: rc=0, ABC target blocks **105/105**, three Yosys zero-problem
  checks plus final `synth_check=0`, elapsed 1398.51s, peak 3651.65MiB; final netlist
  68,133,006 bytes, SHA-256 `d5b9cda8c31ee47e93bba2581fd44d7ea590ebe38802381024498997d3cfc2b7`.
- Independent OpenSTA @5.0ns: WNS/TNS **-10.00/-120125.49ns**, top40 **39 D-cache→MIQ +
  1 D-cache→backend/branch recovery→fetch-cache enable**, AxiXbar paths=0. The one fetch endpoint
  does not contain the new RDATA/lane/length/fill cone, so no speculative FINISH register is added.
- Related system `/tmp` archive: 134 top-level sources / 712 members / 846,552,126 source bytes,
  compressed to 17,555,742 bytes; `zstd --test` and `tar --list` PASS, archive SHA-256
  `0cc175cfb0049621d986a7019789d2b5eae28b078d47ecb3b1ab3fd394d3c9bb`.
- Closeout reruns: focused integration **8/8**, sized DPI/guard suite PASS, assertion non-vacuity
  **4/4** with production hashes unchanged, style PASS, contract **60≥59**, Verilator 5.051 lint PASS,
  and current Difftest-OFF default build PASS.
- e2e profiles `npc-dev`, `yosys-sta`, and `agent-system` all completed with PASS nodes; DB-first audit,
  Markdown coverage, doctor (`blocking_drift=0`) and strict guard all PASS.

## Review and remaining boundaries

- Independent bridge and bus/C reviewers both return READY with no functional blocker.
- Independent STA reviewer confirms the hashes, WNS/TNS and `39 MIQ + 1 fetch` classification, and
  confirms that an IFU FINISH register cannot cut the reported lookup-enable path. It also rejects the
  stronger one-boundary claim; exact registered cut placement remains conditional on post-cut STA and
  flush/kill/replay proof.
- `IFU-TVAL-G1`, PTE A-update WRITE-side PMP, PTW→MMIO/PMA, LSU standard split transaction and
  external physical-wrapper ARSIZE consumption remain separate open contracts.
- Fresh 5ns target-driven synthesis/OpenSTA is reviewed in `evidence/sta-current-review.md`. The IFU
  final-R cone is not in the top40, while the leading family remains D-cache→MIQ/redirect/fetch-cache;
  the 39 MIQ tails and one redirect→fetch tail share a D-cache/backend root but are not one serial
  chain. The next timing slice must evaluate one or more registered owner/credit/ready cuts and prove
  the selected placement with post-cut STA plus flush/kill/replay tests.
  Physical 200MHz remains OPEN: current diagnostic required period is about 15.001ns (66.7MHz), and
  ideal clock/placeholder macros/unconstrained IO/loops prevent signoff claims.
- Per user request, relevant system `/tmp` artifacts are archived under workspace `tmp/` with allowlist,
  contents, inventory and SHA-256. System `/tmp` was not modified; the clean duplicate Git worktree is
  represented by HEAD/status/size metadata instead of being repacked wholesale.
