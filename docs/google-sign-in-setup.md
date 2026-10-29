# Google sign-in setup

Zema's sign-in is Google only (intent 005). The app uses the native Google account
picker. It gets a Google ID token and passes it to Supabase Auth, which checks it
against the OAuth client IDs it has been given. That needs three OAuth clients in one
Google Cloud project: **web**, **Android** and **iOS**.

None of the values below are committed. They live in two gitignored files:

| File | What goes in it | Read by |
|------|-----------------|---------|
| `backend/supabase/.env` | The client IDs (web, Android, iOS) and the web client's secret | The local Supabase Auth (`config.toml`) |
| `apps/mobile/config/google.local.json` | The web and iOS client IDs | The app, through `--dart-define-from-file` |

Until these exist, the backend still starts and everything else works. The app hides
sign-in, and tests use a fake.

## 1. Project and consent screen

1. In the [Google Cloud console](https://console.cloud.google.com/), create a project,
   for example "Zema".
2. Go to **APIs & Services → OAuth consent screen**.
   - User type: **External**.
   - App name "Zema", with your support email.
   - Scopes: `openid`, `email` and `profile` only.
   - While the app is in testing, add your own Google accounts as test users.

## 2. Web client (used by Supabase)

1. Go to **APIs & Services → Credentials → Create credentials → OAuth client ID**.
2. Choose **Web application**, named "Zema backend".
3. No redirect URIs are needed, because the app signs in with an ID token, not a
   browser redirect.
4. Copy the **client ID** and the **client secret**.

## 3. Android client

The Android client is matched by package name and signing certificate. Make one for
each certificate: debug now, and release when there is one.

1. Get the SHA-1 of the debug key:

   ```text
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   ```

   Or, from `apps/mobile/android/`: `./gradlew signingReport`.
2. **Create credentials → OAuth client ID → Android**:
   - package name `com.zemaapp.zema`
   - the SHA-1 from step 1
3. Copy the **client ID**. The app doesn't use it directly, but Google checks the
   package and the SHA-1 against it, and Supabase must accept its tokens.

## 4. iOS client

1. **Create credentials → OAuth client ID → iOS**, with bundle ID `com.zemaapp.zema`.
2. Copy the **client ID**. The **reversed client ID**
   (`com.googleusercontent.apps.…`) becomes a URL scheme in the iOS app. Bolt 032 adds
   it to `Info.plist` from the config.

## 5. Put the values in place

**Backend**: copy `backend/supabase/.env.example` to `backend/supabase/.env`:

```text
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=<web id>,<android id>,<ios id>
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=<web client secret>
```

The web ID goes first. Supabase accepts an ID token whose audience is any of the
listed IDs.

**App**: create `apps/mobile/config/google.local.json`:

```json
{
  "ZEMA_GOOGLE_WEB_CLIENT_ID": "<web id>",
  "ZEMA_GOOGLE_IOS_CLIENT_ID": "<ios id>"
}
```

The app asks Google for a token meant for the web client, which is what Supabase
checks. On iOS it also needs its own client ID.

## 6. Restart and check

From `backend/`:

```text
npx supabase stop && npx supabase start
```

Then run the app with both config files:

```text
flutter run --dart-define-from-file=config/backend.local.json \
            --dart-define-from-file=config/google.local.json
```

**Without `.env`**, the provider is still listed as enabled, but its client ID is the
unresolved `env(…)` text, so every Google token is refused. That's harmless, but sign-in
only works once `.env` is filled in.

## 7. Never commit these values

- `.env` and `config/*.local.json` are gitignored. Check `git status` before every
  commit.
- The client IDs aren't secret in the strict sense, because they ship inside the app,
  but they're kept out of the repo like the keys.
- The **web client secret** is secret. It's only ever in `backend/supabase/.env`, or in
  the hosted project's dashboard later.
