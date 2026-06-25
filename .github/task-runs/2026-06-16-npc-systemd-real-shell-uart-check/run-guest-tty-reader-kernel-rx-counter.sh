#!/usr/bin/env bash
set -euo pipefail

cd /home/lyg/PA/ysyx-workbench

export NPC_TTY_READER_MODE=c-probe
export NPC_TTY_READER_SKIP_BUILD=1
export NPC_TTY_READER_SKIP_IMAGE_CHECK=1
export NPC_TTY_READER_LOG_NAME=npc-systemd-tty-reader-c-probe-kernel-rx-counter
export NPC_TTY_READER_RC_NAME=tty-reader-c-probe-kernel-rx-counter.rc
export NPC_TTY_READER_DONE_MARKER=__NPC_TTY_READER_DONE__
export NPC_TTY_READER_MAX_CYCLES=760000000
export NPC_TTY_READER_HOST_TIMEOUT=4200
export NPC_UART_ACCESS_TRACE=0
export NPC_IRQ_TRACE=0

exec bash .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-tty-reader.sh
