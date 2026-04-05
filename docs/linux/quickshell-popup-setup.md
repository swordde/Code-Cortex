# QuickShell Popup Setup Guide (Fedora Wayland, 2-Laptop Flow)

A clean runbook to get QuickShell popups working with minimal drama.

This project supports three popup paths:

- Standalone QML popups (recommended)
- In-app QML popups (inside QuickShell process)
- System daemon notifications (dunst or notify-send)

For your setup, use Standalone QML popups.

## 1. Prerequisites

On the UI laptop (the one running QuickShell):

```bash
sudo dnf install -y qt6-qtdeclarative qt6-qtquickcontrols2 jq curl
```

On the backend laptop:

```bash
# Go toolchain and your backend deps should be available
# Open backend port if firewall is enabled
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

## 2. Start Backend (Backend Laptop)

From repository root:

```bash
cd backend
go mod tidy
./scripts/run_backend.sh
```

Quick API check (on backend laptop):

```bash
curl http://localhost:8080/api/modes
```

## 3. Verify Reachability (UI Laptop)

Use backend IP from your network (example below):

```bash
curl http://10.142.59.129:8080/api/modes
```

If this fails, fix networking first.

## 4. Run QuickShell (UI Laptop, Recommended Mode)

From repository root:

```bash
BACKEND_HOST=10.142.59.129 BACKEND_PORT=8080 USE_QML_POPUP_BRIDGE=1 ./scripts/run_quickshell_live.sh
```

What this does:

- Runs QuickShell dashboard
- Starts shell popup bridge
- Spawns standalone popup-only QML windows for new notifications

## 5. Trigger a Test Popup

```bash
BACKEND_HOST=10.142.59.129 BACKEND_PORT=8080 ./scripts/trigger_qml_popup.sh EMERGENCY Mom Signal "Call me now"
```

Other examples:

```bash
./scripts/trigger_qml_popup.sh HIGH TeamLead Slack "Need update in 10 mins"
./scripts/trigger_qml_popup.sh MEDIUM Calendar System "Study session starts in 15 mins"
./scripts/trigger_qml_popup.sh LOW Promo Shop "Weekend sale live"
```

## 6. Run Modes Cheat Sheet

### A) Standalone QML popups (best for global-like behavior)

```bash
USE_QML_POPUP_BRIDGE=1 USE_SYSTEM_NOTIFICATIONS=0 ./scripts/run_quickshell_live.sh
```

### B) In-app QML popups only

```bash
USE_QML_POPUP_BRIDGE=0 USE_SYSTEM_NOTIFICATIONS=0 ./scripts/run_quickshell_live.sh
```

### C) System daemon popups (dunst/notify-send)

```bash
USE_QML_POPUP_BRIDGE=0 USE_SYSTEM_NOTIFICATIONS=1 ./scripts/run_quickshell_live.sh
```

## 7. Health Checks

Check QuickShell process:

```bash
pgrep -af qml6
```

Check popup bridge process:

```bash
pgrep -af qml_popup_bridge.sh
```

Check backend notifications feed:

```bash
curl http://10.142.59.129:8080/api/notifications | head
```

## 8. Troubleshooting

### No popups at all

- Confirm backend reachable from UI laptop
- Confirm QuickShell is running
- Confirm popup bridge process is running
- Confirm trigger script returns created JSON

### Notification appears in dashboard but no floating popup

- You are likely not in bridge mode
- Run with USE_QML_POPUP_BRIDGE=1

### Popups look tied to app window on Wayland

- Wayland compositors can enforce strict window behavior
- Standalone bridge mode is the most reliable workaround in this repo

### Wrong backend target

- Set BACKEND_HOST and BACKEND_PORT explicitly when launching

## 9. Scripts Involved

- scripts/run_quickshell_live.sh
- scripts/qml_popup_bridge.sh
- scripts/system_notification_bridge.sh
- scripts/trigger_qml_popup.sh

## 10. Team Notes

If you want this to auto-start for login sessions later, wrap the launch command in a user systemd service after final stability checks.
