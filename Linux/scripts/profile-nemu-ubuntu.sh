#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$LINUX_HOME/.." && pwd)

date_stamp=$(date '+%Y-%m-%d')
OUT_DIR=${NEMU_PROFILE_OUTPUT_DIR:-"$REPO_ROOT/.github/task-runs/${date_stamp}-nemu-ubuntu-profile/evidence/nemu-profile"}
case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$REPO_ROOT/$OUT_DIR" ;;
esac
MAX_CYCLES=${NEMU_PROFILE_MAX_CYCLES:-1000000000}
PROGRESS=${NEMU_PROFILE_PROGRESS:-50000000}
ROOTFS_FLAVOR=${NEMU_PROFILE_ROOTFS_FLAVOR:-full}
TB_MAX_INST=${NEMU_PROFILE_TB_MAX_INST:-32}
OPCODE_MIX=${NEMU_PROFILE_OPCODE_MIX:-0}
STOP_DETAIL=${NEMU_PROFILE_STOP_DETAIL:-0}
DECODE_CACHE_DETAIL=${NEMU_PROFILE_DECODE_CACHE:-0}
RVC_DETAIL=${NEMU_PROFILE_RVC_DETAIL:-0}
GUEST_COUNTERS=${NEMU_PROFILE_GUEST_COUNTERS:-1}
TIMEOUT_SECONDS=${NEMU_PROFILE_TIMEOUT_SECONDS:-0}
RUNTIME_BASIC_BLOCK=${NEMU_INTERPRETER_BASIC_BLOCK:-1}
RUNTIME_WIDE_IFETCH=${NEMU_INTERPRETER_WIDE_IFETCH:-1}
RUNTIME_DECODE_CACHE=${NEMU_INTERPRETER_DECODE_CACHE:-1}
RUNTIME_VADDR_HOST_FAST=${NEMU_VADDR_HOST_FAST:-1}
RUNTIME_MMU_TLB=${NEMU_RISCV_MMU_TLB:-1}
RUNTIME_VIRTIO_BLK_SYNC=${NEMU_VIRTIO_BLK_SYNC:-0}
NEMU_PLATFORM_ROOT=${NEMU_PLATFORM_ROOT:-"$LINUX_HOME/env/platforms/nemu"}
NEMU_IMAGE_ROOT=${NEMU_IMAGE_ROOT:-"$NEMU_PLATFORM_ROOT/images/ubuntu2204"}
HOST_PERF_RECORD=${NEMU_PROFILE_HOST_PERF_RECORD:-0}
HOST_PERF_FREQ=${NEMU_PROFILE_HOST_PERF_FREQ:-99}
HOST_PERF_AUTO=${NEMU_PROFILE_HOST_PERF_AUTO:-1}
HOST_PERF_CACHE=${NEMU_PROFILE_HOST_PERF_CACHE:-"$NEMU_PLATFORM_ROOT/tools/host-perf"}
HOST_PERF_BIN=${NEMU_PROFILE_HOST_PERF_BIN:-}
HOST_PERF_LD_LIBRARY_PATH=${NEMU_PROFILE_HOST_PERF_LD_LIBRARY_PATH:-}
HOST_PERF_ANNOTATE=${NEMU_PROFILE_HOST_PERF_ANNOTATE:-0}
HOST_PERF_ANNOTATE_TOP=${NEMU_PROFILE_HOST_PERF_ANNOTATE_TOP:-3}

