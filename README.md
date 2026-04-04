# Smart Notification Prioritizer

Cross-platform notification intelligence project.

Current repo state includes Flutter app scaffolding plus Linux platform setup for Member 2 workflows (QuickShell, D-Bus bridge service templates, and install scripts).

## Quick Start

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Run the Flutter app:

```bash
flutter run
```

## Linux Platform Setup (Member 2)

Linux-focused files live under:

- platform/linux
- deploy/systemd/user
- scripts
- docs/linux

Use the installer to stage user services and Linux config:

```bash
./scripts/install_linux.sh
```

## QuickShell Run Modes

Use separate scripts so you never edit code to switch modes.

Test mode (demo data, popup-only overlay, auto-exit):

```bash
./scripts/run_quickshell_mock.sh
```

Production mode (no demo seed, full app behavior for live backend wiring):

```bash
./scripts/run_quickshell_live.sh
```

Dashboard demo mode (demo data with full QuickShell dashboard view):

```bash
./scripts/run_quickshell_dashboard_demo.sh
```

If Qt modules are missing:

- Fedora:

```bash
sudo dnf install -y qt6-qtdeclarative qt6-qtquickcontrols2
```

- Arch:

```bash
sudo pacman -S --noconfirm qt6-declarative qt6-5compat
```

## Popup Style Presets

Popup presets are centralized and easy to switch:

1. Open platform/linux/quickshell/main.qml
2. Set popupPreset to one of:

- projectCore
- batNoir
- densePro
- cleanGlass
- neonGamer

Preset token definitions are in:

- platform/linux/quickshell/components/PopupTheme.js

Theme contract and Flutter-to-QuickShell mapping:

- docs/linux-quickshell-theme-contract.md

Selected dashboard preset is persisted automatically and restored on next launch.

## Priority Routing Rules (Current UI)

- EMERGENCY -> center
- HIGH -> top-right stack
- MEDIUM and LOW -> bottom-right stack

The QML entrypoint exposes ingestNotificationFromBackend(n) to feed live notifications into these zones.

## Distro Validation Notes

- Arch + i3 checklist: docs/linux/arch-i3-checklist.md
- Fedora + Hyprland checklist: docs/linux/fedora-hyprland-checklist.md

## Hyprland User Flow

For teammates on Hyprland, use this flow:

1. Install dependencies and run installer:

```bash
sudo dnf install -y qt6-qtdeclarative qt6-qtquickcontrols2
./scripts/install_linux.sh
```

2. Validate user services:

```bash
systemctl --user status snp-backend.service
systemctl --user status snp-ai.service
systemctl --user status snp-dbus-bridge.service
```

3. Test popup UI quickly:

```bash
./scripts/run_quickshell_mock.sh
```

4. If another notification daemon is active, stop it to avoid duplicate popups:

```bash
for svc in mako dunst swaync xfce4-notifyd; do
	systemctl --user stop "$svc.service" 2>/dev/null || true
	systemctl --user disable "$svc.service" 2>/dev/null || true
done
```

5. Optional Hyprland startup integration after stability checks:

- Add installer/service startup to user session.
- Add QuickShell launch to Hyprland exec-once if not auto-managed yet.

6. If local IPC fails on Fedora/SELinux systems, keep runtime sockets under $XDG_RUNTIME_DIR/snp.

## Common Risks

- Conflicting notification daemons can duplicate or suppress popups.
- Missing QtQuick Controls runtime breaks QML preview startup.
- Wayland and X11 can render overlays differently; always validate on both targets.

## Team Note

For now, global shortcut integration can stay deferred while popup UI and backend ingestion are stabilized.
