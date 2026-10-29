#!/usr/bin/env bash
# Generates test audio files and pushes them to a connected Android device or
# emulator, then asks MediaStore to index them.
#
# Usage (from apps/mobile):
#   tool/test_audio.sh            # the standard test set
#   tool/test_audio.sh --bulk N   # also N short tagged files for scan timing
#   tool/test_audio.sh --lyrics   # also audio for the bundled sample lyrics
#   tool/test_audio.sh --clean    # remove everything this script pushed
#
# Needs ffmpeg and adb. Files are generated into build/test_audio (ignored).
set -euo pipefail

cd "$(dirname "$0")/.."
OUT=build/test_audio
ADB="${ADB:-adb}"
DEVICE_ROOT=/sdcard
# Every folder this script writes to, so --clean can remove them.
FOLDERS=("Music/Zema Test" "Music/መዝሙር" "Download/Zema Test" "Telegram/Telegram Audio/Zema Test" "Recordings/Zema Test" "Music/Zema Bulk" "Music/Zema Lyrics")

bulk=0
lyrics=0
case "${1:-}" in
  --bulk) bulk="${2:?--bulk needs a count}" ;;
  --lyrics) lyrics=1 ;;
  --clean)
    for f in "${FOLDERS[@]}"; do "$ADB" shell rm -rf "\"$DEVICE_ROOT/$f\""; done
    "$ADB" shell content call --uri content://media/external/file --method scan_volume --arg external_primary >/dev/null 2>&1 || true
    echo "Removed test audio from the device."
    exit 0
    ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac

rm -rf "$OUT"
mkdir -p "$OUT"

# tone <file> <seconds> <frequency> [ffmpeg -metadata args...]
tone() {
  local file="$1" seconds="$2" freq="$3"
  shift 3
  mkdir -p "$(dirname "$OUT/$file")"
  ffmpeg -loglevel error -y -f lavfi -i "sine=frequency=$freq:duration=$seconds" \
    -ac 2 -ar 44100 -b:a 128k -id3v2_version 3 "$@" "$OUT/$file"
}


# Tagged tracks (Latin and Ethiopic), two albums with track numbers.
tone "Music/Zema Test/01 Kidus Kidus.mp3" 62 440 \
  -metadata title="Kidus Kidus" -metadata artist="Zerfe Kebede" \
  -metadata album="Mezmur Vol. 1" -metadata track=1 -metadata date=2019
tone "Music/Zema Test/02 Amlak.mp3" 75 494 \
  -metadata title="Amlak" -metadata artist="Zerfe Kebede" \
  -metadata album="Mezmur Vol. 1" -metadata track=2 -metadata date=2019
tone "Music/Zema Test/03 Selam.mp3" 48 523 \
  -metadata title="ሰላም ለኪ" -metadata artist="ዘማሪት ዘርፌ ከበደ" \
  -metadata album="Mezmur Vol. 1" -metadata track=3 -metadata date=2019
tone "Music/መዝሙር/ቅዱስ.mp3" 90 587 \
  -metadata title="ቅዱስ ቅዱስ ቅዱስ" -metadata artist="ሊቀ መዘምራን ይልማ ኃይሉ" \
  -metadata album="የቅዱሳን መዝሙር" -metadata track=1 -metadata date=2015
tone "Music/መዝሙር/እግዚአብሔር.mp3" 66 659 \
  -metadata title="እግዚአብሔር ይመስገን" -metadata artist="ሊቀ መዘምራን ይልማ ኃይሉ" \
  -metadata album="የቅዱሳን መዝሙር" -metadata track=2 -metadata date=2015

# Folder variety: downloads and Telegram audio.
tone "Download/Zema Test/Tsome Digua.mp3" 55 698 \
  -metadata title="Tsome Digua" -metadata artist="Tewodros Yosef"
tone "Telegram/Telegram Audio/Zema Test/Tselot.mp3" 40 784 \
  -metadata title="Tselot" -metadata artist="Mahlet Hailu" \
  -metadata album="Telegram Mezmur"

# No tags at all: the title must fall back to the file name.
tone "Download/Zema Test/untagged_mezmur.mp3" 35 880 -map_metadata -1

# A 10 s voice note: must be excluded by the 30 s minimum.
tone "Recordings/Zema Test/Voice note 001.mp3" 10 330 -metadata title="Voice note 001"

for ((i = 1; i <= bulk; i++)); do
  n=$(printf '%04d' "$i")
  tone "Music/Zema Bulk/Bulk $n.mp3" 31 $((200 + i % 600)) \
    -metadata title="Bulk Track $n" -metadata artist="Bulk Artist $((i % 40))" \
    -metadata album="Bulk Album $((i % 80))" -metadata track=$((i % 12 + 1))
done

# Sample lyrics: one file per song in test/fixtures/lyrics (the same songs the local catalog is seeded with), tagged with the song's
# title and artist so the app links them. The pitch changes at every line
# start, so you can hear when the highlight should move.
if ((lyrics)); then
  mkdir -p "$OUT/Music/Zema Lyrics" "$OUT/segments"
  python3 - "$OUT" <<'PY'
import json, re, subprocess, sys
out = sys.argv[1]
index = json.load(open("test/fixtures/lyrics/index.json"))
for song in index["songs"]:
    text = open(f"test/fixtures/lyrics/{song['file']}", encoding="utf-8").read()
    title = re.search(r"^\[ti:(.*)\]$", text, re.M).group(1)
    artist = re.search(r"^\[ar:(.*)\]$", text, re.M).group(1)
    starts = sorted(
        int(m) * 60 + float(s)
        for m, s in re.findall(r"\[(\d+):(\d+(?:\.\d+)?)\]", text)
    )
    total = song["durationMs"] / 1000
    bounds = [0.0] + starts + [total]
    parts = []
    for i, (a, b) in enumerate(zip(bounds, bounds[1:])):
        if b <= a:
            continue
        # Silence-like low hum before the first line, then a new pitch per line.
        freq = 110 if i == 0 else 330 + (i * 70) % 440
        seg = f"{out}/segments/{song['id']}-{i:03d}.wav"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i",
                        f"sine=frequency={freq}:duration={b - a:.3f}", "-ac", "2", "-ar", "44100", seg],
                       check=True)
        parts.append(seg)
    listing = f"{out}/segments/{song['id']}.txt"
    with open(listing, "w") as f:
        f.writelines(f"file '{p.split('/')[-1]}'\n" for p in parts)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", listing,
                    "-b:a", "128k", "-id3v2_version", "3",
                    "-metadata", f"title={title}", "-metadata", f"artist={artist}",
                    "-metadata", "album=Zema Samples",
                    f"{out}/Music/Zema Lyrics/{song['id']}.mp3"], check=True)
PY
  rm -rf "$OUT/segments"
fi

echo "Generated $(find "$OUT" -name '*.mp3' | wc -l | tr -d ' ') files in $OUT"

"$ADB" wait-for-device
(cd "$OUT" && find . -name '*.mp3' -print0) | while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  dir="$DEVICE_ROOT/$(dirname "$rel")"
  "$ADB" shell mkdir -p "\"$dir\"" </dev/null
  "$ADB" push "$OUT/$rel" "$dir/" </dev/null >/dev/null
done

# Ask MediaStore to index the new files.
"$ADB" shell content call --uri content://media/external/file \
  --method scan_volume --arg external_primary >/dev/null 2>&1 || true
echo "Pushed to the device and requested a media scan."