case "$ROOTFS_FLAVOR" in
  full)
    ROOTFS_IMAGE=${NEMU_PROFILE_ROOTFS_IMAGE:-"$NEMU_IMAGE_ROOT/ubuntu-22.04-riscv64-full.ext4"}
    ROOTFS_CPIO_IMAGE=${NEMU_PROFILE_ROOTFS_CPIO_IMAGE:-"$NEMU_IMAGE_ROOT/ubuntu-22.04-riscv64-full-rootfs.cpio"}
    ROOTFS_IMAGE_MAKE_VAR=UBUNTU_ROOTFS_FULL_IMAGE
    ROOTFS_CPIO_MAKE_VAR=UBUNTU_ROOTFS_FULL_CPIO_IMAGE
    ;;
  interactive)
    ROOTFS_IMAGE=${NEMU_PROFILE_ROOTFS_IMAGE:-"$NEMU_IMAGE_ROOT/ubuntu-22.04-riscv64-interactive.ext4"}
    ROOTFS_CPIO_IMAGE=${NEMU_PROFILE_ROOTFS_CPIO_IMAGE:-"$NEMU_IMAGE_ROOT/ubuntu-22.04-riscv64-interactive-rootfs.cpio"}
    ROOTFS_IMAGE_MAKE_VAR=UBUNTU_ROOTFS_INTERACTIVE_IMAGE
    ROOTFS_CPIO_MAKE_VAR=UBUNTU_ROOTFS_INTERACTIVE_CPIO_IMAGE
    ;;
  systemd-minimal)
    ROOTFS_IMAGE=${NEMU_PROFILE_ROOTFS_IMAGE:-"$NEMU_IMAGE_ROOT/ubuntu-22.04-riscv64.ext4"}
    ROOTFS_CPIO_IMAGE=${NEMU_PROFILE_ROOTFS_CPIO_IMAGE:-"$NEMU_IMAGE_ROOT/ubuntu-22.04-riscv64-rootfs.cpio"}
    ROOTFS_IMAGE_MAKE_VAR=UBUNTU_ROOTFS_SYSTEMD_IMAGE
    ROOTFS_CPIO_MAKE_VAR=UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE
    ;;
  *)
    printf 'profile error: unsupported NEMU_PROFILE_ROOTFS_FLAVOR=%s\n' "$ROOTFS_FLAVOR" >&2
    exit 2
    ;;
esac

RUN_DIR="$OUT_DIR/linux-run"
CONSOLE_LOG="$OUT_DIR/console.log"
NEMU_LOG="$OUT_DIR/nemu.log"
RUN_LOG="$OUT_DIR/profile-run.log"
SUMMARY="$OUT_DIR/profile-summary.txt"
COMMAND_FILE="$OUT_DIR/profile-command.txt"
HOST_PROFILE="$OUT_DIR/host-profiler.txt"
OVERLAY="$OUT_DIR/rootfs-overlay.raw"
mkdir -p "$OUT_DIR" "$RUN_DIR"

{
  printf 'repo_root=%s\n' "$REPO_ROOT"
  printf 'rootfs_flavor=%s\n' "$ROOTFS_FLAVOR"
  printf 'rootfs_image=%s\n' "$ROOTFS_IMAGE"
  printf 'max_cycles=%s\n' "$MAX_CYCLES"
  printf 'progress=%s\n' "$PROGRESS"
  printf 'tb_max_inst=%s\n' "$TB_MAX_INST"
  printf 'opcode_mix=%s\n' "$OPCODE_MIX"
  printf 'stop_detail=%s\n' "$STOP_DETAIL"
  printf 'decode_cache_detail=%s\n' "$DECODE_CACHE_DETAIL"
  printf 'rvc_detail=%s\n' "$RVC_DETAIL"
  printf 'guest_counters=%s\n' "$GUEST_COUNTERS"
  printf 'host_perf_record=%s\n' "$HOST_PERF_RECORD"
  printf 'host_perf_freq=%s\n' "$HOST_PERF_FREQ"
  printf 'host_perf_annotate=%s\n' "$HOST_PERF_ANNOTATE"
  printf 'host_perf_annotate_top=%s\n' "$HOST_PERF_ANNOTATE_TOP"
  printf 'timeout_seconds=%s\n' "$TIMEOUT_SECONDS"
  printf 'runtime.basic_block=%s\n' "$RUNTIME_BASIC_BLOCK"
  printf 'runtime.wide_ifetch=%s\n' "$RUNTIME_WIDE_IFETCH"
  printf 'runtime.decode_cache=%s\n' "$RUNTIME_DECODE_CACHE"
  printf 'runtime.vaddr_host_fast=%s\n' "$RUNTIME_VADDR_HOST_FAST"
  printf 'runtime.mmu_tlb=%s\n' "$RUNTIME_MMU_TLB"
  printf 'runtime.virtio_blk_sync=%s\n' "$RUNTIME_VIRTIO_BLK_SYNC"
  printf 'mode=performance-profile-tests-off\n'
} > "$COMMAND_FILE"

host_perf_cmd() {
  if [[ -n "$HOST_PERF_LD_LIBRARY_PATH" ]]; then
    LD_LIBRARY_PATH="$HOST_PERF_LD_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      "$HOST_PERF_BIN" "$@"
  else
    "$HOST_PERF_BIN" "$@"
  fi
}

