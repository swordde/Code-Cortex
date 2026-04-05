#!/usr/bin/env bash
set -euo pipefail

BACKEND_HOST="${BACKEND_HOST:-localhost}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
POLL_INTERVAL="${POLL_INTERVAL:-1.8}"
POPUP_COOLDOWN="${POPUP_COOLDOWN:-0.35}"
PRIME_ON_START="${PRIME_ON_START:-1}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML_FILE="$ROOT_DIR/platform/linux/quickshell/main.qml"

if ! command -v curl >/dev/null 2>&1; then
  echo "qml_popup_bridge.sh: curl is required" >&2
  exit 1
fi

JSON_PARSER=""
if command -v jq >/dev/null 2>&1; then
  JSON_PARSER="jq"
elif command -v python3 >/dev/null 2>&1; then
  JSON_PARSER="python3"
else
  echo "qml_popup_bridge.sh: requires either jq or python3" >&2
  exit 1
fi

json_is_array() {
  local input="$1"
  if [[ "$JSON_PARSER" == "jq" ]]; then
    printf '%s' "$input" | jq -e 'type == "array"' >/dev/null 2>&1
    return $?
  fi

  printf '%s' "$input" | python3 -c '
import json
import sys

try:
    data = json.loads(sys.stdin.read())
    raise SystemExit(0 if isinstance(data, list) else 1)
except Exception:
    raise SystemExit(1)
'
}

json_to_rows() {
  local input="$1"
  if [[ "$JSON_PARSER" == "jq" ]]; then
    printf '%s' "$input" | jq -r '.[] | [
      (.id // ""),
      (.sender_name // "Unknown"),
      (.app_name // .app_package // "System"),
      (.content // ""),
      ((.priority // "LOW") | ascii_upcase),
      (.timestamp // "")
    ] | @tsv'
    return $?
  fi

  printf '%s' "$input" | python3 -c '
import json
import sys

def clean(value):
    if value is None:
        return ""
    text = str(value)
    return text.replace("\t", " ").replace("\n", " ").replace("\r", " ")

try:
    rows = json.loads(sys.stdin.read())
    if not isinstance(rows, list):
        raise SystemExit(0)

    for row in rows:
        if not isinstance(row, dict):
            continue
        rid = clean(row.get("id", ""))
        sender = clean(row.get("sender_name", "Unknown")) or "Unknown"
        app = clean(row.get("app_name", "") or row.get("app_package", "") or "System") or "System"
        preview = clean(row.get("content", ""))
        priority = clean((row.get("priority", "LOW") or "LOW")).upper() or "LOW"
        ts = clean(row.get("timestamp", ""))
        print("\t".join([rid, sender, app, preview, priority, ts]))
except Exception:
    pass
    '
}

find_qml_cmd() {
  for c in qml6 qmlscene6 qmlscene qml; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

QML_CMD="$(find_qml_cmd || true)"
if [[ -z "$QML_CMD" ]]; then
  echo "qml_popup_bridge.sh: no qml runtime found (qml6/qmlscene6/qmlscene/qml)" >&2
  exit 1
fi

if [[ ! -f "$QML_FILE" ]]; then
  echo "qml_popup_bridge.sh: main.qml not found at $QML_FILE" >&2
  exit 1
fi

declare -A seen_ids=()
primed=0
if [[ "$PRIME_ON_START" == "0" ]]; then
  primed=1
fi

launch_popup() {
  local sender="$1"
  local app="$2"
  local preview="$3"
  local priority="$4"
  local ts="$5"

  "$QML_CMD" "$QML_FILE" -- \
    --popup-only \
    --popup-once 1 \
    --popup-sender "$sender" \
    --popup-app "$app" \
    --popup-preview "$preview" \
    --popup-priority "$priority" \
    --popup-timestamp "$ts" >/dev/null 2>&1 &
}

while true; do
  json="$(curl -sS -m 4 "http://${BACKEND_HOST}:${BACKEND_PORT}/api/notifications" || true)"

  if [[ -z "$json" ]]; then
    sleep "$POLL_INTERVAL"
    continue
  fi

  if ! json_is_array "$json"; then
    sleep "$POLL_INTERVAL"
    continue
  fi

  mapfile -t rows < <(json_to_rows "$json")

  declare -A latest_ids=()
  new_rows=()

  for row in "${rows[@]}"; do
    IFS=$'\t' read -r id sender app preview priority ts <<<"$row"
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
      IFS=$'\t' read -r _id sender app preview priority ts <<<"${new_rows[$i]}"
      if [[ -z "$ts" ]]; then
        ts="$(date +%H:%M)"
      elif [[ "$ts" == *T* && ${#ts} -ge 16 ]]; then
        ts="${ts:11:5}"
      fi
      launch_popup "$sender" "$app" "$preview" "$priority" "$ts"
      sleep "$POPUP_COOLDOWN"
    done
  fi

  unset seen_ids
  declare -A seen_ids=()
  for k in "${!latest_ids[@]}"; do
    seen_ids["$k"]=1
  done

  sleep "$POLL_INTERVAL"
done
