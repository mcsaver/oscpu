#!/usr/bin/env bash
set -euo pipefail

action="${1:-${NEMU_TAP_HOST_ACTION:-check}}"
tap_ifname="${NEMU_TAP_IFNAME:-${NEMU_SYSTEMD_NET_TAP:-nemu-tap0}}"
tap_owner="${NEMU_TAP_OWNER:-${USER:-}}"
host_ipv4_cidr="${NEMU_TAP_HOST_IPV4_CIDR:-10.0.3.1/24}"
guest_ipv4_cidr="${NEMU_TAP_GUEST_IPV4_CIDR:-10.0.3.15/24}"
guest_gateway="${NEMU_TAP_GATEWAY:-10.0.3.1}"
guest_dns="${NEMU_TAP_DNS:-1.1.1.1}"
nat_source_cidr="${NEMU_TAP_NAT_SOURCE_CIDR:-10.0.3.0/24}"
uplink_iface="${NEMU_TAP_UPLINK_IFACE:-}"
enable_nat="${NEMU_TAP_ENABLE_NAT:-0}"
require_ready="${NEMU_TAP_REQUIRE_READY:-0}"

fail() {
  echo "[nemu-tap-host] FAIL: $*" >&2
  exit 1
}

require_uint() {
  local name="$1"
  local value="$2"
  case "$value" in
    ''|*[!0-9]*)
      fail "$name must be an unsigned integer: $value"
      ;;
  esac
}

require_plain_token() {
  local name="$1"
  local value="$2"
  case "$value" in
    ''|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:/-]*)
      fail "$name contains unsupported char: $value"
      ;;
  esac
}

require_ifname() {
  local name="$1"
  local value="$2"
  case "$value" in
    ''|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-]*)
      fail "$name contains unsupported char: $value"
      ;;
  esac
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