host_perf_try_bin() {
  local candidate=$1
  local ld_path=${2:-}
  local smoke="$OUT_DIR/perf-smoke.out"
  if [[ ! -x $candidate ]]; then
    return 1
  fi
  HOST_PERF_BIN="$candidate"
  HOST_PERF_LD_LIBRARY_PATH="$ld_path"
  printf 'perf.path=%s\n' "$HOST_PERF_BIN"
  if [[ -n "$HOST_PERF_LD_LIBRARY_PATH" ]]; then
    printf 'perf.ld_library_path=%s\n' "$HOST_PERF_LD_LIBRARY_PATH"
  fi
  if host_perf_cmd stat -e task-clock true >"$smoke" 2>&1; then
    printf 'perf.status=available\n'
    cat "$smoke"
    return 0
  fi
  printf 'perf.status=unavailable\n'
  cat "$smoke"
  return 1
}

host_perf_try_local_cache() {
  if [[ "$HOST_PERF_AUTO" == 0 ]]; then
    printf 'perf.local.status=disabled\n'
    return 1
  fi
  if ! command -v apt-cache >/dev/null 2>&1 ||
      ! command -v apt-get >/dev/null 2>&1 ||
      ! command -v dpkg-deb >/dev/null 2>&1; then
    printf 'perf.local.status=missing-apt-tools\n'
    return 1
  fi

  local flavor_pkg base_pkg downloads root perf_bin ld_path
  flavor_pkg=$(apt-cache depends linux-tools-generic 2>/dev/null |
    awk '/Depends: linux-tools-[0-9].*-generic/ { print $2; exit }')
  if [[ -z "$flavor_pkg" ]]; then
    printf 'perf.local.status=missing-linux-tools-generic-dep\n'
    return 1
  fi
  base_pkg=${flavor_pkg%-generic}
  downloads="$HOST_PERF_CACHE/downloads"
  root="$HOST_PERF_CACHE/root"
  mkdir -p "$downloads" "$root"
  printf 'perf.local.package=%s\n' "$base_pkg"
  printf 'perf.local.cache=%s\n' "$HOST_PERF_CACHE"

  if ! find "$root" -path '*/perf' -type f -perm -u+x | grep -q .; then
    (
      cd "$downloads"
      apt-get download "$base_pkg" libtraceevent1
    )
    for deb in "$downloads"/*.deb; do
      dpkg-deb -x "$deb" "$root"
    done
  fi

  perf_bin=$(find "$root" -path '*/perf' -type f -perm -u+x | sort -V | tail -1)
  ld_path="$root/usr/lib/x86_64-linux-gnu"
  if [[ -z "$perf_bin" ]]; then
    printf 'perf.local.status=missing-perf-binary\n'
    return 1
  fi
  if host_perf_try_bin "$perf_bin" "$ld_path"; then
    printf 'perf.local.status=available\n'
    return 0
  fi
  printf 'perf.local.status=unavailable\n'
  return 1
}

host_perf_resolve() {
  printf 'perf.record.requested=%s\n' "$HOST_PERF_RECORD"
  printf 'perf.record.freq=%s\n' "$HOST_PERF_FREQ"
  if [[ -n "$HOST_PERF_BIN" ]]; then
    printf 'perf.source=env\n'
    host_perf_try_bin "$HOST_PERF_BIN" "$HOST_PERF_LD_LIBRARY_PATH" && return 0
  fi
  if command -v perf >/dev/null 2>&1; then
    printf 'perf.source=system\n'
    host_perf_try_bin "$(command -v perf)" "" && return 0
  else
    printf 'perf.status=missing\n'
  fi
  printf 'perf.source=local-cache\n'
  host_perf_try_local_cache && return 0
  return 1
}

{
  host_perf_resolve || true
} > "$HOST_PROFILE" 2>&1

