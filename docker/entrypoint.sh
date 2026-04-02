#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${XDG_RUNTIME_DIR:-/tmp/runtime-appuser}" \
  "${XDG_RUNTIME_DIR:-/tmp/runtime-appuser}/pulse"
chmod 700 "${XDG_RUNTIME_DIR:-/tmp/runtime-appuser}" || true

host_runtime_dir="${HOST_XDG_RUNTIME_DIR:-/host-runtime}"

wayland_name="${WAYLAND_DISPLAY:-wayland-0}"
if [[ -S "${host_runtime_dir}/${wayland_name}" ]]; then
  ln -sf "${host_runtime_dir}/${wayland_name}" "${XDG_RUNTIME_DIR}/${wayland_name}"
  export WAYLAND_DISPLAY="${wayland_name}"
elif [[ -S "/mnt/wslg/runtime-dir/${wayland_name}" ]]; then
  ln -sf "/mnt/wslg/runtime-dir/${wayland_name}" "${XDG_RUNTIME_DIR}/${wayland_name}"
  export WAYLAND_DISPLAY="${wayland_name}"
elif [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  unset WAYLAND_DISPLAY
fi

if [[ -z "${PULSE_SERVER:-}" ]]; then
  if [[ -S "${host_runtime_dir}/pulse/native" ]]; then
    ln -sf "${host_runtime_dir}/pulse/native" "${XDG_RUNTIME_DIR}/pulse/native"
    export PULSE_SERVER="unix:${XDG_RUNTIME_DIR}/pulse/native"
  elif [[ -S "/mnt/wslg/PulseServer" ]]; then
    export PULSE_SERVER="unix:/mnt/wslg/PulseServer"
  fi
elif [[ "${PULSE_SERVER}" == unix:${XDG_RUNTIME_DIR}/pulse/native && -S "${host_runtime_dir}/pulse/native" ]]; then
  ln -sf "${host_runtime_dir}/pulse/native" "${XDG_RUNTIME_DIR}/pulse/native"
fi

if [[ -n "${PULSE_SERVER:-}" && "${PULSE_SERVER}" == unix:* ]]; then
  pulse_socket="${PULSE_SERVER#unix:}"
  if [[ ! -S "${pulse_socket}" ]]; then
    unset PULSE_SERVER
  fi
fi

if [[ "${MAX_USE_HOST_DBUS:-0}" == "1" && -n "${HOST_DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  export DBUS_SESSION_BUS_ADDRESS="${HOST_DBUS_SESSION_BUS_ADDRESS}"
  exec "$@"
fi

exec dbus-run-session -- bash -lc '
set -euo pipefail

# MAX expects a Secret Service on the session bus.
mkdir -p "$HOME/.cache/keyring" "$HOME/.local/share/keyrings"
eval "$(gnome-keyring-daemon --start --components=secrets)" >/dev/null

exec "$@"
' -- "$@"
