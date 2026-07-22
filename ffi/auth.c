#define _XOPEN_SOURCE 700
#include "hg_auth.h"

#include <crypt.h>
#include <ctype.h>
#include <openssl/rand.h>
#include <stdio.h>
#include <string.h>

static int constant_time_eq(const char *a, const char *b, size_t n) {
  unsigned char diff = 0;
  for (size_t i = 0; i < n; i++) {
    diff |= (unsigned char)(a[i] ^ b[i]);
  }
  return diff == 0;
}

int hg_auth_require_admin_token(void) {
  const char *expected = getenv("ADMIN_TOKEN");
  if (expected == NULL || expected[0] == '\0') {
    fprintf(stderr, "FATAL: ADMIN_TOKEN must be set (keeper login requires a non-empty token)\n");
    return -1;
  }
  return 0;
}

int hg_auth_verify_admin_token(const char *token) {
  const char *expected = getenv("ADMIN_TOKEN");
  if (expected == NULL || expected[0] == '\0') {
    return 0;
  }
  if (token == NULL) {
    return 0;
  }
  while (*token != '\0' && isspace((unsigned char)*token)) {
    token++;
  }
  size_t tlen = strlen(token);
  while (tlen > 0 && isspace((unsigned char)token[tlen - 1])) {
    tlen--;
  }
  size_t elen = strlen(expected);
  if (tlen != elen || tlen == 0) {
    return 0;
  }
  return constant_time_eq(token, expected, tlen);
}

int hg_auth_phrase_ok(const char *phrase) {
  if (phrase == NULL) {
    return 0;
  }
  size_t len = strlen(phrase);
  return len >= 8 && len <= 128;
}

static int make_bcrypt_salt(char *out, size_t out_len) {
  unsigned char raw[16];
  if (out_len < 30) {
    return -1;
  }
  if (RAND_bytes(raw, (int)sizeof(raw)) != 1) {
    return -1;
  }
  if (crypt_gensalt_rn("$2b$", 10U, (const char *)raw, (int)sizeof(raw), out,
                       (int)out_len) == NULL) {
    return -1;
  }
  return 0;
}

int hg_auth_hash_passphrase(const char *phrase, char *out, size_t out_len) {
  struct crypt_data data;
  char salt[64];

  if (!hg_auth_phrase_ok(phrase) || out == NULL || out_len < 72) {
    return -1;
  }
  memset(&data, 0, sizeof(data));
  if (make_bcrypt_salt(salt, sizeof(salt)) != 0) {
    return -1;
  }
  char *hash = crypt_r(phrase, salt, &data);
  if (hash == NULL || hash[0] == '*') {
    return -1;
  }
  if (strlen(hash) >= out_len) {
    return -1;
  }
  strcpy(out, hash);
  return 0;
}

int hg_auth_verify_passphrase(const char *phrase, const char *hash) {
  struct crypt_data data;

  if (!hg_auth_phrase_ok(phrase) || hash == NULL || hash[0] == '\0') {
    return 0;
  }
  if (strncmp(hash, "$2", 2) != 0) {
    return 0;
  }
  memset(&data, 0, sizeof(data));
  char *got = crypt_r(phrase, hash, &data);
  if (got == NULL || got[0] == '*') {
    return 0;
  }
  return constant_time_eq(got, hash, strlen(hash));
}
