#!/usr/bin/env bash
set -euo pipefail

BACKEND_HOST="${BACKEND_HOST:-10.142.59.129}"
BACKEND_PORT="${BACKEND_PORT:-8080}"

payload='{"content":"SNP bridge test from QuickShell","app_name":"SNP","app_package":"com.snp.test","sender_name":"Code Cortex"}'

curl -sS -m 5 -X POST "http://${BACKEND_HOST}:${BACKEND_PORT}/api/notifications/ingest" \
  -H 'Content-Type: application/json' \
  -d "$payload"

echo
echo "Sent test notification to backend at ${BACKEND_HOST}:${BACKEND_PORT}."
