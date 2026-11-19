# Implementation: 055-admin-website

- `packages/zema_data`: redirect sign-in on `SupabaseAuthRepository`; exports `GotrueAsyncStorage`.
- `apps/admin/lib/src/`: `config.dart` (dart-defines as in the app), `session.dart` (`AdminAuth`, `SessionNotifier`: code or error in the URL → sign in or show why, cleans the address; else restore; then the role), `browser.dart` (address, `localStorage` for the session and the PKCE verifier; web only, set in `main.dart`), `theme.dart` (Night Vigil dark), `strings.dart`, `app.dart` (gate, sign-in, Not a moderator, shell).
- Root `pubspec.yaml` lists `apps/admin`; local `config.toml` allows `http://localhost:5555/**`.
- Owner to do once: Google redirect URI, Supabase redirect URL, `wrangler login` (docs/admin-website.md).
