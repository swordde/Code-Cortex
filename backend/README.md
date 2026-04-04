# Cortex Backend (Member 3 Scope)

Go backend for Cortex notification intelligence pipeline.

## Implemented modules

- Ingestion Service (HTTP endpoint for Android + Linux D-Bus bridge payload forwarding)
- Classification Orchestrator (retry + in-memory cache)
- Rule Engine (contact/keyword overrides)
- Mode Manager (active context mode)
- Push Dispatcher (Flutter HTTP + QuickShell Unix socket)
- Auth Service (voice signature storage + activation token)
- Analytics Writer (async SQLite persistence)

## Run

```bash
cd backend
go mod tidy
go run ./cmd/server
```

Server defaults to `127.0.0.1:8088`.

## Key endpoints

- `GET /v1/health`
- `POST /v1/ingest`
- `GET /v1/rules`
- `POST /v1/rules`
- `GET /v1/mode`
- `PUT /v1/mode`
- `POST /v1/auth/voice-signature`
- `POST /v1/auth/token`

## Example ingest payload

```json
{
  "platform": "android",
  "app": "com.whatsapp",
  "sender": "Mom",
  "title": "Urgent",
  "content": "Please call me now",
  "receivedAt": "2026-04-04T09:30:00Z"
}
```
