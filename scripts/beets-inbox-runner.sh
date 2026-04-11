set -euo pipefail

ROOT_INBOX="${BEETS_ROOT_INBOX:-/srv/media/inbox}"
APPROVED_ROOT="${BEETS_APPROVED_ROOT:-/srv/media/quarantine/approved}"
UNTAGGED_ROOT="${BEETS_UNTAGGED_ROOT:-/srv/media/quarantine/untagged}"
BEETS_DATA_DIR="${BEETS_DATA_DIR:-/srv/data/beets}"
TARGET_PATH="${1:-$ROOT_INBOX}"
CANONICAL_TARGET="$(realpath -m "$TARGET_PATH")"
SETTLE_SECONDS="${BEETS_SETTLE_SECONDS:-10}"
DEMOTE_LEFTOVERS=0

case "$CANONICAL_TARGET" in
"$ROOT_INBOX" | "$ROOT_INBOX"/*)
	DEMOTE_LEFTOVERS=1
	;;
"$APPROVED_ROOT" | "$APPROVED_ROOT"/*)
	DEMOTE_LEFTOVERS=0
	;;
*)
	echo "Target must stay under $ROOT_INBOX or $APPROVED_ROOT"
	exit 1
	;;
esac

if [[ ! -d "$CANONICAL_TARGET" ]]; then
	echo "Target path does not exist: $CANONICAL_TARGET"
	exit 1
fi

export BEETSDIR="$BEETS_DATA_DIR"
export HOME="$BEETS_DATA_DIR"

mkdir -p "$UNTAGGED_ROOT"
mkdir -p "$BEETS_DATA_DIR/state"
mkdir -p "$BEETS_DATA_DIR/logs"

cp "${BEETS_CONFIG_SOURCE:?missing BEETS_CONFIG_SOURCE}" "$BEETS_DATA_DIR/config.yaml"
chmod 0640 "$BEETS_DATA_DIR/config.yaml"

TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
IMPORT_LOG_FILE="$BEETS_DATA_DIR/logs/$TIMESTAMP-import.log"
RUNNER_LOG_FILE="$BEETS_DATA_DIR/logs/$TIMESTAMP-runner.log"

exec > >(tee -a "$RUNNER_LOG_FILE") 2>&1

if ! [[ "$SETTLE_SECONDS" =~ ^[0-9]+$ ]]; then
	echo "BEETS_SETTLE_SECONDS must be a non-negative integer"
	exit 1
fi

has_tmp_lock() {
	[[ -n "$(find "$CANONICAL_TARGET" -type f -name '*.tmp' -print -quit)" ]]
}

if has_tmp_lock; then
	echo "beets-inbox-runner: skipping run because .tmp transfer files are present"
	exit 0
fi

if ((SETTLE_SECONDS > 0)); then
	sleep "$SETTLE_SECONDS"
fi

if has_tmp_lock; then
	echo "beets-inbox-runner: skipping run because .tmp transfer files remain after settle delay"
	exit 0
fi

mapfile -d $'\0' -t CANDIDATES < <(find "$CANONICAL_TARGET" -type f \
	\( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.wav' \) \
	-print0 | sort -z)

if ((${#CANDIDATES[@]} == 0)); then
	echo "beets-inbox-runner: no eligible audio files found under target"
	exit 0
fi

echo "beets-inbox-runner: candidates=${#CANDIDATES[@]}"

demote_and_record_unresolved() {
	local file="$1"
	local relative_path
	local destination_file
	local destination_dir

	if [[ "$file" == "$ROOT_INBOX/"* ]]; then
		relative_path="${file#"$ROOT_INBOX"/}"
	else
		relative_path="$(basename "$file")"
	fi

	destination_file="$UNTAGGED_ROOT/$relative_path"
	destination_dir="$(dirname "$destination_file")"

	if ! mkdir -p "$destination_dir"; then
		echo "beets-inbox-runner: failed to create demotion directory for $file"
		return
	fi

	if [[ -e "$destination_file" ]]; then
		echo "beets-inbox-runner: skipping demotion because destination already exists source=$file destination=$destination_file"
		return 1
	fi

	if ! mv "$file" "$destination_file"; then
		echo "beets-inbox-runner: failed to demote $file"
		return 1
	fi

	return 0
}

if [[ "${BEETS_DRY_RUN:-0}" == "1" ]]; then
	beet -c "$BEETS_DATA_DIR/config.yaml" import -q -p -C -l "$IMPORT_LOG_FILE" "$CANONICAL_TARGET"
	echo "beets-inbox-runner: dry-run complete import_log=$IMPORT_LOG_FILE runner_log=$RUNNER_LOG_FILE"
	exit 0
fi

if ! beet -c "$BEETS_DATA_DIR/config.yaml" import -q -C -l "$IMPORT_LOG_FILE" "$CANONICAL_TARGET"; then
	echo "beets-inbox-runner: beets import failed; skipping demotion import_log=$IMPORT_LOG_FILE runner_log=$RUNNER_LOG_FILE"
	exit 1
fi

mapfile -d $'\0' -t LEFTOVER_AUDIO < <(find "$CANONICAL_TARGET" -type f \
	\( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.wav' \) \
	-print0 | sort -z)

demoted_count=0
if ((DEMOTE_LEFTOVERS == 1)); then
	for file in "${LEFTOVER_AUDIO[@]}"; do
		if [[ ! -f "$file" ]]; then
			continue
		fi
		if demote_and_record_unresolved "$file"; then
			((demoted_count += 1))
		fi
	done
fi

imported_estimate=$(( ${#CANDIDATES[@]} - ${#LEFTOVER_AUDIO[@]} ))
if (( imported_estimate < 0 )); then
	imported_estimate=0
fi

echo "beets-inbox-runner: summary target=$CANONICAL_TARGET candidates=${#CANDIDATES[@]} imported_estimate=$imported_estimate leftovers=${#LEFTOVER_AUDIO[@]} demoted=$demoted_count import_log=$IMPORT_LOG_FILE runner_log=$RUNNER_LOG_FILE"
