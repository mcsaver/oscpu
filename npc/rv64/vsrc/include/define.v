`ifndef __NPC_RV64_DEFINE_V__
`define __NPC_RV64_DEFINE_V__

// 用统一宏收口 ISA 编码、控制枚举和状态编码，后续补 CSR/异常时不用到处找 magic number。
`define XLEN               64
`define INST_W             32
`define PC_W               64
`define REG_NUM            32
`define REG_ADDR_W         5
`define SHIFT_AMT_W        6
`define STRB_W             (`XLEN / 8)
`define XLEN_BYTES         (`XLEN / 8)
`define XLEN_BYTE_W        3
`define XLEN_BIT_SHIFT     6
`define TRAP_CAUSE_W       5
`define CORE_STATE_W       4

// 可配置结构参数统一放在本文件，便于后续由外部软件生成或覆盖这组宏。
// OoO 后端容量只在这里定义默认值，顶层和子模块默认参数都引用这组宏，
// 避免调 ROB/IQ/PRF/FETCH 深度时产生端口位宽和真实数组深度漂移。
`ifndef OOO_PHY_REG_ADDR_W
`define OOO_PHY_REG_ADDR_W 6
`endif
`ifndef OOO_PHY_REG_COUNT
`define OOO_PHY_REG_COUNT  (1 << `OOO_PHY_REG_ADDR_W)
`endif
`ifndef OOO_FREE_COUNT_W
`define OOO_FREE_COUNT_W   (`OOO_PHY_REG_ADDR_W + 1)
`endif
`ifndef OOO_ROB_INDEX_W
`define OOO_ROB_INDEX_W    4
`endif
`ifndef OOO_ROB_COUNT_W
`define OOO_ROB_COUNT_W    (`OOO_ROB_INDEX_W + 1)
`endif
`ifndef OOO_ISSUE_INDEX_W
`define OOO_ISSUE_INDEX_W  3
`endif
`ifndef OOO_ISSUE_COUNT_W
`define OOO_ISSUE_COUNT_W  (`OOO_ISSUE_INDEX_W + 1)
`endif
`ifndef OOO_FETCH_PACKET_COUNT_W
`define OOO_FETCH_PACKET_COUNT_W 2
`endif
`ifndef OOO_FETCH_PACKET_CACHE_INDEX_W
// 取指包 cache 默认保持 4096 项；综合/面积实验可通过同名 define 显式缩小。
`define OOO_FETCH_PACKET_CACHE_INDEX_W 12
`endif
`ifndef OOO_DATA_WORD_CACHE_INDEX_W
// D-cache 默认保持 4096 项；综合/面积实验可通过同名 define 显式缩小。
`define OOO_DATA_WORD_CACHE_INDEX_W 12
`endif

`ifndef RESET_PC
`define RESET_PC           64'h0000_0000_8000_0000
`endif
`ifndef PC_STEP
`define PC_STEP            64'd4
`endif

