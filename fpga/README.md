# RV64 NPC Vivado 工程

本目录用于对 `npc/rv64` 的可综合 NPC 顶层做 Vivado 综合。当前默认顶层是
`NpcTop`：它实例化 `NpcCoreTop`、AXI crossbar、UART、CLINT、PLIC 和默认
slave，并把 PSRAM、legacy MMIO、virtio-blk 这类外部设备窗口导出为 AXI-Lite
端口。Vivado 只纳入 `npc/rv64/vsrc/filelist.mk` 中的 `RTL_DEFINE` 与
`RTL_CORE_SRCS`，不会纳入 `NpcSimTop.sv`、DPI slave、DPI virtio block 或 host C++。

默认器件沿用仓库中已有 Vivado 示例的 `xc7s25csga225-1`。如果后续切到真实
开发板，可以通过 `FPGA_PART=<part>` 覆盖。

## 快速使用

```bash
cd /home/lyg/PA/ysyx-workbench/fpga
make synth
```

常用覆盖参数：

```bash
make synth FPGA_PART=xc7a100tcsg324-1 TOP=NpcTop CLOCK_PERIOD_NS=10.000
make synth VIVADO_THREADS=1 SYNTH_DIRECTIVE=RuntimeOptimized SYNTH_FLATTEN_HIERARCHY=none
```

## 产物

- `filelists/npc_rv64_top_files.f`：由 `npc/rv64/vsrc/filelist.mk` 生成的 Vivado 源清单
- `vivado/npc_rv64_top/npc_rv64_top.xpr`：Vivado 工程
- `reports/`：综合日志、利用率、时序、DRC 与高扇出报告

## 边界

当前工程是 NPC 顶层 out-of-context 综合入口，不包含板级封装、引脚约束、外部存储器
IP 或 bitstream 生成。Verilator 的 `NpcSimTop` 只作为仿真外壳包住 `NpcTop`，负责把
导出的外部 AXI-Lite 端口接到 DPI memory/virtio 设备并上报仿真事件。
