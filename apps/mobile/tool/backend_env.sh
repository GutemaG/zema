#!/usr/bin/env bash
# Writes config/backend.local.json for running the app against the local
# backend (npx supabase start in backend/):
#
#   tool/backend_env.sh
#   flutter run --dart-define-from-file=config/backend.local.json
#
# Only the public anon key is written; the file is gitignored.
# Pass a URL to override the emulator default, e.g. your computer's LAN
# address for a real phone: tool/backend_env.sh http://192.168.1.20:54321
set -euo pipefail

app_dir="$(cd "$(dirname "$0")/.." && pwd)"
url="${1:-http://10.0.2.2:54321}"
key="$(cd "$app_dir/../../backend" && npx supabase status -o json 2>/dev/null |
  python3 -c 'import json, sys; print(json.load(sys.stdin)["ANON_KEY"])')" || {
  echo "Local backend not running: start it with 'npx supabase start' in backend/" >&2
  exit 1
}

mkdir -p "$app_dir/config"
printf '{\n  "ZEMA_BACKEND_URL": "%s",\n  "ZEMA_BACKEND_KEY": "%s"\n}\n' "$url" "$key" \
  >"$app_dir/config/backend.local.json"
echo "Wrote config/backend.local.json ($url)"
