#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$BACKEND_DIR/.env" ]]; then
  set -a
  source "$BACKEND_DIR/.env"
  set +a
fi

LOCAL_MONGO_URI="mongodb://127.0.0.1:27017"
AUTO_FALLBACK="${SNP_AUTO_LOCAL_MONGO_FALLBACK:-true}"

if [[ "${SNP_USE_LOCAL_MONGO:-false}" == "true" ]]; then
  export SNP_MONGO_URI="$LOCAL_MONGO_URI"
fi

if [[ "$AUTO_FALLBACK" == "true" ]] && [[ "${SNP_MONGO_URI:-}" == mongodb+srv://* ]]; then
  if command -v podman >/dev/null 2>&1; then
    if ! podman ps --format '{{.Names}}' | grep -qx 'snp-mongo'; then
      if podman ps -a --format '{{.Names}}' | grep -qx 'snp-mongo'; then
        podman start snp-mongo >/dev/null
      else
        podman run -d --name snp-mongo -p 27017:27017 docker.io/library/mongo:7 >/dev/null
      fi
    fi
    export SNP_MONGO_URI="$LOCAL_MONGO_URI"
    export SNP_MONGO_DB="${SNP_MONGO_DB:-snp}"
    echo "[run_backend] Using local Mongo fallback at $SNP_MONGO_URI"
  fi
fi

cd "$BACKEND_DIR"
exec go run ./cmd/server