// [已删死宏 CACHEABLE_BASE/LAST — RV32 遗留，与真实可缓存判定(NPC_AXI_PMEM_MASK 256MB 窗)
//  矛盾且全仓零消费。可缓存区真源见 OooDataWordCache/OooMemAxiBridge 的 PMEM mask 判定。]
// ysyxSoC 地址图统一在这里预留。未实现设备先在顶层接错误 slave，
// 后续替换成真实 IP 时只需要沿用同名窗口，不再改 core/cache 接口。
`ifndef NPC_AXI_CLINT_BASE
`define NPC_AXI_CLINT_BASE 64'h0000_0000_0200_0000
`endif
`ifndef NPC_AXI_CLINT_MASK
`define NPC_AXI_CLINT_MASK 64'hffff_ffff_ffff_0000
`endif
`ifndef NPC_AXI_PLIC_BASE
`define NPC_AXI_PLIC_BASE 64'h0000_0000_0c00_0000
`endif
`ifndef NPC_AXI_PLIC_MASK
`define NPC_AXI_PLIC_MASK 64'hffff_ffff_fc00_0000
`endif
`ifndef NPC_AXI_SRAM_BASE
`define NPC_AXI_SRAM_BASE  64'h0000_0000_0f00_0000
`endif
`ifndef NPC_AXI_SRAM_MASK
`define NPC_AXI_SRAM_MASK  64'hffff_ffff_ff00_0000
`endif
`ifndef NPC_AXI_UART_BASE
`define NPC_AXI_UART_BASE  64'h0000_0000_1000_0000
`endif
`ifndef NPC_AXI_UART_MASK
`define NPC_AXI_UART_MASK  64'hffff_ffff_ffff_f000
`endif
// [已删死宏 NPC_AXI_SPI_BASE/MASK — 全仓零消费，且其 base 0x1000_1000 已被 VIRTIO_BLK 复用；
//  SPI 设备当前不用，故直接移除该预留槽。]
`ifndef NPC_AXI_VIRTIO_BLK_BASE
`define NPC_AXI_VIRTIO_BLK_BASE 64'h0000_0000_1000_1000
`endif
`ifndef NPC_AXI_VIRTIO_BLK_MASK
`define NPC_AXI_VIRTIO_BLK_MASK 64'hffff_ffff_ffff_f000
`endif
`ifndef NPC_AXI_GPIO_BASE
`define NPC_AXI_GPIO_BASE  64'h0000_0000_1000_2000
`endif
`ifndef NPC_AXI_GPIO_MASK
`define NPC_AXI_GPIO_MASK  64'hffff_ffff_ffff_fff0
`endif
`ifndef NPC_AXI_PS2_BASE
`define NPC_AXI_PS2_BASE   64'h0000_0000_1001_1000
`endif
`ifndef NPC_AXI_PS2_MASK
`define NPC_AXI_PS2_MASK   64'hffff_ffff_ffff_fff8
`endif
`ifndef NPC_AXI_MROM_BASE
`define NPC_AXI_MROM_BASE  64'h0000_0000_2000_0000
`endif
`ifndef NPC_AXI_MROM_MASK
`define NPC_AXI_MROM_MASK  64'hffff_ffff_ffff_f000
`endif
`ifndef NPC_AXI_VGA_BASE
`define NPC_AXI_VGA_BASE   64'h0000_0000_2100_0000
`endif
`ifndef NPC_AXI_VGA_MASK
`define NPC_AXI_VGA_MASK   64'hffff_ffff_ffe0_0000
`endif
`ifndef NPC_AXI_FLASH_BASE
`define NPC_AXI_FLASH_BASE 64'h0000_0000_3000_0000
`endif
`ifndef NPC_AXI_FLASH_MASK
`define NPC_AXI_FLASH_MASK 64'hffff_ffff_f000_0000
`endif
`ifndef NPC_AXI_CHIPLINK_MMIO_BASE
`define NPC_AXI_CHIPLINK_MMIO_BASE 64'h0000_0000_4000_0000
`endif
`ifndef NPC_AXI_CHIPLINK_MMIO_MASK
`define NPC_AXI_CHIPLINK_MMIO_MASK 64'hffff_ffff_c000_0000
`endif
`ifndef NPC_AXI_PSRAM_BASE
`define NPC_AXI_PSRAM_BASE 64'h0000_0000_8000_0000
`endif
`ifndef NPC_AXI_PSRAM_MASK
`define NPC_AXI_PSRAM_MASK 64'hffff_ffff_e000_0000
`endif
`ifndef NPC_AXI_SDRAM_BASE
`define NPC_AXI_SDRAM_BASE 64'h0000_0000_a000_0000
`endif
`ifndef NPC_AXI_SDRAM_MASK
`define NPC_AXI_SDRAM_MASK 64'hffff_ffff_e000_0000
`endif
`ifndef NPC_AXI_CHIPLINK_MEM_BASE
`define NPC_AXI_CHIPLINK_MEM_BASE 64'h0000_0000_c000_0000
`endif
`ifndef NPC_AXI_CHIPLINK_MEM_MASK
`define NPC_AXI_CHIPLINK_MEM_MASK 64'hffff_ffff_c000_0000
`endif
`ifndef NPC_AXI_PMEM_BASE
`define NPC_AXI_PMEM_BASE  64'h0000_0000_8000_0000
`endif
`ifndef NPC_AXI_PMEM_MASK
`define NPC_AXI_PMEM_MASK  64'hffff_ffff_f000_0000
`endif
// 简易 csrc 仿真设备 (rtc/kbd/vga/fb) 的 DPI 窗口。经此 slave 桥到 AxiDpiSlave→DPI→
// csrc paddr.c→设备回调 (skip_ref, difftest 安全)。须与 csrc/include/device_address.h
// 的 NPC_DEVICE_BASE(0x12000000)/NPC_DEVICE_TOP(0x14000000) 一致。旧 legacy 0xa0000000
// 窗口已移除,SDRAM 0xa0000000 不再被别名遮挡。
`ifndef NPC_AXI_LEGACY_MMIO_BASE
`define NPC_AXI_LEGACY_MMIO_BASE 64'h0000_0000_1200_0000
`endif
`ifndef NPC_AXI_LEGACY_MMIO_MASK
`define NPC_AXI_LEGACY_MMIO_MASK 64'hffff_ffff_fe00_0000
`endif
`ifndef NPC_AXI_DEFAULT_BASE
`define NPC_AXI_DEFAULT_BASE 64'h0000_0000_0000_0000
`endif
`ifndef NPC_AXI_DEFAULT_MASK
`define NPC_AXI_DEFAULT_MASK 64'h0000_0000_0000_0000
`endif

