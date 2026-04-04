# SNP AI Layer — Complete API Reference
Base URL: https://marisela-tiderode-mollifyingly.ngrok-free.dev
No authentication required — exposed for external demo access via ngrok tunnel.
All requests: Content-Type: application/json
All responses: application/json

## Error format
All errors follow FastAPI default shape:
{"detail": "<error message string>"}
HTTP 422 = validation error (wrong field types or missing required fields)
HTTP 500 = server error (model crash, file not found, etc.)
HTTP 200 = always success, even for stubs (stubs return {"status": "not_implemented"})

### POST /classify
Classify a notification and return priority label.

Request:
{
  "content": "string — notification text",
  "app": "string — app name e.g. WhatsApp, Gmail, Slack",
  "mode": "string — study | office | home | gaming | college | custom",
  "user_id": "string — any identifier e.g. demo_user"
}

Response:
{
  "priority": "Emergency | High | Medium | Low",
  "confidence": 0.91,
  "label_reason": "string — e.g. rule_override_service_outage"
}

Notes:
- priority is always capitalized first letter exactly as shown
- confidence is a float between 0.0 and 1.0
- label_reason explains why this priority was assigned

### POST /classify/batch
Batch classification endpoint (currently a stub).

Request:
{}

Response:
{
  "status": "not_implemented",
  "detail": "Batch classification endpoint is reserved for integration."
}

Notes:
- currently no batch payload is accepted
- always returns HTTP 200 with stub payload

### POST /feedback
Submit correction feedback for future fine-tuning.

Request:
{
  "content": "string — original notification text",
  "app": "string — source app name",
  "mode": "string — user mode",
  "label": "Emergency | High | Medium | Low",
  "user_id": "string — user identifier"
}

Response:
{
  "status": "ok",
  "total_feedback_count": 123
}

Notes:
- label must be one of Emergency, High, Medium, Low
- invalid label returns HTTP 400 with FastAPI detail

### POST /finetune
Run model fine-tuning using dataset + feedback.

Request:
{}

Response:
{
  "status": "completed",
  "new_accuracy": 0.94,
  "version": 5,
  "duration_seconds": 47.2
}

Notes:
- request body is empty
- internally reloads inference service after successful training

### GET /model/status
Fetch current classifier version and health.

Request:
{}

Response:
{
  "version": 5,
  "accuracy": 0.94,
  "last_finetune_timestamp": "2026-04-05T09:15:10.123456+00:00",
  "sample_count": 840,
  "model_loaded": true
}

Notes:
- last_finetune_timestamp can be null if never fine-tuned
- model_loaded indicates inference service readiness

### POST /cortex/reply
Generate Cortex reply/action for a classified message.

Request:
{
  "content": "string — notification/message body",
  "app": "string — source app",
  "mode": "string — study | office | home | gaming | college | custom",
  "priority": "Emergency | High | Medium | Low",
  "tone": "casual | formal | brief | professional",
  "user_id": "string — requester id"
}

Response:
{
  "reply": "string — generated or templated reply (can be empty when suppressed)",
  "action": "auto_send | draft | suppress",
  "tone_used": "casual | formal | brief | professional",
  "mode_used": "string — echo of mode",
  "cortex_version": "string — model identifier",
  "latency_ms": 183
}

Notes:
- action controls downstream UX (auto-send vs draft vs suppress)
- reply may be empty when action is suppress

### GET /cortex/status
Get Cortex runtime/model status.

Request:
{}

Response:
{
  "model_loaded": true,
  "device": "cpu",
  "idle_timer_seconds_remaining": 241,
  "total_replies_generated": 56
}

Notes:
- total_replies_generated increments when non-empty reply is produced

### GET /cortex/log
Get recent Cortex activity logs.

Request:
{}

Response:
[
  {
    "timestamp": "2026-04-05T09:20:44.120000+00:00",
    "user_id": "demo_user",
    "app": "WhatsApp",
    "mode": "study",
    "priority": "High",
    "action": "draft",
    "tone": "professional",
    "reply": "string",
    "latency_ms": 201,
    "model_version": "microsoft/phi-2"
  }
]

Notes:
- returns up to last 50 entries
- entries are returned newest first

### POST /voice/enroll
Enroll a user voice profile from 3 samples.

Request:
{
  "user_id": "string — user identifier",
  "audio_samples": [
    "string — base64 mono PCM16 WAV @16kHz",
    "string — base64 mono PCM16 WAV @16kHz",
    "string — base64 mono PCM16 WAV @16kHz"
  ]
}

Response:
{
  "status": "ok",
  "user_id": "string",
  "enrolled_at": "2026-04-05T09:30:11.006000+00:00"
}