cap_net_admin_available() {
  local cap_eff
  cap_eff="$(awk '/^CapEff:/ { print $2; exit }' /proc/self/status 2>/dev/null || true)"
  [ -n "$cap_eff" ] || return 1
  (( (16#$cap_eff & (1 << 12)) != 0 ))
}

print_plan_cmd() {
  local marker="$1"
  shift
  printf '__NEMU_TAP_HOST_%s_CMD__:%s\n' "$marker" "$*"
}

print_common_config() {
  printf '__NEMU_TAP_HOST_ACTION__:%s\n' "$action"
  printf '__NEMU_TAP_HOST_IFNAME__:%s\n' "$tap_ifname"
  printf '__NEMU_TAP_HOST_OWNER__:%s\n' "${tap_owner:-none}"
  printf '__NEMU_TAP_HOST_IPV4_CIDR__:%s\n' "$host_ipv4_cidr"
  printf '__NEMU_TAP_HOST_GUEST_IPV4_CIDR__:%s\n' "$guest_ipv4_cidr"
  printf '__NEMU_TAP_HOST_GUEST_GATEWAY__:%s\n' "$guest_gateway"
  printf '__NEMU_TAP_HOST_GUEST_DNS__:%s\n' "$guest_dns"
  printf '__NEMU_TAP_HOST_NAT_REQUESTED__:%s\n' "$enable_nat"
  printf '__NEMU_TAP_HOST_NAT_SOURCE_CIDR__:%s\n' "$nat_source_cidr"
  printf '__NEMU_TAP_HOST_UPLINK_IFACE__:%s\n' "${uplink_iface:-none}"
}

validate_config() {
  require_uint NEMU_TAP_ENABLE_NAT "$enable_nat"
  require_uint NEMU_TAP_REQUIRE_READY "$require_ready"
  require_ifname NEMU_TAP_IFNAME "$tap_ifname"
  if [ -n "$tap_owner" ]; then
    require_ifname NEMU_TAP_OWNER "$tap_owner"
  fi
  require_plain_token NEMU_TAP_HOST_IPV4_CIDR "$host_ipv4_cidr"
  require_plain_token NEMU_TAP_GUEST_IPV4_CIDR "$guest_ipv4_cidr"
  require_plain_token NEMU_TAP_GATEWAY "$guest_gateway"
  require_plain_token NEMU_TAP_DNS "$guest_dns"
  require_plain_token NEMU_TAP_NAT_SOURCE_CIDR "$nat_source_cidr"
  if [ -n "$uplink_iface" ]; then
    require_ifname NEMU_TAP_UPLINK_IFACE "$uplink_iface"
  fi
}

emit_setup_plan() {
  print_common_config
  print_plan_cmd SETUP "sudo ip tuntap add dev $tap_ifname mode tap${tap_owner:+ user $tap_owner}"
  print_plan_cmd SETUP "sudo ip addr replace $host_ipv4_cidr dev $tap_ifname"
  print_plan_cmd SETUP "sudo ip link set dev $tap_ifname up"
  if [ "$enable_nat" = "1" ]; then
    if [ -z "$uplink_iface" ]; then
      print_plan_cmd SETUP "# set NEMU_TAP_UPLINK_IFACE before enabling NAT"
    else
      print_plan_cmd SETUP "sudo sysctl -w net.ipv4.ip_forward=1"
      print_plan_cmd SETUP "sudo iptables -t nat -A POSTROUTING -s $nat_source_cidr -o $uplink_iface -j MASQUERADE"
      print_plan_cmd SETUP "sudo iptables -A FORWARD -i $tap_ifname -o $uplink_iface -j ACCEPT"
      print_plan_cmd SETUP "sudo iptables -A FORWARD -i $uplink_iface -o $tap_ifname -m state --state RELATED,ESTABLISHED -j ACCEPT"
    fi
  fi
  printf '__NEMU_TAP_HOST_GUEST_GATE_ARGS__:NEMU_SYSTEMD_NET_TAP=%s NEMU_SYSTEMD_TAP_IPV4_CIDR=%s NEMU_SYSTEMD_TAP_GATEWAY=%s NEMU_SYSTEMD_TAP_DNS=%s\n' \
    "$tap_ifname" "$guest_ipv4_cidr" "$guest_gateway" "$guest_dns"
  printf '__NEMU_TAP_HOST_PLAN_DONE__:setup\n'
}

emit_teardown_plan() {
  print_common_config
  if [ "$enable_nat" = "1" ] && [ -n "$uplink_iface" ]; then
    print_plan_cmd TEARDOWN "sudo iptables -D FORWARD -i $uplink_iface -o $tap_ifname -m state --state RELATED,ESTABLISHED -j ACCEPT"
    print_plan_cmd TEARDOWN "sudo iptables -D FORWARD -i $tap_ifname -o $uplink_iface -j ACCEPT"
    print_plan_cmd TEARDOWN "sudo iptables -t nat -D POSTROUTING -s $nat_source_cidr -o $uplink_iface -j MASQUERADE"
  fi
  print_plan_cmd TEARDOWN "sudo ip link set dev $tap_ifname down"
  print_plan_cmd TEARDOWN "sudo ip tuntap del dev $tap_ifname mode tap"
  printf '__NEMU_TAP_HOST_PLAN_DONE__:teardown\n'
}

run_check() {
  local tun_chardev=0
  local ip_cmd=0
  local iptables_cmd=0
  local cap_net_admin=0
  local iface_exists=0
  local host_ipv4_ready=0
  local ip_forward_value="unknown"
  local uplink_ready=0
  local nat_ready=1
  local ready=0

  [ -c /dev/net/tun ] && tun_chardev=1
  has_cmd ip && ip_cmd=1
  has_cmd iptables && iptables_cmd=1
  cap_net_admin_available && cap_net_admin=1

  if [ "$ip_cmd" = "1" ] && ip link show dev "$tap_ifname" >/dev/null 2>&1; then
    iface_exists=1
    if ip -o -4 addr show dev "$tap_ifname" 2>/dev/null |
       awk -v cidr="$host_ipv4_cidr" '$4 == cidr { found=1 } END { exit found ? 0 : 1 }'; then
      host_ipv4_ready=1
    fi
  fi

  ip_forward_value="$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo unknown)"
  if [ -n "$uplink_iface" ] && [ "$ip_cmd" = "1" ] &&
     ip link show dev "$uplink_iface" >/dev/null 2>&1; then
    uplink_ready=1
  fi
  if [ "$enable_nat" = "1" ]; then
    nat_ready=0
    if [ "$ip_forward_value" = "1" ] &&
       [ "$uplink_ready" = "1" ] &&
       [ "$iptables_cmd" = "1" ]; then
      nat_ready=1
    fi
  fi

  if [ "$tun_chardev" = "1" ] &&
     [ "$ip_cmd" = "1" ] &&
     [ "$iface_exists" = "1" ] &&
     [ "$host_ipv4_ready" = "1" ] &&
     [ "$nat_ready" = "1" ]; then
    ready=1
  fi

  print_common_config
  printf '__NEMU_TAP_HOST_TUN_CHARDEV__:%s\n' "$tun_chardev"
  printf '__NEMU_TAP_HOST_IP_CMD__:%s\n' "$ip_cmd"
  printf '__NEMU_TAP_HOST_IPTABLES_CMD__:%s\n' "$iptables_cmd"
  printf '__NEMU_TAP_HOST_CAP_NET_ADMIN__:%s\n' "$cap_net_admin"
  printf '__NEMU_TAP_HOST_IFACE_EXISTS__:%s\n' "$iface_exists"
  printf '__NEMU_TAP_HOST_IPV4_READY__:%s\n' "$host_ipv4_ready"
  printf '__NEMU_TAP_HOST_IP_FORWARD__:%s\n' "$ip_forward_value"
  printf '__NEMU_TAP_HOST_UPLINK_READY__:%s\n' "$uplink_ready"
  printf '__NEMU_TAP_HOST_NAT_READY__:%s\n' "$nat_ready"
  printf '__NEMU_TAP_HOST_READY__:%s\n' "$ready"

  if [ "$ready" != "1" ]; then
    printf '__NEMU_TAP_HOST_NEXT__:run setup-plan and apply with root/CAP_NET_ADMIN, then rerun check with NEMU_TAP_REQUIRE_READY=1\n'
  fi
  if [ "$require_ready" = "1" ] && [ "$ready" != "1" ]; then
    fail "TAP host preflight is not ready for $tap_ifname"
  fi
}

validate_config
case "$action" in
  check)
    run_check
    ;;
  setup-plan)
    emit_setup_plan
    ;;
  teardown-plan)
    emit_teardown_plan
    ;;
  *)
    fail "unsupported action: $action"
    ;;
esac
