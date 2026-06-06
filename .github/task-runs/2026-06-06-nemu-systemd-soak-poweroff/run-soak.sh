#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

out=.github/task-runs/2026-06-06-nemu-systemd-soak-poweroff/run.out
status=.github/task-runs/2026-06-06-nemu-systemd-soak-poweroff/run.status

timeout 2600s make -C Linux check-nemu-systemd-guest-soak >"$out" 2>&1
printf "%s\n" "$?" >"$status"
