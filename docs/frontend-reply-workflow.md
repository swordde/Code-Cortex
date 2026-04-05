# Frontend Reply Workflow

This document describes the current frontend reply behavior in the Flutter app, including manual reply generation, send flow, WhatsApp handoff, and fallback behavior.

## Scope

- Dashboard notification list flow
- Generate → review → send UX
- WhatsApp-specific open behavior
- Clipboard fallback behavior

## Entry Points

- Notification list screen: [lib/screens/notification_list_screen.dart](lib/screens/notification_list_screen.dart)
- Notification model: [lib/models/app_notification.dart](lib/models/app_notification.dart)
- API client methods: [lib/core/api_client.dart](lib/core/api_client.dart)
- Backend endpoint constants: [lib/core/backend_endpoints.dart](lib/core/backend_endpoints.dart)

## User Flow

1. User opens a priority category from dashboard.
2. User taps **Generate Reply** on a notification.
3. App requests generated text from backend (`/reply/generate`).
4. App shows a dialog with editable draft text.
5. User taps **Send**.
6. App sends final text to backend (`/reply/send`).

## Backend APIs Used by Frontend

- Generate draft:
  - `POST /api/notifications/{id}/reply/generate?user_id=<id>`
- Send draft:
  - `POST /api/notifications/{id}/reply/send?user_id=<id>`
  - body: `{ "reply": "..." }`

## WhatsApp Behavior

When notification source indicates WhatsApp and backend send does not return `sent`:

- Reply text is copied to clipboard.
- App attempts to open WhatsApp using deep link with prefilled message.
- If sender contains a parseable phone number, app includes it in deep link.

Phone extraction source:

- `sender_name` from notification payload, mapped to `senderName` in `AppNotification`.

## Fallback Behavior

If delivery is not completed by backend (`status != sent`):

- Reply remains available as backend draft.
- Reply text is auto-copied to clipboard.
- Snackbar shows drafted state and delivery note (if provided).

## Dependency

Frontend uses:

- `url_launcher` for opening WhatsApp externally.

Defined in:

- [pubspec.yaml](pubspec.yaml)

## Quick Manual Test Checklist

1. Start backend and app.
2. Ingest one WhatsApp-style notification with sender phone in `sender_name`.
3. Open category list and tap **Generate Reply**.
4. Confirm draft dialog appears.
5. Tap **Send**.
6. If backend returns drafted, verify:
   - Snackbar indicates draft fallback.
   - Clipboard contains reply text.
   - WhatsApp open is attempted.

## Notes

- Direct platform delivery still depends on backend webhook configuration.
- Frontend fallback ensures user can continue with manual send even when webhook delivery is unavailable.
