#!/usr/bin/env bash
set -euo pipefail

mkdir -p frames

BASE_W=666
BASE_H=2083
BASE_TOP=774
BASE_CROP_H=1108

for f in warera/*.png; do
  name=$(basename "$f")
  dims=$(identify -format '%w %h' "$f")
  w=$(echo "$dims" | cut -d' ' -f1)
  h=$(echo "$dims" | cut -d' ' -f2)

  scale=$(echo "scale=6; $w / $BASE_W" | bc)
  top=$(echo "scale=0; ($BASE_TOP * $scale) / 1" | bc)
  crop_h=$(echo "scale=0; ($BASE_CROP_H * $scale) / 1" | bc)

  echo "Cropping $name (${w}x${h}) -> top=${top}, height=${crop_h}..."
  ffmpeg -y -i "$f" -vf "crop=${w}:${crop_h}:0:${top}" -frames:v 1 "frames/$name" 2>/dev/null || true
done

count=$(find frames -name '*.png' | wc -l)
echo "Done. $count files cropped into frames/"
