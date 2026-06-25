# NEMU full logind root serial session notes

- Scope: prove the current ttyS0 root autologin shell is a PAM/systemd-logind managed session in the NEMU Ubuntu 22.04 full rootfs gate.
- Rootfs contract: `libpam-systemd` is part of full flavor; `pam_systemd.so` exists; `/etc/pam.d/common-session` contains `session optional pam_systemd.so`.
- Important correction: `/etc/pam.d/common-session` is runtime PAM config, not a `libpam-systemd` ownership requirement.
- Static gate: `.github/task-runs/2026-06-25-nemu-full-logind-root-serial-session-contract/` PASS.
- Full gate: `.github/task-runs/2026-06-25-nemu-full-logind-root-serial-session-full-gate/` PASS, profile `nemu-dev-full-gate`, 4 nodes PASS.
- Console evidence: line 709 `__NEMU_CHECK_FULL_PAM_SYSTEMD_MODULE__:1`; line 710 `__NEMU_CHECK_FULL_PAM_COMMON_SESSION_SYSTEMD_HOOK__:1`; line 711 `full-userland-pam-systemd-session-hook`.
- Logind evidence: line 714 `XDG_SESSION_ID=c1`; line 716 logind active; lines 721-734 root session id/source/name/user/tty/type/class/remote/active/state/scope all satisfy the gate; line 735 `loginctl list-seats` rc 0; line 746 `full-userland-logind-root-serial-session`.
- Completion evidence: line 13607 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`; final console tail reaches poweroff and NEMU `HIT GOOD TRAP`.
- Negative scan: no `__NEMU_CHECK_FAIL__`, BAD TRAP, panic, Oops, SIGILL, Illegal instruction, unhandled signal, I/O error, or budget stop in task report/focused evidence/console/focused make log.
- Residual process scan: no real `riscv64-nemu`, `agent-e2e`, or `check-nemu-systemd` process after gate exit.
- Boundary: this is a root serial login/session-management gate, not a display manager, GNOME, Wayland/Xorg, DRM/GPU, or physical input-seat gate.
