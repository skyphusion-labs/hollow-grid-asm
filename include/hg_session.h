#ifndef HG_SESSION_H
#define HG_SESSION_H

#include <stddef.h>
#include <stdint.h>

/* Keep in lockstep with include/state.inc */
#define HG_SESSION_STATE 0
#define HG_SESSION_NAME 8
#define HG_SESSION_RACE 48
#define HG_SESSION_ROOM 64
#define HG_SESSION_HP 72
#define HG_SESSION_MAX_HP 80
#define HG_SESSION_LEVEL 88
#define HG_SESSION_XP 96
#define HG_SESSION_GOLD 104
#define HG_SESSION_MORALITY 112
#define HG_SESSION_ADDICTION 120
#define HG_SESSION_ASHSWORN 128
#define HG_SESSION_STRAYED 136
#define HG_SESSION_REDEEMED 144
#define HG_SESSION_RESISTED 152
#define HG_SESSION_POISONED 160
#define HG_SESSION_FACTION 168
#define HG_SESSION_POSITION 184
#define HG_SESSION_TITLE 200
#define HG_SESSION_EQ_WEAPON 248
#define HG_SESSION_EQ_HEAD 264
#define HG_SESSION_EQ_BODY 280
#define HG_SESSION_EQ_HANDS 296
#define HG_SESSION_EQ_FEET 312
#define HG_SESSION_INV_COUNT 328
#define HG_SESSION_INVENTORY 336
#define HG_SESSION_INV_SLOTS 16
#define HG_SESSION_INV_SLOT_SIZE 16
#define HG_SESSION_TARGET 592
#define HG_SESSION_IN_COMBAT 600
#define HG_SESSION_TRAIT_READY 608
#define HG_SESSION_TREAT_READY 616
#define HG_SESSION_REPLY_TO 624
#define HG_SESSION_MKT_RESOLVED 664
#define HG_SESSION_LAST_GRIDCAST_ID 672
#define HG_SESSION_LAST_FREED 680
#define HG_SESSION_WSI 720
#define HG_SESSION_LAST_TICK 728
#define HG_SESSION_OUT_LEN 736
#define HG_SESSION_CLOSE 744
#define HG_SESSION_OUT 752
#define HG_SESSION_OUT_CAP 16384
#define HG_SESSION_RX_LEN 17136 /* assembled-message length, -1 = overflowed */
#define HG_SESSION_RX 17144     /* WS fragment reassembly buffer */
#define HG_SESSION_RX_CAP 256
#define HG_SESSION_SECRET_HASH 17400
#define HG_SESSION_KEEPER_AUTHED 17472
#define HG_SESSION_PASS_MODE 17480
#define HG_SESSION_SIZE 17488

#define HG_MAX_SESSIONS 32

static inline int64_t hg_s_i64(const void *s, size_t off) {
  return *(const int64_t *)((const unsigned char *)s + off);
}

static inline void hg_s_set_i64(void *s, size_t off, int64_t v) {
  *(int64_t *)((unsigned char *)s + off) = v;
}

static inline const char *hg_s_str(const void *s, size_t off) {
  return (const char *)((const unsigned char *)s + off);
}

static inline char *hg_s_str_mut(void *s, size_t off) {
  return (char *)((unsigned char *)s + off);
}

#endif /* HG_SESSION_H */
