#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

container_name="max-isolated"
compose_cmd=()

if ! command -v docker >/dev/null 2>&1; then
  echo "docker не найден"
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  compose_cmd=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  compose_cmd=(docker-compose)
else
  echo "docker compose не найден"
  echo "Установи Docker Compose plugin или docker-compose."
  exit 1
fi

display_value="${DISPLAY:-:0}"
wayland_value="${WAYLAND_DISPLAY:-}"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
pulse_value="${PULSE_SERVER:-}"
dbus_value="${DBUS_SESSION_BUS_ADDRESS:-}"
qt_platform_value="${QT_QPA_PLATFORM:-}"
display_backend="${MAX_DISPLAY_BACKEND:-}"
gdk_backend_value="${GDK_BACKEND:-}"
xdg_session_type_value="${XDG_SESSION_TYPE:-}"
xcursor_theme_value="${XCURSOR_THEME:-}"
xcursor_size_value="${XCURSOR_SIZE:-}"
qtwebengine_flags_value="${QTWEBENGINE_CHROMIUM_FLAGS:-}"
timezone_value="${TZ:-Etc/GMT-3}"

if [[ -d /mnt/wslg ]]; then
  if [[ -z "${display_backend}" ]]; then
    display_backend="auto"
  fi
  if [[ -z "${wayland_value}" && -S "${runtime_dir%/}/wayland-0" ]]; then
    wayland_value="wayland-0"
  fi
  if [[ -z "${qt_platform_value}" ]]; then
    qt_platform_value="wayland;xcb"
  fi
elif [[ -z "${qt_platform_value}" ]]; then
  if [[ -z "${display_backend}" ]]; then
    display_backend="x11"
  fi
  qt_platform_value="xcb"
fi

if [[ "${display_backend}" == "x11" ]]; then
  wayland_value=""
  qt_platform_value="${QT_QPA_PLATFORM:-xcb}"
  gdk_backend_value="${GDK_BACKEND:-x11}"
  xdg_session_type_value="${XDG_SESSION_TYPE:-x11}"
fi

mkdir -p .docker

cat > .docker/max.env <<EOF
DISPLAY=${display_value}
WAYLAND_DISPLAY=${wayland_value}
XDG_RUNTIME_DIR=${runtime_dir}
PULSE_SERVER=${pulse_value}
DBUS_SESSION_BUS_ADDRESS=${dbus_value}
MAX_USE_HOST_DBUS=0
MAX_DISPLAY_BACKEND=${display_backend}
QT_QPA_PLATFORM=${qt_platform_value}
GDK_BACKEND=${gdk_backend_value}
XDG_SESSION_TYPE=${xdg_session_type_value}
XCURSOR_THEME=${xcursor_theme_value}
XCURSOR_SIZE=${xcursor_size_value}
QTWEBENGINE_CHROMIUM_FLAGS=${qtwebengine_flags_value}
TZ=${timezone_value}
EOF

if command -v xhost >/dev/null 2>&1 && [[ -n "${display_value}" ]]; then
  xhost +SI:localuser:"$(whoami)" >/dev/null 2>&1 || true
fi

"${compose_cmd[@]}" --env-file .docker/max.env up -d --build "$@"

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
  "${compose_cmd[@]}" logs --tail=80
  exit 1
fi

if ! docker exec "${container_name}" bash -lc 'ps -ef | grep -q "[/]usr/share/max/bin/crashpad_handler" && ps -ef | grep -q "[[:space:]]max$"'; then
  echo
  echo "MAX внутри контейнера не выглядит полностью запущенным. Последние логи:"
  "${compose_cmd[@]}" logs --tail=80
  exit 1
fi

echo
echo "GUI окружение процесса MAX:"
docker exec "${container_name}" bash -lc '
pid="$(pgrep -xo max || true)"
if [[ -n "${pid}" ]]; then
  tr "\0" "\n" < "/proc/${pid}/environ" | sort | grep -E "^(DISPLAY|WAYLAND_DISPLAY|MAX_DISPLAY_BACKEND|QT_QPA_PLATFORM|GDK_BACKEND|XDG_SESSION_TYPE|XCURSOR_THEME|XCURSOR_SIZE|QTWEBENGINE_CHROMIUM_FLAGS|TZ)=" || true
fi
ls -l /tmp/runtime-appuser 2>/dev/null || true
'

echo
echo "MAX запущен. Окно должно появиться автоматически."
echo "Если окно не появилось, проверь: ${compose_cmd[*]} logs -f"
echo "Остановить: ${compose_cmd[*]} down"
