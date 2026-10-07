// User-mode IPv4 networking. All callbacks run on the emulator thread;
// only that thread is allowed to update virtqueues or guest memory.
#include <common.h>
#include <utils.h>
#include <device/net-user.h>
#include <slirp/libslirp.h>
#include <poll.h>
#include <errno.h>
#include <limits.h>
#include <signal.h>

typedef struct NetTimer {
  SlirpTimerCb callback;
  void *opaque;
  int64_t expires_ms;
  struct NetTimer *next;
} NetTimer;

static Slirp *stack;
static bool requested;
static unsigned ssh_port;
static NetUserReceive receive_frame;
static struct pollfd *pollfds;
static size_t poll_count, poll_capacity;
static NetTimer *timers;
static uint64_t last_poll_us;

bool net_user_requested(void) { return requested; }
bool net_user_enabled(void) { return stack != NULL; }
unsigned net_user_ssh_port(void) { return ssh_port; }
void net_user_request(void) { requested = true; }

void net_user_set_ssh_port(const char *port) {
  char *end = NULL;
  errno = 0;
  unsigned long value = strtoul(port, &end, 10);
  Assert(errno == 0 && end != port && *end == '\0' && value <= 65535 && value > 0,
      "invalid --ssh-port: %s (expected 1..65535)", port);
  ssh_port = (unsigned)value;
}

static ssize_t send_packet(const void *buf, size_t size, void *opaque) {
  (void)opaque;
  if (size <= UINT32_MAX && receive_frame(buf, (uint32_t)size))
    return (ssize_t)size;
  // A full guest RX ring drops the packet; TCP handles retransmission.
  return (ssize_t)size;
}
static void guest_error(const char *message, void *opaque) {
  (void)opaque;
  Log("virtio-net user backend: %s", message);
}
static int64_t clock_ns(void *opaque) {
  (void)opaque;
  return (int64_t)get_time() * 1000;
}
static void *timer_new(SlirpTimerCb callback, void *cb_opaque, void *opaque) {
  (void)opaque;
  NetTimer *timer = calloc(1, sizeof(*timer));
  Assert(timer, "libslirp timer allocation failed");
  timer->callback = callback;
  timer->opaque = cb_opaque;
  timer->expires_ms = -1;
  timer->next = timers;
  timers = timer;
  return timer;
}
static void timer_free(void *value, void *opaque) {
  (void)opaque;
  NetTimer **p = &timers;
  while (*p && *p != value) p = &(*p)->next;
  if (*p) { NetTimer *old = *p; *p = old->next; free(old); }
}
static void timer_mod(void *value, int64_t expires_ms, void *opaque) {
  (void)opaque;
  ((NetTimer *)value)->expires_ms = expires_ms;
}
static void fd_notice(int fd, void *opaque) { (void)fd; (void)opaque; }
static void notify(void *opaque) { (void)opaque; }

static int add_poll(int fd, int events, void *opaque) {
  (void)opaque;
  if (poll_count == poll_capacity) {
    size_t capacity = poll_capacity ? poll_capacity * 2 : 32;
    Assert(capacity <= INT_MAX, "libslirp poll table too large");
    struct pollfd *next = realloc(pollfds, capacity * sizeof(*next));
    Assert(next, "libslirp poll allocation failed");
    pollfds = next;
    poll_capacity = capacity;
  }
  short native = 0;
  if (events & SLIRP_POLL_IN) native |= POLLIN;
  if (events & SLIRP_POLL_OUT) native |= POLLOUT;
  if (events & SLIRP_POLL_PRI) native |= POLLPRI;
  pollfds[poll_count] = (struct pollfd){ .fd = fd, .events = native };
  return (int)poll_count++;
}
static int get_revents(int index, void *opaque) {
  (void)opaque;
  Assert(index >= 0 && (size_t)index < poll_count, "bad libslirp poll index");
  short native = pollfds[index].revents;
  int events = 0;
  if (native & POLLIN) events |= SLIRP_POLL_IN;
  if (native & POLLOUT) events |= SLIRP_POLL_OUT;
  if (native & POLLPRI) events |= SLIRP_POLL_PRI;
  if (native & (POLLERR | POLLNVAL)) events |= SLIRP_POLL_ERR;
  if (native & POLLHUP) events |= SLIRP_POLL_HUP;
  return events;
}
static void cleanup(void) {
  if (stack) { slirp_cleanup(stack); stack = NULL; }
  free(pollfds);
  pollfds = NULL;
}
void net_user_init(NetUserReceive receive) {
  Assert(requested || ssh_port == 0, "--ssh-port requires --net-user");
  if (!requested) return;
  // A remote TCP close is an I/O error, never a reason to terminate the VM.
  signal(SIGPIPE, SIG_IGN);
  receive_frame = receive;
  SlirpConfig config = {
    .version = 4, .in_enabled = true, .in6_enabled = false,
    .vhostname = "nemu", .if_mtu = 1500, .if_mru = 1500,
    .disable_host_loopback = true, .enable_emu = false,
  };
  inet_pton(AF_INET, "10.0.2.0", &config.vnetwork);
  inet_pton(AF_INET, "255.255.255.0", &config.vnetmask);
  inet_pton(AF_INET, "10.0.2.2", &config.vhost);
  inet_pton(AF_INET, "10.0.2.15", &config.vdhcp_start);
  inet_pton(AF_INET, "10.0.2.3", &config.vnameserver);
  // libslirp retains the callback table.
  static const SlirpCb callbacks = {
    .send_packet = send_packet, .guest_error = guest_error,
    .clock_get_ns = clock_ns, .timer_new = timer_new,
    .timer_free = timer_free, .timer_mod = timer_mod,
    .register_poll_fd = fd_notice, .unregister_poll_fd = fd_notice,
    .notify = notify,
  };
  stack = slirp_new(&config, &callbacks, NULL);
  Assert(stack, "libslirp initialization failed");
  atexit(cleanup);
  if (ssh_port) {
    struct in_addr host;
    inet_pton(AF_INET, "127.0.0.1", &host);
    int rc = slirp_add_hostfwd(stack, 0, host, ssh_port, config.vdhcp_start, 22);
    Assert(rc == 0, "cannot bind SSH forward on 127.0.0.1:%u", ssh_port);
  }
  Log("virtio-net: libslirp %s IPv4 NAT, DHCP/DNS enabled; SSH localhost port=%u",
      slirp_version_string(), ssh_port);
}
void net_user_input(const uint8_t *frame, uint32_t size) {
  Assert(stack && size <= INT_MAX, "invalid libslirp input");
  slirp_input(stack, frame, (int)size);
}
void net_user_poll(void) {
  if (!stack) return;
  uint64_t now = get_time();
  // Nonblocking host I/O at 1 kHz; do not poll sockets every 512 instructions.
  if (now - last_poll_us < 1000) return;
  last_poll_us = now;
  for (unsigned fired = 0; fired < 1024; fired++) {
    NetTimer *due = timers;
    while (due && (due->expires_ms < 0 || due->expires_ms > (int64_t)(now / 1000)))
      due = due->next;
    if (!due) break;
    due->expires_ms = -1;
    due->callback(due->opaque); // Callback may delete or reschedule any timer.
  }
  poll_count = 0;
  uint32_t timeout = 0;
  slirp_pollfds_fill(stack, &timeout, add_poll, NULL);
  int rc = poll(pollfds, poll_count, 0);
  slirp_pollfds_poll(stack, rc < 0, get_revents, NULL);
}
