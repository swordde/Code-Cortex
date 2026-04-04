#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$BACKEND_DIR/.env" ]]; then
  echo "[ERROR] Missing $BACKEND_DIR/.env"
  echo "Create it with: cp $BACKEND_DIR/.env.example $BACKEND_DIR/.env"
  exit 1
fi

set -a
source "$BACKEND_DIR/.env"
set +a

if [[ -z "${SNP_MONGO_URI:-}" || "$SNP_MONGO_URI" == *"<username>"* ]]; then
  echo "[ERROR] SNP_MONGO_URI is not configured in .env"
  exit 1
fi

if [[ -z "${SNP_MONGO_DB:-}" ]]; then
  echo "[ERROR] SNP_MONGO_DB is not configured in .env"
  exit 1
fi

echo "[1/4] Checking backend health via /api/modes ..."
if ! curl -fsS "http://localhost:8080/api/modes" >/dev/null; then
  echo "[ERROR] Backend is not reachable at http://localhost:8080"
  echo "Start it with: $BACKEND_DIR/scripts/run_backend.sh"
  exit 1
fi

echo "[2/4] Checking analytics endpoint ..."
curl -fsS "http://localhost:8080/api/analytics?range=week" >/dev/null

echo "[3/4] Ingesting a sample notification ..."
curl -fsS -X POST "http://localhost:8080/api/notifications/ingest" \
  -H "Content-Type: application/json" \
  -d '{"content":"urgent hello","app_name":"WhatsApp","app_package":"com.whatsapp","sender_name":"Mom"}' >/dev/null

echo "[4/4] Re-checking notification list ..."
curl -fsS "http://localhost:8080/api/notifications" >/dev/null

echo "[OK] Backend + Mongo flow looks healthy."
