`include "define.v"
`include "tb_common.svh"

module tb_ooo_pma_checker;
  reg [`XLEN-1:0] paddr;
  reg [3:0] access_size;
  reg access_read;
  reg access_write;
  wire fault;
  wire attr_valid;
  wire [1:0] mem_class;
  wire compat_fault;

  OooTypedPmaChecker dut (
    .paddr_i(paddr),
    .access_size_i(access_size),
    .access_read_i(access_read),
    .access_write_i(access_write),
    .fault_o(fault),
    .attr_valid_o(attr_valid),
    .class_o(mem_class)
  );

  // S1.1 不迁 live bridge；旧 checker 必须保持 P0 精确行为直到 S1.2 原子切换。
  OooPmaChecker compat_dut (
    .paddr_i(paddr),
    .access_size_i(access_size),
    .access_read_i(access_read),
    .access_write_i(access_write),
    .fault_o(compat_fault)
  );

  task automatic check_access;
    input [1023:0] what;
    input [`XLEN-1:0] addr;
    input [3:0] size;
    input rd;
    input wr;
    input exp_fault;
    input [1:0] exp_class;
    reg exp_attr;
    begin
      paddr = addr;
      access_size = size;
      access_read = rd;
      access_write = wr;
      #1;
      tb_check1(what, fault, exp_fault);
      exp_attr = (rd || wr) && !exp_fault;
      tb_check1(what, attr_valid, exp_attr);
      if (mem_class !== exp_class) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s class=%02b expected=%02b",
                 what, mem_class, exp_class);
      end
    end
  endtask

  task automatic check_compat_access;
    input [1023:0] what;
    input [`XLEN-1:0] addr;
    input [3:0] size;
    input exp_fault;
    begin
      paddr = addr;
      access_size = size;
      access_read = 1'b1;
      access_write = 1'b0;
      #1;
      tb_check1(what, compat_fault, exp_fault);
    end
  endtask

  initial begin
    tb_errors = 0;
    paddr = {`XLEN{1'b0}};
    access_size = 4'd1;
    access_read = 1'b0;
    access_write = 1'b0;

    check_access("no request never faults", 64'hffff_ffff_ffff_ffff,
                 4'd8, 1'b0, 1'b0, 1'b0, `OOO_MEM_CLASS_RSVD);
    check_access("reset syscon mapped word", `NPC_AXI_RESET_SYSCON_BASE,
                 4'd4, 1'b0, 1'b1, 1'b0, `OOO_MEM_CLASS_IO);
    check_access("CLINT mapped write", `NPC_AXI_CLINT_BASE,
                 4'd4, 1'b0, 1'b1, 1'b0, `OOO_MEM_CLASS_IO);
    check_access("PLIC mapped read", `NPC_AXI_PLIC_BASE + 64'h20_0004,
                 4'd4, 1'b1, 1'b0, 1'b0, `OOO_MEM_CLASS_IO);
    check_access("UART mapped byte", `NPC_AXI_UART_BASE + 64'h5,
                 4'd1, 1'b0, 1'b1, 1'b0, `OOO_MEM_CLASS_IO);
    check_access("virtio mapped word", `NPC_AXI_VIRTIO_BLK_BASE + 64'h100,
                 4'd4, 1'b0, 1'b1, 1'b0, `OOO_MEM_CLASS_IO);
    check_access("PMEM wins overlapping PSRAM decode",
                 `NPC_AXI_PSRAM_BASE + 64'h1000,
                 4'd8, 1'b1, 1'b0, 1'b0, `OOO_MEM_CLASS_CACHED);
    check_access("PSRAM residual is NC",
                 (`NPC_AXI_PMEM_BASE | ~`NPC_AXI_PMEM_MASK) + 64'd1,
                 4'd8, 1'b1, 1'b0, 1'b0, `OOO_MEM_CLASS_NC);
    check_access("legacy MMIO mapped dword",
                 `NPC_AXI_LEGACY_MMIO_BASE + 64'h100, 4'd8,
                 1'b0, 1'b1, 1'b0, `OOO_MEM_CLASS_IO);
    check_access("SDRAM mapped dword", `NPC_AXI_SDRAM_BASE + 64'h1000,
                 4'd8, 1'b0, 1'b1, 1'b0, `OOO_MEM_CLASS_NC);

    check_access("default gap denied", 64'h0000_0000_1800_0000,
                 4'd8, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("nominal SRAM window aliases higher-priority PLIC",
                 `NPC_AXI_SRAM_BASE, 4'd8, 1'b0, 1'b1, 1'b0,
                 `OOO_MEM_CLASS_IO);
    check_access("GPIO stub denied", `NPC_AXI_GPIO_BASE,
                 4'd1, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("PS2 stub denied", `NPC_AXI_PS2_BASE,
                 4'd1, 1'b1, 1'b0, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("MROM stub denied", `NPC_AXI_MROM_BASE,
                 4'd4, 1'b1, 1'b0, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("VGA stub denied", `NPC_AXI_VGA_BASE,
                 4'd8, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("FLASH stub denied", `NPC_AXI_FLASH_BASE,
                 4'd8, 1'b1, 1'b0, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("ChipLink MMIO stub denied", `NPC_AXI_CHIPLINK_MMIO_BASE,
                 4'd8, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("ChipLink memory stub denied", `NPC_AXI_CHIPLINK_MEM_BASE,
                 4'd8, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);

    check_access("cross UART-to-virtio range denied",
                 (`NPC_AXI_UART_BASE | ~`NPC_AXI_UART_MASK) - 64'd3,
                 4'd8, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("cross reset syscon boundary denied",
                 (`NPC_AXI_RESET_SYSCON_BASE |
                  ~`NPC_AXI_RESET_SYSCON_MASK) - 64'd1,
                 4'd4, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("cross PMEM-to-PSRAM-residual class denied",
                 (`NPC_AXI_PMEM_BASE | ~`NPC_AXI_PMEM_MASK) - 64'd3,
                 4'd8, 1'b1, 1'b0, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("address wrap denied", 64'hffff_ffff_ffff_fffc,
                 4'd8, 1'b0, 1'b1, 1'b1, `OOO_MEM_CLASS_RSVD);
    check_access("size zero is one byte", `NPC_AXI_UART_BASE,
                 4'd0, 1'b1, 1'b0, 1'b0, `OOO_MEM_CLASS_IO);

    check_compat_access("S0 compat still allows PMEM-to-PSRAM footprint",
                        (`NPC_AXI_PMEM_BASE | ~`NPC_AXI_PMEM_MASK) - 64'd3,
                        4'd8, 1'b0);
    check_compat_access("S0 compat still denies default gap",
                        64'h0000_0000_1800_0000, 4'd8, 1'b1);
    check_compat_access("S0 compat still denies address wrap",
                        64'hffff_ffff_ffff_fffc, 4'd8, 1'b1);

    $display("[R4-S1.1-PMA-TYPED] CACHED/NC/IO + overlap/range/RSVD + S0 compat PASS");
    tb_finish("tb_ooo_pma_checker");
  end
endmodule
