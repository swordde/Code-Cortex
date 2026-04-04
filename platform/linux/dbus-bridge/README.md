# SNP D-Bus Bridge

This service subscribes to `org.freedesktop.Notifications` on the user session bus,
normalizes events, and forwards them to the local Go backend ingestion endpoint.

## Responsibilities

- Subscribe to `org.freedesktop.Notifications` signals.
- Convert desktop-specific payloads to a stable internal JSON schema.
- Forward to local backend endpoint with timeout and retry.
- Emit structured logs for diagnostics.

## Runtime Contract

- Input source: user session D-Bus
- Forward target: `http://127.0.0.1:8080/v1/ingest/linux`
- Timeout: 2s
- Retry: exponential backoff, max 5 attempts

## Safety Notes

- Never run as root.
- Keep all runtime sockets and temporary files in `$XDG_RUNTIME_DIR`.
- Do not write raw notification content to logs in production mode.
