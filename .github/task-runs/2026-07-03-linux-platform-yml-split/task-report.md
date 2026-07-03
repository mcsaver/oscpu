# Linux 平台 yml 拆分:NEMU/NPC 分开管理(2026-07-03)

## 任务

用户指出 Linux 配置中 npc 和 nemu 混在同一个 `Linux/platform/npc-rv64.yml` 里,要求拆开分别管理。

## 前置调查(6 路并行扫描 + 完整性批判,741k tokens)

- 消费链全貌:`gen_dts.py` 是全仓唯一解析该 yml 的程序;入口仅 `Linux/Makefile:64` 与 `Linux/tools/Makefile:36` 的 `PLATFORM_CONFIG`(6+1 条 DTB 规则)。NEMU/NPC 仿真器代码均不读 yml(注释级引用),靠 `device_address.h` 人工同步 + 门禁。
- "混"的实质:平台差异不在 yml 表达而藏在 Makefile CLI 开关(NEMU-only 设备 virtio_rng/virtio_net/goldfish_rtc/reset_syscon 由 `--virtio-rng` 等开关只进 NEMU rootfs DTB);`bootargs.rootfs` 仅对 NEMU 生效(NPC 被 `--bootargs-override` 整串覆盖);yml 路径字段全部硬编码 npc 命名空间,对 NEMU 不成立(死字段);`reset/opensbi/kernel/dtb/ubuntu_initrd/rootfs` 六段无人解析。
- 拆分红线:DTB 文件名是跨脚本 API(`build-opensbi.sh` 按 basename case 分发,改名静默落 `*)` 分支构建错误固件);e2e 硬编码 `gen_dts.py` 路径+源码字面量、NEMU rootfs DTB 路径+fdtget 内容断言;NEMU 是 NPC golden reference,共享地址布局是 difftest 前提 → **验证标准定为拆分前后 DTB bit-exact**。

## 方案

`common-rv64.yml`(两侧必须一致的共享 SoC 契约:memory/装载布局/clint/plic/uart0/virtio_blk/共享 bootargs/rng-seed)+ `npc-rv64.yml`/`nemu-rv64.yml`(平台差异:产物路径、NEMU 独有设备、rootfs bootargs),平台文件顶层 `base: common-rv64.yml`,`gen_dts.py` 递归加载深合并(平台键覆盖 base,dict 递归、标量/列表整体替换;带成环检测与缺文件报错)。`Linux/Makefile` 的 `PLATFORM_CONFIG` 改为 `$(LINUX_HOME)/platform/$(LINUX_PLATFORM)-rv64.yml` 按 ARCH 自动选中,新增 `PLATFORM_CONFIG_COMMON` 进 6 条 DTB 规则依赖;`tools/Makefile` 固定 npc(其 DTB 只喂 NPC_SIM)同样补 common 依赖。顺带:死字段 `fw_jump_addr` 更名 `opensbi.load_addr` 消歧(与 build-opensbi.sh 的 OpenSBI 官方编译参数 FW_JUMP_ADDR=0x80200000 同名不同义,原值 0x80000000 是装载地址)。

## 改动文件

- 新增 `Linux/platform/common-rv64.yml`、`Linux/platform/nemu-rv64.yml`;重写 `Linux/platform/npc-rv64.yml`(文件名保留,e2e 存在性契约不破)
- `Linux/platform/gen_dts.py`:`deep_merge`/`load_config` base 支持
- `Linux/Makefile`(PLATFORM_CONFIG 平台化 + 6 规则依赖)、`Linux/tools/Makefile`(common 依赖)
- `Linux/platform/README.md` 重写;`.github/agents/{linux-device,display-vga}.agent.md` 引用更新
- 审查修复:`scripts/e2e/modules/{module_contracts,nemu}.sh` required-files 登记新 yml;`nemu/include/device/device_address.h:41`、`nemu/src/device/Kconfig:46` 过时交叉引用改指 common+nemu yml;两平台 yml 注释修正(initrd.image 是 gen_dts fallback 非纯文档;NEMU 独有设备门禁不覆盖、goldfish_rtc/reset_syscon 还需同步 AM 侧 device_address.h)

## 验证证据

1. **bit-exact 主证据**:复刻 6+1 条 DTB 规则全部调用形态(kernel/initramfs/ubuntu-probe/ubuntu-shell/npc-rootfs/nemu-rootfs × 两平台 config,共 11 个 DTS),拆分前后 `diff -r` 零差异(三轮:拆分后、错误路径加固后、审查修复后均 PASS)。
2. **真实 make**:`make -C Linux ARCH=riscv64-npc rootfs-dtb`、`ARCH=riscv64-nemu rootfs-dtb`、`ARCH=riscv64-npc dtb`、`make -C Linux/tools dtb` 全部成功,重建 DTB md5 与拆分前产物一致(npc-rootfs `6a8f8665...`、nemu-rootfs `a3f2bee2...`),DTB 未变 → 无需重建 fw_jump.bin。
3. **门禁**:`check-device-address-map.sh` PASS;e2e 对 gen_dts.py 的两组字面量 grep 契约逐条复现 PASS;`python3 -m py_compile` PASS;e2e 模块脚本 `bash -n` PASS。
4. **守护路径**:base 成环 → 干净 SystemExit;base 缺文件 → 明确报错(含引用者路径)。
5. **对抗性审查**(3 维度 × 逐 finding 独立证伪,14 agents):4 个确认缺陷全部为文档/门禁级并已修复(上节);7 个误报否决(均"技术现象属实但实际使用路径零影响或非本次回归",其中"ARCH=riscv64-npc 直接构建 NEMU_ROOTFS_DTB 文件目标改为报错"判定为拆分契约的预期防护——语义矛盾的组合 fail-fast 优于偶然成功)。

## 遗留/边界

- 本轮是配置管理拆分,刻意零语义变化:`plic.sources_rootfs=32` 仍按 mode 不按平台(NPC 实际只挂 irq1/2,声明上限无害)、rng_seed 字节串(内容含"nemu"命名)保持原值进两侧 DTB(改动会使 DTB 全变)。若将来平台化这两项,DTB 会变,须连带重建 fw_jump.bin(FW_FDT_PATH 恒嵌)并复验两侧 boot。
- `check-device-address-map.sh` 不校验 NEMU 独有 4 设备(virtio_rng/net/goldfish_rtc/reset_syscon)——门禁缺口已在 nemu-rv64.yml 注释如实标注,扩门禁属后续可选加固。
- OpenSBI/Linux 内核源码树两平台共享、NPC 补丁无条件 apply(NEMU 固件/内核也带 NPC 补丁)——调查中确认的既有事实,不属本次范围。
