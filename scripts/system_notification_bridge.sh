#!/usr/bin/env bash
set -euo pipefail

BACKEND_HOST="${BACKEND_HOST:-localhost}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
POLL_INTERVAL="${POLL_INTERVAL:-2.5}"
PRIME_ON_START="${PRIME_ON_START:-1}"

if ! command -v curl >/dev/null 2>&1; then
  echo "system_notification_bridge.sh: curl is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "system_notification_bridge.sh: jq is required" >&2
  exit 1
fi

tool=""
if command -v dunstify >/dev/null 2>&1; then
  tool="dunstify"
elif command -v notify-send >/dev/null 2>&1; then
  tool="notify-send"
else
  echo "system_notification_bridge.sh: neither dunstify nor notify-send found" >&2
  exit 1
fi

declare -A seen_ids=()
primed=0
if [[ "$PRIME_ON_START" == "0" ]]; then
  primed=1
fi

urgency_for() {
  case "$1" in
    EMERGENCY) echo "critical" ;;
    HIGH) echo "normal" ;;
    *) echo "low" ;;
  esac
}

send_notification() {
  local app="$1"
  local sender="$2"
  local body="$3"
  local priority="$4"
  local urgency
  urgency="$(urgency_for "$priority")"
  local summary="${sender} [${priority}]"

  if [[ "$tool" == "dunstify" ]]; then
    dunstify -a "$app" -u "$urgency" -h "string:x-snp-priority:${priority}" "$summary" "$body" >/dev/null 2>&1 || true
  else
    notify-send -a "$app" -u "$urgency" "$summary" "$body" >/dev/null 2>&1 || true
  fi
}

while true; do
  json="$(curl -sS -m 4 "http://${BACKEND_HOST}:${BACKEND_PORT}/api/notifications" || true)"

  if [[ -z "$json" ]] || ! printf '%s' "$json" | jq -e 'type == "array"' >/dev/null 2>&1; then
    sleep "$POLL_INTERVAL"
    continue
  fi

  mapfile -t rows < <(
    printf '%s' "$json" | jq -r '.[] | [
      (.id // ""),
      (.app_name // .app_package // "Cortex"),
      (.sender_name // "Notification"),
      (.content // ""),
      ((.priority // "LOW") | ascii_upcase)
    ] | @tsv'
  )

  declare -A latest_ids=()
  new_rows=()

  for row in "${rows[@]}"; do
    IFS=$'\t' read -r id app sender body priority <<<"$row"
    [[ -z "$id" ]] && continue
    latest_ids["$id"]=1
    if [[ "$primed" -eq 1 && -z "${seen_ids[$id]:-}" ]]; then
      new_rows+=("$row")
    fi
  done

  if [[ "$primed" -eq 0 ]]; then
    primed=1
  else
    for ((i=${#new_rows[@]}-1; i>=0; i--)); do
      IFS=$'\t' read -r _id app sender body priority <<<"${new_rows[$i]}"
      send_notification "$app" "$sender" "$body" "$priority"
    done
  fi

  unset seen_ids
  declare -A seen_ids=()
  for k in "${!latest_ids[@]}"; do
    seen_ids["$k"]=1
  done

  sleep "$POLL_INTERVAL"
done
