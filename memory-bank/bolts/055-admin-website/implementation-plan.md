# Plan: 055-admin-website

- `flutter create --platforms web --empty apps/admin`; workspace member; Riverpod, `zema_core`, `zema_data`, `web`.
- Sign-in on the web through Supabase's Google redirect (PKCE), added to `SupabaseAuthRepository` (`googleRedirectUrl`, `completeRedirectSignIn`, `redirectStorage`), so the queue and profile repositories are reused unchanged.
- Role from `SupabaseProfileRepository.profile()`; the server still checks every call.
- Shell: rail ≥ 720 px, bottom bar below; page bodies filled by bolts 056–057.
- Deploy: `tool/deploy.sh` (`wrangler pages deploy`), setup in `docs/admin-website.md`.
