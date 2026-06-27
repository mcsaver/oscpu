`ifndef __NPC_RV64_OOO_SLOT_FACTS_VH__
`define __NPC_RV64_OOO_SLOT_FACTS_VH__

// 单个 fetch/decode slot 的组合事实总线。先用 packed bus + 宏切片，
// 让父模块可以逐步从散线迁移到统一事实载体。
`define OOO_SLOT_FACT_ILLEGAL              0
`define OOO_SLOT_FACT_BRANCH               1
`define OOO_SLOT_FACT_JAL                  2
`define OOO_SLOT_FACT_JALR                 3
`define OOO_SLOT_FACT_JUMP                 4
`define OOO_SLOT_FACT_MEM                  5
`define OOO_SLOT_FACT_CONTROL              6
`define OOO_SLOT_FACT_FP_LOAD              7
`define OOO_SLOT_FACT_FP_STORE             8
`define OOO_SLOT_FACT_FP_MOVE_TO_FPR       9
`define OOO_SLOT_FACT_FP_MOVE_TO_GPR       10
`define OOO_SLOT_FACT_FP_CLASS             11
`define OOO_SLOT_FACT_FP_SGNJ              12
`define OOO_SLOT_FACT_FP_ADDSUB            13
`define OOO_SLOT_FACT_FP_MUL               14
`define OOO_SLOT_FACT_FP_FMA               15
`define OOO_SLOT_FACT_FP_DIV               16
`define OOO_SLOT_FACT_FP_SQRT              17
`define OOO_SLOT_FACT_FP_MINMAX            18
`define OOO_SLOT_FACT_FP_COMPARE           19
`define OOO_SLOT_FACT_FP_CONVERT_TO_FPR    20
`define OOO_SLOT_FACT_FP_CONVERT_TO_GPR    21
`define OOO_SLOT_FACT_FP_RAW               22
`define OOO_SLOT_FACT_FP_DOUBLE            23
`define OOO_SLOT_FACT_FP_GPR_WRITE         24
`define OOO_SLOT_FACT_FP_DISABLED          25
`define OOO_SLOT_FACT_FP_ENABLED           26
`define OOO_SLOT_FACT_ECALL                27
`define OOO_SLOT_FACT_EBREAK               28
`define OOO_SLOT_FACT_SEMIHOST_EBREAK      29
`define OOO_SLOT_FACT_CSR                  30
`define OOO_SLOT_FACT_MRET                 31
`define OOO_SLOT_FACT_SRET                 32
`define OOO_SLOT_FACT_XRET                 33
`define OOO_SLOT_FACT_WFI                  34
`define OOO_SLOT_FACT_SFENCE               35
`define OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL  36
`define OOO_SLOT_FACT_EXIT                 37
`define OOO_SLOT_FACT_SYSTEM               38
`define OOO_SLOT_FACT_ARCH_TRAP            39
`define OOO_SLOT_FACT_STOP                 40
`define OOO_SLOT_FACTS_W                   41

`endif
