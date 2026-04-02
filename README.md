# MAX в Docker

Этот каталог поднимает официальный Linux-клиент MAX в изолированном Docker-контейнере с GUI, звуком и отдельным writable home.

Основа установки берется из официального Linux-репозитория MAX:
- `https://download.max.ru/linux/deb`
- пакет `max`

## Что здесь есть

- `Dockerfile` - образ Ubuntu 24.04 с установленным `max`
- `compose.yaml` - запуск контейнера с урезанными правами
- `docker/entrypoint.sh` - локальная DBus-сессия внутри контейнера
- `run.sh` - удобный старт под обычный Linux и WSLg

## Быстрый старт

```bash
chmod +x run.sh
./run.sh
```

После запуска:

```bash
docker compose logs -f
docker compose down
```

## Что пробрасывается в контейнер

- X11 сокет `/tmp/.X11-unix`
- `~/.Xauthority` для X11
- Wayland-сокет, если он есть
- PulseAudio/PipeWire сокет для звука
- `/mnt/wslg`, если запуск идет в WSLg
- отдельный volume `max_home` для данных приложения

## Ограничения

- корневая ФС контейнера read-only
- добавлен `tmpfs` для `/tmp`, `/run`, `/var/tmp`, `/dev/shm`
- удалены все Linux capabilities через `cap_drop: ALL`
- включен `no-new-privileges:true`

## Если нужен доступ к камере

В `compose.yaml` можно вручную добавить устройство:

```yaml
devices:
  - /dev/video0:/dev/video0
```

## Если нужны уведомления через host DBus

По умолчанию контейнер стартует с собственной DBus-сессией. Это безопаснее, но некоторые desktop-интеграции могут быть ограничены.
