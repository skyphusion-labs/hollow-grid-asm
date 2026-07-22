# Changelog

## v0.1.0

### Security (K3 audit #33, #34)

- Bcrypt secret-phrase login; legacy characters migrate on next login.
- Keeper names require `ADMIN_TOKEN` at login (not name-only).
- Reject duplicate concurrent sessions for the same character name.
