FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    dbus-x11 \
    gnome-keyring \
    gnupg \
    libasound2t64 \
    libgbm1 \
    libfontenc1 \
    libopengl0 \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libpulse0 \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-res0 \
    libxcb-render-util0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libxres1 \
    libsecret-1-0 \
    libxss1 \
    libpipewire-0.3-0t64 \
    xauth \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.max.ru/linux/deb/public.asc | gpg --dearmor -o /etc/apt/keyrings/max.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/max.gpg] https://download.max.ru/linux/deb stable main" > /etc/apt/sources.list.d/max.list && \
    apt-get update && \
    apt-get install -y max && \
    rm -rf /var/lib/apt/lists/*

RUN if getent passwd 1000 >/dev/null; then \
      existing_user="$(getent passwd 1000 | cut -d: -f1)"; \
      usermod -l appuser "${existing_user}" || true; \
      usermod -d /home/appuser -m appuser || true; \
      chsh -s /bin/bash appuser || true; \
    else \
      useradd -m -u 1000 -s /bin/bash appuser; \
    fi

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER appuser
WORKDIR /home/appuser

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["max"]
