#!/usr/bin/env bash
set -euo pipefail

SUMMARY_URL="https://status.claude.com/api/v2/summary.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude-status-monitor/components"
NOTIFY_NOW=0

usage() {
    cat <<'EOF'
Usage: claude-status-notify.sh [--notify-now|-n]

Options:
  -n, --notify-now   Force notifications for current component states
  -h, --help         Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        -n|--notify-now)
            NOTIFY_NOW=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

mkdir -p "$STATE_DIR"

for cmd in curl jq notify-send; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd is required" >&2
        exit 1
    fi
done

json="$(curl -fsS --max-time 20 "$SUMMARY_URL")"

jq -r '.components[] | [.id, .name, .status] | @tsv' <<<"$json" | \
while IFS=$'\t' read -r id name status; do
    state_file="$STATE_DIR/$id.status"

    previous=""
    if [[ -f "$state_file" ]]; then
        previous="$(<"$state_file")"
    fi

    case "$status" in
        operational)
            message="$name is operational."
            ;;
        degraded_performance)
            message="$name is experiencing degraded performance."
            ;;
        partial_outage)
            message="$name has a partial outage."
            ;;
        major_outage)
            message="$name has a major outage."
            ;;
        under_maintenance)
            message="$name is under maintenance."
            ;;
        *)
            message="$name status: $status"
            ;;
    esac

    if [[ "$NOTIFY_NOW" -eq 1 ]]; then
        notify-send -i "dialog-information" "Claude service status" "$message"
        printf '%s\n' "$status" > "$state_file"
        continue
    fi

    if [[ -z "$previous" ]]; then
        printf '%s\n' "$status" > "$state_file"
        continue
    fi

    if [[ "$status" != "$previous" ]]; then
        notify-send -i "dialog-information" "Claude service status changed" "$message"
        printf '%s\n' "$status" > "$state_file"
    fi
done
