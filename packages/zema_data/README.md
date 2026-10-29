# zema_data

Zema's backend access: `SupabaseCatalogRepository`, the Supabase implementation of
`zema_core`'s `CatalogRepository`. Pure Dart with no `dart:io`, so the app, the admin
website and tools can all use it. Storage on the phone (Drift) is the app's job; this
package only talks to the network.

| Call | Backend function | Returns |
|------|------------------|---------|
| `index()` | `song_index` | Every approved song (no lyrics), with `version` and `synced` |
| `song(id)` | `get_song` | The song with its recordings and timings, or null |
| `search(query)` | `search_songs` | Songs by title or lyric line, best first |
| `report(...)` | `submit_report` | Nothing; 5 per install per day |

Every request gives up after 10 s. Errors are always `ZemaFailure`s:
`NetworkFailure` (offline, timeout, server down), `RateLimitFailure`, `BackendFailure`
(refused key, rejected input) or `LyricsFormatFailure` (malformed answer).

The catalog stays anonymous (the anon key only), even when the user is signed in.

## Accounts

`SupabaseAuthRepository` signs in with a Google ID token (`signInWithIdToken`) and
keeps the session in a `SessionStore` (secure storage in the app; `MemorySessionStore`
in tests). `restore()` signs the saved user in at once and checks the session in the
background (`confirmed`):

- **Refused by the server** (revoked, or the account was deleted): it is cleared, and
  `userChanges` gives null.
- **Server out of reach**: the user stays signed in, and the check runs again before
  the next call.

`SupabaseProfileRepository` reads the user's `profiles` row and `user_roles`, and
renames. It validates the name first (`validateDisplayName`), and the server's check
becomes a `ValidationFailure`. Calls as the user go through `SupabaseAuthRepository.run`,
which turns a refused session into `AuthFailure`.

## Tests

```text
cd packages/zema_data && dart test
```

The unit tests need nothing. The tests tagged `backend` run against the local backend
(`npx supabase start` in `backend/`) and are skipped, with a message, when it isn't
running; they read the key from `npx supabase status`.
