#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: make_video_review_sheet.sh input.mp4 output.jpg" >&2
  exit 2
fi

input="$1"
output="$2"
workdir="$(mktemp -d /tmp/coachlog-video-review.XXXXXX)"
trap 'rm -rf "$workdir"' EXIT

duration="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$input")"
python3 - "$duration" "$workdir" <<'PY'
import os, sys
duration = float(sys.argv[1])
workdir = sys.argv[2]
start = min(0.15, max(duration * 0.02, 0))
end = max(duration - 0.15, start)
times = [start, duration * 0.2, duration * 0.4, duration * 0.6, duration * 0.8, end]
with open(os.path.join(workdir, "times.txt"), "w", encoding="utf-8") as fh:
    for i, t in enumerate(times):
        fh.write(f"{i} {t:.3f}\n")
PY

while read -r index timestamp; do
  ffmpeg -y -ss "$timestamp" -i "$input" -frames:v 1 -q:v 2 "$workdir/frame-${index}.jpg" >/dev/null 2>&1
done < "$workdir/times.txt"

ffmpeg -y -pattern_type glob -i "$workdir/frame-*.jpg" -vf "scale=240:240:force_original_aspect_ratio=decrease,pad=240:240:(ow-iw)/2:(oh-ih)/2,tile=3x2" -frames:v 1 "$output" >/dev/null 2>&1
echo "$output"
