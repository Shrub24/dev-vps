set -euo pipefail

ROOT_INBOX="/srv/media/inbox"
UNTAGGED_ROOT="/srv/media/library/untagged"
TARGET_PATH="${1:-/srv/media/inbox}"
CANONICAL_TARGET="$(realpath -m "$TARGET_PATH")"
SETTLE_SECONDS="${BEETS_SETTLE_SECONDS:-10}"

case "$CANONICAL_TARGET" in
/srv/media/inbox | /srv/media/inbox/*) ;;
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

mkdir -p "$UNTAGGED_ROOT"
mkdir -p /srv/data/beets/state
mkdir -p /srv/data/beets/logs

cp "${BEETS_CONFIG_SOURCE:?missing BEETS_CONFIG_SOURCE}" /srv/data/beets/config.yaml
chmod 0640 /srv/data/beets/config.yaml

TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
IMPORT_LOG_FILE="/srv/data/beets/logs/$TIMESTAMP-import.log"
RUNNER_LOG_FILE="/srv/data/beets/logs/$TIMESTAMP-runner.log"

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
		local filename
		local base
		local extension
		filename="$(basename "$destination_file")"
		base="${filename%.*}"
		extension="${filename##*.}"
		if [[ "$base" == "$filename" ]]; then
			destination_file="$destination_dir/${filename}.$TIMESTAMP"
		else
			destination_file="$destination_dir/${base}.$TIMESTAMP.${extension}"
		fi
	fi

	mv "$file" "$destination_file" || echo "beets-inbox-runner: failed to demote $file"
}

if [[ "${BEETS_DRY_RUN:-0}" == "1" ]]; then
	beet -c /srv/data/beets/config.yaml import -q -p -C -l "$IMPORT_LOG_FILE" "$CANONICAL_TARGET"
	echo "beets-inbox-runner: dry-run complete import_log=$IMPORT_LOG_FILE runner_log=$RUNNER_LOG_FILE"
	exit 0
fi

if ! beet -c /srv/data/beets/config.yaml import -q -C -l "$IMPORT_LOG_FILE" "$CANONICAL_TARGET"; then
	echo "beets-inbox-runner: beets import failed; skipping demotion import_log=$IMPORT_LOG_FILE runner_log=$RUNNER_LOG_FILE"
	exit 1
fi

mapfile -d $'\0' -t LEFTOVER_AUDIO < <(find "$CANONICAL_TARGET" -type f \
	\( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.wav' \) \
	-print0 | sort -z)

demoted_count=0
for file in "${LEFTOVER_AUDIO[@]}"; do
	if [[ ! -f "$file" ]]; then
		continue
	fi
	demote_and_record_unresolved "$file"
	((demoted_count += 1))
done

imported_estimate=$(( ${#CANDIDATES[@]} - ${#LEFTOVER_AUDIO[@]} ))
if (( imported_estimate < 0 )); then
	imported_estimate=0
fi

echo "beets-inbox-runner: summary candidates=${#CANDIDATES[@]} imported_estimate=$imported_estimate leftovers=${#LEFTOVER_AUDIO[@]} demoted=$demoted_count import_log=$IMPORT_LOG_FILE runner_log=$RUNNER_LOG_FILE"
