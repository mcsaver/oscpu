#ifndef NEMU_NET_USER_H
#define NEMU_NET_USER_H
#include <stdbool.h>
#include <stdint.h>
typedef bool (*NetUserReceive)(const uint8_t *, uint32_t);
#ifdef CONFIG_NET_SLIRP
void net_user_request(void);
void net_user_set_ssh_port(const char *port);
bool net_user_requested(void);
bool net_user_enabled(void);
unsigned net_user_ssh_port(void);
void net_user_init(NetUserReceive receive);
void net_user_input(const uint8_t *frame, uint32_t size);
void net_user_poll(void);
#else
static inline bool net_user_requested(void) { return false; }
static inline bool net_user_enabled(void) { return false; }
static inline unsigned net_user_ssh_port(void) { return 0; }
static inline void net_user_init(NetUserReceive receive) { (void)receive; }
static inline void net_user_input(const uint8_t *frame, uint32_t size) { (void)frame; (void)size; }
static inline void net_user_poll(void) {}
#endif
#endif
