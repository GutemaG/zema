---
id: 002-google-auth-config
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
status: complete
priority: must
created: '2026-10-29T19:05:45Z'
assigned_bolt: 029-accounts-backend
implemented: true
---

# Story: 002-google-auth-config

## User Story

**As a** developer
**I want** Google sign-in set up in the local backend from environment variables, with a setup guide
**So that** sign-in can be switched on without committing any secret

## Acceptance Criteria

- [ ] **Given** `config.toml`, **When** read, **Then** `[auth.external.google]` is enabled with `client_id` and `secret` from `env()`, and `skip_nonce_check` as the guide explains
- [ ] **Given** no Google env variables set, **When** `supabase start` runs, **Then** the backend starts as before
- [ ] **Given** `docs/google-sign-in-setup.md`, **When** followed, **Then** it explains the Google Cloud project, the Android client (package + debug and release SHA-1), the iOS client and URL scheme, the web client for Supabase, and where each ID goes (local config, env)
- [ ] **Given** the repo, **When** scanned, **Then** no client secret or service key is present

## Technical Notes

- `supabase/.env` is gitignored. The app reads `googleWebClientId` and `googleIosClientId` from `config/*.local.json`.

## Dependencies

### Requires
- None

### Enables
- 003-google-sign-in (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Client IDs added later | No code change; only local config and env |

## Out of Scope

- Creating the Google Cloud project (the owner does it)
