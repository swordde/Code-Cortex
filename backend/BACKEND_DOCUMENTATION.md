# Cortex Go Backend Documentation

This document explains how the backend works end-to-end: architecture, runtime flow, modules, persistence, and API behavior.

## 1) Purpose

The backend is the runtime core for Cortex.

It:
- accepts notification ingestion events,
- classifies and post-processes them,
- applies user mode/rule overrides,
- persists data in MongoDB,
- pushes live updates over WebSocket and Linux Unix socket,
- serves all Flutter-facing REST endpoints.

## 2) Tech Stack

- Go `1.22+`
- `net/http` router (no framework)
- MongoDB Atlas via `go.mongodb.org/mongo-driver`
- WebSocket via `github.com/gorilla/websocket`
- UUID generation via `github.com/google/uuid`

## 3) Project Structure

- `cmd/server/main.go`: entrypoint, dependency wiring, HTTP server startup/shutdown
- `internal/config/config.go`: env confzig loader
- `internal/server/router.go`: route registration + handlers + CORS/error response format
- `internal/models/models.go`: API/data contracts (JSON + BSON tags)
- `internal/store/mongo.go`: MongoDB collections, seed data, CRUD operations
- `internal/services/classifier.go`: AI classify bridge + timeout/retry/cache
- `internal/services/rules.go`: rule engine evaluation order
- `internal/services/mode_manager.go`: active mode state transitions + scheduler tick
- `internal/services/dispatcher.go`: WebSocket fan-out + Unix socket push
- `internal/services/cortex.go`: Cortex auto-reply/schedule/activity logic
- `internal/services/analytics.go`: analytics aggregation for day/week/month

## 4) Runtime Configuration

Environment variables:

- `SNP_PORT` (default `:8080`)
- `SNP_MONGO_URI` (default `mongodb://localhost:27017`)
- `SNP_MONGO_DB` (default `snp`)
- `SNP_AI_URL` (default `https://marisela-tiderode-mollifyingly.ngrok-free.dev`)
- `SNP_SOCKET_PATH` (default `/tmp/snp.sock`)
- `SNP_AVATAR_DIR` (default `./avatars`)

## 5) Startup Lifecycle

On startup:

1. Config is loaded.
2. MongoDB connection is established.
3. Seed data is ensured if missing:
   - preset modes (`default`, `study`, `office`, `home`, `gaming`),
   - default cortex config,
   - default profile row.
4. Services are initialized.
5. Mode manager initializes active mode and starts 1-minute scheduler loop.
6. HTTP server starts on `SNP_PORT`.

## 6) Notification Pipeline (Critical Path)

`POST /api/notifications/ingest`

1. Validate payload (`content`, `app_package` required).
2. Assign server fields (`id`, `timestamp`, default booleans).
3. Load active mode.
4. Call classifier service:
   - target: `${SNP_AI_URL}/classify`
   - timeout: 3s
   - retry: one retry for 5xx with short backoff
   - cache: 60s for equivalent `(content, app_package, mode)`.
5. Apply rules in order (contact -> keyword -> app -> time), then mode app caps.
6. Save notification to Mongo.
7. Dispatch live push:
   - WebSocket `type: NEW_NOTIFICATION`
   - Linux Unix socket `/tmp/snp.sock` equivalent JSON.
8. Launch cortex automation asynchronously (non-blocking).
9. Return `201` with saved notification JSON.

## 7) Push Protocols

### WebSocket

Endpoint: `GET /ws`

Message types:
- `NEW_NOTIFICATION`
- `MODE_CHANGED`
- `CORTEX_ACTION`

Top-level `type` is required because frontend routing relies on it.

### Unix Socket (Linux)

Path: `SNP_SOCKET_PATH` (default `/tmp/snp.sock`)

Same JSON message envelope as WebSocket messages.

## 8) MongoDB Collections

Main collections used:
- `notifications`
- `modes`
- `rules`
- `cortex_config`
- `reply_templates`
- `scheduled_messages`
- `cortex_activity`
- `profile`
- `mode_sessions`
- `finetune_events`

The store layer handles ordering, soft-delete behavior, and mode/rule integrity operations.

## 9) API Surface

### Notifications
- `POST /api/notifications/ingest`
- `GET /api/notifications`
- `GET /api/notifications/{id}`
- `PUT /api/notifications/{id}/read`
- `PUT /api/notifications/{id}/action`
- `DELETE /api/notifications/{id}`

### Analytics
- `GET /api/analytics?range=day|week|month`

### Modes
- `GET /api/modes`
- `GET /api/modes/active`
- `POST /api/modes`
- `PUT /api/modes/{id}`
- `PUT /api/modes/{id}/activate`
- `DELETE /api/modes/{id}`

### Rules
- `GET /api/rules`
- `POST /api/rules`
- `PUT /api/rules/{id}`
- `DELETE /api/rules/{id}`
- `PUT /api/rules/reorder`

### Cortex
- `GET /api/cortex/config`
- `PUT /api/cortex/config`
- `GET /api/cortex/replies`
- `POST /api/cortex/replies`
- `PUT /api/cortex/replies/{id}`
- `DELETE /api/cortex/replies/{id}`
- `GET /api/cortex/scheduled`
- `PUT /api/cortex/scheduled/{id}/approve`
- `DELETE /api/cortex/scheduled/{id}`
- `GET /api/cortex/activity`
- `POST /api/cortex/voice/enroll`
- `POST /api/cortex/voice/verify`

### Profile
- `GET /api/profile`
- `PUT /api/profile`
- `POST /api/profile/avatar`

## 10) Response/Error Contract

All responses are JSON with CORS headers.

Error format:

```json
{
  "error": "human readable message",
  "code": "MACHINE_CODE"
}
```

Status usage:
- `200`: successful GET/PUT
- `201`: successful resource creation
- `204`: successful delete/empty response
- `400`: bad input/validation failure
- `404`: missing resource
- `409`: conflict (e.g., deleting preset mode)
- `500`: internal error

## 11) Local Run

```bash
cd backend
go mod tidy
go run ./cmd/server
```

Quick checks:

```bash
curl -X GET http://localhost:8080/api/modes
curl -X GET "http://localhost:8080/api/analytics?range=week"
curl -X POST http://localhost:8080/api/notifications/ingest \
  -H "Content-Type: application/json" \
  -d '{"content":"urgent help","app_name":"WhatsApp","app_package":"com.whatsapp","sender_name":"Mom"}'
```

## 12) Operational Notes

- Keep priority strings uppercase: `EMERGENCY`, `HIGH`, `MEDIUM`, `LOW`.
- Keep mode names lowercase: `default`, `study`, `office`, `home`, `gaming`, `custom`.
- WebSocket `type` field must remain exact.
- Cortex automation is intentionally async to avoid ingest latency inflation.
- The scheduler loop in mode manager evaluates time windows every minute.

## 13) Future Safe Extensions

Recommended extension points:
- add indexes on `notifications.timestamp`, `rules.order`, `modes.is_active`,
- add request/trace IDs in middleware,
- add structured logging for pipeline latency metrics,
- add integration tests for ingest + websocket + mode activation transitions.
