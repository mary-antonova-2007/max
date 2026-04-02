#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

container_name="max-isolated"

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
qt_platform_value="${QT_QPA_PLATFORM:-}"

if [[ -d /mnt/wslg ]]; then
  if [[ -z "${wayland_value}" && -S "${runtime_dir%/}/wayland-0" ]]; then
    wayland_value="wayland-0"
  fi
  if [[ -z "${qt_platform_value}" ]]; then
    qt_platform_value="wayland;xcb"
  fi
elif [[ -z "${qt_platform_value}" ]]; then
  qt_platform_value="xcb"
fi

mkdir -p .docker

cat > .docker/max.env <<EOF
DISPLAY=${display_value}
WAYLAND_DISPLAY=${wayland_value}
XDG_RUNTIME_DIR=${runtime_dir}
PULSE_SERVER=${pulse_value}
DBUS_SESSION_BUS_ADDRESS=${dbus_value}
MAX_USE_HOST_DBUS=0
QT_QPA_PLATFORM=${qt_platform_value}
EOF

if command -v xhost >/dev/null 2>&1 && [[ -n "${display_value}" ]]; then
  xhost +SI:localuser:"$(whoami)" >/dev/null 2>&1 || true
fi

docker compose --env-file .docker/max.env up -d --build "$@"

echo "Жду запуск MAX..."

for _ in $(seq 1 30); do
  status="$(docker inspect "${container_name}" --format '{{.State.Status}}' 2>/dev/null || true)"
  if [[ "${status}" == "running" ]]; then
    break
  fi
  sleep 1
done

status="$(docker inspect "${container_name}" --format '{{.State.Status}}' 2>/dev/null || true)"
if [[ "${status}" != "running" ]]; then
  echo
  echo "Контейнер не перешел в состояние running. Последние логи:"
  docker compose logs --tail=80
  exit 1
fi

if ! docker exec "${container_name}" bash -lc 'ps -ef | grep -q "[/]usr/share/max/bin/crashpad_handler" && ps -ef | grep -q "[[:space:]]max$"'; then
  echo
  echo "MAX внутри контейнера не выглядит полностью запущенным. Последние логи:"
  docker compose logs --tail=80
  exit 1
fi

echo
echo "GUI окружение внутри контейнера:"
docker exec "${container_name}" bash -lc 'printf "DISPLAY=%s\nWAYLAND_DISPLAY=%s\nQT_QPA_PLATFORM=%s\n" "$DISPLAY" "${WAYLAND_DISPLAY:-}" "${QT_QPA_PLATFORM:-}"; ls -l /tmp/runtime-appuser 2>/dev/null || true'

echo
echo "MAX запущен. Окно должно появиться автоматически."
echo "Если окно не появилось, проверь: docker compose logs -f"
echo "Остановить: docker compose down"
