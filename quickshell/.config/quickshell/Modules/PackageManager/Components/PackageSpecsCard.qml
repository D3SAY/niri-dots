import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Card {
    id: specsRoot

    property var parsedInfo: ({
    })

    function getValue(key, defaultVal) {
        return (parsedInfo && parsedInfo[key] !== undefined) ? parsedInfo[key] : defaultVal;
    }

    function formatDate(str) {
        if (!str)
            return "-";

        let parts = str.trim().split(/\s+/);
        if (parts.length >= 4 && isNaN(parts[0]))
            return parts[1] + " " + parts[2] + " " + parts[3];

        return str;
    }

    Layout.fillWidth: true
    cardRadius: Constants.sizeSm
    useBorder: true
    borderColor: Theme.border
    backgroundColor: Theme.bgSecondary
    contentPadding: Constants.sizeLg

    ColumnLayout {
        id: specsCol

        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            spacing: Constants.sizeXs
            Layout.bottomMargin: Constants.size3Xs

            SvgIcon {
                icon: "tune"
                iconSize: Constants.sizeMd
                iconColor: Theme.muted
                flat: true
            }

            ThemedText {
                text: "ХАРАКТЕРИСТИКИ"
                font.bold: true
                font.letterSpacing: 0.8
                customSize: 10
                color: Theme.muted
            }

        }

        // Spec Rows
        Repeater {
            model: [{
                "key": "Версия",
                "val": specsRoot.getValue("Version", "")
            }, {
                "key": "Сопровождающий",
                "val": specsRoot.getValue("Maintainer", specsRoot.getValue("Packager", ""))
            }, {
                "key": "Лицензии",
                "val": specsRoot.getValue("Licenses", "")
            }, {
                "key": "Архитектура",
                "val": specsRoot.getValue("Architecture", "")
            }, {
                "key": "Размер загрузки",
                "val": specsRoot.getValue("Download Size", "")
            }, {
                "key": "Размер на диске",
                "val": specsRoot.getValue("Installed Size", "")
            }, {
                "key": "Установлен",
                "val": specsRoot.formatDate(specsRoot.getValue("Install Date", ""))
            }, {
                "key": "Собран",
                "val": specsRoot.formatDate(specsRoot.getValue("Build Date", ""))
            }, {
                "key": "Опубликован",
                "val": specsRoot.formatDate(specsRoot.getValue("First Submitted", ""))
            }, {
                "key": "Изменён",
                "val": specsRoot.formatDate(specsRoot.getValue("Last Modified", ""))
            }].filter((item) => {
                return item.val !== "" && item.val !== "None" && item.val !== "-";
            })

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm

                ThemedText {
                    text: modelData.key
                    color: Theme.muted
                    customSize: Constants.sizeSm
                    Layout.preferredWidth: 105
                }

                ThemedText {
                    text: modelData.val
                    color: Theme.fg
                    customSize: Constants.sizeSm
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignRight
                    font.bold: modelData.key === "Версия"
                }

            }

        }

        // AUR Community Stats (Votes & Popularity)
        RowLayout {
            Layout.fillWidth: true
            visible: specsRoot.parsedInfo["Votes"] !== undefined || specsRoot.parsedInfo["Popularity"] !== undefined
            spacing: Constants.sizeSm
            Layout.topMargin: Constants.size2Xs

            ThemedText {
                text: "Статистика AUR"
                color: Theme.muted
                customSize: Constants.sizeSm
                Layout.preferredWidth: 105
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm
                Layout.alignment: Qt.AlignRight

                Item {
                    Layout.fillWidth: true
                }

                // Votes
                RowLayout {
                    spacing: Constants.size2Xs
                    visible: specsRoot.parsedInfo["Votes"] !== undefined

                    SvgIcon {
                        icon: "star-filled"
                        iconSize: Constants.sizeSm
                        iconColor: Theme.accent
                        flat: true
                    }

                    ThemedText {
                        text: specsRoot.getValue("Votes", "0")
                        customSize: Constants.sizeSm
                        color: Theme.fg
                        font.bold: true
                    }

                }

                // Popularity
                ThemedText {
                    text: "• " + Number(specsRoot.getValue("Popularity", "0")).toFixed(2)
                    customSize: Constants.sizeSm
                    color: Theme.muted
                    visible: specsRoot.parsedInfo["Popularity"] !== undefined
                }

            }

        }

    }

}