run_make_profile() {
  env NEMU_PROFILE="$GUEST_COUNTERS" \
    NEMU_PROFILE_OPCODE_MIX="$OPCODE_MIX" \
    NEMU_PROFILE_STOP_DETAIL="$STOP_DETAIL" \
    NEMU_PROFILE_DECODE_CACHE="$DECODE_CACHE_DETAIL" \
    NEMU_PROFILE_RVC_DETAIL="$RVC_DETAIL" \
    NEMU_INTERPRETER_BASIC_BLOCK="$RUNTIME_BASIC_BLOCK" \
    NEMU_INTERPRETER_TB_MAX_INST="$TB_MAX_INST" \
    NEMU_INTERPRETER_WIDE_IFETCH="$RUNTIME_WIDE_IFETCH" \
    NEMU_INTERPRETER_DECODE_CACHE="$RUNTIME_DECODE_CACHE" \
    NEMU_VADDR_HOST_FAST="$RUNTIME_VADDR_HOST_FAST" \
    NEMU_RISCV_MMU_TLB="$RUNTIME_MMU_TLB" \
    NEMU_VIRTIO_BLK_SYNC="$RUNTIME_VIRTIO_BLK_SYNC" \
    /usr/bin/time -v \
    make -C "$LINUX_HOME" ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
      NEMU_SYSTEMD_ROOTFS_FLAVOR="$ROOTFS_FLAVOR" \
      UBUNTU_ROOTFS_FLAVOR="$ROOTFS_FLAVOR" \
      UBUNTU_ROOTFS_IMAGE="$ROOTFS_IMAGE" \
      UBUNTU_ROOTFS_CPIO_IMAGE="$ROOTFS_CPIO_IMAGE" \
      "$ROOTFS_IMAGE_MAKE_VAR=$ROOTFS_IMAGE" \
      "$ROOTFS_CPIO_MAKE_VAR=$ROOTFS_CPIO_IMAGE" \
      LOG_DIR="$RUN_DIR" \
      LOG_FILE="$NEMU_LOG" \
      CONSOLE_LOG="$CONSOLE_LOG" \
      NEMU_RUN_ROOTFS_OVERLAY="$OVERLAY" \
      NEMU_RUN_ROOTFS_OVERLAY_RESET=1 \
      MAX_CYCLES="$MAX_CYCLES" \
      PROGRESS="$PROGRESS" \
      run
}
export LINUX_HOME ROOTFS_FLAVOR ROOTFS_IMAGE ROOTFS_CPIO_IMAGE ROOTFS_IMAGE_MAKE_VAR ROOTFS_CPIO_MAKE_VAR RUN_DIR NEMU_LOG
export CONSOLE_LOG OVERLAY MAX_CYCLES PROGRESS TB_MAX_INST OPCODE_MIX DECODE_CACHE_DETAIL RVC_DETAIL
export GUEST_COUNTERS
export RUNTIME_BASIC_BLOCK RUNTIME_WIDE_IFETCH RUNTIME_DECODE_CACHE
export RUNTIME_VADDR_HOST_FAST RUNTIME_MMU_TLB RUNTIME_VIRTIO_BLK_SYNC
export -f run_make_profile

run_profile_command() {
  if [[ "$HOST_PERF_RECORD" != 0 && -n "$HOST_PERF_BIN" ]]; then
    host_perf_cmd record -F "$HOST_PERF_FREQ" -g \
      -o "$OUT_DIR/perf.data" -- bash -c 'run_make_profile'
  else
    run_make_profile
  fi
}
export OUT_DIR HOST_PERF_BIN HOST_PERF_LD_LIBRARY_PATH HOST_PERF_RECORD HOST_PERF_FREQ
export -f host_perf_cmd run_profile_command

set +e
if [[ "$TIMEOUT_SECONDS" != 0 ]]; then
  timeout "$TIMEOUT_SECONDS" bash -c 'run_profile_command' 2>&1 | tee "$RUN_LOG"
  run_rc=${PIPESTATUS[0]}
else
  run_profile_command 2>&1 | tee "$RUN_LOG"
  run_rc=${PIPESTATUS[0]}
fi
set -e

