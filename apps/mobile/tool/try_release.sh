#!/usr/bin/env bash
# Builds the release APK against the hosted backend, installs it on every
# connected Android device and emulator (keeping the app's data), and opens it.
#
# Usage (from apps/mobile):
#   tool/try_release.sh            # build, install, open
#   tool/try_release.sh --no-build # install and open the last build
#   tool/try_release.sh --fresh    # uninstall first: onboarding, empty data
#
# Needs config/backend.prod.local.json and config/google.local.json, and adb.
set -euo pipefail

cd "$(dirname "$0")/.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
command -v "$ADB" >/dev/null || ADB=adb
APK=build/app/outputs/flutter-apk/app-release.apk
APP=com.zemaapp.zema

build=1
fresh=0
for arg in "$@"; do
  case "$arg" in
    --no-build) build=0 ;;
    --fresh) fresh=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [[ $build == 1 ]]; then
  flutter build apk --release \
    --dart-define-from-file=config/backend.prod.local.json \
    --dart-define-from-file=config/google.local.json
fi
[[ -f $APK ]] || { echo "No APK at $APK; run without --no-build." >&2; exit 1; }

devices=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1 }')
if [[ -z $devices ]]; then
  echo "No device or emulator connected. The APK is at $APK"
  exit 0
fi

for d in $devices; do
  echo "== $d"
  if [[ $fresh == 1 ]]; then "$ADB" -s "$d" uninstall "$APP" >/dev/null 2>&1 || true; fi
  "$ADB" -s "$d" install -r "$APK" | tail -1
  "$ADB" -s "$d" shell am force-stop "$APP"
  "$ADB" -s "$d" shell monkey -p "$APP" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
done
echo "Opened Zema. APK: $APK"
