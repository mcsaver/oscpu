set +e
set +u
stty -echo 2>/dev/null || true
exec /usr/local/sbin/ysyx-npc-systemd-strict-check --poweroff
