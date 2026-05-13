{
  pkgs,
  beetsRuntime,
  configSource ? null,
  targetPath ? null,
  args ? [ ],
  preCommands ? [ ],
  postCommands ? [ ],
  mediaPaths,
  dataDir,
  lib,
  ...
}:
let
  inherit (lib) concatStringsSep;
in
{
  # ------------------------------------------------------------------------ #
  # Built-in runner kind implementations
  # ------------------------------------------------------------------------ #
  # Each runner kind is a generated shell-application with the correct beets
  # invocation baked in. No arbitrary custom commands - only these kinds.

  import = pkgs.writeShellApplication {
    name = "beets-runner-import";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      set -euo pipefail

      BEETS_DATA_DIR="${dataDir}"
      export BEETSDIR="$BEETS_DATA_DIR"
      export HOME="$BEETS_DATA_DIR"

      TARGET_PATH="''${1:-${if targetPath != null then targetPath else ""}}"

      if [[ ! -d "$TARGET_PATH" ]]; then
        echo "import-runner: target path does not exist: $TARGET_PATH"
        exit 1
      fi

      mkdir -p "$BEETS_DATA_DIR/state"
      mkdir -p "$BEETS_DATA_DIR/logs"

      CONFIG="''${BEETS_CONFIG_SOURCE:?BEETS_CONFIG_SOURCE must be set}"

      TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
      RUNNER_LOG_FILE="$BEETS_DATA_DIR/logs/$TIMESTAMP-runner.log"

      exec > >(tee -a "$RUNNER_LOG_FILE") 2>&1

      # --- Pre-check: skip if no media files in target ---
      # Avoids running the full import pipeline on an empty directory.
      has_media_files() {
        [[ -n "$(find "$TARGET_PATH" -type f \( \
          -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' \
          -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' \
          -o -iname '*.wav' -o -iname '*.aiff' -o -iname '*.aif' \
          -o -iname '*.wma' -o -iname '*.wmv' \
        \) -print -quit 2>/dev/null)" ]]
      }
      if ! has_media_files; then
        echo "import-runner: no media files found in $TARGET_PATH — nothing to import"
        exit 0
      fi
      echo "import-runner: media files detected, proceeding with import..."

      ${concatStringsSep "\n" preCommands}

      # --- Transfer safety: skip if .tmp lock files are present ---
      SETTLE_DELAY_SEC="''${BEETS_SETTLE_SECONDS:-10}"

      has_tmp_lock() {
        [[ -n "$(find "$TARGET_PATH" -type f -name '*.tmp' -print -quit)" ]]
      }

      if has_tmp_lock; then
        echo "import-runner: skipping because .tmp transfer files are present in $TARGET_PATH"
        exit 0
      fi

      if (( SETTLE_DELAY_SEC > 0 )); then
        sleep "$SETTLE_DELAY_SEC"
        if has_tmp_lock; then
          echo "import-runner: skipping because .tmp transfer files remain after settle delay"
          exit 0
        fi
      fi

      # --- Headless import ---
      beet -c "$CONFIG" import -q -C "$TARGET_PATH"

      ${concatStringsSep "\n" postCommands}

      # --- Demote leftovers to quarantine/untagged ---
      echo "import-runner: checking for leftover files in $TARGET_PATH..."
      leftover_count=0
      find "$TARGET_PATH" -type f \( \
        -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' \
        -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' \
        -o -iname '*.wav' -o -iname '*.aiff' \
      \) -print0 | while IFS= read -r -d $'\0' src; do
        rel="''${src#"$TARGET_PATH"/}"
        dest="${mediaPaths.untaggedDir}/$rel"
        mkdir -p "$(dirname "$dest")"
        if mv "$src" "$dest"; then
          leftover_count=$(( leftover_count + 1 ))
          echo "import-runner: demoted $src -> $dest"
        fi
      done
      echo "import-runner: demoted $leftover_count leftover files to ${mediaPaths.untaggedDir}"

      # --- Post-cleanup: tidy stale artifacts ---
      echo "import-runner: running post-cleanup..."
      # Remove empty directories left behind in the target path.
      find "$TARGET_PATH" -mindepth 1 -type d -empty -delete 2>/dev/null || true
      # Remove stale .tmp transfer artifacts older than 1 hour.
      find "$TARGET_PATH" -type f -name '*.tmp' -mmin +60 -delete 2>/dev/null || true
      # Purge runner logs older than 30 days.
      find "$BEETS_DATA_DIR/logs" -type f -name '*-runner.log' -mtime +30 -delete 2>/dev/null || true
      echo "import-runner: post-cleanup complete"
    '';
  };

  quarantine-interactive = pkgs.writeShellApplication {
    name = "beets-runner-quarantine-interactive";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
      pkgs.chromaprint
    ];
    text = ''
      set -euo pipefail

      BEETS_DATA_DIR="${dataDir}"
      export BEETSDIR="$BEETS_DATA_DIR"
      export HOME="$BEETS_DATA_DIR"

      mkdir -p "$BEETS_DATA_DIR/state"
      TARGET="''${1:-${if targetPath != null then targetPath else ""}}"

      CONFIG="''${BEETS_CONFIG_SOURCE:?BEETS_CONFIG_SOURCE must be set}"

      ${concatStringsSep "\n" preCommands}

      exec beet -c "$CONFIG" import "$TARGET"

      ${concatStringsSep "\n" postCommands}
    '';
  };

  reconcile = pkgs.writeShellApplication {
    name = "beets-runner-reconcile";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
      pkgs.ffmpeg
    ];
    text = ''
      set -euo pipefail

      BEETS_DATA_DIR="${dataDir}"
      export BEETSDIR="$BEETS_DATA_DIR"
      export HOME="$BEETS_DATA_DIR"
      mkdir -p "$BEETS_DATA_DIR/state"

      CONFIG="''${BEETS_CONFIG_SOURCE:?BEETS_CONFIG_SOURCE must be set}"

      ${concatStringsSep "\n" preCommands}

      echo "=== beet update (reconcile library with filesystem) ==="
      beet -c "$CONFIG" update -a
      echo "=== beet convert (lossless -> AIFF, auto-accept) ==="
      beet -c "$CONFIG" convert --yes
      echo "=== beet duplicates (detect duplicate albums) ==="
      beet -c "$CONFIG" duplicates -a
      echo "=== beet move (reorganize files to match path templates) ==="
      beet -c "$CONFIG" move

      ${concatStringsSep "\n" postCommands}
    '';
  };

  # Note: standalone beets-convert runner removed.
  # Pre-import conversion is now handled by ffmpeg-preprocess (pure ffmpeg, no beets).
  # In-library conversion is bundled into the reconcile runner (beet convert step).

  duplicates = pkgs.writeShellApplication {
    name = "beets-runner-duplicates";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      BEETS_DATA_DIR="${dataDir}"
      export BEETSDIR="$BEETS_DATA_DIR"
      export HOME="$BEETS_DATA_DIR"
      mkdir -p "$BEETS_DATA_DIR/state"

      CONFIG="''${BEETS_CONFIG_SOURCE:?BEETS_CONFIG_SOURCE must be set}"

      ${concatStringsSep "\n" preCommands}

      exec beet -c "$CONFIG" duplicates -a "$@"
    '';
  };

  permission-reconcile = pkgs.writeShellApplication {
    name = "beets-runner-permission-reconcile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.acl
    ];
    text = ''
      set -euo pipefail

      ${concatStringsSep "\n" preCommands}

      fixup() {
        local dir="$1"
        [[ -d "$dir" ]] || return 0
        find "$dir" -type d -exec chgrp music-ingest {} +
        find "$dir" -type d -exec chmod 2775 {} +
        find "$dir" -type f -exec chgrp music-ingest {} +
        find "$dir" -type f -exec chmod 0664 {} +
        setfacl -R -m g:music-ingest:rwx "$dir"
        find "$dir" -type d -exec setfacl -m d:g:music-ingest:rwX {} +
        setfacl -R -m g:media:r-X "$dir"
        find "$dir" -type d -exec setfacl -m d:g:media:r-X {} +
      }
      fixup "${mediaPaths.libraryDir}"
      fixup "${mediaPaths.quarantineDir}"
      fixup "${mediaPaths.untaggedDir}"
      fixup "${mediaPaths.approvedDir}"

      ${concatStringsSep "\n" postCommands}
    '';
  };
}
