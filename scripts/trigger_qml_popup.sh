#!/usr/bin/env bash
set -euo pipefail

BACKEND_HOST="${BACKEND_HOST:-localhost}"
BACKEND_PORT="${BACKEND_PORT:-8080}"

PRIORITY="${1:-HIGH}"
SENDER="${2:-Popup Tester}"
APP_NAME="${3:-SNP Test}" 
CONTENT="${4:-QuickShell QML popup trigger}"

PRIORITY_UPPER="$(printf '%s' "$PRIORITY" | tr '[:lower:]' '[:upper:]')"

case "$PRIORITY_UPPER" in
  EMERGENCY|HIGH|MEDIUM|LOW) ;;
  *)
    echo "Invalid priority: $PRIORITY_UPPER (use EMERGENCY|HIGH|MEDIUM|LOW)" >&2
    exit 1
    ;;
esac

payload=$(cat <<JSON
{
  "content": "$CONTENT",
  "app_name": "$APP_NAME",
  "app_package": "com.snp.trigger",
  "sender_name": "$SENDER",
  "priority": "$PRIORITY_UPPER"
}
JSON
)

curl -sS -m 6 -X POST "http://${BACKEND_HOST}:${BACKEND_PORT}/api/notifications/ingest" \
  -H "Content-Type: application/json" \
  -d "$payload"

echo
echo "Triggered popup via backend at ${BACKEND_HOST}:${BACKEND_PORT}"
