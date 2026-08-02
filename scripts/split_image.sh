#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 || "$#" -gt 3 ]]; then
  cat <<'EOF'
Usage: split_image.sh INPUT_IMAGE [MAX_HEIGHT] [OUTPUT_PREFIX]

Splits a tall image into multiple PNG slices with a maximum height.

Arguments:
  INPUT_IMAGE   Path to the source image (PNG, JPG, etc.)
  MAX_HEIGHT    Maximum height for each slice (default: 600)
  OUTPUT_PREFIX Output file prefix (default: source basename without extension + "_part")
EOF
  exit 1
fi

input="$1"
max_height="${2:-600}"
prefix="${3:-$(basename "${input%.*}")_part}"

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg is required." >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo "ffprobe is required." >&2; exit 1; }

IFS=x read -r width height < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$input")
if [[ -z "$width" || -z "$height" ]]; then
  echo "Unable to read image dimensions from '$input'." >&2
  exit 1
fi

slices=$(( (height + max_height - 1) / max_height ))

for ((i=0;i<slices;i++)); do
  y=$(( i * max_height ))
  h=$(( height - y ))
  if [[ h -gt max_height ]]; then
    h=$max_height
  fi
  out=$(printf "%s%02d.png" "$prefix" "$((i+1))")
  ffmpeg -y -loglevel error -i "$input" -vf "crop=${width}:${h}:0:${y}" -frames:v 1 "$out"
  echo "wrote $out ($width x $h at y=$y)"
done
