#!/usr/bin/env bash
set -euo pipefail

export GDK_BACKEND="${MAX_SERVICE_GDK_BACKEND:-wayland,x11}"
export XDG_SESSION_TYPE="${MAX_SERVICE_XDG_SESSION_TYPE:-wayland}"

exec /usr/share/max/bin/max-service/bin/max-service.real "$@"
