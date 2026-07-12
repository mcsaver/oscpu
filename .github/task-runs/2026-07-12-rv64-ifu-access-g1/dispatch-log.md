# IFU-ACCESS-G1 dispatch log

### [2026-07-12 23:40 +0800] `contract-map` - PASS

- `owner`: root + prior ifu_access_recon.
- `action`: generated bounded DB brief; read bridge, bus, xbar, DPI and frontend pending-owner paths;
  converted G2 reviewer counterexamples into one end-to-end contract.
- `output`: exact 2B footprint, PMP/cache separation, ARSIZE/ARPROT/device firewall and lane1 PF/AF
  priority frozen; IFU-TVAL and physical 200MHz explicitly excluded.
- `handoff`: three independent permanent RED builders.

### [2026-07-12 23:42 +0800] `red-builders` - RUNNING

- `access_footprint_red`: direct/Sv39 N×B×fault-frontier dynamic matrix, no production edits.
- `access_lane1_red`: branch prediction/actual direction + PF/AF capture/squash path, no production edits.
- `access_bus_firewall`: size/prot stall ABI and non-executable-device path, no production edits.

### [2026-07-13 00:05 +0800] `bus-firewall-red` - PASS

- `owner`: access_bus_firewall.
- `action`: traced ARSIZE/ARPROT through bridge/core/bus/xbar/top/DPI/paddr and audited
  UART/CLINT/PLIC/default read side effects; froze the LSU exact-address/low-window exception.
- `output`: attrs old-RTL compile=0/sim=1 with exact 2 RED; execute→UART old-RTL compile=0/sim=1
  with exact 5 RED; LSU offset5,size4 focused control 1/1 PASS.
- `boundary`: sized host range needs a new DPI guarded-buffer test after the size ABI exists;
  PTW-to-MMIO PMA and PTW-PMP-G1 are not closed by the execute firewall.
