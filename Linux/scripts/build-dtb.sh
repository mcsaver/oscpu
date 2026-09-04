#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: build-dtb.sh --build-dir DIR --dtb FILE --dts FILE --stamp FILE
                    --python COMMAND --dtc COMMAND
                    [--input FILE]... [--profile ENTRY]... -- GEN_DTS_ARGS...
EOF
  exit 2
}

BUILD_DIR=
DTB_OUTPUT=
DTS_OUTPUT=
PROFILE_STAMP=
PYTHON_COMMAND=
DTC_COMMAND=
declare -a INPUTS=()
declare -a PROFILE_ENTRIES=()

while (($#)); do
  case "$1" in
    --build-dir)
      (($# >= 2)) || usage
      BUILD_DIR=$2
      shift 2
      ;;
    --dtb)
      (($# >= 2)) || usage
      DTB_OUTPUT=$2
      shift 2
      ;;
    --dts)
      (($# >= 2)) || usage
      DTS_OUTPUT=$2
      shift 2
      ;;
    --stamp)
      (($# >= 2)) || usage
      PROFILE_STAMP=$2
      shift 2
      ;;
    --python)
      (($# >= 2)) || usage
      PYTHON_COMMAND=$2
      shift 2
      ;;
    --dtc)
      (($# >= 2)) || usage
      DTC_COMMAND=$2
      shift 2
      ;;
    --input)
      (($# >= 2)) || usage
      INPUTS+=("$2")
      shift 2
      ;;
    --profile)
      (($# >= 2)) || usage
      PROFILE_ENTRIES+=("$2")
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      ;;
  esac
done

declare -a GEN_DTS_ARGS=("$@")
[[ -n $BUILD_DIR && -n $DTB_OUTPUT && -n $DTS_OUTPUT &&
   -n $PROFILE_STAMP && -n $PYTHON_COMMAND && -n $DTC_COMMAND &&
   ${#GEN_DTS_ARGS[@]} -gt 0 ]] || usage

for arg in "${GEN_DTS_ARGS[@]}"; do
  case "$arg" in
    --output|--output=*)
      echo "[dtb] caller must not provide --output; the transaction owns its temporary output" >&2
      exit 1
      ;;
  esac
done

for host_tool in awk cmp flock id mktemp mv realpath sha256sum sort stat sync; do
  command -v "$host_tool" >/dev/null 2>&1 || {
    echo "[dtb] missing host tool: $host_tool" >&2
    exit 1
  }
done

resolve_command() {
  local command_name=$1 resolved
  if [[ $command_name == */* ]]; then
    [[ -x $command_name ]] || {
      echo "[dtb] command is not executable: $command_name" >&2
      exit 1
    }
    # Keep the logical executable path (notably a Python venv symlink), while
    # separately hashing its canonical bytes below.
    resolved=$(realpath -s -- "$command_name")
  else
    resolved=$(command -v -- "$command_name") || {
      echo "[dtb] command not found: $command_name" >&2
      exit 1
    }
    resolved=$(realpath -s -- "$resolved")
  fi
  printf '%s\n' "$resolved"
}

canonical_output() {
  local label=$1 requested=$2 parent base
  if [[ -L $requested || ( -e $requested && ! -f $requested ) ]]; then
    echo "[dtb] unsafe $label output: $requested" >&2
    exit 1
  fi
  parent=$(dirname -- "$requested")
  base=$(basename -- "$requested")
  [[ $base != . && $base != .. && -d $parent ]] || {
    echo "[dtb] missing or unsafe $label parent: $parent" >&2
    exit 1
  }
  parent=$(realpath -e -- "$parent")
  printf '%s/%s\n' "$parent" "$base"
}

canonical_input() {
  local label=$1 requested=$2 resolved
  [[ -f $requested ]] || {
    echo "[dtb] missing or non-regular $label input: $requested" >&2
    exit 1
  }
  resolved=$(realpath -e -- "$requested")
  printf '%s\n' "$resolved"
}

[[ -d $BUILD_DIR ]] || {
  echo "[dtb] missing build directory: $BUILD_DIR" >&2
  exit 1
}
BUILD_DIR_CANONICAL=$(realpath -e -- "$BUILD_DIR")
[[ $BUILD_DIR_CANONICAL != / ]] || {
  echo "[dtb] refusing filesystem root as build directory" >&2
  exit 1
}

DTB_OUTPUT=$(canonical_output DTB "$DTB_OUTPUT")
DTS_OUTPUT=$(canonical_output DTS "$DTS_OUTPUT")
PROFILE_STAMP=$(canonical_output profile-stamp "$PROFILE_STAMP")
PYTHON_COMMAND=$(resolve_command "$PYTHON_COMMAND")
DTC_COMMAND=$(resolve_command "$DTC_COMMAND")
HELPER_INPUT=$(realpath -e -- "${BASH_SOURCE[0]}")
PYTHON_INPUT=$(realpath -e -- "$PYTHON_COMMAND")
DTC_INPUT=$(realpath -e -- "$DTC_COMMAND")

declare -a CANONICAL_INPUTS=("$HELPER_INPUT" "$PYTHON_INPUT" "$DTC_INPUT")
for input in "${INPUTS[@]}"; do
  CANONICAL_INPUTS+=("$(canonical_input declared "$input")")
done

# Always execute the canonical generator path when it was supplied as a file.
# This prevents a path alias from changing between profile construction and exec.
if [[ -f ${GEN_DTS_ARGS[0]} ]]; then
  GEN_DTS_ARGS[0]=$(realpath -e -- "${GEN_DTS_ARGS[0]}")
fi

paths_alias() {
  local left=$1 right=$2
  if [[ $(realpath -m -- "$left") == $(realpath -m -- "$right") ]]; then
    return 0
  fi
  [[ -e $left && -e $right && $left -ef $right ]]
}

declare -a OUTPUTS=("$DTB_OUTPUT" "$DTS_OUTPUT" "$PROFILE_STAMP")

# Lock identities are global for this uid and derived from both canonical path
# and existing inode.  The path key serializes atomic replacements; the inode
# key also closes hard-link aliases that spell the same object differently.
LOCK_ROOT="/tmp/ysyx-linux-dtb-locks-$(id -u)"
if [[ -L $LOCK_ROOT || ( -e $LOCK_ROOT && ! -d $LOCK_ROOT ) ]]; then
  echo "[dtb] unsafe global lock directory: $LOCK_ROOT" >&2
  exit 1
fi
if [[ ! -d $LOCK_ROOT ]]; then
  old_umask=$(umask)
  umask 077
  mkdir "$LOCK_ROOT" 2>/dev/null || true
  umask "$old_umask"
fi
[[ -d $LOCK_ROOT && ! -L $LOCK_ROOT ]] || {
  echo "[dtb] cannot create safe global lock directory: $LOCK_ROOT" >&2
  exit 1
}
[[ $(stat -Lc '%u' -- "$LOCK_ROOT") == $(id -u) ]] || {
  echo "[dtb] global lock directory is not owned by the current uid: $LOCK_ROOT" >&2
  exit 1
}
LOCK_ROOT=$(realpath -e -- "$LOCK_ROOT")

declare -a RESOURCE_IDENTITIES=()
add_resource_identities() {
  local resource=$1 inode
  RESOURCE_IDENTITIES+=("path:$resource")
  if [[ -e $resource ]]; then
    inode=$(stat -Lc '%d:%i' -- "$resource")
    RESOURCE_IDENTITIES+=("inode:$inode")
  fi
}
add_resource_identities "$BUILD_DIR_CANONICAL"
add_resource_identities "$DTB_OUTPUT"
add_resource_identities "$DTS_OUTPUT"
add_resource_identities "$PROFILE_STAMP"

declare -a LOCK_PATHS=()
mapfile -t LOCK_PATHS < <(
  for identity in "${RESOURCE_IDENTITIES[@]}"; do
    key=$(printf '%s\0' "$identity" | sha256sum | awk '{print $1}')
    printf '%s/%s.lock\n' "$LOCK_ROOT" "$key"
  done | LC_ALL=C sort -u
)

guard_paths() {
  local i j output input lock_path
  for output in "${OUTPUTS[@]}"; do
    if [[ -L $output || ( -e $output && ! -f $output ) ]]; then
      echo "[dtb] unsafe output appeared: $output" >&2
      exit 1
    fi
    if paths_alias "$output" "$LOCK_ROOT"; then
      echo "[dtb] output aliases global lock directory: $output" >&2
      exit 1
    fi
    case "$output" in
      "$LOCK_ROOT"/*)
        echo "[dtb] output must not be placed inside the global lock directory: $output" >&2
        exit 1
        ;;
    esac
    for input in "${CANONICAL_INPUTS[@]}"; do
      if paths_alias "$output" "$input"; then
        echo "[dtb] output aliases input: $output == $input" >&2
        exit 1
      fi
    done
    for lock_path in "${LOCK_PATHS[@]}"; do
      if paths_alias "$output" "$lock_path"; then
        echo "[dtb] output aliases transaction lock: $output == $lock_path" >&2
        exit 1
      fi
    done
  done
  for ((i = 0; i < ${#OUTPUTS[@]}; ++i)); do
    for ((j = i + 1; j < ${#OUTPUTS[@]}; ++j)); do
      if paths_alias "${OUTPUTS[i]}" "${OUTPUTS[j]}"; then
        echo "[dtb] DTB/DTS/profile outputs alias each other: ${OUTPUTS[i]} == ${OUTPUTS[j]}" >&2
        exit 1
      fi
    done
  done
  for ((i = 0; i < ${#LOCK_PATHS[@]}; ++i)); do
    lock_path=${LOCK_PATHS[i]}
    if [[ -L $lock_path || ( -e $lock_path && ! -f $lock_path ) ]]; then
      echo "[dtb] unsafe transaction lock: $lock_path" >&2
      exit 1
    fi
    for input in "${CANONICAL_INPUTS[@]}"; do
      if paths_alias "$lock_path" "$input"; then
        echo "[dtb] transaction lock aliases input: $lock_path == $input" >&2
        exit 1
      fi
    done
    for ((j = i + 1; j < ${#LOCK_PATHS[@]}; ++j)); do
      if paths_alias "$lock_path" "${LOCK_PATHS[j]}"; then
        echo "[dtb] transaction locks alias each other: $lock_path == ${LOCK_PATHS[j]}" >&2
        exit 1
      fi
    done
  done
}

# Validate before any lock redirection: opening a malicious lock alias must not
# be the first operation performed on an input or output inode.
guard_paths
declare -a LOCK_FDS=()
for lock_path in "${LOCK_PATHS[@]}"; do
  exec {lock_fd}>>"$lock_path"
  flock "$lock_fd"
  LOCK_FDS+=("$lock_fd")
done
# Paths may have changed while this process waited for a lock.
guard_paths

declare -a INPUT_HASHES=()
for input in "${CANONICAL_INPUTS[@]}"; do
  INPUT_HASHES+=("$(sha256sum -- "$input" | awk '{print $1}')")
done
ARGV_SHA256=$(printf '%s\0' "${GEN_DTS_ARGS[@]}" | sha256sum | awk '{print $1}')

inputs_still_match() {
  local i
  for ((i = 0; i < ${#CANONICAL_INPUTS[@]}; ++i)); do
    [[ $(sha256sum -- "${CANONICAL_INPUTS[i]}" | awk '{print $1}') == ${INPUT_HASHES[i]} ]] || return 1
  done
}

stamp_tmp=
dts_tmp=
dtb_tmp=
cleanup_temps() {
  local status=$?
  trap - EXIT HUP INT TERM
  rm -f -- "${stamp_tmp:-}" "${dts_tmp:-}" "${dtb_tmp:-}"
  exit "$status"
}
trap cleanup_temps EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

stamp_dir=$(dirname -- "$PROFILE_STAMP")
dts_dir=$(dirname -- "$DTS_OUTPUT")
dtb_dir=$(dirname -- "$DTB_OUTPUT")
stamp_tmp=$(mktemp "$stamp_dir/.$(basename -- "$PROFILE_STAMP").tmp.XXXXXX")

write_profile_prefix() {
  local output=$1 i
  {
    printf '%s\n' \
      'DTB_PROFILE_FORMAT=1' \
      "DTB_BUILD_DIR=$BUILD_DIR_CANONICAL" \
      "DTB_OUTPUT=$DTB_OUTPUT" \
      "DTS_OUTPUT=$DTS_OUTPUT" \
      "DTB_PROFILE_STAMP=$PROFILE_STAMP" \
      "PYTHON_COMMAND=$PYTHON_COMMAND" \
      "PYTHON_INPUT=$PYTHON_INPUT" \
      "DTC_COMMAND=$DTC_COMMAND" \
      "DTC_INPUT=$DTC_INPUT" \
      "GEN_DTS_ARGV_SHA256=$ARGV_SHA256"
    for ((i = 0; i < ${#PROFILE_ENTRIES[@]}; ++i)); do
      printf 'PROFILE_%d=%s\n' "$i" "${PROFILE_ENTRIES[i]}"
    done
    for ((i = 0; i < ${#CANONICAL_INPUTS[@]}; ++i)); do
      printf 'INPUT_%d_PATH=%s\n' "$i" "${CANONICAL_INPUTS[i]}"
      printf 'INPUT_%d_SHA256=%s\n' "$i" "${INPUT_HASHES[i]}"
    done
  } > "$output"
}

write_profile_prefix "$stamp_tmp"
if [[ -s $DTS_OUTPUT && -s $DTB_OUTPUT && -f $PROFILE_STAMP ]]; then
  current_dts_sha=$(sha256sum -- "$DTS_OUTPUT" | awk '{print $1}')
  current_dtb_sha=$(sha256sum -- "$DTB_OUTPUT" | awk '{print $1}')
  printf 'DTS_SHA256=%s\nDTB_SHA256=%s\n' \
    "$current_dts_sha" "$current_dtb_sha" >> "$stamp_tmp"
  if cmp -s "$stamp_tmp" "$PROFILE_STAMP" &&
     "$DTC_COMMAND" -I dtb -O dts -o /dev/null "$DTB_OUTPUT" >/dev/null 2>&1 &&
     inputs_still_match &&
     [[ $(sha256sum -- "$DTS_OUTPUT" | awk '{print $1}') == "$current_dts_sha" ]] &&
     [[ $(sha256sum -- "$DTB_OUTPUT" | awk '{print $1}') == "$current_dtb_sha" ]]; then
    guard_paths
    echo "[dtb] profile and DTS/DTB are current: $DTB_OUTPUT"
    exit 0
  fi
  write_profile_prefix "$stamp_tmp"
fi

dts_tmp=$(mktemp "$dts_dir/.$(basename -- "$DTS_OUTPUT").tmp.XXXXXX")
dtb_tmp=$(mktemp "$dtb_dir/.$(basename -- "$DTB_OUTPUT").tmp.XXXXXX")
"$PYTHON_COMMAND" "${GEN_DTS_ARGS[@]}" --output "$dts_tmp"
[[ -s $dts_tmp ]] || {
  echo "[dtb] generator produced an empty DTS" >&2
  exit 1
}
"$DTC_COMMAND" -I dts -O dtb -o "$dtb_tmp" "$dts_tmp"
[[ -s $dtb_tmp ]] || {
  echo "[dtb] dtc produced an empty DTB" >&2
  exit 1
}
"$DTC_COMMAND" -I dtb -O dts -o /dev/null "$dtb_tmp" >/dev/null 2>&1 || {
  echo "[dtb] generated DTB is not parseable" >&2
  exit 1
}

# Do not publish a result stamped with input bytes different from those used by
# the generator.  A subsequent invocation can retry from a stable snapshot.
for ((i = 0; i < ${#CANONICAL_INPUTS[@]}; ++i)); do
  if [[ $(sha256sum -- "${CANONICAL_INPUTS[i]}" | awk '{print $1}') != ${INPUT_HASHES[i]} ]]; then
    echo "[dtb] input changed during generation: ${CANONICAL_INPUTS[i]}" >&2
    exit 1
  fi
done

new_dts_sha=$(sha256sum -- "$dts_tmp" | awk '{print $1}')
new_dtb_sha=$(sha256sum -- "$dtb_tmp" | awk '{print $1}')
write_profile_prefix "$stamp_tmp"
printf 'DTS_SHA256=%s\nDTB_SHA256=%s\n' "$new_dts_sha" "$new_dtb_sha" >> "$stamp_tmp"
sync -f "$dts_tmp"
sync -f "$dtb_tmp"
sync -f "$stamp_tmp"

# Recheck immediately before rename.  All compliant writers hold the same
# ordered locks; this also fails safely if an external process substituted a
# symlink or hard-link alias while generation was running.
guard_paths
mv -fT -- "$dts_tmp" "$DTS_OUTPUT"
dts_tmp=
sync -f "$dts_dir"
mv -fT -- "$dtb_tmp" "$DTB_OUTPUT"
dtb_tmp=
sync -f "$dtb_dir"
# The stamp is the commit record and is intentionally published last.  It
# carries both output hashes, so interruption between renames is recoverable.
mv -fT -- "$stamp_tmp" "$PROFILE_STAMP"
stamp_tmp=
sync -f "$stamp_dir"

echo "[dtb] published consistent DTS/DTB profile: $DTB_OUTPUT"
