# Fedora + Hyprland Checklist

## Preflight

- Confirm user services are available: `systemctl --user status`
- Confirm PipeWire is running: `systemctl --user status pipewire`
- Confirm session bus exists: `echo $DBUS_SESSION_BUS_ADDRESS`

## Install Dependencies

```bash
sudo dnf update -y
sudo dnf install -y git curl jq python3 python3-pip python3-virtualenv go dbus-tools pipewire pipewire-utils
```

## Install SNP Linux Services

```bash
./scripts/install_linux.sh
```

## Disable Conflicting Notification Daemons

```bash
for svc in mako dunst swaync xfce4-notifyd; do
  systemctl --user stop "$svc.service" 2>/dev/null || true
  systemctl --user disable "$svc.service" 2>/dev/null || true
done
pkill -f mako || true
pkill -f dunst || true
pkill -f swaync || true
pkill -f xfce4-notifyd || true
```

## Verify Overlay Placement

- Emergency notification appears center.
- High notification appears top-right.
- Medium and Low appear bottom-right corner.

## SELinux Note

If local IPC fails on Fedora, keep sockets under `$XDG_RUNTIME_DIR/snp` and avoid privileged locations.
