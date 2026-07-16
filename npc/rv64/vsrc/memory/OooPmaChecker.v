`include "define.v"

// Static physical-memory-attribute checker for the concrete NpcTop map.
// Only slaves that have a real implementation/port are admitted.  Stub and
// default windows deliberately fail closed so a plain-store probe can report
// a precise access fault before the store reaches ROB retirement.
module OooPmaChecker (
  input [`XLEN-1:0] paddr_i,
  input [3:0] access_size_i,
  input access_read_i,
  input access_write_i,
  output fault_o
);

  function region_full_cover;
    input [`XLEN-1:0] first_addr;
    input [`XLEN-1:0] last_addr;
    input [`XLEN-1:0] region_base;
    input [`XLEN-1:0] region_mask;
    begin
      region_full_cover =
          ((first_addr & region_mask) == region_base) &&
          ((last_addr & region_mask) == region_base);
    end
  endfunction

  wire access_req_w = access_read_i || access_write_i;
  wire [3:0] safe_size_w =
      (access_size_i == 4'd0) ? 4'd1 : access_size_i;
  wire [`XLEN:0] access_last_ext_w =
      {1'b0, paddr_i} +
      {{(`XLEN-3){1'b0}}, safe_size_w} -
      {{`XLEN{1'b0}}, 1'b1};
  wire [`XLEN-1:0] access_last_w = access_last_ext_w[`XLEN-1:0];
  wire access_wrap_w = access_last_ext_w[`XLEN];

  // Keep this list mechanically aligned with NpcTop's non-stub slaves.
  // reset-syscon/CLINT/PLIC/UART are concrete RTL；virtio/PSRAM/SDRAM/
  // legacy-MMIO are concrete external ports. GPIO/PS2/MROM/VGA/FLASH/
  // ChipLink/default are AxiDefaultSlave stubs and therefore are excluded.
  // The nominal SRAM macro
  // window lies wholly inside the earlier/higher-priority PLIC decode, so those
  // addresses are correctly admitted by the PLIC region rather than as SRAM.
  wire mapped_rw_w =
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_RESET_SYSCON_BASE,
                        `NPC_AXI_RESET_SYSCON_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_CLINT_BASE, `NPC_AXI_CLINT_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_PLIC_BASE, `NPC_AXI_PLIC_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_UART_BASE, `NPC_AXI_UART_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_VIRTIO_BLK_BASE,
                        `NPC_AXI_VIRTIO_BLK_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_PSRAM_BASE, `NPC_AXI_PSRAM_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_LEGACY_MMIO_BASE,
                        `NPC_AXI_LEGACY_MMIO_MASK) ||
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_SDRAM_BASE, `NPC_AXI_SDRAM_MASK);

  assign fault_o = access_req_w && (access_wrap_w || !mapped_rw_w);

endmodule
