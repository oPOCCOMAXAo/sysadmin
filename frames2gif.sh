#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-frames}"
DIR="${DIR%/}"

if [ ! -d "$DIR" ]; then
    echo "Error: directory '$DIR' not found" >&2
    exit 1
fi

# Find smallest dimensions across all images
MIN_W=999999
MIN_H=999999
for img in "$DIR"/*.png "$DIR"/*.jpg "$DIR"/*.jpeg; do
    [ -f "$img" ] || continue
    dims=$(identify -format '%w %h' "$img")
    w=${dims%% *}
    h=${dims##* }
    if [ "$w" -lt "$MIN_W" ]; then
        MIN_W=$w
        MIN_H=$h
    fi
done

if [ "$MIN_W" -eq 999999 ]; then
    echo "Error: no images found in '$DIR'" >&2
    exit 1
fi

echo "Smallest dimensions: ${MIN_W}x${MIN_H}"

# Generate concat file list (sorted alphabetically)
FILELIST=$(mktemp)
trap 'rm -f "$FILELIST"' EXIT

ABS_DIR="$(cd "$DIR" && pwd)"
{
    for img in "$DIR"/*.png "$DIR"/*.jpg "$DIR"/*.jpeg; do
        [ -f "$img" ] || continue
        echo "${ABS_DIR}/$(basename "$img")"
    done | sort | while read -r path; do
        echo "file '$path'"
        case "$path" in
            *fast*) echo "duration 0.1" ;;
            *)      echo "duration 0.5" ;;
        esac
    done
} > "$FILELIST"

FRAME_COUNT=$(grep -c "^file " "$FILELIST")
echo "Frames: $FRAME_COUNT"

OUTPUT="${DIR}/$(basename "$DIR").gif"

ffmpeg -y -f concat -safe 0 -i "$FILELIST" \
    -vf "scale=${MIN_W}:${MIN_H}:force_original_aspect_ratio=disable,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    -r 10 \
    "$OUTPUT"

echo "Created: $OUTPUT"