Notes:
- exactly 3 samples required
- each sample must decode to mono, PCM16, 16kHz WAV

### POST /voice/verify
Verify live voice sample against enrolled profile.

Request:
{
  "user_id": "string — enrolled user id",
  "audio": "string — base64 mono PCM16 WAV @16kHz"
}

Response:
{
  "match": true,
  "confidence": 0.89,
  "user_id": "string",
  "locked": false
}

Notes:
- locked field is always present in response
- locked becomes true when failed attempts reach configured lock threshold
- successful match resets failed-attempt counter

### POST /voice-assistant/start
Start backend voice assistant runtime.

Request:
{}

Response:
{
  "status": "started",
  "wake_word": "hey cortex"
}

Notes:
- if already running, response is:
  {"status": "already_running"}

### POST /voice-assistant/stop
Stop backend voice assistant runtime.

Request:
{}

Response:
{
  "status": "stopped"
}

Notes:
- safe to call even when already stopped

### GET /voice-assistant/status
Get runtime status and wake diagnostics.

Request:
{}

Response:
{
  "running": true,
  "state": "idle",
  "wake_word": "hey cortex",
  "total_activations_today": 8,
  "wake_threshold": 0.5,
  "wake_debug": {
    "enabled": true,
    "model_name": "hey_jarvis",
    "model_score_key": "hey_jarvis",
    "last_score": 0.12,
    "last_score_key": "hey_jarvis",
    "last_error": ""
  }
}

Notes:
- state values are conversation runtime states (e.g. idle/listening/processing/speaking)
- wake_debug is for diagnostics and can evolve

### POST /voice-assistant/transcribe
Transcribe frontend-captured audio using backend STT.

Request:
{
  "audio_base64": "string — base64 encoded audio bytes",
  "mime_type": "string — e.g. audio/wav, audio/webm, audio/ogg, audio/mp4"
}

Response:
{
  "transcript": "string",
  "detected_hey_cortex": false,
  "error": "string — optional, present when decode/transcribe fails"
}

Notes:
- transcript is empty when no speech detected or an error occurs
- error field appears only on transcribe failure

### POST /voice-assistant/reader/command
Process transcript through backend wake/reader controller.

Request:
{
  "transcript": "string — e.g. hey cortex, read message 1, next, previous"
}

Response:
{
  "action": "wake_detected | waiting_for_wake | read_specific_message | next_message | previous_message | stopped | unknown | ignored_duplicate | ignored_command_cooldown",
  "wake_active": true,
  "speech_text": "string — text to speak back",
  "hint": "string — optional guidance",
  "intent": {
    "intent": "string",
    "index": 0,
    "raw": "string"
  }
}

Notes:
- wake phrase required before command execution
- intent object appears when command maps to parsed intent

### POST /voice-assistant/reader/reset
Reset backend reader wake/command state.

Request:
{}

Response:
{
  "status": "reset",
  "wake_active": false
}

Notes:
- use before starting a new voice-reader session

## Quick reference table
| Method | Path | Owner | Used by |
|--------|------|-------|---------|
| POST | /classify | Member 1 | Member 3 (Go backend), Member 4 (Flutter) |
| POST | /classify/batch | Member 1 | Member 3 (reserved/stub) |
| POST | /feedback | Member 1 | Member 3, Member 4 |
| POST | /finetune | Member 1 | Member 3 (admin/dev flow) |
| GET | /model/status | Member 1 | Member 3, Member 4 |
| POST | /cortex/reply | Member 1 | Member 3, Member 4 |
| GET | /cortex/status | Member 1 | Member 3, Member 4 |
| GET | /cortex/log | Member 1 | Member 3, Member 4 |
| POST | /voice/enroll | Member 1 | Member 4 |
| POST | /voice/verify | Member 1 | Member 4 |
| POST | /voice-assistant/start | Member 1 | Member 3, Member 4 |
| POST | /voice-assistant/stop | Member 1 | Member 3, Member 4 |
| GET | /voice-assistant/status | Member 1 | Member 3, Member 4 |
| POST | /voice-assistant/transcribe | Member 1 | Member 4 |
| POST | /voice-assistant/reader/command | Member 1 | Member 4 |
| POST | /voice-assistant/reader/reset | Member 1 | Member 4 |

## Priority values reference
Priority strings (exact case):
  Emergency — suppress all Cortex replies, surface immediately
  High       — Cortex drafts reply, user approves before send
  Medium     — Cortex auto-sends reply
  Low        — template reply or suppress (gaming mode)

Mode strings (exact case):
  study | office | home | gaming | college | custom

Tone strings (exact case):
  casual | formal | brief | professional

Action strings returned by /cortex/reply:
  auto_send | draft | suppress
