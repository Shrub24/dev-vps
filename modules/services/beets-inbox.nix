{ pkgs, ... }:
let
  beetsRuntime = pkgs.python3.withPackages (ps: [
    ps.beets
    ps.requests-oauthlib
    ps.beetcamp
    ps."discogs-client"
  ]);

  beetsConfig = pkgs.writeText "beets-config.yaml" ''
    directory: /srv/media/library
    library: /srv/data/beets/state/library.db
    plugins: discogs beatport bandcamp fromfilename
    import:
      write: yes
      copy: no
      move: no
      link: no
      hardlink: no
      quiet: yes
      quiet_fallback: asis
      incremental: no
      incremental_skip_later: no
  '';

  beetsInboxRunner = pkgs.writeShellScriptBin "beets-inbox-runner" ''
    set -euo pipefail

    ROOT_INBOX="/srv/media/inbox"
    LIBRARY_ROOT="/srv/media/library"
    TARGET_PATH="''${1:-/srv/media/inbox}"
    CANONICAL_TARGET="$(realpath -m "$TARGET_PATH")"

    case "$CANONICAL_TARGET" in
      /srv/media/inbox|/srv/media/inbox/*) ;;
      *)
        echo "Target must stay under /srv/media/inbox"
        exit 1
        ;;
    esac

    if [[ ! -d "$CANONICAL_TARGET" ]]; then
      echo "Target path does not exist: $CANONICAL_TARGET"
      exit 1
    fi

    export BEETSDIR=/srv/data/beets
    export HOME=/srv/data/beets

    mkdir -p "$LIBRARY_ROOT"
    mkdir -p /srv/data/beets/state
    mkdir -p /srv/data/beets/reports
    mkdir -p /srv/data/beets/unresolved

    cp ${beetsConfig} /srv/data/beets/config.yaml
    chmod 0640 /srv/data/beets/config.yaml

    TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
    SUMMARY_FILE="/srv/data/beets/reports/$TIMESTAMP-summary.txt"
    FALLBACK_FILE="/srv/data/beets/reports/$TIMESTAMP-promoted-with-fallback.tsv"
    HARD_FAILURES_FILE="/srv/data/beets/unresolved/$TIMESTAMP-hard-failures.tsv"

    mapfile -d $'\\0' -t CANDIDATES < <(find "$CANONICAL_TARGET" -type f -mmin +2 \
      \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.wav' \) \
      -print0 | sort -z)

    : > "$FALLBACK_FILE"
    : > "$HARD_FAILURES_FILE"

    promoted_count=0
    promoted_with_fallback_count=0
    hard_failures_count=0
    processed_count=0

    {
      echo "timestamp=$TIMESTAMP"
      echo "target=$CANONICAL_TARGET"
      echo "candidate_count=''${#CANDIDATES[@]}"
      echo "processed_count=$processed_count"
      echo "promoted_count=$promoted_count"
      echo "promoted_with_fallback_count=$promoted_with_fallback_count"
      echo "hard_failures_count=$hard_failures_count"
      echo "dry_run=''${BEETS_DRY_RUN:-0}"
      echo "config=/srv/data/beets/config.yaml"
      echo "reports_dir=/srv/data/beets/reports"
      echo "unresolved_dir=/srv/data/beets/unresolved"
      echo "command=beet -c /srv/data/beets/config.yaml import -q -s -C"
    } > "$SUMMARY_FILE"

    if (( ''${#CANDIDATES[@]} == 0 )); then
      echo "No eligible files older than 120 seconds." >> "$SUMMARY_FILE"
      exit 0
    fi

    for file in "''${CANDIDATES[@]}"; do
      processed_count=$((processed_count + 1))

      if [[ "''${BEETS_DRY_RUN:-0}" == "1" ]]; then
        if ! ${beetsRuntime}/bin/beet -c /srv/data/beets/config.yaml import -q -s -C -p "$file" >/dev/null 2>&1; then
          hard_failures_count=$((hard_failures_count + 1))
          printf '%s\t%s\n' "$file" "beet import failed in dry-run mode" >> "$HARD_FAILURES_FILE"
        fi
        continue
      fi

      if ! ${beetsRuntime}/bin/beet -c /srv/data/beets/config.yaml import -q -s -C "$file" >/dev/null 2>&1; then
        hard_failures_count=$((hard_failures_count + 1))
        printf '%s\t%s\n' "$file" "beet import failed" >> "$HARD_FAILURES_FILE"
        continue
      fi

      meta_line="$(${beetsRuntime}/bin/python - "$file" <<'PY'
import pathlib
import re
import sys

from mediafile import MediaFile


def clean(value: object | None) -> str:
    if value is None:
        return ""
    text = str(value).strip()
    if not text:
        return ""
    text = text.replace("/", "-")
    text = re.sub(r"[\x00-\x1f]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


path = pathlib.Path(sys.argv[1])
try:
    mf = MediaFile(path)
except Exception as exc:
    print(f"metadata read failed: {exc}", file=sys.stderr)
    sys.exit(1)

label = clean(getattr(mf, "label", ""))
albumartist = clean(getattr(mf, "albumartist", ""))
artist = clean(getattr(mf, "artist", ""))
album = clean(getattr(mf, "album", ""))
title = clean(getattr(mf, "title", ""))

if label and (not albumartist or albumartist == "Various Artists"):
    top_level = label
    top_source = "label"
elif albumartist:
    top_level = albumartist
    top_source = "albumartist"
elif artist:
    top_level = artist
    top_source = "artist"
else:
    top_level = "Unknown Artist"
    top_source = "unknown"

if album:
    release = album
    release_source = "album"
elif title:
    release = title
    release_source = "title"
else:
    release = clean(path.stem) or "Unknown Release"
    release_source = "stem"

fallback = "1" if top_level == "Unknown Artist" or top_source != "albumartist" or release_source != "album" else "0"
print("\t".join([top_level, release, fallback, top_source, release_source]))
PY
)" || {
        hard_failures_count=$((hard_failures_count + 1))
        printf '%s\t%s\n' "$file" "metadata extraction failed" >> "$HARD_FAILURES_FILE"
        continue
      }

      IFS=$'\t' read -r top_level release fallback_used top_source release_source <<< "$meta_line"
      destination_dir="$LIBRARY_ROOT/$top_level/$release"
      destination_file="$destination_dir/$(basename "$file")"

      if ! mkdir -p "$destination_dir"; then
        hard_failures_count=$((hard_failures_count + 1))
        printf '%s\t%s\n' "$file" "destination directory creation failed" >> "$HARD_FAILURES_FILE"
        continue
      fi

      if [[ -e "$destination_file" ]]; then
        hard_failures_count=$((hard_failures_count + 1))
        printf '%s\t%s\n' "$file" "destination already exists: $destination_file" >> "$HARD_FAILURES_FILE"
        continue
      fi

      if ! mv "$file" "$destination_file"; then
        hard_failures_count=$((hard_failures_count + 1))
        printf '%s\t%s\n' "$file" "file move failed" >> "$HARD_FAILURES_FILE"
        continue
      fi

      promoted_count=$((promoted_count + 1))
      if [[ "$fallback_used" == "1" ]]; then
        promoted_with_fallback_count=$((promoted_with_fallback_count + 1))
        printf '%s\t%s\t%s\t%s\t%s\n' "$file" "$destination_file" "$top_source" "$release_source" "$top_level/$release" >> "$FALLBACK_FILE"
      fi
    done

    {
      echo "processed_count=$processed_count"
      echo "promoted_count=$promoted_count"
      echo "promoted_with_fallback_count=$promoted_with_fallback_count"
      echo "hard_failures_count=$hard_failures_count"
      echo "fallback_report=$FALLBACK_FILE"
      echo "hard_failures_report=$HARD_FAILURES_FILE"
    } >> "$SUMMARY_FILE"
  '';
in
{
  users.groups.beets = { };
  users.users.beets = {
    isSystemUser = true;
    group = "beets";
    home = "/srv/data/beets";
    createHome = false;
    extraGroups = [
      "music-ingest"
      "music-library"
    ];
  };

  environment.systemPackages = [
    beetsRuntime
    beetsInboxRunner
  ];

  systemd.tmpfiles.rules = [
    "d /srv/data/beets 0750 beets beets - -"
    "d /srv/data/beets/state 0750 beets beets - -"
    "d /srv/data/beets/reports 0750 beets beets - -"
    "d /srv/data/beets/unresolved 0750 beets beets - -"
    "d /srv/media/library 2775 syncthing music-library - -"
  ];

  systemd.services.beets-inbox-run = {
    description = "Beets inbox-only singleton import worker";
    serviceConfig = {
      Type = "oneshot";
      User = "beets";
      Group = "beets";
      WorkingDirectory = "/srv/data/beets";
      Environment = "BEETSDIR=/srv/data/beets";
      ExecStart = "${beetsInboxRunner}/bin/beets-inbox-runner /srv/media/inbox";
    };
  };

  systemd.paths.beets-inbox-watch = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathExistsGlob = "/srv/media/inbox/*";
    pathConfig.Unit = "beets-inbox-run.service";
  };

  systemd.timers.beets-inbox-backstop = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Unit = "beets-inbox-run.service";
    };
  };
}
