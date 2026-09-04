#!/usr/bin/env bash
set -euo pipefail

inputs=()
outputs=()

fail() {
  echo "[artifact-path-guard] FAIL: $*" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --input=*) inputs+=("${arg#*=}") ;;
    --output=*) outputs+=("${arg#*=}") ;;
    *) fail "unknown argument: $arg" ;;
  esac
done

((${#inputs[@]} > 0)) || fail "at least one --input is required"
((${#outputs[@]} > 0)) || fail "at least one --output is required"
command -v realpath >/dev/null 2>&1 || fail "missing host realpath"

input_reals=()
for input in "${inputs[@]}"; do
  [[ -f $input ]] || fail "required input is not a regular file: $input"
  input_reals+=("$(realpath -e -- "$input")")
done

output_reals=()
for ((i = 0; i < ${#outputs[@]}; i++)); do
  output=${outputs[i]}
  [[ -n $output ]] || fail "writable artifact path is empty"
  output_real=$(realpath -m -- "$output") ||
    fail "cannot resolve writable artifact: $output"
  case $output_real in
    /|'') fail "unsafe writable artifact path: $output_real" ;;
  esac

  if [[ -e $output || -L $output ]]; then
    [[ ! -L $output ]] || fail "writable artifact must not be a symlink: $output"
    [[ ! -d $output ]] || fail "writable artifact is a directory: $output"
    [[ -f $output ]] || fail "writable artifact has unsafe existing type: $output"
  fi

  for ((j = 0; j < ${#inputs[@]}; j++)); do
    if [[ $output_real == "${input_reals[j]}" ]] ||
       { [[ -e $output ]] && [[ $output -ef ${inputs[j]} ]]; }; then
      fail "writable artifact aliases required input: $output -> ${input_reals[j]}"
    fi
  done

  for ((j = 0; j < ${#output_reals[@]}; j++)); do
    if [[ $output_real == "${output_reals[j]}" ]] ||
       { [[ -e $output ]] && [[ -e ${outputs[j]} ]] &&
         [[ $output -ef ${outputs[j]} ]]; }; then
      fail "writable artifacts alias each other: $output and ${outputs[j]}"
    fi
  done
  output_reals+=("$output_real")
done

printf '[artifact-path-guard] inputs=%d outputs=%d OK\n' \
  "${#inputs[@]}" "${#outputs[@]}"
