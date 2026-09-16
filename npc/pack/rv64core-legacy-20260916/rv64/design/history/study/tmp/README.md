# tmp 目录说明

本目录保存大体量 PDF 的临时提取文本和中间学习材料，目的是避免后续 agent 每次都从整本规范重新提取。

## 当前文件

- spec-vol1-front80.txt：第一卷前 80 页文本提取，覆盖 EEI、内存、异常、RV32I 基础、Zifencei、Zicsr 等当前最相关章节。
- spec-vol2-front70.txt：第二卷前 70 页文本提取，覆盖特权级别、CSR、M 模式 trap、mtvec、mepc、mcause、mtval、ECALL、EBREAK、MRET、WFI、复位等当前最相关章节。

## 使用原则

- 本目录只放临时提取和中间材料。
- 最终结论以 study 根目录下的正式 Markdown 笔记为准。
- 当前的 `spec-vol1-front80.txt` 和 `spec-vol2-front70.txt` 已同时覆盖 functional-sim 与 hardware-architecture 两条学习线，本轮直接复用，不再重复提取同一批前部章节。
- 若新增更大规范，优先继续使用“只提取当前目标相关页段”的方式，不默认整本展开。
