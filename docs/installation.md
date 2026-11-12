# Установка Minflair как на моём Arch

Здесь весь путь от базовой установки до моего рабочего стола с панелью Convex, темой из обоев, Spotify, текстами песен и покемоном в Ghostty. Для первого запуска достаточно первых двух шагов. Остальное можно подключать по частям.

[Быстрый старт](../README.md#быстрый-старт) · [Все функции, горячие клавиши и видео](features.md)

## 1. Установи базовый райс

Нужна уже установленная система Arch Linux или CachyOS с systemd, PipeWire и рабочим доступом к `sudo`. Сохрани репозиторий в постоянной папке, потому что Stow создаёт ссылки на файлы внутри неё.

```bash
sudo pacman -S --needed git
git clone https://github.com/D3SAY/niri-dots.git ~/niri-dots
cd ~/niri-dots
./install.sh --dry-run
./install.sh
```

Установщик поставит недостающие зависимости, подключит конфиги niri, Quickshell, hypridle, Ghostty и Fastfetch, создаст папку для обоев и проверит niri. Если GNU Stow ещё отсутствует, первый `--dry-run` покажет зависимости. Проверка конфликтов станет доступна после установки Stow.

При конфликте сохрани существующий файл по пути, который указал Stow. Например, если конфликтует `~/.config/niri/config.kdl`:

```bash
backup=$(mktemp -d "$HOME/minflair-backup.XXXXXXXX")
mv -- "$HOME/.config/niri/config.kdl" "$backup/"
./install.sh --dry-run
./install.sh
```

Если конфликтует несколько путей, перенеси каждый в резервную копию, сохранив его относительный путь. Для подключения конфигов при уже установленных пакетах есть `./install.sh --configs-only`.

## 2. Войди в niri и настрой внешний вид

Выйди из текущей сессии и выбери **niri** на экране входа. Если пользуешься TTY, выполни `niri-session` от своего пользователя. Открой Ghostty через **Super+Enter** и настройки через **Super+,**.

1. Положи изображение в `~/Pictures/Wallpapers`, открой выбор обоев через **Ctrl+Alt+W** и выбери его. В **Оформление** включи **Цвета из обоев** и тёмную тему. Палитра будет зависеть от выбранного изображения.
2. Установи пакеты `otf-geist` и `bibata-cursor-theme-bin` из AUR. В **Оформление** выбери **Geist** и масштаб шрифтов **1,00×**. В **Мышь и тачпад** выбери **Bibata-Modern-Classic** и размер **16**.
3. В **Панель** выбери **Convex**, **10** рабочих столов и 24-часовой формат с датой. **Island** включается там же. **Gaming** включается в центре управления через **Ctrl+Alt+S**.
4. В **Окна и экран** поставь скругление **8** и отступы **10**. В **Эффекты** оставь скорость анимаций **1×**, непрозрачность **100%** и включи тени. В **Клавиатура и буфер** оставь раскладки **US** и **RU**.
5. В **О системе** загрузи свой аватар. В **Автозапуске** добавь нужные приложения. Текущие настройки, аватар и обои сохраняются в твоём домашнем каталоге.

### Мониторы

На моём ПК основной монитор работает в режиме **2560×1440 при 144 Гц**. На другом ПК niri сам подберёт режим. Чтобы задать его вручную, выполни `niri msg outputs` из сессии niri и возьми оттуда имя выхода и поддерживаемый режим. Пример моего `~/.config/niri/outputs.local.kdl`:

```kdl
output "DP-2" {
    mode "2560x1440@143.999"
    position x=0 y=0
}
```

После правки выполни `niri validate`. Файлы `colors.kdl`, `minflair.kdl` и `cursor.kdl` генерирует оболочка при применении настроек.

## 3. Подключи приложения и тексты песен

Базовые ярлыки уже настроены. Чтобы они открывали те же приложения, установи нужные пакеты:

| Клавиши | Приложение и пакет |
|---|---|
| **Super+E** | Loaf (`loaf-fm`) |
| **Super+M** | Telegram (`telegram-desktop`) |
| **Super+D** | Vesktop (`vesktop-bin`) |
| **Super+B** | Zen (`zen-browser-bin`) |
| **Super+S** | Spotify (`spotify-launcher`) |
| **Super+G** | Steam (`steam`, на Arch может понадобиться репозиторий multilib) |
| **Super+Shift+T** | NormCap (`normcap`) |

Мои дополнительные конфиги для GTK, Fish, MPV, Swayimg и Loaf можно подключить вместе. Сначала установи приложения, которыми будешь пользоваться. Для Fish у меня также стоят `starship` и `lsd`. Для MPV я использую `mpv-mpris`, `mpv-uosc` и `mpv-thumbfast-git`.

```bash
cd ~/niri-dots
stow --target="$HOME" --no-folding --simulate --verbose gtk-theme fish mpv swayimg loaf
stow --target="$HOME" --no-folding gtk-theme fish mpv swayimg loaf
```

Для текстов песен установи [Lyse](https://github.com/snoowfall/lyse) из AUR и проверь `/usr/bin/lyse --help`. В **Настройки → Интеграции → Музыкальный плеер** я выбираю **Spotify**. Запусти трек, открой плеер через **Ctrl+Alt+M** и нажми **Текст**. Если у песни есть синхронизированный текст, текущая строка также появится на экране блокировки. Для Lyse в терминале подключи обёртку и проверь, что `~/.local/bin` стоит в PATH перед `/usr/bin`.

```bash
./install.sh --configs-only --lyse
```

## 4. Настрой Ghostty и покемона

Ghostty использует палитру Minflair, размер шрифта **10** и прозрачность фона **85%**. Fastfetch уже показывает звезду Minflair, русские подписи и возраст установки Arch. Запусти его командой `fastfetch`.

Для случайного покемона при открытии терминала установи [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts), например пакет `pokemon-colorscripts-git` из AUR. В моей сессии Ghostty запускает Bash. Добавь в конец `~/.bashrc` один раз:

```bash
if [[ $- == *i* && -t 1 && ${TERM:-dumb} != dumb ]] && command -v pokemon-colorscripts >/dev/null; then
    pokemon-colorscripts --random
fi
```

Открой новую вкладку Ghostty, чтобы проверить. Если Ghostty запускает Fish, соответствующую команду добавь в `~/.config/fish/conf.d/pokemon.fish`:

```fish
if status is-interactive; and isatty stdout; and type -q pokemon-colorscripts
    pokemon-colorscripts --random
end
```

## 5. Подключи системные интеграции при необходимости

На моём ПК включены greetd и вход при загрузке с последующей блокировкой. На новом компьютере сначала проверь обычный вход в niri. Сохрани работу и нажми **Super+I**. Проверь, что неверный пароль отклоняется, а пароль твоей учётной записи разблокирует экран.

Чтобы поставить экран входа Minflair с паролем, установи `greetd` и из папки репозитория выполни:

```bash
sudo pacman -S --needed greetd
sudo ./system/install.sh --greetd
```

Когда готов переключиться на greetd, отключи прежний дисплейный менеджер и включи `greetd.service` через `sudo systemctl enable greetd.service`. Для поведения как на моём ПК выполни `sudo ./system/install.sh --autologin`. Этот режим запускает рабочий стол при загрузке до ввода пароля и затем блокирует его. Для возврата к экрану входа с паролем снова выполни `sudo ./system/install.sh --greetd`.

| Интеграция | Как подключить |
|---|---|
| VPN | Установи `awg-quick`, положи свои профили в `~/.config/awg` и выполни `sudo ./system/install.sh --network-helper`. Панель открывается через **Ctrl+Alt+V**. Действия подтверждаются через polkit. |
| DNS через openresolv | Если у тебя NetworkManager и установлен `openresolv`, опция `sudo ./system/install.sh --network-dns` переключает обработку DNS. |
| Zapret2 | Если уже пользуешься Zapret2, примени комплект конфигов командой `sudo ./system/install.sh --zapret`. |
| Виртуальная камера OBS | Установи v4l2loopback и заголовки своего ядра. Выполни `sudo ./system/install.sh --virtual-camera` и перезагрузись. |
| Прокси Telegram | Установи `tg-ws-proxy-cli`, подключи пакет Stow `tg-ws-proxy`, укажи собственный `TG_WS_SECRET` в `~/.config/tg-ws-proxy/env` с правами `600` и запусти `systemctl --user enable --now tg-ws-proxy.service`. |

## Проверка и возврат

- `niri validate` проверяет конфигурацию. При первом запуске предупреждения о сгенерированных необязательных файлах ожидаемы.
- `qs list` показывает запущенную оболочку, `qs log -t 80` выводит её журнал.
- `./install.sh --uninstall` удаляет ссылки базовых конфигов. Если подключал тему или обёртку через установщик, добавь `--gtk-theme` или `--lyse`. Остальные пакеты отключаются командой `stow --target="$HOME" --no-folding -D` с их именами.
- После удаления ссылок верни свои конфиги из резервной копии. Для возврата прежнего экрана входа сначала переключись в TTY, затем отключи greetd и снова включи прежний дисплейный менеджер. Резервная копия существовавшего до установки `/etc/greetd/config.toml` сохраняется как `/etc/greetd/config.toml.pre-minflair`.