`ifndef BPU_BHT_INDEX_W
`define BPU_BHT_INDEX_W    12
`endif
`ifndef BPU_BHT_ENTRIES
`define BPU_BHT_ENTRIES    (1 << `BPU_BHT_INDEX_W)
`endif
`ifndef BPU_BTB_INDEX_W
`define BPU_BTB_INDEX_W    8
`endif
`ifndef BPU_BTB_ENTRIES
`define BPU_BTB_ENTRIES    (1 << `BPU_BTB_INDEX_W)
`endif
`ifndef BPU_LOCAL_HISTORY_INDEX_W
`define BPU_LOCAL_HISTORY_INDEX_W 8
`endif
`ifndef BPU_LOCAL_HISTORY_ENTRIES
`define BPU_LOCAL_HISTORY_ENTRIES (1 << `BPU_LOCAL_HISTORY_INDEX_W)
`endif
`ifndef BPU_LOCAL_HISTORY_W
`define BPU_LOCAL_HISTORY_W 8
`endif
`ifndef BPU_LOCAL_PHT_PC_BITS
`define BPU_LOCAL_PHT_PC_BITS 4
`endif
`ifndef BPU_LOCAL_PHT_INDEX_W
`define BPU_LOCAL_PHT_INDEX_W (`BPU_LOCAL_PHT_PC_BITS + `BPU_LOCAL_HISTORY_W)
`endif
`ifndef BPU_LOCAL_PHT_ENTRIES
`define BPU_LOCAL_PHT_ENTRIES (1 << `BPU_LOCAL_PHT_INDEX_W)
`endif
// [已删死宏 BPU_RAS_ENTRIES/INDEX_W/SIZE_W/DEPTH — 全仓零消费且谎报深度(值 16，
//  真实 RAS 为 32 深，见 frontend/OooRasStack.v)。删除以免误导。]
`ifndef BPU_COUNTER_INIT
`define BPU_COUNTER_INIT   2'd2
`endif

`ifndef ICACHE_LINE_WORDS
`define ICACHE_LINE_WORDS  8
`endif
`ifndef ICACHE_WAY_COUNT
`define ICACHE_WAY_COUNT   2
`endif
`ifndef ICACHE_WAY_BITS
`define ICACHE_WAY_BITS    1
`endif
`ifndef ICACHE_LINE_COUNT
`define ICACHE_LINE_COUNT  32
`endif
`ifndef ICACHE_OFFSET_BITS
`define ICACHE_OFFSET_BITS 6
`endif
`ifndef ICACHE_INDEX_BITS
`define ICACHE_INDEX_BITS  5
`endif
`ifndef ICACHE_WORD_BITS
`define ICACHE_WORD_BITS   3
`endif

`ifndef DCACHE_LINE_WORDS
`define DCACHE_LINE_WORDS  8
`endif
`ifndef DCACHE_WAY_COUNT
`define DCACHE_WAY_COUNT   2
`endif
`ifndef DCACHE_WAY_BITS
`define DCACHE_WAY_BITS    1
`endif
`ifndef DCACHE_LINE_COUNT
`define DCACHE_LINE_COUNT  32
`endif
`ifndef DCACHE_OFFSET_BITS
`define DCACHE_OFFSET_BITS 6
`endif
`ifndef DCACHE_INDEX_BITS
`define DCACHE_INDEX_BITS  5
`endif
`ifndef DCACHE_WORD_BITS
`define DCACHE_WORD_BITS   3
`endif

`define OPCODE_LOAD        7'b0000011
`define OPCODE_LOAD_FP     7'b0000111
`define OPCODE_MISC_MEM    7'b0001111
`define OPCODE_OP_IMM      7'b0010011
`define OPCODE_OP_IMM_32   7'b0011011
`define OPCODE_AUIPC       7'b0010111
`define OPCODE_STORE       7'b0100011
`define OPCODE_STORE_FP    7'b0100111
`define OPCODE_AMO         7'b0101111
`define OPCODE_OP          7'b0110011
`define OPCODE_OP_32       7'b0111011
`define OPCODE_LUI         7'b0110111
`define OPCODE_MADD        7'b1000011
`define OPCODE_MSUB        7'b1000111
`define OPCODE_NMSUB       7'b1001011
`define OPCODE_NMADD       7'b1001111
`define OPCODE_OP_FP       7'b1010011
`define OPCODE_BRANCH      7'b1100011
`define OPCODE_JALR        7'b1100111
`define OPCODE_JAL         7'b1101111
`define OPCODE_SYSTEM      7'b1110011

`define FUNCT3_ADD_SUB     3'b000
`define FUNCT3_SLL         3'b001
`define FUNCT3_SLT         3'b010
`define FUNCT3_SLTU        3'b011
`define FUNCT3_XOR         3'b100
`define FUNCT3_SRL_SRA     3'b101
`define FUNCT3_OR          3'b110
`define FUNCT3_AND         3'b111

`define FUNCT3_BEQ         3'b000
`define FUNCT3_BNE         3'b001
`define FUNCT3_BLT         3'b100
`define FUNCT3_BGE         3'b101
`define FUNCT3_BLTU        3'b110
`define FUNCT3_BGEU        3'b111

`define FUNCT3_LB          3'b000
`define FUNCT3_LH          3'b001
`define FUNCT3_LW          3'b010
`define FUNCT3_LD          3'b011
`define FUNCT3_LBU         3'b100
`define FUNCT3_LHU         3'b101
`define FUNCT3_LWU         3'b110

`define FUNCT3_SB          3'b000
`define FUNCT3_SH          3'b001
`define FUNCT3_SW          3'b010
`define FUNCT3_SD          3'b011

`define FUNCT3_FENCE       3'b000
`define FUNCT3_FENCE_I     3'b001

`define FUNCT7_STD         7'b0000000
`define FUNCT7_MULDIV      7'b0000001
`define FUNCT7_ALT         7'b0100000

`define SYSTEM_FUNCT12_ECALL   12'h000
`define SYSTEM_FUNCT12_EBREAK  12'h001
`define SYSTEM_FUNCT12_SRET    12'h102
`define SYSTEM_FUNCT12_MRET    12'h302
`define SYSTEM_FUNCT12_WFI     12'h105
`define SYSTEM_FUNCT7_SFENCE_VMA   7'b0001001
`define SYSTEM_FUNCT7_SINVAL_VMA   7'b0001011
`define SYSTEM_FUNCT7_SFENCE_INVAL 7'b0001100
`define SYSTEM_RS2_SFENCE_W_INVAL  5'b00000
`define SYSTEM_RS2_SFENCE_INVAL_IR 5'b00001

`define CSR_MVENDORID      12'hf11
`define CSR_MARCHID        12'hf12
`define CSR_MIMPID         12'hf13
`define CSR_FFLAGS         12'h001
`define CSR_FRM            12'h002
`define CSR_FCSR           12'h003
`define CSR_SSTATUS        12'h100
`define CSR_SIE            12'h104
`define CSR_STVEC          12'h105
`define CSR_SSCRATCH       12'h140
`define CSR_SEPC           12'h141
`define CSR_SCAUSE         12'h142
`define CSR_STVAL          12'h143
`define CSR_SIP            12'h144
`define CSR_SCOUNTEREN     12'h106
`define CSR_SATP           12'h180
`define CSR_MSTATUS        12'h300
`define CSR_MISA           12'h301
`define CSR_MEDELEG        12'h302
`define CSR_MIDELEG        12'h303
`define CSR_MIE            12'h304
`define CSR_MTVEC          12'h305
`define CSR_MCOUNTEREN     12'h306
`define CSR_MCOUNTINHIBIT  12'h320
`define CSR_MENVCFG        12'h30a
`define CSR_PMPCFG0        12'h3a0
`define CSR_PMPCFG1        12'h3a1
`define CSR_PMPCFG2        12'h3a2
`define CSR_PMPCFG3        12'h3a3
`define CSR_MSCRATCH       12'h340
`define CSR_MEPC           12'h341
`define CSR_MCAUSE         12'h342
`define CSR_MTVAL          12'h343
`define CSR_MIP            12'h344
`define CSR_PMPADDR0       12'h3b0
`define CSR_PMPADDR15      12'h3bf
`define CSR_MCYCLE         12'hb00
`define CSR_MINSTRET       12'hb02
`define CSR_MCYCLEH        12'hb80
`define CSR_MINSTRETH      12'hb82
`define CSR_TSELECT        12'h7a0
`define CSR_TDATA1         12'h7a1
`define CSR_TDATA2         12'h7a2
`define CSR_TCONTROL       12'h7a5
// Smrnmi mnstatus(0x744)：riscv-tests 启动码 `csrwi mnstatus,8` 会访问它。★2026-07-07 裁决更新:
// 当前金标 **RV64** NEMU 对 0x744 取 illegal（未实现 Smrnmi，spec-correct: 未实现 CSR 应 illegal）;
// 旧注释"金标 NEMU 视其合法"是 RV32 时代且已过时。故本核从 known 白名单**移除** MNSTATUS → 落
// default → csr_illegal_o 拉高，与 RV64 NEMU 对齐。当年被迫加 WARL-zero no-op 是因当时 difftest 无
// 异常同步（NPC illegal 而 NEMU 合法 → 启动码 abort）; 现 item5 的**自主 trap 恢复**(difftest.cpp)
// 让两侧同为 illegal 时对齐（NEMU exec 该指令也 illegal → 跳同 handler），且 riscv-tests 启动码有临时
// mtvec 兜底跳过该 illegal。本核未实现 NMI，故无功能副作用。宏保留仅作地址常量存档。
`define CSR_MNSTATUS       12'h744
`define CSR_CYCLE          12'hc00
`define CSR_TIME           12'hc01
`define CSR_INSTRET        12'hc02
`define CSR_CYCLEH         12'hc80
`define CSR_TIMEH          12'hc81
`define CSR_INSTRETH       12'hc82
`define CSR_MHARTID        12'hf14

`define MCOUNTINHIBIT_CY   64'h0000_0000_0000_0001
`define MCOUNTINHIBIT_IR   64'h0000_0000_0000_0004
`define COUNTEREN_CY       64'h0000_0000_0000_0001
`define COUNTEREN_TM       64'h0000_0000_0000_0002
`define COUNTEREN_IR       64'h0000_0000_0000_0004
`define COUNTEREN_MASK     (`COUNTEREN_CY | `COUNTEREN_TM | `COUNTEREN_IR)

`define PMP_ENTRY_COUNT    16
`define PMP_CFG_ENTRY_W    8
`define PMP_CFG_BUS_W      (`PMP_ENTRY_COUNT * `PMP_CFG_ENTRY_W)
`define PMP_ADDR_BUS_W     (`PMP_ENTRY_COUNT * `XLEN)
`ifndef PMP_PADDR_BITS
// 当前 RVA22S64/Sail 配置按 56-bit physical address 建模，pmpaddr 只保存 PA[55:2]。
`define PMP_PADDR_BITS     56
`endif
`define PMP_ADDR_BITS      (`PMP_PADDR_BITS - 2)
`define PMP_ADDR_MASK      {{(`XLEN - `PMP_ADDR_BITS){1'b0}}, {`PMP_ADDR_BITS{1'b1}}}
`define PMP_CFG_R          0
`define PMP_CFG_W          1
`define PMP_CFG_X          2
`define PMP_CFG_A_HI       4
`define PMP_CFG_A_LO       3
`define PMP_CFG_L          7
`define PMP_A_OFF          2'b00
`define PMP_A_TOR          2'b01
`define PMP_A_NA4          2'b10
`define PMP_A_NAPOT        2'b11

`define PRIV_U             2'b00
`define PRIV_S             2'b01
`define PRIV_M             2'b11

`define MSTATUS_SIE        64'h0000_0000_0000_0002
`define MSTATUS_MIE        64'h0000_0000_0000_0008
`define MSTATUS_SPIE       64'h0000_0000_0000_0020
`define MSTATUS_MPIE       64'h0000_0000_0000_0080
`define MSTATUS_SPP        64'h0000_0000_0000_0100
`define MSTATUS_FS_MASK    64'h0000_0000_0000_6000
`define MSTATUS_FS_INITIAL 64'h0000_0000_0000_2000
`define MSTATUS_FS_CLEAN   64'h0000_0000_0000_4000
`define MSTATUS_FS_DIRTY   64'h0000_0000_0000_6000
`define MSTATUS_MPP_MASK   64'h0000_0000_0000_1800
`define MSTATUS_MPP_S      64'h0000_0000_0000_0800
`define MSTATUS_MPP_M      64'h0000_0000_0000_1800
`define MSTATUS_SUM        64'h0000_0000_0004_0000
`define MSTATUS_MXR        64'h0000_0000_0008_0000
`define MSTATUS_MPRV       64'h0000_0000_0002_0000
`define MSTATUS_TVM        64'h0000_0000_0010_0000
`define MSTATUS_TW         64'h0000_0000_0020_0000
`define MSTATUS_TSR        64'h0000_0000_0040_0000
`define MSTATUS_SXL_UXL    64'h0000_000a_0000_0000
`define MSTATUS_SD         64'h8000_0000_0000_0000
`define MENVCFG_PBMTE      64'h4000_0000_0000_0000
`define SSTATUS_MASK       (`MSTATUS_SIE | `MSTATUS_SPIE | `MSTATUS_SPP | \
                            `MSTATUS_FS_MASK | \
                            `MSTATUS_SUM | `MSTATUS_MXR | `MSTATUS_SXL_UXL | \
                            `MSTATUS_SD)
`define SV39_PTE_N         64'h8000_0000_0000_0000
`define SV39_PTE_RESERVED_MASK 64'he7c0_0000_0000_0000
`define SV39_PTE_RESERVED_MASK_SVPBMT 64'h87c0_0000_0000_0000
`define SV39_PTE_NONLEAF_RESERVED_MASK 64'h0000_0000_0000_00d0
`define SV39_PTE_PBMT_HI   62
`define SV39_PTE_PBMT_LO   61

`define IRQ_CAUSE_SSI      5'd1
`define IRQ_CAUSE_MSI      5'd3
`define IRQ_CAUSE_STI      5'd5
`define IRQ_CAUSE_MTI      5'd7
`define IRQ_CAUSE_SEI      5'd9
`define IRQ_CAUSE_MEI      5'd11
`define MCAUSE_INTERRUPT   64'h8000_0000_0000_0000
`define MIP_SSIP           64'h0000_0000_0000_0002
`define MIP_MSIP           64'h0000_0000_0000_0008
`define MIP_STIP           64'h0000_0000_0000_0020
`define MIP_MTIP           64'h0000_0000_0000_0080
`define MIP_SEIP           64'h0000_0000_0000_0200
`define MIP_MEIP           64'h0000_0000_0000_0800
`define MIE_SSIE           64'h0000_0000_0000_0002
`define MIE_MSIE           64'h0000_0000_0000_0008
`define MIE_STIE           64'h0000_0000_0000_0020
`define MIE_MTIE           64'h0000_0000_0000_0080
`define MIE_SEIE           64'h0000_0000_0000_0200
`define MIE_MEIE           64'h0000_0000_0000_0800

// 立即数类型编码：DecodeUnit 给出类型，ImmGen 按类型完成拼接与符号扩展。
`define IMM_TYPE_X         3'b000  // 不使用立即数
`define IMM_TYPE_I         3'b001  // I-type: 算术立即数 / load / jalr
`define IMM_TYPE_S         3'b010  // S-type: store 偏移
`define IMM_TYPE_B         3'b011  // B-type: branch 偏移
`define IMM_TYPE_U         3'b100  // U-type: lui / auipc 高 20 位立即数
`define IMM_TYPE_J         3'b101  // J-type: jal 跳转偏移

// EXU 第一个操作数来源选择。
`define OP1_SEL_RS1        2'b00   // 来自寄存器 rs1
`define OP1_SEL_PC         2'b01   // 来自当前 pc
`define OP1_SEL_ZERO       2'b10   // 常数 0，用于 lui 等场景

// EXU 第二个操作数来源选择。
`define OP2_SEL_RS2        2'b00   // 来自寄存器 rs2
`define OP2_SEL_IMM        2'b01   // 来自立即数 imm
`define OP2_SEL_FOUR       2'b10   // 常数 4，主要服务 PC+4 类计算
`define OP2_SEL_ZERO       2'b11   // 常数 0，用于 AMO 等 rs2 不是地址偏移的场景

// ALU 运算编码：DecodeUnit 只描述“做什么”，ALU 负责真正计算。
`define ALU_OP_ADD         4'h0    // 加法：地址生成 / auipc / addi / add
`define ALU_OP_SLL         4'h1    // 逻辑左移
`define ALU_OP_SLT         4'h2    // 有符号小于比较，结果写成 0/1
`define ALU_OP_SLTU        4'h3    // 无符号小于比较，结果写成 0/1
`define ALU_OP_XOR         4'h4    // 按位异或
`define ALU_OP_SRL         4'h5    // 逻辑右移
`define ALU_OP_OR          4'h6    // 按位或
`define ALU_OP_AND         4'h7    // 按位与
`define ALU_OP_SUB         4'h8    // 减法：sub 等场景
`define ALU_OP_SRA         4'hd    // 算术右移
`define ALU_OP_COPY_B      4'he    // 直通第二操作数，常用于 lui
`define ALU_OP_COPY_A      4'hf    // 直通第一操作数，当前预留

// CompareUnit 关系比较编码：只产出真假，不直接决定是否跳转。
`define CMP_OP_NONE        3'b000  // 当前指令不需要比较
`define CMP_OP_EQ          3'b001  // 相等
`define CMP_OP_NE          3'b010  // 不相等
`define CMP_OP_LT          3'b011  // 有符号小于
`define CMP_OP_GE          3'b100  // 有符号大于等于
`define CMP_OP_LTU         3'b101  // 无符号小于
`define CMP_OP_GEU         3'b110  // 无符号大于等于

// 访存粒度编码：LSU 依据它生成 wstrb 并完成 load 扩展。
`define MEM_SIZE_BYTE      2'b00   // 8-bit
`define MEM_SIZE_HALF      2'b01   // 16-bit
`define MEM_SIZE_WORD      2'b10   // 32-bit
`define MEM_SIZE_DWORD     2'b11   // 64-bit

// IEEE-754 fflags 异常标志位（fflags[4:0]）：FP execute 各 owner 共享，
// 由 define.v 统一管理（原 execute/OooFpDefs.v 已并入这里）。
`define FP_FLAG_NV         5'b10000  // invalid
`define FP_FLAG_DZ         5'b01000  // divide-by-zero
`define FP_FLAG_OF         5'b00100  // overflow
`define FP_FLAG_UF         5'b00010  // underflow
`define FP_FLAG_NX         5'b00001  // inexact

// 写回源选择：WBU 在这里统一做多路选择，避免前级直接写寄存器堆。
`define WB_SEL_NONE        3'b000  // 不写回
`define WB_SEL_ALU         3'b001  // 写回 ALU 结果
`define WB_SEL_LOAD        3'b010  // 写回 load 返回值
`define WB_SEL_PC4         3'b011  // 写回 pc + 4，jal/jalr 使用
`define WB_SEL_IMM         3'b100  // 写回立即数，lui 使用
`define WB_SEL_CSR         3'b101  // 写回 CSR 指令读到的旧值

`define EXC_INST_ADDR_MISALIGN   5'd0
`define EXC_INST_ACCESS_FAULT    5'd1
`define EXC_ILLEGAL_INST         5'd2
`define EXC_BREAKPOINT           5'd3
`define EXC_LOAD_ADDR_MISALIGN   5'd4
`define EXC_LOAD_ACCESS_FAULT    5'd5
`define EXC_STORE_ADDR_MISALIGN  5'd6
`define EXC_STORE_ACCESS_FAULT   5'd7
`define EXC_ECALL_UMODE          5'd8
`define EXC_ECALL_SMODE          5'd9
`define EXC_ECALL_MMODE          5'd11
`define EXC_INST_PAGE_FAULT      5'd12
`define EXC_LOAD_PAGE_FAULT      5'd13
`define EXC_STORE_PAGE_FAULT     5'd15

// redirect 统一仲裁 reason 编码（P4 复活，2026-07-08）：消费者 OooRedirectArbiter。
// shadow 等价断言阶段仅在 OooCoreTopGlue 的 `ifdef OOO_ASSERT 段作并行影子仲裁（不驱动
// 功能逻辑，零综合影响）；全绿后才切消费点。曾于 2026-07-03 因零实例化删档（C7），
// 现按 design/arch/pipeline-stage-boundary.md §5（flush 单点化 assert-then-converge）回填。
`define REDIR_REASON_W           3
`define REDIR_REASON_NONE        3'd0
`define REDIR_REASON_BRANCH_MISS 3'd1   // 条件分支误预测（后端解析）
`define REDIR_REASON_JALR_MISS   3'd2   // JALR 目标误预测（后端 AGU 解析）
`define REDIR_REASON_TRAP        3'd3   // commit 阶段精确异常/中断
`define REDIR_REASON_XRET        3'd4   // mret/sret 返回
`define REDIR_REASON_SFENCE      3'd5   // sfence.vma 后重取指
`define REDIR_REASON_FENCEI      3'd6   // fence.i 后重取指
`define REDIR_REASON_DIRECT      3'd7   // dispatch 期直算的 direct 控制流（JAL/已知目标）

// B2 总开关：1=启用「分支投机 + ROB-walk 误预测恢复」（取代 weak checkpoint 恢复）；0=原 pending+drain。
// 单分支深度（复用前端单 spec tracker 的 mispredict + branch_resolve_rob_idx），多分支待 pred-next-pc threading。
`ifndef OOO_ROB_WALK_MODE
`define OOO_ROB_WALK_MODE 1'b1
`endif
// domain-A 迁移第一刀(#105 总闸拆除): head0 条件分支不再走 direct 前端解析-then-drain
// 提交模型(每条 stop_pending+全 drain, 占 99.997% stop), 而是与 head1 分支同构地作为普通
// uop 经 frontend_dispatch 进 ROB/IQ, 由后端 resolve + mode=1 redirect/ROB-walk 按序提交。
// 1=domain-A(拆总闸); 0=原 direct+drain 模型(对照/回退用)。
`ifndef OOO_DBRANCH_DOMAIN_A
`define OOO_DBRANCH_DOMAIN_A 1'b1
`endif
// serialize-at-retire Phase1(CSR 队头化)总开关: 1=合法非-FP head0-CSR 走正常 ROB dispatch + mem-quiet
// 门控 serial_flush 队头提交(§9 修向①); 0=所有 CSR 仍走 pending+drain(基线行为)。
// ⚠️ 当前默认 0: §9 mem_quiet 安全机制 + §4 核心已验证(riscv rv64mi/si 23/23 + FP), 但中间态
// (head0-CSR 与 lane1-drain-CSR 共存)有未解死锁——两条 lane1-CSR 覆写单个 pending 寄存器 +
// ecall-drain stuck-store(mem_retire_quiet=0), 致 sbi-base-console/fp-difftest-probe 挂死。
// 详见 design/arch/serialize-at-retire-phase1.md §10。置 1 需先解中间态串行化。
`ifndef OOO_CSR_QUEUE_HEAD
`define OOO_CSR_QUEUE_HEAD 1'b0
`endif
// LSQ·SQ 切换(spec ooo-lsq-implementation-plan.md §3.6): 1=plain store 不再等 ROB 队头,
// issue 拍经桥 probe(翻译+PMP 前置精确异常) → SQ(PA) → 退休后 drain 落存(pretrans+nokill);
// 0=旧路径(store 队头发射+真事务, SQ 保持影子对拍)。
`ifndef OOO_SQ_STORE_PATH
`define OOO_SQ_STORE_PATH 1'b1
`endif
// `define ROB_WALK_DEBUG

`define CORE_STATE_RESET      4'd0
`define CORE_STATE_FETCH_REQ  4'd1
`define CORE_STATE_FETCH_WAIT 4'd2
`define CORE_STATE_DECODE     4'd3
`define CORE_STATE_EXEC       4'd4
`define CORE_STATE_MEM_REQ    4'd5
`define CORE_STATE_MEM_WAIT   4'd6
`define CORE_STATE_WB         4'd7
`define CORE_STATE_HALT       4'd8
`define CORE_STATE_TRAP       4'd9

// 统一控制总线字段定义：DecodeUnit 产出 ctrl_o，NpcCore 在 DECODE 阶段锁存后供各后级模块消费。
// 单 bit 标记优先描述“这条指令是什么/需要什么”，多 bit 字段则描述“后级该怎么做”。
`define CTRL_VALID_BIT           0   // 译码结果有效；当前实现默认对取到的 inst 都置 1
`define CTRL_ILLEGAL_BIT         1   // 该编码是否非法；若为 1，顶层会直接进入 illegal trap
`define CTRL_RS1_EN_BIT          2   // 是否需要读取 rs1
`define CTRL_RS2_EN_BIT          3   // 是否需要读取 rs2
`define CTRL_RD_EN_BIT           4   // 是否存在 rd 写回目标
`define CTRL_BRANCH_BIT          5   // 是否属于条件分支类指令
`define CTRL_JAL_BIT             6   // 是否属于 jal
`define CTRL_JALR_BIT            7   // 是否属于 jalr
`define CTRL_LOAD_BIT            8   // 是否属于 load
`define CTRL_STORE_BIT           9   // 是否属于 store
`define CTRL_ECALL_BIT           10  // 是否为 ecall
`define CTRL_EBREAK_BIT          11  // 是否为 ebreak
`define CTRL_FENCE_BIT           12  // 是否为 fence/fence.i；当前实现视为合法 no-op
`define CTRL_IMM_TYPE_LSB        13  // 立即数字段低位：交给 ImmGen 选择拼接规则
`define CTRL_IMM_TYPE_MSB        15  // 立即数字段高位
`define CTRL_OP1_SEL_LSB         16  // EXU 第一个操作数来源字段低位
`define CTRL_OP1_SEL_MSB         17  // EXU 第一个操作数来源字段高位
`define CTRL_OP2_SEL_LSB         18  // EXU 第二个操作数来源字段低位
`define CTRL_OP2_SEL_MSB         19  // EXU 第二个操作数来源字段高位
`define CTRL_ALU_OP_LSB          20  // ALU 运算编码字段低位
`define CTRL_ALU_OP_MSB          23  // ALU 运算编码字段高位
`define CTRL_CMP_OP_LSB          24  // CompareUnit 比较关系字段低位
`define CTRL_CMP_OP_MSB          26  // CompareUnit 比较关系字段高位
`define CTRL_MEM_SIZE_LSB        27  // LSU 访存粒度字段低位
`define CTRL_MEM_SIZE_MSB        28  // LSU 访存粒度字段高位
`define CTRL_MEM_UNSIGNED_BIT    29  // load 是否按无符号扩展处理
`define CTRL_WB_SEL_LSB          30  // WBU 写回源选择字段低位
`define CTRL_WB_SEL_MSB          32  // WBU 写回源选择字段高位
`define CTRL_NEED_EXEC_BIT       33  // 指令是否需要经过 EXEC 阶段
`define CTRL_NEED_MEM_BIT        34  // 指令是否需要经过 MEM 阶段
`define CTRL_NEED_WB_BIT         35  // 指令是否需要在 WB 阶段提交写回
`define CTRL_SYSTEM_BIT          36  // 是否属于 system 指令族
`define CTRL_MISC_MEM_BIT        37  // 是否属于 misc-mem 指令族（当前只接 fence/fence.i）
`define CTRL_CSR_BIT             38  // 是否属于 Zicsr 读改写指令
`define CTRL_MRET_BIT            39  // 是否为 mret
`define CTRL_WFI_BIT             40  // 是否为 wfi；当前实现为合法 no-op
`define CTRL_MULDIV_BIT          41  // 是否属于 RVM 乘除法扩展，EX 阶段按 funct3/funct7 计算
`define CTRL_BITMANIP_BIT        42  // 是否属于 Zba/Zbb/Zbc/Zbs 扩展，EX 阶段按原始编码计算
`define CTRL_WORD_OP_BIT         43  // RV64 的 *W 指令：只保留低 32 位并符号扩展
`define CTRL_SFENCE_VMA_BIT      44  // 是否为 supervisor TLB/ICache 刷新边界；执行侧作为序列化 no-op+flush
`define CTRL_SRET_BIT            45  // 是否为 sret；用于 Linux/S-mode trap 返回
`define CTRL_AMO_BIT             46  // 是否属于 A 扩展原子访存指令族
`define CTRL_AMO_LR_BIT          47  // 是否为 lr.w/lr.d
`define CTRL_AMO_SC_BIT          48  // 是否为 sc.w/sc.d
`define CTRL_SFENCE_TVM_BIT      49  // 是否属于受 mstatus.TVM 约束的地址转换 fence
`define CTRL_FENCEI_BIT          50  // fence.i(真 flush)：序列化 stop 类，退休拍整块清取指 cache + redirect(OOO_FENCEI_TRUE_FLUSH)
// fence.i 真 flush 默认开(#111 #3B 修复)；排查时注释此行即回落旧 no-op(零回归，见 Step B commit)
`define OOO_FENCEI_TRUE_FLUSH
`define CTRL_BUS_W               51  // 统一控制总线总宽度

`endif
