#!/usr/bin/env bash

_ysyx_agent_env_script=${BASH_SOURCE[0]:-$0}
_ysyx_agent_env_root=$(cd "$(dirname "$_ysyx_agent_env_script")/.." && pwd)

# 非交互 agent/e2e 入口不能依赖 ~/.bashrc；这里集中加载可追踪的工程软环境。
# 只继承到 sourced marker、但没有继承工作区变量时，必须重新初始化，避免“看似 source、实际为空”。
if [[ -n ${YSYX_AGENT_ENV_SOURCED:-} ]]; then
  if [[ ${YSYX_HOME:-} == "$_ysyx_agent_env_root" &&
        ${NEMU_HOME:-} == "$_ysyx_agent_env_root/nemu" &&
        ${AM_HOME:-} == "$_ysyx_agent_env_root/abstract-machine" &&
        ${NPC_HOME:-} == "$_ysyx_agent_env_root/npc" &&
        ${NVBOARD_HOME:-} == "$_ysyx_agent_env_root/nvboard" ]]; then
    return 0 2>/dev/null || exit 0
  fi
  unset YSYX_AGENT_ENV_SOURCED YSYX_AGENT_ENV_SOURCE
  unset YSYX_HOME NEMU_HOME AM_HOME NPC_HOME NVBOARD_HOME YOSYSSTA_HOME
fi

ysyx_agent_env_prepend_path() {
  local dir=$1
  [[ -d $dir ]] || return 0
  case ":${PATH:-}:" in
    *":$dir:"*) ;;
    *) PATH="$dir:${PATH:-}" ;;
  esac
}

export YSYX_AGENT_ENV_SOURCED=1
export YSYX_AGENT_ENV_SOURCE=$_ysyx_agent_env_script
export YSYX_HOME=${YSYX_HOME:-$_ysyx_agent_env_root}
export NEMU_HOME=${NEMU_HOME:-$YSYX_HOME/nemu}
export AM_HOME=${AM_HOME:-$YSYX_HOME/abstract-machine}
export NPC_HOME=${NPC_HOME:-$YSYX_HOME/npc}
export NVBOARD_HOME=${NVBOARD_HOME:-$YSYX_HOME/nvboard}
export YOSYSSTA_HOME=${YOSYSSTA_HOME:-$YSYX_HOME/yosys-sta}

_ysyx_agent_home=${HOME:-}
if [[ -n $_ysyx_agent_home ]]; then
  ysyx_agent_env_prepend_path "$_ysyx_agent_home/.local/bin"
  ysyx_agent_env_prepend_path "$_ysyx_agent_home/oss-cad-suite/bin"

  if [[ -z ${RISCV_TOOLCHAIN_HOME:-} && -d "$_ysyx_agent_home/riscv-toolchain/riscv/bin" ]]; then
    export RISCV_TOOLCHAIN_HOME="$_ysyx_agent_home/riscv-toolchain/riscv"
  fi
  if [[ -n ${RISCV_TOOLCHAIN_HOME:-} ]]; then
    ysyx_agent_env_prepend_path "$RISCV_TOOLCHAIN_HOME/bin"
  fi

  if [[ -z ${JAVA_HOME:-} ]]; then
    for _ysyx_agent_java in "$_ysyx_agent_home"/.cache/coursier/arc/https/cdn.azul.com/zulu/bin/*/*; do
      if [[ -x "$_ysyx_agent_java/bin/java" ]]; then
        export JAVA_HOME=$_ysyx_agent_java
        break
      fi
    done
  fi
fi

ysyx_agent_env_prepend_path "$YSYX_HOME/oss-cad-suite/bin"
if [[ -n ${JAVA_HOME:-} ]]; then
  ysyx_agent_env_prepend_path "$JAVA_HOME/bin"
fi

# Vivado/Vitis 初始化较重，默认不在 e2e 中加载；需要 FPGA/EDA 任务时显式打开。
if [[ ${YSYX_AGENT_ENV_ENABLE_XILINX:-0} = 1 && -n ${_ysyx_agent_home:-} ]]; then
  [[ -f "$_ysyx_agent_home/AMD/2025.2/2025.2/Vivado/settings64.sh" ]] && source "$_ysyx_agent_home/AMD/2025.2/2025.2/Vivado/settings64.sh" >/dev/null 2>&1
  [[ -f "$_ysyx_agent_home/AMD/2025.2/2025.2/Vitis/settings64.sh" ]] && source "$_ysyx_agent_home/AMD/2025.2/2025.2/Vitis/settings64.sh" >/dev/null 2>&1
fi

export PATH
unset _ysyx_agent_env_root _ysyx_agent_env_script _ysyx_agent_home _ysyx_agent_java
