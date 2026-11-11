import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    readonly property var layoutDefinitions: [
        { code: "us", name: "Английская (США)" },
        { code: "gb", name: "Английская (Великобритания)" },
        { code: "latam", name: "Испанская (Латинская Америка)" },
        { code: "es", name: "Испанская (Испания)" },
        { code: "ara", name: "Арабская" },
        { code: "fr", name: "Французская (AZERTY)" },
        { code: "ca", name: "Французская (Канада)" },
        { code: "de", name: "Немецкая (QWERTZ)" },
        { code: "it", name: "Итальянская" },
        { code: "pt", name: "Португальская" },
        { code: "br", name: "Португальская (Бразилия)" },
        { code: "ru", name: "Русская" },
        { code: "ua", name: "Украинская" },
        { code: "tr", name: "Турецкая" },
        { code: "se", name: "Шведская" },
        { code: "no", name: "Норвежская" },
        { code: "dk", name: "Датская" },
        { code: "fi", name: "Финская" },
        { code: "cz", name: "Чешская" },
        { code: "gr", name: "Греческая" },
        { code: "il", name: "Иврит" }
    ]

    readonly property var layoutNameMap: {
        let map = {};
        for (let i = 0; i < layoutDefinitions.length; i++) {
            map[layoutDefinitions[i].code] = layoutDefinitions[i].name;
        }
        return map;
    }

    AppGroup {
        title: "Раскладки клавиатуры"
        icon: "keyboard"
        showDividers: false

        Repeater {
            model: SettingsService.enabledKbLayouts

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm

                SettingRowTemplate {
                    label: root.layoutNameMap[modelData] || modelData
                    description: index === 0 ? "Основная раскладка" : ("Раскладка" + (index + 1))

                    SvgIconButton {
                        icon: "trash"
                        visible: SettingsService.enabledKbLayouts.length > 1
                        onClicked: {
                            let layouts = [...SettingsService.enabledKbLayouts];
                            let idx = layouts.indexOf(modelData);
                            if (idx !== -1) {
                                layouts.splice(idx, 1);
                                SettingsService.enabledKbLayouts = layouts;
                            }
                        }
                    }
                }

                Divider {
                    Layout.fillWidth: true
                    visible: true
                }
            }
        }

        ThemedSelect {
            label: "Добавить раскладку"
            description: "Выберите язык"
            searchable: true
            comboWidth: 200
            model: ["—"].concat(root.layoutDefinitions.map(d => d.name))
            currentIndex: 0
            onActivated: (index) => {
                if (index === 0) return;

                let code = root.layoutDefinitions[index - 1].code;
                if (SettingsService.enabledKbLayouts.indexOf(code) === -1) {
                    let layouts = [...SettingsService.enabledKbLayouts];
                    layouts.push(code);
                    SettingsService.enabledKbLayouts = layouts;
                }

                currentIndex = Qt.binding(() => 0);
            }
        }
    }

    AppGroup {
        title: "Буфер обмена"
        icon: "clipboard"

        ThemedSelect {
            label: "Размер истории буфера"
            description: "Сколько записей хранить и показывать"
            model: ["25 записей", "50 записей", "100 записей", "200 записей", "500 записей"]
            currentIndex: {
                let items = SettingsService.clipboardMaxItems;
                if (items === 25)
                    return 0;

                if (items === 50)
                    return 1;

                if (items === 100)
                    return 2;

                if (items === 200)
                    return 3;

                if (items === 500)
                    return 4;

                return 1;
            }
            onActivated: (index) => {
                let vals = [25, 50, 100, 200, 500];
                SettingsService.clipboardMaxItems = vals[index];
            }
        }

    }

}
