#!/usr/bin/env bash
set -euo pipefail

STAGING="${1:?usage: ffmpeg-preprocess <staging-dir>}"
echo "ffmpeg-preprocess: scanning $STAGING for lossless audio..."
count=0

find "$STAGING" -type f \( -iname '*.flac' -o -iname '*.wav' \) -print0 |
  while IFS= read -r -d $'\0' src; do
    dest="${src%.*}.aiff"
    if [[ -f "$dest" ]]; then
      continue
    fi
    if ffmpeg -nostdin -n -i "$src" -c:a pcm_s16be "$dest" 2>/dev/null; then
      echo "ffmpeg-preprocess: $src -> $dest"
      (( ++count )) || true
    else
      echo "ffmpeg-preprocess: FAILED $src" >&2
    fi
  done

echo "ffmpeg-preprocess: done ($count files processed)"
