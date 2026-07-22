#ifndef HG_AUTH_H
#define HG_AUTH_H

#include <stddef.h>

/* Keeper login token (ADMIN_TOKEN env). Returns 1 when token matches. */
int hg_auth_verify_admin_token(const char *token);

/* Secret phrase length gate (8..128). */
int hg_auth_phrase_ok(const char *phrase);

/* bcrypt hash into out (>=72 bytes). Returns 0 on success. */
int hg_auth_hash_passphrase(const char *phrase, char *out, size_t out_len);

/* Verify phrase against stored bcrypt hash. Returns 1 on match. */
int hg_auth_verify_passphrase(const char *phrase, const char *hash);

#endif /* HG_AUTH_H */
