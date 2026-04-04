# Cortex Backend (Member 3)

Go backend aligned to SNP backend spec with MongoDB Atlas persistence.

Detailed documentation: [BACKEND_DOCUMENTATION.md](BACKEND_DOCUMENTATION.md)

Mongo setup guide: [MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md)

## Implemented modules

- Notification ingestion + classification + rule override pipeline
- WebSocket push at `/ws` and Unix socket fan-out for Linux QuickShell
- Mode management (preset/custom CRUD + activation + schedule ticker)
- Rule CRUD/reorder
- Cortex config/templates/scheduled/activity/voice proxy endpoints
- Profile + avatar upload endpoints
- Analytics aggregation endpoint (`day|week|month`)

## Run

```bash
cd backend
go mod tidy
./scripts/run_backend.sh
```

Server defaults to `:8080`.

## Environment

- `SNP_PORT` (default `:8080`)
- `SNP_MONGO_URI` (default `mongodb://localhost:27017`)
- `SNP_MONGO_DB` (default `snp`)
- `SNP_AI_URL` (default `http://localhost:5000`)
- `SNP_SOCKET_PATH` (default `/tmp/snp.sock`)
- `SNP_AVATAR_DIR` (default `./avatars`)

## Key endpoints

- `POST /api/notifications/ingest`
- `GET /api/notifications`
- `GET /api/analytics?range=day|week|month`
- `GET/POST/PUT/DELETE /api/modes*`
- `GET/POST/PUT/DELETE /api/rules*`
- `GET/PUT /api/cortex/config`
- `GET/POST/PUT/DELETE /api/cortex/replies*`
- `GET/PUT/DELETE /api/cortex/scheduled*`
- `GET /api/cortex/activity`
- `POST /api/cortex/voice/enroll`
- `POST /api/cortex/voice/verify`
- `GET/PUT /api/profile`
- `POST /api/profile/avatar`
- `GET /ws`

## Example ingest payload

```json
{
  "content": "Please call me now",
  "app_name": "WhatsApp",
  "app_package": "com.whatsapp",
  "sender_name": "Mom",
  "priority": "HIGH",
  "mode": "study",
  "is_read": false,
  "is_actioned": false,
  "confidence": 0.0,
  "label_reason": "",
  "timestamp": "2026-04-04T09:30:00Z"
}
```