{
  if [[ "$HOST_PERF_RECORD" != 0 ]]; then
    if [[ -s "$OUT_DIR/perf.data" && -n "$HOST_PERF_BIN" ]]; then
      printf 'perf.record.status=captured\n'
      printf 'perf.record.data=%s\n' "$OUT_DIR/perf.data"
      if host_perf_cmd report --stdio --no-children \
          --sort comm,dso,symbol -i "$OUT_DIR/perf.data" \
          > "$OUT_DIR/perf-report.txt" 2> "$OUT_DIR/perf-report.err"; then
        printf 'perf.report.status=available\n'
        printf 'perf.report.path=%s\n' "$OUT_DIR/perf-report.txt"
        if [[ "$HOST_PERF_ANNOTATE" != 0 ]]; then
          python3 - "$OUT_DIR/perf-report.txt" "$OUT_DIR/perf-annotate-symbols.txt" "$HOST_PERF_ANNOTATE_TOP" <<'PY'
import re
import sys
from pathlib import Path

report = Path(sys.argv[1])
symbols = Path(sys.argv[2])
limit = int(sys.argv[3])
top_re = re.compile(r"^\s*([0-9]+(?:\.[0-9]+)?)%\s+.*?\[\.\]\s+(\S+)")
found = []
for raw in report.read_text(encoding="utf-8", errors="replace").splitlines():
    match = top_re.match(raw)
    if not match:
        continue
    found.append(match.group(2))
    if len(found) >= limit:
        break
symbols.write_text("\n".join(found) + ("\n" if found else ""), encoding="utf-8")
PY
          : > "$OUT_DIR/perf-annotate-manifest.tsv"
          if [[ -s "$OUT_DIR/perf-annotate-symbols.txt" ]]; then
            printf 'perf.annotate.status=running\n'
            while IFS= read -r symbol; do
              safe_symbol=$(printf '%s' "$symbol" | tr -c 'A-Za-z0-9_.@+-' '_')
              annotate_out="$OUT_DIR/perf-annotate-${safe_symbol}.txt"
              annotate_err="$OUT_DIR/perf-annotate-${safe_symbol}.err"
              if host_perf_cmd annotate --stdio -i "$OUT_DIR/perf.data" --symbol "$symbol" \
                  > "$annotate_out" 2> "$annotate_err"; then
                printf '%s\tavailable\t%s\n' "$symbol" "$annotate_out" \
                  >> "$OUT_DIR/perf-annotate-manifest.tsv"
                printf 'perf.annotate.symbol=%s path=%s\n' "$symbol" "$annotate_out"
              else
                printf '%s\tfailed\t%s\n' "$symbol" "$annotate_err" \
                  >> "$OUT_DIR/perf-annotate-manifest.tsv"
                printf 'perf.annotate.symbol=%s status=failed\n' "$symbol"
                cat "$annotate_err"
              fi
            done < "$OUT_DIR/perf-annotate-symbols.txt"
            printf 'perf.annotate.status=available\n'
            printf 'perf.annotate.manifest=%s\n' "$OUT_DIR/perf-annotate-manifest.tsv"
          else
            printf 'perf.annotate.status=no-symbols\n'
          fi
        fi
      else
        printf 'perf.report.status=failed\n'
        cat "$OUT_DIR/perf-report.err"
      fi
    else
      printf 'perf.record.status=missing-data\n'
    fi
  fi
} >> "$HOST_PROFILE" 2>&1

python3 - "$CONSOLE_LOG" "$RUN_LOG" "$SUMMARY" "$OUT_DIR/perf-report.txt" "$OUT_DIR/perf-annotate-manifest.tsv" <<'PY'
import re
import sys
from pathlib import Path

console, run_log, summary, perf_report, perf_annotate_manifest = map(Path, sys.argv[1:6])
profile_re = re.compile(r"profile\.([A-Za-z0-9_.]+)=([0-9]+)")
perf_top_re = re.compile(r"^\s*([0-9]+(?:\.[0-9]+)?)%\s+.*?\[\.\]\s+(\S+)")
perf_annotate_re = re.compile(r"^\s*([0-9]+(?:\.[0-9]+)?)\s*:\s+[0-9a-f]+:\s+(.+)$")
ansi_re = re.compile(r"\x1b\[[0-9;]*m")
metrics = {}
sources = [p for p in (console, run_log) if p.exists()]
for path in sources:
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = ansi_re.sub("", raw)
        for name, value in profile_re.findall(line):
            metrics[name] = int(value)

host_perf_top = []
if perf_report.exists():
    for raw in perf_report.read_text(encoding="utf-8", errors="replace").splitlines():
        match = perf_top_re.match(raw)
        if not match:
            continue
        pct = int(round(float(match.group(1)) * 100))
        symbol = match.group(2)
        host_perf_top.append((pct, symbol))
        if len(host_perf_top) >= 10:
            break

