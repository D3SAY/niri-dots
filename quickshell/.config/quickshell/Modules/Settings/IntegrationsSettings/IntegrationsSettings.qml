import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    AppGroup {
        title: "Приложения по умолчанию"
        icon: "star"

        ThemedSelect {
            id: playerSelect

            function syncIndex() {
                let current = SettingsService.musicPlayer;
                if (!current || current === "")
                    current = "none";

                let idx = model.indexOf(current);
                playerSelect.currentIndex = idx !== -1 ? idx : 0;
            }

            label: "Музыкальный плеер"
            description: "Для виджетов музыки"
            model: {
                let players = ["none"];
                for (let i = 0; i < MprisService.availablePlayers.length; i++) {
                    let p = MprisService.availablePlayers[i];
                    if (players.indexOf(p.id) === -1)
                        players.push(p.id);

                }
                if (SettingsService.musicPlayer && players.indexOf(SettingsService.musicPlayer) === -1 && SettingsService.musicPlayer !== "custom" && SettingsService.musicPlayer !== "none" && SettingsService.musicPlayer !== "")
                    players.push(SettingsService.musicPlayer);

                if (players.indexOf("custom") === -1)
                    players.push("custom");

                return players;
            }
            Component.onCompleted: syncIndex()
            onModelChanged: syncIndex()
            onActivated: (index) => {
                let player = model[index];
                if (player === "none") {
                    SettingsService.musicPlayer = "none";
                    SettingsService.musicPlayerCommand = "";
                } else {
                    SettingsService.musicPlayer = player;
                    if (player !== "custom") {
                        let playerObj = MprisService.getPlayerById(player);
                        if (playerObj)
                            SettingsService.musicPlayerCommand = playerObj.exec;
                        else
                            SettingsService.musicPlayerCommand = player;
                    }
                }
            }
            textMap: {
                let map = {
                    "none": "Нет"
                };
                for (let i = 0; i < MprisService.availablePlayers.length; i++) {
                    let p = MprisService.availablePlayers[i];
                    map[p.id] = p.name;
                }
                map["custom"] = "Своя команда";
                return map;
            }
            iconMap: {
                "spotify": "spotify",
                "youtube-music": "youtube",
                "mpd": "music",
                "kew": "music",
                "vlc": "music",
                "mpv": "music",
                "custom": "terminal"
            }

            Connections {
                function onMusicPlayerChanged() {
                    playerSelect.syncIndex();
                }

                target: SettingsService
            }

            Connections {
                function onAvailablePlayersChanged() {
                    playerSelect.syncIndex();
                }

                target: MprisService
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd
            visible: SettingsService.musicPlayer === "custom"

            ThemedTextField {
                Layout.fillWidth: true
                placeholderText: "Команда запуска плеера…"
                text: SettingsService.musicPlayerCommand
                onEditingFinished: {
                    SettingsService.musicPlayerCommand = text;
                }
            }

        }

    }

    AppGroup {
        title: "Цитаты"
        icon: "quote"

        ThemedSelect {
            label: "Категория цитат"
            description: "Для цитат на экране блокировки"
            model: QuoteService.categories
            textMap: ({
                "All": "Все",
                "Philosophy": "Философия",
                "Life": "Жизнь",
                "Programming": "Программирование",
                "Humor": "Юмор"
            })
            currentIndex: {
                let idx = model.indexOf(SettingsService.quoteCategory);
                return idx !== -1 ? idx : 0;
            }
            onActivated: (index) => {
                SettingsService.quoteCategory = model[index];
            }
        }

    }

}
