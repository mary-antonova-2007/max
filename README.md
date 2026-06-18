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

## Если пропадает курсор в окне MAX

В WSLg встречается баг, при котором курсор пропадает над Linux GUI окнами. Самый надежный workaround - перезапустить WSLg с Windows-стороны:

```powershell
wsl.exe --shutdown
```

После этого заново откройте Ubuntu/WSL и запустите:

```bash
./run.sh
```

Если нужно проверить X11/XWayland режим отдельно, можно запустить так:

```bash
MAX_DISPLAY_BACKEND=x11 QT_QPA_PLATFORM=xcb GDK_BACKEND=x11 ./run.sh
```

Но для MAX под WSLg штатный Wayland-режим обычно безопаснее: X11/XWayland может сделать проблему с курсором хуже.

## Что пробрасывается в контейнер

- X11 сокет `/tmp/.X11-unix`
- `~/.Xauthority` для X11
- Wayland-сокет, если он есть
- PulseAudio/PipeWire сокет для звука
- `/mnt/wslg`, если запуск идет в WSLg
- отдельный volume `max_home` для данных приложения
- папка проекта `./shared`, смонтированная в `/home/appuser/Downloads` для обмена файлами с MAX

## Обмен файлами с хостом

- Кладите файлы для отправки в `./shared/inbox`
- Внутри контейнера и в MAX эта папка доступна как `/home/appuser/Downloads`
- Для удобства можно использовать:
- `/home/appuser/Downloads/inbox` для файлов, которые хотите отправить из MAX
- `/home/appuser/Downloads/outbox` для файлов, которые сохраняете или скачиваете из MAX
- Всё из этих папок на хосте будет доступно в `./shared/inbox` и `./shared/outbox`

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
