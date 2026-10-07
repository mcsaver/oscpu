#!/usr/bin/env python3
"""Boot the real GUI/full image, use NAT/SSH/APT, then verify a persistent reboot."""
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
env = os.environ.copy()
required = ("NEMU_SIM", "LINUX_IMAGE", "RUN_FW", "RUN_DTB", "RUN_ROOTFS", "NEMU_SSH_KEY")
for name in required:
    if not Path(env[name]).is_file():
        raise SystemExit(f"missing {name}: {env[name]}")
log_root = Path(env["NEMU_FULL_CHECK_LOG_DIR"])
log_root.mkdir(parents=True, exist_ok=True)
out = Path(tempfile.mkdtemp(prefix="run-", dir=log_root))
port = int(env.get("NEMU_FULL_CHECK_SSH_PORT", "2224"))
console = out / "console.log"
guest_log = out / "guest-check.log"
known_hosts = out / "known_hosts"
key = subprocess.run(
    ["debugfs", "-R", "cat /etc/ssh/ssh_host_ed25519_key.pub", env["RUN_ROOTFS"]],
    check=True, capture_output=True, text=True,
).stdout.strip()
if not key.startswith("ssh-ed25519 "):
    raise SystemExit("image has no Ed25519 SSH host key")
known_hosts.write_text(f"[127.0.0.1]:{port} {key}\n")
ssh = ["ssh", "-p", str(port), "-i", env["NEMU_SSH_KEY"],
       "-o", "BatchMode=yes", "-o", "ConnectTimeout=30",
       "-o", "StrictHostKeyChecking=yes", "-o", f"UserKnownHostsFile={known_hosts}",
       "-o", "ServerAliveInterval=30", "-o", "ServerAliveCountMax=6", "root@127.0.0.1"]
env.update(NEMU_SERIAL_INPUT_STDIN="0", SDL_VIDEODRIVER="x11",
           NEMU_SERIAL_FIFO=str(out / "serial.fifo"))
command = ["xvfb-run", "-a", "bash", str(ROOT / "Linux/scripts/run-nemu-reboot-loop.sh"),
           "--max-boots=2", "--", env["NEMU_SIM"], "-b", "--max-insts=0",
           "--net-user", f"--ssh-port={port}", "--boot-hartid=0", "--boot-dtb=0x82200000",
           "-i", env["RUN_FW"], "--load=0x80200000:" + env["LINUX_IMAGE"],
           "--load=0x82200000:" + env["RUN_DTB"], "--block=" + env["RUN_ROOTFS"],
           "--block-overlay=" + str(out / "overlay.raw")]
backing_before = Path(env["RUN_ROOTFS"]).stat()
print(f"[nemu-full-check] logs: {out}", flush=True)
stream = console.open("w")
proc = subprocess.Popen(command, env=env, stdout=stream, stderr=subprocess.STDOUT,
                        stdin=subprocess.DEVNULL, start_new_session=True)

def alive():
    if proc.poll() is not None:
        raise RuntimeError(f"NEMU exited early: {proc.returncode}; see {console}")

