# Admin website

`apps/admin`: moderators sign in with Google and review contributions, fingerprints and
reports, and hide or restore songs. Only accounts with the moderator or admin role get
in; grant it with `backend/scripts/moderator.sh grant <email>`.

## One-time setup

1. **Google Cloud console** → the **web** OAuth client → *Authorized redirect URIs*: add
   `https://iwwhqgkppytoxqlqlogg.supabase.co/auth/v1/callback` (and
   `http://127.0.0.1:54321/auth/v1/callback` for the local backend). The site signs in
   through Supabase's redirect, unlike the app.
2. **Supabase dashboard** → Authentication → Sign In / Providers → Google: the web client
   ID and its secret are filled in.
3. **Supabase dashboard** → Authentication → URL Configuration → *Redirect URLs*: add
   `https://zema-admin.pages.dev/**` and `http://localhost:5555/**`.
4. **Cloudflare**: `npx wrangler login`, then the first `tool/deploy.sh` creates the
   `zema-admin` Pages project (`ZEMA_ADMIN_PROJECT` picks another name; update step 3).

## Deploying

    cd apps/admin && tool/deploy.sh

It builds with `apps/mobile/config/backend.prod.local.json` (URL and anon key only) and
uploads `build/web`. Deploying on push waits for CI on GitHub.

## Running locally

    cd apps/admin
    flutter run -d chrome --web-port 5555 --dart-define-from-file=../mobile/config/backend.local.json

`backend.local.json` points at the emulator's address (`10.0.2.2`); for Chrome use
`http://127.0.0.1:54321` as `ZEMA_BACKEND_URL`.
