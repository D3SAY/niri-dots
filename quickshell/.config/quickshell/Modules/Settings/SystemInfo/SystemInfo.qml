import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    property string osName: SystemStats.osName
    property string hostModel: SystemStats.hostModel
    property string kernel: SystemStats.kernel
    property string hostname: SystemStats.hostname
    property string username: SystemStats.username
    property string shell: SystemStats.shell
    property string wm: SystemStats.wm
    property string packages: SystemStats.packages
    property string display: SystemStats.display
    property string cpuModel: SystemStats.cpuModel
    property string cpuCores: SystemStats.cpuCores
    property string memTotal: SystemStats.memTotal
    property string diskTotal: SystemStats.diskTotal
    property string gpuName: SystemStats.gpuName
    property string avatarMessage: ""

    FileDialog {
        id: avatarDialog
        title: "Выбрать аватар"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Изображения (*.png *.jpg *.jpeg *.webp *.gif *.bmp *.avif)", "Все файлы (*)"]
        onAccepted: {
            root.avatarMessage = "";
            saveAvatar.command = ["python3", Quickshell.shellDir + "/Scripts/system/set_avatar.py", selectedFile.toString()];
            saveAvatar.running = true;
        }
    }

    Process {
        id: saveAvatar
        stdout: StdioCollector { id: avatarOutput }
        stderr: StdioCollector { id: avatarError }
        onExited: function(code) {
            if (code === 0) {
                SystemStats.avatarRevision++;
                SystemStats.hasAvatar = true;
                root.avatarMessage = avatarOutput.text.trim() || "Аватар обновлён";
            } else {
                root.avatarMessage = avatarError.text.trim() || "Не удалось сохранить аватар";
            }
        }
    }

    // System Overview Hero Card
    Card {
        Layout.fillWidth: true
        contentPadding: Constants.sizeLg
        cardRadius: Constants.sizeSm
        useBorder: true

        RowLayout {
            spacing: Constants.sizeLg

            Item {
                Layout.preferredWidth: Constants.size5Xl
                Layout.preferredHeight: Constants.size5Xl

                AnimatedMinflair {
                    anchors.centerIn: parent
                    iconSize: Constants.size5Xl
                    visible: avatarPreview.status !== Image.Ready
                }

                Image {
                    id: avatarPreview
                    anchors.fill: parent
                    source: SystemStats.avatarSource
                    cache: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    layer.enabled: visible
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: avatarPreview.width
                            height: avatarPreview.height
                            radius: width / 2
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.size2Xs

                ThemedText {
                    text: root.username + "@" + root.hostname
                    font.weight: Font.Bold
                    customSize: 15
                    color: Theme.fg
                }

                ThemedText {
                    text: root.osName + (root.kernel !== "" ? (" (" + root.kernel + ")") : "")
                    customSize: 11
                    color: Theme.muted
                }

                ThemedText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.avatarMessage
                    customSize: 11
                    color: Theme.accent
                    wrapMode: Text.Wrap
                }

            }

            SvgIconButton {
                icon: "picture"
                textIcon: "Сменить аватар"
                textIconSize: 11
                useCustomWidth: true
                disabled: saveAvatar.running
                onClicked: avatarDialog.open()
            }

        }

    }

    AppGroup {
        title: "Сведения о системе"
        icon: "info"

        InfoRow {
            label: "Модель"
            value: root.hostModel
            visible: root.hostModel !== ""
        }

        InfoRow {
            label: "ОС"
            value: root.osName
        }

        InfoRow {
            label: "Ядро"
            value: root.kernel
        }

        InfoRow {
            label: "Окружение / WM"
            value: root.wm
        }

        InfoRow {
            label: "Оболочка"
            value: root.shell
        }

        InfoRow {
            label: "Пакеты"
            value: root.packages
        }

        InfoRow {
            label: "Экран"
            value: root.display
        }

    }

    AppGroup {
        title: "Железо"
        icon: "cpu"

        InfoRow {
            label: "Processor"
            value: root.cpuModel
        }

        InfoRow {
            label: "Ядра и потоки"
            value: root.cpuCores
        }

        InfoRow {
            label: "Оперативная память"
            value: root.memTotal
        }

        InfoRow {
            label: "Диск (/)"
            value: root.diskTotal
        }

        InfoRow {
            label: "Видеокарта"
            value: root.gpuName
            visible: root.gpuName !== "" && root.gpuName !== "None"
        }

    }

    AppGroup {
        title: "Обновления системы"
        icon: "update"

        SettingToggle {
            label: "Проверять обновления автоматически"
            checked: UpdateService.packageManagerChecksEnabled
            onCheckedChanged: UpdateService.packageManagerChecksEnabled = checked
        }

        ThemedSelect {
            enabled: UpdateService.packageManagerChecksEnabled
            opacity: enabled ? 1 : 0.5
            label: "Интервал проверки"
            description: "Как часто проверять обновления"
            model: ["1 час", "6 часов", "12 часов", "24 часа"]
            currentIndex: {
                let val = UpdateService.packageManagerCheckInterval;
                if (val === 3.6e+06)
                    return 0;

                if (val === 2.16e+07)
                    return 1;

                if (val === 4.32e+07)
                    return 2;

                if (val === 8.64e+07)
                    return 3;

                return 3;
            }
            onActivated: (index) => {
                let intervals = [3.6e+06, 2.16e+07, 4.32e+07, 8.64e+07];
                UpdateService.packageManagerCheckInterval = intervals[index];
            }
        }

    }

}