def sanitize_summary_value(value: str) -> str:
    value = re.sub(r"\s+", "_", value.strip())
    value = value.replace("=", ":")
    return value[:160]

host_perf_annotate = []
if perf_annotate_manifest.exists():
    for raw in perf_annotate_manifest.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = raw.split("\t", 2)
        if len(parts) != 3:
            continue
        symbol, status, annotate_path = parts
        if status != "available":
            continue
        path = Path(annotate_path)
        hot = []
        if path.exists():
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
                match = perf_annotate_re.match(line)
                if not match:
                    continue
                pct = int(round(float(match.group(1)) * 100))
                asm = sanitize_summary_value(match.group(2))
                if pct > 0:
                    hot.append((pct, asm))
        hot.sort(key=lambda item: item[0], reverse=True)
        host_perf_annotate.append((symbol, path, hot[:5]))

lines = ["# NEMU Ubuntu Profile Summary", ""]
if not metrics:
    lines.append("profile.available=0")
else:
    lines.append("profile.available=1")
    for key in sorted(metrics):
        lines.append(f"profile.{key}={metrics[key]}")

def get(name):
    return metrics.get(name, 0)

if metrics:
    inst = get("guest_inst")
    total_us = get("total_exec_us")
    serial_us = get("serial.tx_flush_us")
    device_us = get("device.interval_us")
    virtio_us = get("device.virtio_blk_us")
    lines.extend([
        "",
        "# Derived",
        f"derived.serial_flush_time_pct_x100={serial_us * 10000 // total_us if total_us else 0}",
        f"derived.device_interval_time_pct_x100={device_us * 10000 // total_us if total_us else 0}",
        f"derived.virtio_blk_time_pct_x100={virtio_us * 10000 // total_us if total_us else 0}",
        f"derived.paddr_mmio_total={get('paddr.mmio_reads') + get('paddr.mmio_writes')}",
        f"derived.serial_bytes_per_kinst_x100={get('serial.tx_bytes') * 100000 // inst if inst else 0}",
        f"derived.decode_cache_hit_rate_x100={get('cpu.decode_cache.hits') * 10000 // get('cpu.decode_cache.lookups') if get('cpu.decode_cache.lookups') else 0}",
        f"derived.decode_cache_rvc_hit_pct_x100={get('cpu.decode_cache.hit_rvc') * 10000 // get('cpu.decode_cache.hits') if get('cpu.decode_cache.hits') else 0}",
        f"derived.decode_cache_rvc_fill_pct_x100={get('cpu.decode_cache.fill_rvc') * 10000 // get('cpu.decode_cache.fills') if get('cpu.decode_cache.fills') else 0}",
    ])
    tb_blocks = get("cpu.basic_blocks")
    for key in (
        "control",
        "system",
        "memory_order",
        "io_write",
        "store_conservative",
        "limit",
        "state",
        "control_fallback",
        "fence_i",
        "amo",
        "system_csr",
        "system_wfi",
        "system_sfence_vma",
        "system_other",
    ):
        value = get(f"cpu.tb_stop_{key}")
        lines.append(f"derived.tb_stop_{key}_pct_x100={value * 10000 // tb_blocks if tb_blocks else 0}")
    amo_total = get("cpu.tb_stop_amo")
    for key in ("lr", "sc", "swap", "add", "other"):
        value = get(f"cpu.tb_stop_amo.{key}")
        lines.append(f"derived.tb_stop_amo_{key}_pct_x100={value * 10000 // amo_total if amo_total else 0}")
    system_csr_total = get("cpu.tb_stop_system_csr")
    for key in (
        "sstatus",
        "sie",
        "stvec",
        "sscratch",
        "sepc",
        "scause",
        "stval",
        "sip",
        "satp",
        "mstatus",
        "mie",
        "mtvec",
        "mscratch",
        "mepc",
        "mcause",
        "mtval",
        "mip",
        "medeleg",
        "mideleg",
        "mcounteren",
        "other",
    ):
        value = get(f"cpu.tb_stop_system_csr.{key}")
        lines.append(
            f"derived.tb_stop_system_csr_{key}_pct_x100="
            f"{value * 10000 // system_csr_total if system_csr_total else 0}"
        )
    for key in (
        "branch_taken",
        "branch_not_taken",
        "jump_direct",
        "jalr",
        "compressed_misc",
        "fence",
        "csr_readonly",
        "amo",
    ):
        value = get(f"cpu.tb_continue_{key}")
        lines.append(f"derived.tb_continue_{key}_per_block_x100={value * 100 // tb_blocks if tb_blocks else 0}")
    continue_amo_total = get("cpu.tb_continue_amo")
    for key in ("lr", "sc", "swap", "add", "other"):
        value = get(f"cpu.tb_continue_amo.{key}")
        lines.append(
            f"derived.tb_continue_amo_{key}_pct_x100="
            f"{value * 10000 // continue_amo_total if continue_amo_total else 0}"
        )
    if get("cpu.opcode_mix.enabled"):
        opcode_keys = (
            "rvc",
            "load",
            "load_fp",
            "misc_mem",
            "op_imm",
            "op_imm_32",
            "auipc",
            "store",
            "store_fp",
            "amo",
            "op",
            "op_32",
            "fp",
            "branch",
            "jalr",
            "jal",
            "lui",
            "system",
            "other",
        )
        opcode_total = sum(get(f"cpu.opcode.{key}") for key in opcode_keys)
        lines.append(f"derived.opcode_mix_total={opcode_total}")
        for key in opcode_keys:
            value = get(f"cpu.opcode.{key}")
            lines.append(f"derived.opcode_{key}_pct_x100={value * 10000 // opcode_total if opcode_total else 0}")
    if get("cpu.rvc_detail.enabled"):
        rvc_keys = (
            "addi4spn",
            "fld",
            "lw",
            "ld",
            "fsd",
            "sw",
            "sd",
            "addi",
            "addiw",
            "li",
            "addi16sp",
            "lui",
            "srli",
            "srai",
            "andi",
            "sub",
            "xor",
            "or",
            "and",
            "subw",
            "addw",
            "j",
            "beqz",
            "bnez",
            "slli",
            "fldsp",
            "lwsp",
            "ldsp",
            "jr",
            "mv",
            "ebreak",
            "jalr",
            "add",
            "fsdsp",
            "swsp",
            "sdsp",
            "other",
        )
        rvc_total = sum(get(f"cpu.rvc.{key}") for key in rvc_keys)
        lines.append(f"derived.rvc_detail_total={rvc_total}")
        for key in rvc_keys:
            value = get(f"cpu.rvc.{key}")
            lines.append(f"derived.rvc_{key}_pct_x100={value * 10000 // rvc_total if rvc_total else 0}")

