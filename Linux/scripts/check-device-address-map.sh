#!/usr/bin/env bash
# 三侧设备地址图一致性门禁
#   AM   : abstract-machine/am/include/device_address.h      (DEV_*_BASE, SoC 分支)
#   NEMU : nemu/include/device/device_address.h              (DEV_*_MMIO, SoC 分支)
#   NPC  : npc/rv64/csrc/include/device_address.h            (NPC_*)
#        + npc/rv64/vsrc/include/define.v                    (DPI/syscon RTL 窗口)
# difftest 要求三方设备地址逐一相等;RV32 legacy(0xa0000000)分支不在校验范围。
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
AM=$ROOT/abstract-machine/am/include/device_address.h
NEMU=$ROOT/nemu/include/device/device_address.h
NPC=$ROOT/npc/rv64/csrc/include/device_address.h
DEFV=$ROOT/npc/rv64/vsrc/include/define.v

fail=0
note() { echo "[devmap] $*"; }
err()  { echo "[devmap] MISMATCH: $*" >&2; fail=1; }

# 取某文件中某宏的 SoC 分支值(过滤掉 legacy 0xa... 家族)
soc_val() { grep -oE "$2[[:space:]]+0x[0-9a-fA-F]+" "$1" | grep -oE '0x[0-9a-fA-F]+' | grep -viE '^0xa' | head -1; }
# NPC define.v 里的 64'hxxxx_xxxx_xxxx_xxxx -> 0x...
defv_val() { grep -E "define[[:space:]]+$2" "$1" | grep -oE "64'h[0-9a-fA-F_]+" | tr -d "_" | sed "s/64'h0*/0x/;s/0x$/0x0/" | head -1; }

norm() { printf '0x%x' "$1"; }  # 归一化十六进制

# 期望的统一 SoC 图
declare -A EXP=(
  [serial]=0x10000000 [clint]=0x02000000 [plic]=0x0c000000
  [syscon]=0x00100000
  [rtc]=0x12000048 [kbd]=0x12000060 [vgactl]=0x12000100 [fb]=0x13000000 [disk]=0x10001000
)

am_serial=$(soc_val "$AM" DEV_SERIAL_BASE); am_clint=$(soc_val "$AM" DEV_CLINT_BASE); am_plic=$(soc_val "$AM" DEV_PLIC_BASE)
am_syscon=$(soc_val "$AM" DEV_SYSCON_BASE)
am_rtc=$(soc_val "$AM" DEV_RTC_BASE); am_kbd=$(soc_val "$AM" DEV_KBD_BASE); am_vga=$(soc_val "$AM" DEV_VGACTL_BASE)
am_fb=$(soc_val "$AM" DEV_FB_BASE); am_disk=$(soc_val "$AM" DEV_DISK_BASE)

ne_serial=$(soc_val "$NEMU" DEV_SERIAL_MMIO); ne_clint=$(soc_val "$NEMU" DEV_CLINT_MMIO); ne_plic=$(soc_val "$NEMU" DEV_PLIC_MMIO)
ne_syscon=$(soc_val "$NEMU" DEV_SYSCON_RESET_MMIO)
ne_rtc=$(soc_val "$NEMU" DEV_RTC_MMIO); ne_kbd=$(soc_val "$NEMU" DEV_KBD_MMIO); ne_vga=$(soc_val "$NEMU" DEV_VGA_CTL_MMIO)
ne_fb=$(soc_val "$NEMU" DEV_FB_ADDR); ne_disk=$(soc_val "$NEMU" DEV_DISK_MMIO)

