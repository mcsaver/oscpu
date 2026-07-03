#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
ARCH_TEST_HOME=${ARCH_TEST_HOME:-$ROOT_DIR/am-kernels/arch-test}
ARTIFACT_ROOT=${ARTIFACT_ROOT:-$ARCH_TEST_HOME}
ARCH_TEST_REPO=${ARCH_TEST_REPO:-https://github.com/riscv/riscv-arch-test.git}
ARCH_TEST_DIR=${ARCH_TEST_DIR:-$ARTIFACT_ROOT/src/riscv-arch-test}
ACT4_VENV=${ACT4_VENV:-$ARTIFACT_ROOT/env/act4-venv}
ACT4_GEMS=${ACT4_GEMS:-$ARTIFACT_ROOT/env/gems}
RUBY_DEV_PACKAGE=${RUBY_DEV_PACKAGE:-ruby3.2-dev}
RUBY_DEV_ROOT=${RUBY_DEV_ROOT:-$ARTIFACT_ROOT/env/ruby-dev-deb/extract}
RUBY_PATCH_DIR=${RUBY_PATCH_DIR:-$ARTIFACT_ROOT/env/ruby-dev-patch}
SAIL_DIR=${SAIL_DIR:-$ARTIFACT_ROOT/env/sail-riscv-0.12}
SAIL_VERSION=${SAIL_VERSION:-0.12}
XPACK_GCC_VERSION=${XPACK_GCC_VERSION:-15.2.0-1}
XPACK_GCC_DIR=${XPACK_GCC_DIR:-$ARTIFACT_ROOT/env/xpack-riscv-none-elf-gcc-$XPACK_GCC_VERSION}
XPACK_GCC_TARBALL=${XPACK_GCC_TARBALL:-$ARTIFACT_ROOT/env/xpack-riscv-none-elf-gcc-$XPACK_GCC_VERSION-linux-x64.tar.gz}
XPACK_GCC_URL=${XPACK_GCC_URL:-https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v$XPACK_GCC_VERSION/xpack-riscv-none-elf-gcc-$XPACK_GCC_VERSION-linux-x64.tar.gz}
WORKDIR=${WORKDIR:-$ARTIFACT_ROOT/build/probe-work}
CONFIG_NAME=${CONFIG_NAME:-sail-rv64-max}
ACT4_CONFIG_SRC_DIR=${ACT4_CONFIG_SRC_DIR:-}
if [[ -v PROBE_CONFIG_DIR ]]; then
  PROBE_CONFIG_DIR_EXPLICIT=1
else
  PROBE_CONFIG_DIR=$ARTIFACT_ROOT/config/$CONFIG_NAME-linux-gnu
  PROBE_CONFIG_DIR_EXPLICIT=0
fi
EXTENSIONS=${EXTENSIONS:-I}
EXCLUDE_EXTENSIONS=${EXCLUDE_EXTENSIONS:-Sm}
JOBS=${JOBS:-1}
COMPILER_EXE=${COMPILER_EXE:-riscv64-linux-gnu-gcc}
OBJDUMP_EXE=${OBJDUMP_EXE:-riscv64-linux-gnu-objdump}
ACT4_FAST=${ACT4_FAST:-1}
RUN_PREPARE=0
RUN_INSTALL_XPACK_GCC=0
RUN_PROBE_TESTS=0
RUN_PROBE_ELFS=0
CHECK_ONLY=1

usage() {
  cat <<'EOF'
Usage:
  npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh [options]

Options:
  --prepare             Clone/install ACT4 runtime prerequisites under npc/rv64/testsuites/core-tests
  --install-xpack-gcc   Download xPack RISC-V GCC 15 into the core-tests artifact
  --probe-tests         Run ACT4 assembly generation smoke (no DUT execution)
  --probe-elfs          Run ACT4 ELF generation probe
  --final-elfs          Build final self-checking ELFs under elfs/ for DUT execution
  --extensions LIST     ACT extension filter, default: I
  --config-name NAME    ACT config name/output dir, default: sail-rv64-max
  --config-src DIR      Source config dir under riscv-arch-test, default: auto by config name
  --probe-config-dir DIR
                        Generated DUT config dir, default: act4-config/<config-name>-linux-gnu
  --workdir DIR         ACT work directory, default: runtime artifact workdir
  --compiler EXE        Compiler for probe config, default: riscv64-linux-gnu-gcc
  --objdump EXE         Objdump for probe config, default: riscv64-linux-gnu-objdump
  -h, --help            Show this help

Notes:
  - This script does not run full Linux/rootfs.
  - --probe-tests proves the ACT4 generator path is usable.
  - --probe-elfs defaults to FAST=True and may only leave *.sig.elf intermediate files.
  - --final-elfs leaves FAST unset so final self-checking elfs/.../*.elf are emitted.
  - ELF generation currently requires ACT4-supported toolchains: GCC 15+ or LLVM 21+.
EOF
}

log() {
  printf '[npc-act4] %s\n' "$*"
}

fail() {
  log "FAIL: $*"
  return 1
}

abspath_from_root() {
  local path=$1
  if [[ $path = /* ]]; then
    printf '%s\n' "$path"
  else
    # ACT4 通过 make -C 进入源码目录，先归一到仓库根可避免相对 workdir 生成嵌套产物。
    printf '%s/%s\n' "$ROOT_DIR" "$path"
  fi
}

set_config_name() {
  CONFIG_NAME=$1
  if [[ $PROBE_CONFIG_DIR_EXPLICIT -eq 0 ]]; then
    PROBE_CONFIG_DIR=$ARTIFACT_ROOT/config/$CONFIG_NAME-linux-gnu
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prepare)
        RUN_PREPARE=1
        CHECK_ONLY=0
        shift
        ;;
      --install-xpack-gcc)
        RUN_INSTALL_XPACK_GCC=1
        CHECK_ONLY=0
        shift
        ;;
      --probe-tests)
        RUN_PROBE_TESTS=1
        CHECK_ONLY=0
        shift
        ;;
      --probe-elfs)
        RUN_PROBE_ELFS=1
        CHECK_ONLY=0
        shift
        ;;
      --final-elfs)
        RUN_PROBE_ELFS=1
        ACT4_FAST=0
        CHECK_ONLY=0
        shift
        ;;
      --extensions)
        [[ $# -ge 2 ]] || { echo "--extensions requires LIST" >&2; exit 2; }
        EXTENSIONS=$2
        shift 2
        ;;
      --config-name)
        [[ $# -ge 2 ]] || { echo "--config-name requires NAME" >&2; exit 2; }
        set_config_name "$2"
        shift 2
        ;;
      --config-src)
        [[ $# -ge 2 ]] || { echo "--config-src requires DIR" >&2; exit 2; }
        ACT4_CONFIG_SRC_DIR=$(abspath_from_root "$2")
        shift 2
        ;;
      --probe-config-dir)
        [[ $# -ge 2 ]] || { echo "--probe-config-dir requires DIR" >&2; exit 2; }
        PROBE_CONFIG_DIR=$(abspath_from_root "$2")
        PROBE_CONFIG_DIR_EXPLICIT=1
        shift 2
        ;;
      --workdir)
        [[ $# -ge 2 ]] || { echo "--workdir requires DIR" >&2; exit 2; }
        WORKDIR=$(abspath_from_root "$2")
        shift 2
        ;;
      --compiler)
        [[ $# -ge 2 ]] || { echo "--compiler requires EXE" >&2; exit 2; }
        COMPILER_EXE=$2
        shift 2
        ;;
      --objdump)
        [[ $# -ge 2 ]] || { echo "--objdump requires EXE" >&2; exit 2; }
        OBJDUMP_EXE=$2
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done
}

ensure_arch_test() {
  mkdir -p "$ARTIFACT_ROOT/src"
  if [[ -d $ARCH_TEST_DIR/.git ]]; then
    log "riscv-arch-test checkout: $ARCH_TEST_DIR ($(git -C "$ARCH_TEST_DIR" rev-parse --short HEAD))"
    return 0
  fi
  log "clone riscv-arch-test -> $ARCH_TEST_DIR"
  git clone --depth 1 "$ARCH_TEST_REPO" "$ARCH_TEST_DIR"
}

ensure_act4_python() {
  [[ -d $ARCH_TEST_DIR/.git ]] || fail "missing riscv-arch-test checkout; run --prepare first" || return 1
  if [[ ! -x $ACT4_VENV/bin/python ]]; then
    log "create ACT4 venv: $ACT4_VENV"
    python3 -m venv "$ACT4_VENV"
  fi
  local needs_install=0
  if ! "$ACT4_VENV/bin/python" -m pip show act testgen covergroupgen >/dev/null 2>&1; then
    needs_install=1
  elif ! "$ACT4_VENV/bin/act" --help >/dev/null 2>&1; then
    log "refresh ACT4 venv entrypoints after relocation"
    needs_install=1
  fi
  if [[ $needs_install -eq 1 ]]; then
    log "install ACT4 Python packages into venv"
    "$ACT4_VENV/bin/python" -m pip install \
      -e "$ARCH_TEST_DIR/framework" \
      -e "$ARCH_TEST_DIR/generators/testgen" \
      -e "$ARCH_TEST_DIR/generators/coverage"
  fi
  log "ACT4 python: $("$ACT4_VENV/bin/act" --help >/dev/null 2>&1 && echo ok)"
}

ensure_bundler() {
  mkdir -p "$ACT4_GEMS"
  if [[ ! -x $ACT4_GEMS/bin/bundle ]]; then
    log "install bundler into $ACT4_GEMS"
    gem install --install-dir "$ACT4_GEMS" bundler --no-document
  fi
  log "bundler: $("$ACT4_GEMS/bin/bundle" --version)"
}

ensure_ruby_dev_headers() {
  if [[ ! -f $RUBY_DEV_ROOT/usr/include/ruby-3.2.0/ruby.h ]]; then
    local deb_dir="$ARTIFACT_ROOT/env/ruby-dev-deb"
    mkdir -p "$deb_dir"
    log "download $RUBY_DEV_PACKAGE headers into core-tests artifact"
    (
      cd "$deb_dir" || exit 1
      rm -f ./*.deb
      apt-get download "$RUBY_DEV_PACKAGE"
      rm -rf extract
      mkdir -p extract
      dpkg-deb -x ./*.deb extract
    )
  fi

  local libdir="$RUBY_DEV_ROOT/usr/lib/x86_64-linux-gnu"
  local so_name
  so_name=$(ruby -rrbconfig -e 'print RbConfig::CONFIG["LIBRUBY_SO"]' 2>/dev/null || true)
  if [[ -n $so_name && -d $libdir && ! -e $libdir/$so_name ]]; then
    local system_so
    system_so=$(find /usr/lib /lib -name "$so_name" -print -quit 2>/dev/null || true)
    if [[ -n $system_so ]]; then
      ln -sfn "$system_so" "$libdir/$so_name"
    fi
  fi

  mkdir -p "$RUBY_PATCH_DIR"
  cat > "$RUBY_PATCH_DIR/npc_act4_rbconfig_patch.rb" <<'RUBY'
require "rbconfig"

root = ENV["NPC_ACT4_RUBY_DEV_ROOT"]
if root && !root.empty?
  include_base = File.join(root, "usr/include/ruby-3.2.0")
  include_arch = File.join(root, "usr/include/x86_64-linux-gnu/ruby-3.2.0")
  libdir = File.join(root, "usr/lib/x86_64-linux-gnu")
  ruby_so_name = RbConfig::CONFIG["RUBY_SO_NAME"] || "ruby-3.2"

  {
    "rubyhdrdir" => include_base,
    "rubyarchhdrdir" => include_arch,
    "libdir" => libdir,
    "topdir" => libdir,
    "LIBRUBYARG" => "-L#{libdir} -l#{ruby_so_name}",
    "LIBRUBYARG_SHARED" => "-L#{libdir} -l#{ruby_so_name}",
  }.each do |key, value|
    RbConfig::CONFIG[key] = value
    RbConfig::MAKEFILE_CONFIG[key] = value
  end
end
RUBY
  log "ruby dev headers: $RUBY_DEV_ROOT"
}

ensure_sail() {
  local sail_bin="$SAIL_DIR/bin/sail_riscv_sim"
  if [[ ! -x $sail_bin ]]; then
    local os
    local arch
    os=$(uname -s)
    arch=$(uname -m)
    mkdir -p "$SAIL_DIR"
    log "download Sail RISC-V $SAIL_VERSION for $os-$arch -> $SAIL_DIR"
    curl -L "https://github.com/riscv/sail-riscv/releases/download/$SAIL_VERSION/sail-riscv-$os-$arch.tar.gz" \
      | tar xz -C "$SAIL_DIR" --strip-components=1
  fi
  log "sail_riscv_sim: $("$sail_bin" --version | head -n 1)"
}

ensure_xpack_gcc() {
  if [[ ! -x $XPACK_GCC_DIR/bin/riscv-none-elf-gcc ]]; then
    mkdir -p "$ARTIFACT_ROOT"
    if [[ ! -f $XPACK_GCC_TARBALL ]]; then
      log "download xPack RISC-V GCC $XPACK_GCC_VERSION"
      curl -L "$XPACK_GCC_URL" -o "$XPACK_GCC_TARBALL"
    fi
    rm -rf "$XPACK_GCC_DIR"
    mkdir -p "$XPACK_GCC_DIR"
    log "extract xPack RISC-V GCC -> $XPACK_GCC_DIR"
    tar xzf "$XPACK_GCC_TARBALL" -C "$XPACK_GCC_DIR" --strip-components=1
  fi
  COMPILER_EXE="$XPACK_GCC_DIR/bin/riscv-none-elf-gcc"
  OBJDUMP_EXE="$XPACK_GCC_DIR/bin/riscv-none-elf-objdump"
  log "xPack compiler: $("$COMPILER_EXE" --version | head -n 1)"
}

act4_env() {
  export VIRTUAL_ENV="$ACT4_VENV"
  export GEM_HOME="$ACT4_GEMS"
  export GEM_PATH="$ACT4_GEMS"
  export BUNDLE_PATH="$ACT4_GEMS/bundle"
  export BUNDLE_USER_HOME="$ACT4_GEMS/bundle-home"
  export BUNDLE_APP_CONFIG="$ACT4_GEMS/bundle-config"
  export BUNDLE_BIN="$ACT4_GEMS/bin"
  export PATH="$ACT4_VENV/bin:$ACT4_GEMS/bin:$SAIL_DIR/bin:$XPACK_GCC_DIR/bin:/usr/local/bin:/usr/bin:/bin"
  if [[ -f $RUBY_PATCH_DIR/npc_act4_rbconfig_patch.rb ]]; then
    export NPC_ACT4_RUBY_DEV_ROOT="$RUBY_DEV_ROOT"
    export RUBYLIB="$RUBY_PATCH_DIR${RUBYLIB:+:$RUBYLIB}"
    if [[ ${RUBYOPT:-} != *npc_act4_rbconfig_patch* ]]; then
      export RUBYOPT="${RUBYOPT:+$RUBYOPT }-rnpc_act4_rbconfig_patch"
    fi
  fi
}

check_cli() {
  local name=$1
  if command -v "$name" >/dev/null 2>&1; then
    log "tool $name: $(command -v "$name")"
    return 0
  fi
  fail "missing tool: $name"
}

check_compiler_version() {
  if ! command -v "$COMPILER_EXE" >/dev/null 2>&1; then
    fail "missing compiler: $COMPILER_EXE"
    return 1
  fi
  local first_line
  first_line=$("$COMPILER_EXE" --version | head -n 1)
  log "compiler: $first_line"
  if [[ $first_line =~ GCC|gcc ]]; then
    local major
    major=$(printf '%s\n' "$first_line" | sed -n 's/.* \([0-9][0-9]*\)\..*/\1/p' | tail -n 1)
    if [[ -n $major && $major -lt 15 ]]; then
      fail "ACT4 requires GCC 15+ for ELF generation; found GCC $major"
      return 1
    fi
  elif [[ $first_line =~ clang|Clang ]]; then
    local major
    major=$(printf '%s\n' "$first_line" | sed -n 's/.*version \([0-9][0-9]*\)\..*/\1/p' | tail -n 1)
    if [[ -n $major && $major -lt 21 ]]; then
      fail "ACT4 requires LLVM/Clang 21+ for ELF generation; found Clang $major"
      return 1
    fi
  fi
}

check_ruby_headers() {
  local ruby_hdr_dir
  ruby_hdr_dir=$(ruby -rrbconfig -e 'print RbConfig::CONFIG["rubyhdrdir"]' 2>/dev/null || true)
  if ! ruby -e 'require "mkmf"; exit(have_header("ruby.h") ? 0 : 1)' >/tmp/npc-act4-ruby-header-check.log 2>&1; then
    fail "missing or unusable Ruby development headers: ruby.h check failed under ${ruby_hdr_dir:-<unknown>}"
    return 1
  fi
  log "ruby headers: $ruby_hdr_dir"
}

resolve_config_src_dir() {
  local candidate
  if [[ -n $ACT4_CONFIG_SRC_DIR ]]; then
    [[ -d $ACT4_CONFIG_SRC_DIR ]] || fail "missing ACT4 config source dir: $ACT4_CONFIG_SRC_DIR" || return 1
    printf '%s\n' "$ACT4_CONFIG_SRC_DIR"
    return 0
  fi

  for candidate in \
    "$ARCH_TEST_DIR/config/sail/$CONFIG_NAME" \
    "$ARCH_TEST_DIR/config/cores/cvw/$CONFIG_NAME" \
    "$ARCH_TEST_DIR/config/qemu/$CONFIG_NAME" \
    "$ARCH_TEST_DIR/config/spike/$CONFIG_NAME" \
    "$ARCH_TEST_DIR/config/imperas/$CONFIG_NAME" \
    "$ARCH_TEST_DIR/config/whisper/$CONFIG_NAME"; do
    if [[ -d $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  fail "cannot auto-resolve ACT4 config source for CONFIG_NAME=$CONFIG_NAME"
  return 1
}

write_probe_config() {
  [[ -d $ARCH_TEST_DIR/.git ]] || fail "missing riscv-arch-test checkout" || return 1
  local config_src_dir
  config_src_dir=$(resolve_config_src_dir) || return 1
  rm -rf "$PROBE_CONFIG_DIR"
  mkdir -p "$PROBE_CONFIG_DIR"
  cp "$config_src_dir"/* "$PROBE_CONFIG_DIR"/
  [[ -f $PROBE_CONFIG_DIR/test_config.yaml ]] || fail "config source lacks test_config.yaml: $config_src_dir" || return 1
  python3 - "$PROBE_CONFIG_DIR/test_config.yaml" "$COMPILER_EXE" "$OBJDUMP_EXE" "$SAIL_DIR/bin/sail_riscv_sim" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
compiler = sys.argv[2]
objdump = sys.argv[3]
sail = sys.argv[4]
text = path.read_text()
text = text.replace("riscv64-unknown-elf-gcc", compiler)
text = text.replace("riscv64-unknown-elf-objdump", objdump)
text = text.replace("sail_riscv_sim", sail)
path.write_text(text)
PY
  cat > "$PROBE_CONFIG_DIR/rvmodel_macros.h" <<'EOF'
#ifndef _RVMODEL_MACROS_H
#define _RVMODEL_MACROS_H

#define RVMODEL_DATA_SECTION                                      \
        .pushsection .tohost,"aw",@progbits;                    \
        .align 8; .global tohost; tohost: .dword 0;              \
        .align 8; .global fromhost; fromhost: .dword 0;          \
        .popsection;

#define STANDARD_SM_SUPPORTED

#define RVMODEL_HALT_PASS  \
  li x1, 1                ;\
  la t0, tohost           ;\
  write_tohost_pass:      ;\
    sd x1, 0(t0)          ;\
  self_loop_pass:         ;\
    j self_loop_pass      ;\

#define RVMODEL_HALT_FAIL \
  li x1, 3                ;\
  la t0, tohost           ;\
  write_tohost_fail:      ;\
    sd x1, 0(t0)          ;\
  self_loop_fail:         ;\
    j self_loop_fail      ;\

#define RVMODEL_IO_INIT(_R1, _R2, _R3)
#define RVMODEL_IO_WRITE_STR(_R1, _R2, _R3, _STR_PTR)

#define RVMODEL_ACCESS_FAULT_ADDRESS 0x00000000
#define RVMODEL_INTERRUPT_LATENCY 10
#define RVMODEL_TIMER_INT_SOON_DELAY 100
#define RVMODEL_MTIME_ADDRESS 0x0200BFF8
#define RVMODEL_MTIMECMP_ADDRESS 0x02004000
#define RVMODEL_MSIP_ADDRESS 0x02000000

#define RVMODEL_SET_MEXT_INT(_R1, _R2)
#define RVMODEL_CLR_MEXT_INT(_R1, _R2)
#define RVMODEL_SET_MSW_INT(_R1, _R2) \
  li _R1, 1;                         \
  li _R2, RVMODEL_MSIP_ADDRESS;      \
  sw _R1, 0(_R2);
#define RVMODEL_CLR_MSW_INT(_R1, _R2) \
  li _R2, RVMODEL_MSIP_ADDRESS;      \
  sw zero, 0(_R2);
#define RVMODEL_SET_SEXT_INT(_R1, _R2)
#define RVMODEL_CLR_SEXT_INT(_R1, _R2)
#define RVMODEL_SET_SSW_INT(_R1, _R2)
#define RVMODEL_CLR_SSW_INT(_R1, _R2)

#endif
EOF
  log "probe config: $PROBE_CONFIG_DIR/test_config.yaml (name=$CONFIG_NAME src=$config_src_dir)"
}

run_probe_tests() {
  ensure_act4_python || return 1
  act4_env
  local config_src_dir
  config_src_dir=$(resolve_config_src_dir) || return 1
  log "run ACT4 tests generation smoke EXTENSIONS=$EXTENSIONS"
  make -C "$ARCH_TEST_DIR" tests \
    CONFIG_FILES="$config_src_dir/test_config.yaml" \
    EXTENSIONS="$EXTENSIONS" \
    EXCLUDE_EXTENSIONS="$EXCLUDE_EXTENSIONS" \
    WORKDIR="$WORKDIR" \
    JOBS="$JOBS" \
    FAST=True
}

run_probe_elfs() {
  ensure_act4_python || return 1
  act4_env
  check_ruby_headers || return 1
  write_probe_config || return 1
  local make_args=(
    -C "$ARCH_TEST_DIR" elfs
    CONFIG_FILES="$PROBE_CONFIG_DIR/test_config.yaml"
    EXTENSIONS="$EXTENSIONS"
    EXCLUDE_EXTENSIONS="$EXCLUDE_EXTENSIONS"
    WORKDIR="$WORKDIR"
    JOBS="$JOBS"
  )
  if [[ $ACT4_FAST -eq 1 ]]; then
    make_args+=(FAST=True)
    log "run ACT4 ELF generation probe EXTENSIONS=$EXTENSIONS FAST=True"
  else
    log "run ACT4 final ELF generation EXTENSIONS=$EXTENSIONS FAST=<unset>"
  fi
  make "${make_args[@]}"
}

run_checks() {
  local rc=0
  act4_env
  check_cli python3 || rc=1
  check_cli ruby || rc=1
  check_ruby_headers || rc=1
  check_cli bundle || rc=1
  check_cli act || rc=1
  check_cli testgen || rc=1
  check_cli covergroupgen || rc=1
  check_cli sail_riscv_sim || rc=1
  check_cli "$OBJDUMP_EXE" || rc=1
  check_compiler_version || rc=1
  return "$rc"
}

main() {
  parse_args "$@"

  if [[ $RUN_PREPARE -eq 1 ]]; then
    ensure_arch_test || exit 1
    ensure_act4_python || exit 1
    ensure_bundler || exit 1
    ensure_ruby_dev_headers || exit 1
    ensure_sail || exit 1
  fi

  if [[ $RUN_INSTALL_XPACK_GCC -eq 1 ]]; then
    ensure_xpack_gcc || exit 1
  elif [[ -x $XPACK_GCC_DIR/bin/riscv-none-elf-gcc && $COMPILER_EXE == riscv64-linux-gnu-gcc ]]; then
    COMPILER_EXE="$XPACK_GCC_DIR/bin/riscv-none-elf-gcc"
    OBJDUMP_EXE="$XPACK_GCC_DIR/bin/riscv-none-elf-objdump"
  fi

  if [[ $RUN_PROBE_TESTS -eq 1 ]]; then
    run_probe_tests || exit 1
  fi

  if [[ $RUN_PROBE_ELFS -eq 1 ]]; then
    run_probe_elfs || exit 1
  fi

  if [[ $CHECK_ONLY -eq 1 ]]; then
    run_checks
  fi
}

main "$@"
