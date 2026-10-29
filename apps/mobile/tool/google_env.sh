#!/usr/bin/env bash
# Writes ios/Flutter/Google.local.xcconfig from config/google.local.json, so
# the iOS app gets the URL scheme Google sign-in returns to (the reversed iOS
# client ID). Run after creating or changing config/google.local.json:
#
#   tool/google_env.sh
#
# Both files are gitignored; see docs/google-sign-in-setup.md.
set -euo pipefail

app_dir="$(cd "$(dirname "$0")/.." && pwd)"
config="$app_dir/config/google.local.json"
[ -f "$config" ] || {
  echo "No config/google.local.json: see docs/google-sign-in-setup.md" >&2
  exit 1
}

scheme="$(python3 -c '
import json, sys
ios = json.load(open(sys.argv[1])).get("ZEMA_GOOGLE_IOS_CLIENT_ID", "")
suffix = ".apps.googleusercontent.com"
if ios and not ios.endswith(suffix):
    sys.exit("ZEMA_GOOGLE_IOS_CLIENT_ID should end in " + suffix)
print("com.googleusercontent.apps." + ios[: -len(suffix)] if ios else "")
' "$config")"

printf '// Written by tool/google_env.sh. Gitignored.\nGOOGLE_REVERSED_CLIENT_ID = %s\n' \
  "$scheme" >"$app_dir/ios/Flutter/Google.local.xcconfig"
echo "Wrote ios/Flutter/Google.local.xcconfig${scheme:+ ($scheme)}"
