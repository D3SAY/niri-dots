# niri-dots · Minflair

Конфигурация niri и Quickshell для Arch Linux и CachyOS. Панель меняет палитру вместе с обоями, а настройки, лаунчер, экран блокировки и медиаплеер используют одну тему. Интерфейс Minflair на русском, раскладки клавиатуры — US и RU.

Внутри есть лаунчер приложений, история буфера обмена, заметки, центр уведомлений, экран захвата, настройки автозапуска и аватара, а также синхронизированный текст песен в плеере и на экране блокировки.

## Быстрый старт

Нужны рабочая Arch-совместимая система с Wayland, пользовательская сессия systemd и PipeWire. Установи пакеты из репозиториев дистрибутива:

```bash
sudo pacman -S --needed git stow niri quickshell xwayland-satellite \
  qt6-5compat qt6-declarative qt6-imageformats qt6ct qt5ct \
  python-pam python-pillow python-gobject jq libnotify \
  awww hypridle polkit-gnome gnome-keyring \
  xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
  ghostty playerctl pamixer pavucontrol upower cava wlsunset brightnessctl \
  cliphist wl-clipboard grim slurp imagemagick ffmpeg wf-recorder pacman-contrib \
  papirus-icon-theme noto-fonts noto-fonts-emoji
```

Скачай или клонируй этот репозиторий в постоянную папку и открой её в терминале. Если у тебя уже есть свои конфиги niri, Quickshell или Ghostty, сохрани их в резервную копию. Stow останавливается при конфликте файлов.

```bash
stow --target="$HOME" --no-folding --simulate --verbose niri quickshell hypr ghostty
stow --target="$HOME" --no-folding niri quickshell hypr ghostty
niri validate
mkdir -p ~/Pictures/Wallpapers
```

Выбери **niri** в своём дисплейном менеджере или запусти `niri-session` из TTY. Первый запуск работает и без сгенерированных настроек темы. Положи свои изображения в `~/Pictures/Wallpapers` и выбери обои через **Ctrl+Alt+W**. При необходимости настрой общее оформление через **Super+,**.

Отключить конфиги можно из той же папки командой `stow --target="$HOME" --no-folding -D niri quickshell hypr ghostty`. Пользовательские настройки, созданные самим Minflair, сохраняются отдельно.

## Горячие клавиши

| Клавиши | Действие |
|---|---|
| **Super+/** | Шпаргалка горячих клавиш |
| **Alt+Space** | Лаунчер |
| **Super+,** | Настройки |
| **Super+Enter** | Ghostty |
| **Super+V** | История буфера обмена |
| **Ctrl+Alt+S / A / N / O** | Центр управления / дашборд / уведомления / заметки |
| **Ctrl+Alt+M** | Музыкальная панель, кнопка «Текст» раскрывает слова песни |
| **Ctrl+Alt+W** | Выбор обоев |
| **Print** | Меню захвата экрана |
| **Super+M** | Telegram, если установлен |
| **Super+I** | Блокировка экрана |
| **Super+Shift+I** | Сон |
| **Super+Shift+Q** | Меню питания |

Автозапуск находится в **Настройки → Управление → Автозапуск**. Изменения применяются при следующем входе. Аватар выбирается в **Настройки → О системе → Сменить аватар** и сохраняется в `~/.face`.

## Дополнительные модули

- **Текст песен.** Установи [Lyse](https://github.com/snoowfall/lyse) из AUR. Панель использует установленный `/usr/bin/lyse`; совместимость проверялась с `r17.39ddb35`. Для выбора активного плеера в терминальной версии установи обёртку командой `stow --target="$HOME" --no-folding lyse` и проверь, что `~/.local/bin` идёт перед `/usr/bin` в PATH. Поиск текста в Lyse может отправлять метаданные трека в LRCLIB.
- **Приложения.** `stow --target="$HOME" --no-folding gtk-theme fish fastfetch mpv swayimg loaf` подключает дополнительные конфиги. Устанавливай только нужные пакеты Stow. Для Fish нужны `fish starship lsd`, для MPV — `mpv` и плагины MPRIS/uosc по желанию. Для `loaf` нужен Loaf File Manager. Ярлыки Telegram, Zen, Vesktop, Steam и Spotify требуют соответствующих приложений.
- **Шрифты и курсор.** Дизайн использует Geist и Bibata Modern Classic; пакеты `otf-geist` и `bibata-cursor-theme-bin` доступны через AUR. Без них Qt и niri используют доступные системные варианты.
- **Железо.** niri подбирает режим вывода автоматически. Если нужно задать режим и расположение вручную, посмотри имена выходов через `niri msg outputs` и создай `~/.config/niri/outputs.local.kdl`. Номера шин внешних мониторов можно узнать через `ddcutil detect` и добавить свои команды в Fish.
- **Прокси Telegram.** Подключи пакет `tg-ws-proxy` через Stow, установи его исполняемый файл и задай `TG_WS_SECRET` в `~/.config/tg-ws-proxy/env`. Этот файл хранится только локально. Запуск службы — `systemctl --user enable --now tg-ws-proxy`.

## Системные интеграции

Обычной установке они не нужны. Каждая команда ниже выполняется из папки репозитория и меняет только выбранную интеграцию. Посмотреть варианты можно через `./system/install.sh --help`.

| Опция | Что делает |
|---|---|
| `--greetd` | Ставит оформленный экран входа с паролем. Сначала установи greetd. Службу включай отдельно, когда готов переключиться со своего дисплейного менеджера. |
| `--autologin` | Ставит тот же greeter и добавляет автоматический вход при загрузке с последующей блокировкой. Это осознанный opt-in для личной машины: рабочий стол запускается до ввода пароля. Проверь обычный вход и блокировку до включения. |
| `--network-helper` | Устанавливает помощник для VPN и Zapret. Операции используют обычную авторизацию polkit. VPN читает профили из `~/.config/awg` и требует `awg-quick`. |
| `--network-dns` | Переключает NetworkManager на resolvconf и перечитывает DNS. Только для систем с NetworkManager и openresolv. |
| `--zapret` | Устанавливает набор конфигураций для уже установленного Zapret2; сохраняет резервные копии заменяемых файлов. |
| `--virtual-camera` | Устанавливает конфигурацию для уже установленного модуля v4l2loopback. |

Пример установки только greeter: `sudo ./system/install.sh --greetd`. Исходный `/etc/greetd/config.toml` сохраняется с суффиксом `.pre-minflair`. Для возврата восстанови этот файл или отключи greetd и верни прежний дисплейный менеджер.

## Проверка и диагностика

- `niri validate` — проверка конфига после Stow. Отсутствующие необязательные файлы первого запуска могут появиться в предупреждениях.
- `qs list` и `qs log -t 80` — экземпляр Minflair и последние сообщения.
- Для теста блокировки сохрани работу, заблокируй экран, проверь отказ с неверным паролем и вход с паролем своего аккаунта.
- Скрипты запуска и проверки предполагают стандартные пути Arch. При конфликте с существующим конфигом сперва выполни пробный Stow с `--simulate --verbose`.

## Авторы и лицензии

Оболочка основана на [Minflair](https://github.com/t4lentles5/minflair). Текст GPL-3.0 находится в [LICENSE.minflair](quickshell/.config/quickshell/LICENSE.minflair). У темы Material-Gnome свой [файл лицензии](gtk-theme/.themes/Material-Gnome/LICENSE). Заметки вдохновлены [Whisp](https://github.com/tanaybhomia/Whisp); ссылки на источники сохранены в коде. Для остальных файлов отдельная лицензия репозитория пока не выбрана.
