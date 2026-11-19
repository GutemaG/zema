#!/usr/bin/env bash
# Builds the admin website against the hosted backend and uploads it to
# Cloudflare Pages. Run `npx wrangler login` once first. See docs/admin-website.md.
set -euo pipefail

cd "$(dirname "$0")/.."
config=../mobile/config/backend.prod.local.json
project=${ZEMA_ADMIN_PROJECT:-zema-admin}

if [[ ! -f $config ]]; then
  echo "Missing $config (the hosted URL and anon key)." >&2
  exit 1
fi

flutter build web --release --dart-define-from-file="$config"
npx wrangler pages deploy build/web --project-name "$project" --branch main
