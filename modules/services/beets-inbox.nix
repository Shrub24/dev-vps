{ pkgs, ... }:
let
  beetsRuntime = pkgs.python3.withPackages (ps: [
    ps.beets
    ps.requests-oauthlib
    ps.beetcamp
    ps."discogs-client"
  ]);

  beetsConfig = pkgs.writeText "beets-config.yaml" ''
    directory: /srv/media/inbox
    library: /srv/data/beets/state/library.db
    plugins: discogs beatport bandcamp fromfilename
    import:
      write: yes
      copy: no
      move: no
      link: no
      hardlink: no
      quiet: yes
      quiet_fallback: skip
      incremental: no
      incremental_skip_later: no
  '';

  beetsInboxRunner = pkgs.writeShellScriptBin "beets-inbox-runner" ''
    set -euo pipefail

    ROOT_INBOX="/srv/media/inbox"
    TARGET_PATH="''${1:-/srv/media/inbox/slskd}"
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

    mkdir -p /srv/data/beets/state
    mkdir -p /srv/data/beets/reports
    mkdir -p /srv/data/beets/unresolved

    cp ${beetsConfig} /srv/data/beets/config.yaml
    chmod 0640 /srv/data/beets/config.yaml

    TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
    SUMMARY_FILE="/srv/data/beets/reports/$TIMESTAMP-summary.txt"
    UNRESOLVED_FILE="/srv/data/beets/unresolved/$TIMESTAMP-unresolved.txt"
    LOG_FILE="$(mktemp /tmp/beets-inbox-run.XXXXXX.log)"

    mapfile -t CANDIDATES < <(find "$CANONICAL_TARGET" -type f -mmin +2 \
      \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.wav' \) \
      | sort)

    {
      echo "timestamp=$TIMESTAMP"
      echo "target=$CANONICAL_TARGET"
      echo "candidate_count=''${#CANDIDATES[@]}"
      echo "dry_run=''${BEETS_DRY_RUN:-0}"
      echo "config=/srv/data/beets/config.yaml"
      echo "reports_dir=/srv/data/beets/reports"
      echo "unresolved_dir=/srv/data/beets/unresolved"
    } > "$SUMMARY_FILE"

    if (( ''${#CANDIDATES[@]} == 0 )); then
      echo "No eligible files older than 120 seconds." >> "$SUMMARY_FILE"
      : > "$UNRESOLVED_FILE"
      exit 0
    fi

    IMPORT_ARGS=(import -s -C)
    if [[ "''${BEETS_DRY_RUN:-0}" == "1" ]]; then
      IMPORT_ARGS+=( -p )
    fi

    ${beetsRuntime}/bin/beet -c /srv/data/beets/config.yaml "''${IMPORT_ARGS[@]}" "''${CANDIDATES[@]}" 2>&1 | tee -a "$LOG_FILE"

    if rg --ignore-case --line-number 'skip|unmatched|no match|no candidates' "$LOG_FILE" > "$UNRESOLVED_FILE"; then
      echo "unresolved_count=$(wc -l < "$UNRESOLVED_FILE")" >> "$SUMMARY_FILE"
    else
      : > "$UNRESOLVED_FILE"
      echo "unresolved_count=0" >> "$SUMMARY_FILE"
    fi

    echo "beet -c /srv/data/beets/config.yaml import -s -C" >> "$SUMMARY_FILE"
    rm -f "$LOG_FILE"
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
  ];

  systemd.services.beets-inbox-run = {
    description = "Beets inbox-only singleton import worker";
    serviceConfig = {
      Type = "oneshot";
      User = "beets";
      Group = "beets";
      WorkingDirectory = "/srv/data/beets";
      Environment = "BEETSDIR=/srv/data/beets";
      ExecStart = "${beetsInboxRunner}/bin/beets-inbox-runner /srv/media/inbox/slskd";
    };
  };

  systemd.paths.beets-inbox-watch = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathExistsGlob = "/srv/media/inbox/slskd/*";
    pathConfig.Unit = "beets-inbox-run.service";
  };
}
