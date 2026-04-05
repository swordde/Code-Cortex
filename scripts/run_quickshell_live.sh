#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML_FILE="$ROOT_DIR/platform/linux/quickshell/main.qml"

os_name="$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
if [[ -z "$os_name" ]]; then
  os_name="$(uname -s)"
fi

kernel_name="$(uname -r 2>/dev/null || echo unknown)"
arch_name="$(uname -m 2>/dev/null || echo unknown)"
desktop_name="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
session_type="${XDG_SESSION_TYPE:-unknown}"
if [[ "$desktop_name" == "unknown" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  desktop_name="Hyprland"
fi
if [[ "$session_type" == "unknown" && "$desktop_name" == "Hyprland" ]]; then
  session_type="wayland"
fi
load_one="$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0)"

mem_total_kb="$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
mem_avail_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
if [[ "$mem_total_kb" -gt 0 ]]; then
  mem_used_pct="$(( ( (mem_total_kb - mem_avail_kb) * 100 ) / mem_total_kb ))"
else
  mem_used_pct="0"
fi

uptime_sec="$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)"
uptime_h="$(( uptime_sec / 3600 ))"
uptime_m="$(( (uptime_sec % 3600) / 60 ))"
uptime_fmt="${uptime_h}h ${uptime_m}m"

backend_host="${BACKEND_HOST:-10.142.59.129}"
backend_port="${BACKEND_PORT:-8080}"
use_system_notifications="${USE_SYSTEM_NOTIFICATIONS:-0}"
use_qml_popup_bridge="${USE_QML_POPUP_BRIDGE:-1}"
use_dbus_listener="${USE_DBUS_LISTENER:-1}"

if [[ "$use_qml_popup_bridge" == "1" ]]; then
  # Disable inline dashboard-embedded popup path and let the bridge spawn standalone popup-only windows.
  use_system_notifications="1"
  use_dbus_listener="1"
fi

bg_pids=()
bridge_started=0

register_bg_pid() {
  local pid="$1"
  if [[ -n "$pid" ]]; then
    bg_pids+=("$pid")
  fi
}

cleanup_bg() {
  local pid
  for pid in "${bg_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
}

trap cleanup_bg EXIT

launch_qml() {
  if command -v qml6 >/dev/null 2>&1; then
    qml6 "$QML_FILE" -- "${common_args[@]}"
    return $?
  fi

  if command -v qmlscene6 >/dev/null 2>&1; then
    qmlscene6 "$QML_FILE" -- "${common_args[@]}"
    return $?
  fi

  if command -v qmlscene >/dev/null 2>&1; then
    qmlscene "$QML_FILE" -- "${common_args[@]}"
    return $?
  fi

  if command -v qml >/dev/null 2>&1; then
    qml "$QML_FILE" -- "${common_args[@]}"
    return $?
  fi

  echo "Neither qmlscene nor qml was found. Install Qt declarative runtime first." >&2
  echo "Fedora: sudo dnf install -y qt6-qtdeclarative qt6-qtquickcontrols2" >&2
  echo "Arch: sudo pacman -S --noconfirm qt6-declarative qt6-5compat" >&2
  return 1
}

if [[ "$use_system_notifications" == "1" ]]; then
  if [[ "$use_qml_popup_bridge" == "1" ]]; then
    bridge_script="$ROOT_DIR/scripts/qml_popup_bridge.sh"
    if command -v bash >/dev/null 2>&1 && [[ -f "$bridge_script" ]]; then
      BACKEND_HOST="$backend_host" BACKEND_PORT="$backend_port" PRIME_ON_START=1 "$bridge_script" &
      bridge_pid=$!
      sleep 0.4
      if kill -0 "$bridge_pid" 2>/dev/null; then
        register_bg_pid "$bridge_pid"
        bridge_started=1
        echo "QML popup bridge: enabled (pid $bridge_pid)"
      else
        echo "QML popup bridge exited early; falling back to built-in QML popups" >&2
      fi
    else
      echo "QML popup bridge requested but bridge script not found" >&2
    fi
  else
    bridge_script="$ROOT_DIR/scripts/system_notification_bridge.sh"
    if command -v bash >/dev/null 2>&1 && [[ -f "$bridge_script" ]]; then
      BACKEND_HOST="$backend_host" BACKEND_PORT="$backend_port" PRIME_ON_START=1 "$bridge_script" &
      bridge_pid=$!
      sleep 0.4
      if kill -0 "$bridge_pid" 2>/dev/null; then
        register_bg_pid "$bridge_pid"
        bridge_started=1
        echo "System notifications: enabled via dunstify/notify-send bridge (pid $bridge_pid)"
      else
        echo "System notification bridge exited early; falling back to built-in QML popups" >&2
      fi
    else
      echo "System notifications requested but bridge script not found; continuing without bridge" >&2
    fi
  fi
fi

if [[ "$use_system_notifications" == "1" && "$bridge_started" == "0" ]]; then
  use_system_notifications="0"
fi

if [[ "$use_system_notifications" == "0" ]]; then
  echo "QML popups: enabled (QuickShell handles notifications)"
fi

common_args=(
  --sys-os "$os_name"
  --sys-kernel "$kernel_name"
  --sys-arch "$arch_name"
  --sys-desktop "$desktop_name"
  --sys-session "$session_type"
  --sys-load1 "$load_one"
  --sys-mem-used "$mem_used_pct"
  --sys-uptime "$uptime_fmt"
  --backend-host "$backend_host"
  --backend-port "$backend_port"
  --use-system-notifications "$use_system_notifications"
)

if [[ "$use_dbus_listener" == "1" ]]; then
  dbus_bridge_script="$ROOT_DIR/scripts/dbus_to_backend_bridge.sh"
  if command -v bash >/dev/null 2>&1 && [[ -f "$dbus_bridge_script" ]]; then
    BACKEND_HOST="$backend_host" BACKEND_PORT="$backend_port" "$dbus_bridge_script" &
    dbus_bridge_pid=$!
    register_bg_pid "$dbus_bridge_pid"
    echo "DBus listener bridge: enabled (pid $dbus_bridge_pid)"
  else
    echo "DBus listener bridge requested but script not found" >&2
  fi
fi

launch_qml
exit $?
