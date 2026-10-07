#!/usr/bin/env bash
# Apply NEMU full-userland defaults in a freshly constructed staging root.
set -euo pipefail
root=$1
flavor=$2
nemu=$3
authorized_keys=${4:-}
[[ $flavor == full && $nemu == 1 ]] || exit 0
[[ -d $root/etc && -f $root/etc/os-release && $(realpath "$root") != / ]] || exit 1
mkdir -p "$root/etc/systemd/network" "$root/etc/systemd/system/multi-user.target.wants"
cat > "$root/etc/systemd/network/80-nemu.network" <<'EOF'
[Match]
Name=eth* en*
[Link]
RequiredForOnline=no
[Network]
DHCP=ipv4
IPv6AcceptRA=no
LinkLocalAddressing=no
[DHCPv4]
UseDNS=yes
UseRoutes=yes
UseHostname=no
EOF
# DHCP works with user networking and the existing hostless test responder.
for service in systemd-networkd systemd-resolved systemd-timesyncd ssh cron rsyslog; do
  test -f "$root/lib/systemd/system/$service.service"
  ln -sfn "/lib/systemd/system/$service.service" "$root/etc/systemd/system/multi-user.target.wants/$service.service"
done
ln -sfn /run/systemd/resolve/resolv.conf "$root/etc/resolv.conf"
mkdir -p "$root/etc/apt/apt.conf.d" "$root/etc/ssh/sshd_config.d"
cat > "$root/etc/apt/apt.conf.d/80-nemu-network" <<'EOF'
Acquire::Retries "3";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::ForceIPv4 "true";
EOF
cat > "$root/etc/ssh/sshd_config.d/10-nemu-key-auth.conf" <<'EOF'
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
LoginGraceTime 180
EOF
if [[ -n $authorized_keys ]]; then
  [[ -f $authorized_keys && ! -L $authorized_keys ]] || exit 1
  ssh-keygen -l -f "$authorized_keys" >/dev/null
  install -d -m 0700 "$root/root/.ssh"
  install -m 0600 "$authorized_keys" "$root/root/.ssh/authorized_keys"
fi

# These are data-only equivalents of package initialization which dpkg-deb -x
# does not run. Use the guest CA package, never the host trust store.
mkdir -p "$root/etc/default" "$root/etc/ssl/certs"
printf 'LANG=C.UTF-8\n' > "$root/etc/default/locale"
# sudo resolves the local hostname even when external DNS is available.
printf '127.0.0.1\tlocalhost\n127.0.1.1\t%s\n::1\tlocalhost ip6-localhost ip6-loopback\n' \
  "$(cat "$root/etc/hostname")" > "$root/etc/hosts"
ln -sfn /lib/systemd/system/multi-user.target "$root/etc/systemd/system/default.target"
# This fixed Ubuntu 22.04 appliance does not need an overseas release-advert
# request on every login. APT security updates and manual release upgrades stay available.
if [[ -f $root/etc/update-motd.d/91-release-upgrade ]]; then
  chmod a-x "$root/etc/update-motd.d/91-release-upgrade"
fi
# pam_systemd starts a real user manager. Cold start under the interpreter can
# exceed login's 60 s default when VGA and serial logins arrive together.
sed -i -E 's/^[[:space:]]*LOGIN_TIMEOUT[[:space:]]+.*/LOGIN_TIMEOUT 180/' "$root/etc/login.defs"
systemd-sysusers --root="$root" - <<'EOF'
g input -
g render -
g kvm -
g sgx -
EOF
if [[ ! -s $root/etc/ca-certificates.conf ]]; then
  (cd "$root/usr/share/ca-certificates"; find . -type f -name '*.crt' -printf '%P\n' | LC_ALL=C sort) > "$root/etc/ca-certificates.conf"
fi
# Hook programs belong to the guest architecture; defer them to guest package
# management. CA bundles and OpenSSL subject hashes are architecture independent.
hooks=$(mktemp -d)
trap 'rmdir "$hooks"' EXIT
update-ca-certificates --fresh --certsconf "$root/etc/ca-certificates.conf" \
  --certsdir "$root/usr/share/ca-certificates" \
  --localcertsdir "$root/usr/local/share/ca-certificates" \
  --etccertsdir "$root/etc/ssl/certs" --hooksdir "$hooks"
python3 - "$root" <<'PYCA'
from pathlib import Path
import os, sys
root = Path(sys.argv[1]).resolve()
for link in (root / "etc/ssl/certs").iterdir():
    if not link.is_symlink():
        continue
    target = os.readlink(link)
    if target.startswith(str(root) + "/"):
        link.unlink()
        link.symlink_to(os.path.relpath(target, link.parent))
bundle = root / "etc/ssl/certs/ca-certificates.crt"
if bundle.stat().st_size < 10000:
    raise SystemExit("guest CA bundle unexpectedly empty")
PYCA
