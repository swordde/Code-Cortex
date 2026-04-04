# Arch + i3 (X11) Checklist

## Preflight

- Confirm user services are available: `systemctl --user status`
- Confirm PipeWire and WirePlumber are running.
- Confirm DBus session bus in environment.

## Install Dependencies

```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git curl jq python python-pip python-virtualenv go dbus pipewire wireplumber
```

## Install SNP Linux Services

```bash
./scripts/install_linux.sh
```

## Disable Conflicting Notification Daemons

```bash
systemctl --user stop dunst.service 2>/dev/null || true
systemctl --user disable dunst.service 2>/dev/null || true
pkill -f dunst || true
```

## i3 Validation

- Confirm popup windows are visible in floating layer.
- Confirm panel/tray does not occlude NotificationCenter.
- Confirm D-Bus forwarding path remains active during workspace switches.
