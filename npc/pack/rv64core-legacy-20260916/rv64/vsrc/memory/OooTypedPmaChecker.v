`include "define.v"

// R4-S1 typed PMA checker：对完整 byte range 产生唯一基础 memory class。
// 只有真实、同属性 region 完整覆盖时 attr 才有效；其余情况 class 统一 poison 为 RSVD。
module OooTypedPmaChecker (
  input [`XLEN-1:0] paddr_i,
  input [3:0] access_size_i,
  input access_read_i,
  input access_write_i,
  output fault_o,
  output attr_valid_o,
  output [1:0] class_o
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

  wire pmem_cover_w =
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_PMEM_BASE, `NPC_AXI_PMEM_MASK);
  wire psram_cover_w =
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_PSRAM_BASE, `NPC_AXI_PSRAM_MASK);
  wire sdram_cover_w =
      region_full_cover(paddr_i, access_last_w,
                        `NPC_AXI_SDRAM_BASE, `NPC_AXI_SDRAM_MASK);
  wire pmem_first_w =
      ((paddr_i & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  wire pmem_last_w =
      ((access_last_w & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);

  // PMEM 是较宽 PSRAM slave 内的 CACHED 子窗口。跨越两种属性的访问必须拒绝，
  // 不能因 PSRAM 外层 decode 覆盖完整范围而静默降为 NC。
  wire psram_residual_cover_w =
      psram_cover_w && !pmem_first_w && !pmem_last_w;

  // 与 NpcTop 的真实非 stub slave 对齐；PLIC 优先级也覆盖名义 SRAM 别名。
  wire io_cover_w =
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
                        `NPC_AXI_LEGACY_MMIO_BASE,
                        `NPC_AXI_LEGACY_MMIO_MASK);

  reg attr_valid_r;
  reg [1:0] class_r;
  always @(*) begin
    attr_valid_r = 1'b0;
    class_r = `OOO_MEM_CLASS_RSVD;

    if (access_req_w && !access_wrap_w) begin
      // Priority is architectural: PMEM overlaps PSRAM and must remain CACHED.
      if (pmem_cover_w) begin
        attr_valid_r = 1'b1;
        class_r = `OOO_MEM_CLASS_CACHED;
      end else if (psram_residual_cover_w || sdram_cover_w) begin
        attr_valid_r = 1'b1;
        class_r = `OOO_MEM_CLASS_NC;
      end else if (io_cover_w) begin
        attr_valid_r = 1'b1;
        class_r = `OOO_MEM_CLASS_IO;
      end
    end
  end

  assign attr_valid_o = attr_valid_r;
  assign class_o = class_r;
  assign fault_o = access_req_w && !attr_valid_r;

endmodule
