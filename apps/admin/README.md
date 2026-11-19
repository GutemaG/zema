# admin

The website moderators use to review contributions and reports and to hide songs
(intent 008). Flutter web, sharing `zema_core` and `zema_data` with the app; every
moderator action is checked by the backend.

    flutter run -d chrome --web-port 5555 \
      --dart-define-from-file=../mobile/config/backend.local.json
    flutter test
    tool/deploy.sh          # hosted build to Cloudflare Pages

Setup and deploying: [docs/admin-website.md](../../docs/admin-website.md).