lines.extend(["", "# Host Perf"])
lines.append(f"host_perf.available={1 if host_perf_top else 0}")
for idx, (pct, symbol) in enumerate(host_perf_top, start=1):
    lines.append(f"host_perf.top{idx}_pct_x100={pct}")
    lines.append(f"host_perf.top{idx}_symbol={symbol}")
lines.append(f"host_perf.annotate.available={1 if host_perf_annotate else 0}")
for idx, (symbol, path, hot) in enumerate(host_perf_annotate, start=1):
    lines.append(f"host_perf.annotate.top{idx}_symbol={symbol}")
    lines.append(f"host_perf.annotate.top{idx}_path={path}")
    for hot_idx, (pct, asm) in enumerate(hot, start=1):
        lines.append(f"host_perf.annotate.top{idx}_hot{hot_idx}_pct_x100={pct}")
        lines.append(f"host_perf.annotate.top{idx}_hot{hot_idx}_asm={asm}")

summary.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

if [[ ! -s "$SUMMARY" ]]; then
  printf 'profile error: no profile summary written; see %s and %s\n' "$CONSOLE_LOG" "$RUN_LOG" >&2
  exit 3
fi

if [[ "$GUEST_COUNTERS" != 0 ]] && ! grep -q '^profile.available=1$' "$SUMMARY"; then
  printf 'profile error: no profile.* metrics captured; see %s and %s\n' "$CONSOLE_LOG" "$RUN_LOG" >&2
  exit 3
fi

if grep -Eq 'HIT BAD TRAP|ABORT|Assertion .*failed|address .*out of bound|Segmentation fault' "$CONSOLE_LOG" "$RUN_LOG"; then
  printf 'profile error: NEMU failure marker found; see %s\n' "$SUMMARY" >&2
  exit 4
fi

printf 'profile summary: %s\n' "$SUMMARY"
exit "$run_rc"
