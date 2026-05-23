# RISC-V 大规范硬件架构学习范围

## 目标

- 当前目标不是完整吃透两本规范的所有平台扩展。
- 当前目标是给 npc/single 建立一条独立于“功能仿真语义”的“硬件架构骨架”学习线。
- 这条学习线重点回答：核本身必须暴露哪些架构状态、平台应该提供哪些机器级钩子、哪些属性属于 core，哪些属于平台或 EEI。

## 与上一轮学习的区别

- 上一轮 functional-sim 笔记重点回答“程序看到的执行环境最少应该长什么样”。
- 这一轮 hardware-architecture 笔记重点回答“为了支撑这些语义，RTL 和平台最少要准备哪些硬件结构”。
- 两轮学习不是互相替代，而是分别覆盖“软件可见契约”和“硬件实现骨架”。

## 当前问题对应的学习范围

- 需要明确 hart、core、platform、accelerator、EEI 的层次关系。
- 需要明确基础 ISA 在寄存器、地址空间、指令长度和立即数编码上对硬件带来的直接约束。
- 需要明确机器级最小硬件结构：misa、mhartid、mstatus、mtvec、mip、mie、mepc、mcause、mtval、mscratch、mtime、mtimecmp。
- 需要明确 PMA 与 PMP 的边界，避免把“平台固有属性”和“可编程权限控制”混为一谈。

## 选读资料与章节

### 第一卷：非特权架构

- 1.1 RISC-V 硬件平台术语
- 1.2 RISC-V 软件执行环境和硬件线程
- 1.3 RISC-V ISA 概述
- 1.4 内存
- 1.5 基础指令长度编码
- 2.1 基础整数 ISA 的程序员模型
- 2.2 基本指令格式
- 2.3 立即数编码变体

### 第二卷：特权架构

- 1.1 RISC-V 特权软件栈术语
- 1.2 特权级别
- 1.3 调试模式
- 2.1 CSR 地址映射约定
- 3.1.1 机器 ISA（misa）寄存器
- 3.1.5 硬件线程 ID（mhartid）寄存器
- 3.1.6 机器状态（mstatus 和 mstatush）寄存器
- 3.1.7 机器陷阱向量基址寄存器（mtvec）
- 3.1.8 机器陷阱委托（medeleg 和 mideleg）寄存器
- 3.1.9 机器中断（mip 和 mie）寄存器
- 3.1.10 到 3.1.12 硬件性能监控器与计数器使能/禁止
- 3.1.13 到 3.1.16 mscratch、mepc、mcause、mtval
- 3.2.1 机器定时器寄存器（mtime 与 mtimecmp）
- 3.3.2 陷阱返回指令
- 3.3.3 等待中断（WFI）
- 3.4 复位
- 3.6 物理内存属性（PMA）
- 3.7 物理内存保护（PMP）

## 为什么只选这些

- 这些章节已经足够定义一个 single hart、RV32I、M-mode only CPU 的最小硬件骨架。
- 这些章节能直接指导 decode、CSR block、trap controller、timer/MMIO 与内存边界建模。
- 这些章节还能帮助区分哪些问题属于“核内架构状态”，哪些问题属于“平台/EEI 决策”。

## 当前明确不优先学习的内容

- Supervisor 模式完整语义
- Hypervisor 和两阶段地址翻译
- Smstateen、Smcsrind 等高级平台扩展
- mvendorid、marchid、mimpid 的编码细节
- PMA 的完整一致性/缓存层级建模
- Smepmp、PMP 增强与复杂安全策略

## 暂缓的理由

- 当前 NPC 仍处于 single hart bring-up 阶段，这些内容不阻塞最小硬件骨架成型。
- 过早引入 supervisor、hypervisor 或复杂安全扩展，会把实现重心从“核先跑起来”拉偏。
- 当前最缺的是明确 machine-level 架构状态和平台边界，而不是完整操作系统支撑。

## 本轮学习产物

- 最终摘要：RISC-V-spec-hardware-architecture-notes.md
- 复用临时提取文本：tmp/spec-vol1-front80.txt
- 复用临时提取文本：tmp/spec-vol2-front70.txt

## 后续扩展条件

- 当开始支持 supervisor 或页表时，再补读 S 模式和地址翻译章节。
- 当开始支持定时器中断、外部中断或更完整 MMIO 平台时，再补读更细的中断与平台扩展章节。
- 当开始支持权限隔离或安全测试时，再系统补读 PMP/Smepmp 与相关安全扩展。