# NPC: UART/CLINT/PLIC 直接给, 简易设备 = NPC_DEVICE_BASE + 偏移
np_uart=$(grep -oE 'NPC_UART_BASE[[:space:]]+UINT64_C\(0x[0-9a-fA-F]+' "$NPC" | grep -oE '0x[0-9a-fA-F]+')
np_clint=$(grep -oE 'NPC_CLINT_BASE[[:space:]]+UINT64_C\(0x[0-9a-fA-F]+' "$NPC" | grep -oE '0x[0-9a-fA-F]+')
np_plic=$(grep -oE 'NPC_PLIC_BASE[[:space:]]+UINT64_C\(0x[0-9a-fA-F]+' "$NPC" | grep -oE '0x[0-9a-fA-F]+')
np_syscon=$(grep -oE 'NPC_SYSCON_BASE[[:space:]]+UINT64_C\(0x[0-9a-fA-F]+' "$NPC" | grep -oE '0x[0-9a-fA-F]+')
np_base=$(grep -oE 'NPC_DEVICE_BASE[[:space:]]+UINT64_C\(0x[0-9a-fA-F]+' "$NPC" | grep -oE '0x[0-9a-fA-F]+')
np_rtc=$(norm $((np_base + 0x48))); np_kbd=$(norm $((np_base + 0x60)))
np_vga=$(norm $((np_base + 0x100))); np_fb=$(norm $((np_base + 0x1000000)))

defv_legacy=$(defv_val "$DEFV" NPC_AXI_LEGACY_MMIO_BASE)
defv_syscon=$(defv_val "$DEFV" NPC_AXI_RESET_SYSCON_BASE)

chk() { # name expected am nemu npc
  local n=$1 e=$2 a=$3 m=$4 p=$5
  [ "$((a))" = "$((e))" ] || err "$n: AM=$a != expect $e"
  [ "$((m))" = "$((e))" ] || err "$n: NEMU=$m != expect $e"
  [ "$((p))" = "$((e))" ] || err "$n: NPC=$p != expect $e"
  [ "$fail" = 0 ] && note "$n = $e (AM/NEMU/NPC 一致)"
}

chk serial "${EXP[serial]}" "$am_serial" "$ne_serial" "$np_uart"
chk clint  "${EXP[clint]}"  "$am_clint"  "$ne_clint"  "$np_clint"
chk plic   "${EXP[plic]}"   "$am_plic"   "$ne_plic"   "$np_plic"
chk syscon "${EXP[syscon]}" "$am_syscon" "$ne_syscon" "$np_syscon"
chk rtc    "${EXP[rtc]}"    "$am_rtc"    "$ne_rtc"    "$np_rtc"
chk kbd    "${EXP[kbd]}"    "$am_kbd"    "$ne_kbd"    "$np_kbd"
chk vgactl "${EXP[vgactl]}" "$am_vga"    "$ne_vga"    "$np_vga"
chk fb     "${EXP[fb]}"     "$am_fb"     "$ne_fb"     "$np_fb"
# disk 只在 AM/NEMU (NPC 侧 virtio 由 RTL/其它处理)
[ "$((am_disk))" = "$((${EXP[disk]}))" ] || err "disk: AM=$am_disk != ${EXP[disk]}"
[ "$((ne_disk))" = "$((${EXP[disk]}))" ] || err "disk: NEMU=$ne_disk != ${EXP[disk]}"

# define.v 的 DPI 窗口基址必须等于 NPC_DEVICE_BASE
[ "$((defv_legacy))" = "$((np_base))" ] || err "define.v LEGACY_MMIO_BASE=$defv_legacy != NPC_DEVICE_BASE=$np_base"
[ "$fail" = 0 ] && note "define.v DPI 窗口 = NPC_DEVICE_BASE = $np_base"
[ "$((defv_syscon))" = "$((np_syscon))" ] || err "define.v RESET_SYSCON_BASE=$defv_syscon != NPC_SYSCON_BASE=$np_syscon"
[ "$fail" = 0 ] && note "define.v reset-syscon = NPC_SYSCON_BASE = $np_syscon"

if [ "$fail" = 0 ]; then
  note "PASS: AM / NEMU / NPC 三侧设备地址图一致"
else
  echo "[devmap] FAIL: 三侧设备地址图存在漂移, 见上" >&2
fi
exit $fail
