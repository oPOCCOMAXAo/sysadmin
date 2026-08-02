#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-frames/frames.gif}"

if [ ! -f "$INPUT" ]; then
    echo "Error: file '$INPUT' not found" >&2
    exit 1
fi

command -v ffmpeg >/dev/null || { echo "Error: ffmpeg not found" >&2; exit 1; }

OUTPUT="${INPUT%.gif}.mp4"

ffmpeg -y -i "$INPUT" \
    -vf "scale='trunc(iw/2)*2':'trunc(ih/2)*2'" \
    -c:v libx264 \
	-c:a aac \
	-f mp4 \
    -pix_fmt yuv420p \
    -movflags +faststart \
	-profile:v main \
    "$OUTPUT"

echo "Created: $OUTPUT"