def remote(script, timeout=180, check=True):
    # Preserve live progress and partial output even if slow guest APT times out.
    with guest_log.open("a+") as log:
        start = log.tell()
        result = subprocess.run(ssh + ["bash -se"], input=script, text=True,
                                stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
        log.seek(start)
        result.stdout = log.read()
    if check and result.returncode:
        raise RuntimeError(f"guest command failed ({result.returncode}): {result.stdout[-4000:]}")
    return result

def wait_ready(previous_boot=None):
    deadline = time.monotonic() + int(env.get("NEMU_FULL_CHECK_BOOT_TIMEOUT", "900"))
    # Wait for real PAM/login first; avoid making repeated SSH sessions during cold boot.
    wanted = 1 if previous_boot is None else 2
    while time.monotonic() < deadline:
        alive()
        if console.read_text(errors="replace").count("__NEMU_LOGIN_CHECK_DONE__ rc=0") >= wanted:
            break
        time.sleep(2)
    else:
        raise RuntimeError(f"login timed out; see {console}")
    while time.monotonic() < deadline:
        alive()
        result = remote("cat /proc/sys/kernel/random/boot_id\n", timeout=60, check=False)
        boot_id = result.stdout.strip()
        if result.returncode == 0 and re.fullmatch(r"[0-9a-f-]{36}", boot_id) and boot_id != previous_boot:
            return boot_id
        time.sleep(2)
    raise RuntimeError("SSH or guest reboot did not become ready")

try:
    boot_id = wait_ready()
    print("[nemu-full-check] SSH login ready", flush=True)
    # Regression: a peer disconnect must not deliver fatal SIGPIPE to NEMU.
    with socket.create_connection(("127.0.0.1", port), timeout=10) as peer:
        peer.recv(256)
    remote("""test "$(uname -m)" = riscv64
. /etc/os-release
test "$VERSION_ID" = 22.04
test "$(cat /proc/1/comm)" = systemd
systemctl is-system-running --wait
for unit in ssh systemd-networkd systemd-resolved cron rsyslog; do systemctl is-active "$unit"; done
test -c /dev/fb0
test -c /dev/tty1
test ! -e /etc/dpkg/dpkg.cfg.d/excludes
test ! -e /etc/update-motd.d/60-unminimize
test -s /usr/share/doc/bash/COMPAT.gz
man -w bash
man -w apt-get
grep -qx '800,600' /sys/class/graphics/fb0/virtual_size
ip -4 addr show dev eth0
ip route
getent hosts "$(hostname)"
getent ahostsv4 mirrors.ustc.edu.cn
curl -4 --fail --connect-timeout 20 --max-time 120 https://mirrors.ustc.edu.cn/ubuntu-ports/dists/jammy/InRelease -o /tmp/nemu-jammy-InRelease
gpgv --keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg /tmp/nemu-jammy-InRelease
test -z "$(dpkg --audit)"
echo __FULL_NETWORK_TLS_SIGNATURE_OK__
""", timeout=300)
    print("[nemu-full-check] DHCP/DNS/HTTPS/signature passed; testing APT", flush=True)
    remote("""export DEBIAN_FRONTEND=noninteractive LC_ALL=C
apt-get update -o APT::Update::Error-Mode=any
apt-get install -y --no-install-recommends hello
test "$(hello)" = 'Hello, world!'
dpkg-query -W hello
man -w hello
test -z "$(dpkg --audit)"
echo __FULL_APT_OK__
""", timeout=1800)
    remote("""export LC_ALL=C
useradd -m -s /bin/bash nemucheck
printf 'nemucheck ALL=(ALL) NOPASSWD: /usr/bin/id\n' > /etc/sudoers.d/nemucheck
chmod 0440 /etc/sudoers.d/nemucheck
visudo -cf /etc/sudoers.d/nemucheck
test "$(runuser -u nemucheck -- sudo -n /usr/bin/id -u)" = 0
rm /etc/sudoers.d/nemucheck
userdel -r nemucheck
cat > /etc/systemd/system/nemu-persist-check.service <<'UNIT'
[Unit]
Description=NEMU full-system persistent service check
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo boot >> /root/nemu-full-boot-count'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now nemu-persist-check.service
systemctl restart cron rsyslog
test "$(wc -l < /root/nemu-full-boot-count)" = 1
echo retained > /root/nemu-full-persist
journalctl -u nemu-persist-check --no-pager
echo __FULL_SERVICE_USER_SUDO_OK__
sync
""", timeout=300)
    print("[nemu-full-check] packages, user/sudo and service management passed; rebooting", flush=True)
    result = remote("systemctl --no-wall reboot\n", check=False)
    if result.returncode not in (0, 255):
        raise RuntimeError(f"reboot request failed: {result.stdout}")
    wait_ready(boot_id)
    remote("""test "$(cat /root/nemu-full-persist)" = retained
test "$(wc -l < /root/nemu-full-boot-count)" = 2
test "$(LC_ALL=C hello)" = 'Hello, world!'
systemctl is-system-running --wait
for unit in ssh systemd-networkd systemd-resolved nemu-persist-check; do systemctl is-active "$unit"; done
systemctl --failed --no-pager
echo __FULL_PERSISTENT_REBOOT_OK__
sync
systemctl --no-wall poweroff
""", timeout=300, check=False)
    if proc.wait(timeout=180) != 0:
        raise RuntimeError("NEMU did not exit successfully after poweroff")
    text = console.read_text(errors="replace")
    for marker in ("[nemu-reboot-loop] reboot 1/1", "reboot: Power down",
                   "syscon-reset: poweroff requested", "HIT GOOD TRAP"):
        if marker not in text:
            raise RuntimeError(f"missing lifecycle evidence: {marker}")
    if "__FULL_PERSISTENT_REBOOT_OK__" not in guest_log.read_text():
        raise RuntimeError("reboot verification failed")
    backing_after = Path(env["RUN_ROOTFS"]).stat()
    if (backing_before.st_size, backing_before.st_mtime_ns) != (backing_after.st_size, backing_after.st_mtime_ns):
        raise RuntimeError("immutable backing changed")
    print("[nemu-full-check] PASS: real NAT/APT/SSH/services/VGA nodes/persistent reboot/poweroff", flush=True)
finally:
    if proc.poll() is None:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
    stream.close()
