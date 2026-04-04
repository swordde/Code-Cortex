#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML_FILE="$ROOT_DIR/platform/linux/quickshell/main.qml"

if command -v qml6 >/dev/null 2>&1; then
  exec qml6 "$QML_FILE"
fi

if command -v qmlscene6 >/dev/null 2>&1; then
  exec qmlscene6 "$QML_FILE"
fi

if command -v qmlscene >/dev/null 2>&1; then
  exec qmlscene "$QML_FILE"
fi

if command -v qml >/dev/null 2>&1; then
  exec qml "$QML_FILE"
fi

echo "Neither qmlscene nor qml was found. Install Qt declarative runtime first." >&2
echo "Fedora: sudo dnf install -y qt6-qtdeclarative qt6-qtquickcontrols2" >&2
echo "Arch: sudo pacman -S --noconfirm qt6-declarative qt6-5compat" >&2
exit 1
