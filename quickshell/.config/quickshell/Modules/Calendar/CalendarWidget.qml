import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property real calendarWidth: 320
    readonly property bool isVisibleOnScreen: widget !== null && widget.isOpen !== undefined ? widget.isOpen : true
    readonly property var today: SystemInfoService.currentTime
    property int viewMonth: new Date().getMonth()
    property int viewYear: new Date().getFullYear()
    readonly property bool isCurrentMonth: viewMonth === today.getMonth() && viewYear === today.getFullYear()
    // a clicked day: the line under the grid says how far it is from today; clicking it again clears it
    property var selectedDate: null
    readonly property int selectedOffset: selectedDate ? daysFromToday(selectedDate) : 0

    // whole calendar days, so DST shifts and the time of day don't matter
    function daysFromToday(date) {
        const a = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
        const b = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
        return Math.round((b - a) / 86400000);
    }

    function offsetText(n) {
        if (n === 0)
            return "Сегодня";

        if (n === 1)
            return "Завтра";

        if (n === -1)
            return "Вчера";

        const k = Math.abs(n), t = k % 100, o = k % 10;
        const days = k + ((t >= 11 && t <= 14) ? " дней" : (o === 1 ? " день" : (o >= 2 && o <= 4 ? " дня" : " дней")));
        return n > 0 ? "Через " + days : days + " назад";
    }

    function shiftMonth(delta) {
        let m = viewMonth + delta;
        let y = viewYear;
        while (m < 0) {
            m += 12;
            y--;
        }
        while (m > 11) {
            m -= 12;
            y++;
        }
        viewMonth = m;
        viewYear = y;
    }

    function goToToday() {
        const d = new Date();
        viewMonth = d.getMonth();
        viewYear = d.getFullYear();
    }

    onIsVisibleOnScreenChanged: {
        if (!isVisibleOnScreen) {
            goToToday();
            selectedDate = null;
        }

    }
    implicitWidth: calendarWidth
    implicitHeight: mainColumn.implicitHeight
    width: implicitWidth
    height: implicitHeight

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1);
        }
    }

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Constants.sizeMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            Rectangle {
                id: prevBtn

                Layout.preferredWidth: Constants.size2Xl
                Layout.preferredHeight: Constants.size2Xl
                radius: Constants.sizeSm
                color: prevArea.containsMouse ? Theme.bgSecondary : "transparent"

                ThemedText {
                    anchors.centerIn: parent
                    text: "‹"
                    font.bold: true
                    customSize: Constants.sizeMd
                }

                MouseArea {
                    id: prevArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(-1)
                }

            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Constants.size2Xl

                ThemedText {
                    anchors.centerIn: parent
                    text: {
                        const m = Constants.locale.standaloneMonthName(root.viewMonth);
                        return m.charAt(0).toUpperCase() + m.slice(1) + " " + root.viewYear;
                    }
                    font.bold: true
                    customSize: Constants.sizeMd
                    color: root.isCurrentMonth ? Theme.fg : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: root.isCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !root.isCurrentMonth
                    onClicked: root.goToToday()
                }

            }

            Rectangle {
                id: nextBtn

                Layout.preferredWidth: Constants.size2Xl
                Layout.preferredHeight: Constants.size2Xl
                radius: Constants.sizeSm
                color: nextArea.containsMouse ? Theme.bgSecondary : "transparent"

                ThemedText {
                    anchors.centerIn: parent
                    text: "›"
                    font.bold: true
                    customSize: Constants.sizeMd
                }

                MouseArea {
                    id: nextArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(1)
                }

            }

        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: Constants.locale

            delegate: ThemedText {
                text: model.shortName
                horizontalAlignment: Text.AlignHCenter
                customSize: Constants.sizeXs + 2
                color: Theme.muted
            }

        }

        MonthGrid {
            id: grid

            Layout.fillWidth: true
            month: root.viewMonth
            year: root.viewYear
            locale: Constants.locale

            delegate: Item {
                id: cell

                readonly property bool inMonth: model.month === root.viewMonth
                readonly property bool isToday: model.day === root.today.getDate() && model.month === root.today.getMonth() && model.year === root.today.getFullYear()
                readonly property bool isSelected: root.selectedDate !== null && model.day === root.selectedDate.getDate() && model.month === root.selectedDate.getMonth() && model.year === root.selectedDate.getFullYear()

                implicitWidth: 40
                implicitHeight: 36

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: width / 2
                    color: cell.isToday ? Theme.accent : (cell.isSelected ? Theme.bgAccent : (cellArea.containsMouse && cell.inMonth ? Theme.bgSecondary : "transparent"))
                    border.width: cell.isSelected ? 1.5 : 0
                    border.color: Theme.accent
                }

                ThemedText {
                    anchors.centerIn: parent
                    text: model.day
                    customSize: Constants.sizeSm
                    font.bold: cell.isToday
                    opacity: cell.inMonth ? 1 : 0.3
                    color: cell.isToday ? Theme.bg : Theme.fg
                }

                MouseArea {
                    id: cellArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedDate = cell.isSelected ? null : new Date(model.year, model.month, model.day)
                }

            }

        }

        // how far the clicked day is from today
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.selectedDate ? implicitHeight : 0
            visible: root.selectedDate !== null
            spacing: Constants.sizeXs

            ThemedText {
                text: root.selectedDate ? root.offsetText(root.selectedOffset) : ""
                customSize: Constants.sizeSm
                font.bold: true
                color: Theme.accent
            }

            ThemedText {
                Layout.fillWidth: true
                text: root.selectedDate ? root.selectedDate.toLocaleDateString(Constants.locale, "ddd, d MMMM yyyy") : ""
                customSize: Constants.sizeSm
                color: Theme.muted
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }

        }

    }

}
