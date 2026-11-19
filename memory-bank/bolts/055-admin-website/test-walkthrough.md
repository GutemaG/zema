# Tests: 055-admin-website

- `packages/zema_data/test/supabase_auth_repository_test.dart`: the Google URL (provider, redirect, code challenge, verifier kept), the code exchange (pkce grant, session saved), a refused code → `AuthFailure`. 72 zema_data tests pass.
- `apps/admin/test/session_gate_test.dart`, 8 widget tests: no backend; Sign in → Google; back with a code → pages and clean address; not a moderator → message and sign out; refused code; error in the URL; saved session; narrow layout.
- `flutter build web` with the hosted config builds; `flutter analyze` clean in admin and mobile.
