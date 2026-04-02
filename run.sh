#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker не найден"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose не найден"
  exit 1
fi

display_value="${DISPLAY:-:0}"
wayland_value="${WAYLAND_DISPLAY:-}"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
pulse_value="${PULSE_SERVER:-}"
dbus_value="${DBUS_SESSION_BUS_ADDRESS:-}"

if [[ -d /mnt/wslg ]]; then
  if [[ -z "${wayland_value}" && -S "${runtime_dir%/}/wayland-0" ]]; then
    wayland_value="wayland-0"
  fi
fi

mkdir -p .docker

cat > .docker/max.env <<EOF
DISPLAY=${display_value}
WAYLAND_DISPLAY=${wayland_value}
XDG_RUNTIME_DIR=${runtime_dir}
PULSE_SERVER=${pulse_value}
DBUS_SESSION_BUS_ADDRESS=${dbus_value}
MAX_USE_HOST_DBUS=0
EOF

if command -v xhost >/dev/null 2>&1 && [[ -n "${display_value}" ]]; then
  xhost +SI:localuser:"$(whoami)" >/dev/null 2>&1 || true
fi

docker compose --env-file .docker/max.env up -d --build "$@"

echo
echo "MAX запущен. Логи: docker compose logs -f"
echo "Остановить: docker compose down"
