#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNP_HOME="${HOME}/.local/share/snp"
SNP_BIN="${SNP_HOME}/bin"
SNP_CFG="${SNP_HOME}/config"
SNP_STATE="${SNP_HOME}/state"
SNP_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/snp"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"

log() {
  printf '[snp-install] %s\n' "$*"
}

warn() {
  printf '[snp-install][warn] %s\n' "$*" >&2
}

detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

preflight_tools() {
  local missing=0
  local tools=(systemctl mkdir cp chmod)
  for t in "${tools[@]}"; do
    if ! command -v "$t" >/dev/null 2>&1; then
      warn "Missing required tool: $t"
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    warn "Install missing tools and rerun."
    exit 1
  fi
}

print_dependency_hint() {
  local distro
  distro="$(detect_distro)"

  case "$distro" in
    fedora)
      log "Fedora detected. Install dependencies with:"
      echo "sudo dnf update -y"
      echo "sudo dnf install -y git curl jq python3 python3-pip python3-virtualenv go dbus-tools pipewire pipewire-utils"
      ;;
    arch)
      log "Arch detected. Install dependencies with:"
      echo "sudo pacman -Syu --noconfirm"
      echo "sudo pacman -S --noconfirm git curl jq python python-pip python-virtualenv go dbus pipewire wireplumber"
      ;;
    *)
      warn "Unknown distro. Install dependencies manually."
      ;;
  esac
}

setup_dirs() {
  mkdir -p "$SNP_BIN" "$SNP_CFG" "$SNP_STATE" "$SNP_RUNTIME" "$USER_SYSTEMD_DIR"
  chmod 700 "$SNP_HOME" "$SNP_RUNTIME"
  log "Created runtime directories."
}

install_templates() {
  cp "$ROOT_DIR/deploy/systemd/user/snp-backend.service" "$USER_SYSTEMD_DIR/"
  cp "$ROOT_DIR/deploy/systemd/user/snp-ai.service" "$USER_SYSTEMD_DIR/"
  cp "$ROOT_DIR/deploy/systemd/user/snp-dbus-bridge.service" "$USER_SYSTEMD_DIR/"

  cp "$ROOT_DIR/platform/linux/dbus-bridge/config.example.yaml" "$SNP_CFG/dbus-bridge.yaml"
  log "Installed systemd unit templates and config."
}

check_placeholder_binaries() {
  local ok=1
  local expected=(
    "$SNP_BIN/snp-backend"
    "$SNP_BIN/snp-dbus-bridge"
    "$SNP_HOME/venv/bin/python"
    "$SNP_HOME/ai/main.py"
  )

  for f in "${expected[@]}"; do
    if [ ! -e "$f" ]; then
      warn "Missing runtime artifact: $f"
      ok=0
    fi
  done

  if [ "$ok" -eq 0 ]; then
    warn "Services may fail to start until runtime artifacts are installed."
  fi
}

disable_conflicting_notifiers() {
  local services=(mako dunst swaync xfce4-notifyd)
  for svc in "${services[@]}"; do
    systemctl --user stop "${svc}.service" 2>/dev/null || true
    systemctl --user disable "${svc}.service" 2>/dev/null || true
  done

  pkill -f mako 2>/dev/null || true
  pkill -f dunst 2>/dev/null || true
  pkill -f swaync 2>/dev/null || true
  pkill -f xfce4-notifyd 2>/dev/null || true

  log "Stopped/disabled common conflicting notification daemons."
}

enable_services() {
  systemctl --user daemon-reload
  systemctl --user enable --now snp-backend.service || true
  systemctl --user enable --now snp-ai.service || true
  systemctl --user enable --now snp-dbus-bridge.service || true

  log "Service status summary:"
  systemctl --user --no-pager --full status snp-backend.service || true
  systemctl --user --no-pager --full status snp-ai.service || true
  systemctl --user --no-pager --full status snp-dbus-bridge.service || true
}

main() {
  preflight_tools
  print_dependency_hint
  setup_dirs
  install_templates
  check_placeholder_binaries
  disable_conflicting_notifiers
  enable_services
  log "Install flow complete."
}

main "$@"
