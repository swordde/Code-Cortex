import QtQuick 2.15
import QtQuick.Layouts 1.15
import "PopupTheme.js" as PopupTheme

Rectangle {
    id: dashboard

    property string stylePreset: "projectCore"
    readonly property real fontScale: 1.25
    property int emergencyCount: 0
    property int highCount: 0
    property int mediumCount: 0
    property int lowCount: 0
    property int totalCount: 0
    property int needingAttention: 0
    property real focusPercent: 0.0
    property bool cortexModeEnabled: true
    property bool voicePlaying: false
    property real voiceProgress: 0.55
    property string systemOsName: "Linux"
    property string systemKernel: "unknown"
    property string systemArch: "unknown"
    property string systemDesktop: "unknown"
    property string systemSession: "unknown"
    property real systemLoadOne: 0.0
    property int systemMemUsedPercent: 0
    property string systemUptime: "0h 0m"
    property bool cortexAutoReplyEnabled: true
    property bool cortexScheduleEnabled: true
    property bool cortexSafeModeEnabled: false
    property string customActiveContext: ""
    property bool customContactsEnabled: true
    property bool customKeywordsEnabled: true
    property bool customAppPriorityEnabled: true
    property var customModes: []
    property var selectedCalendarDate: new Date()
    property var displayedMonthStart: new Date((new Date()).getFullYear(), (new Date()).getMonth(), 1)
    readonly property var runtimeLogs: [
        "Kernel check: " + systemKernel,
        "Session: " + systemSession + " on " + systemDesktop,
        "Load " + systemLoadOne.toFixed(2) + " | RAM " + systemMemUsedPercent + "%",
        "Uptime " + systemUptime + " | Status: " + runtimeHealthText()
    ]

    signal presetSelected(string preset)
    signal navigateToRoute(string route)
    signal customModesUpdated(var modes, string activeContext)

    function runtimeHealthText() {
        if (systemMemUsedPercent >= 85 || systemLoadOne >= 4.0) return "High strain"
        if (systemMemUsedPercent >= 65 || systemLoadOne >= 2.0) return "Moderate load"
        return "Running smooth"
    }

    function runtimeHealthColor() {
        if (systemMemUsedPercent >= 85 || systemLoadOne >= 4.0) return "#BD3124"
        if (systemMemUsedPercent >= 65 || systemLoadOne >= 2.0) return "#B56D00"
        return "#2E7D7D"
    }

    function ordinalDate(dayNumber) {
        var mod100 = dayNumber % 100
        if (mod100 >= 11 && mod100 <= 13) return dayNumber + "th"
        var mod10 = dayNumber % 10
        if (mod10 === 1) return dayNumber + "st"
        if (mod10 === 2) return dayNumber + "nd"
        if (mod10 === 3) return dayNumber + "rd"
        return dayNumber + "th"
    }

    function daysInMonth(yearValue, monthValue) {
        return new Date(yearValue, monthValue + 1, 0).getDate()
    }

    function monthGridOffset(yearValue, monthValue) {
        return new Date(yearValue, monthValue, 1).getDay()
    }

    function calendarCellDate(index) {
        var y = displayedMonthStart.getFullYear()
        var m = displayedMonthStart.getMonth()
        var startOffset = monthGridOffset(y, m)
        var dayNumber = index - startOffset + 1

        if (dayNumber < 1) {
            var prevMonth = m - 1
            var prevYear = y
            if (prevMonth < 0) {
                prevMonth = 11
                prevYear = y - 1
            }
            var prevDays = daysInMonth(prevYear, prevMonth)
            return new Date(prevYear, prevMonth, prevDays + dayNumber)
        }

        var currentDays = daysInMonth(y, m)
        if (dayNumber > currentDays) {
            return new Date(y, m + 1, dayNumber - currentDays)
        }

        return new Date(y, m, dayNumber)
    }

    function isSameDate(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
    }

    function calendarMonthTitle() {
        return Qt.formatDate(displayedMonthStart, "MMMM yyyy")
    }

    function moveMonth(delta) {
        displayedMonthStart = new Date(displayedMonthStart.getFullYear(), displayedMonthStart.getMonth() + delta, 1)
    }

    function selectedDateLabel() {
        var d = selectedCalendarDate
        return Qt.formatDate(d, "dddd, MMMM ") + ordinalDate(d.getDate())
    }

    function maxPriorityCount() {
        return Math.max(1, emergencyCount, highCount, mediumCount, lowCount)
    }

    function barHeightFor(value) {
        return Math.max(10, Math.round((value / maxPriorityCount()) * 76))
    }

    function addCustomMode() {
        var nextName = "Mode " + (customModes.length + 1)
        customModes = customModes.concat([nextName])
        customActiveContext = nextName
        customModesUpdated(customModes, customActiveContext)
    }

    color: "transparent"

    readonly property int contentMaxWidth: 920
    readonly property int contentMinWidth: 360

    Flickable {
        id: dashboardScroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentContainer.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: contentContainer
            width: dashboardScroll.width
            implicitHeight: contentColumn.implicitHeight + 24

            ColumnLayout {
                id: contentColumn
                width: Math.max(contentMinWidth, Math.min(contentMaxWidth, contentContainer.width - 24))
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

            Text {
                text: "Custom"
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: Math.round(24 * dashboard.fontScale)
                font.bold: false

                MouseArea {
                    anchors.fill: parent
                    onClicked: dashboard.navigateToRoute("customMode")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Modes"
                    color: PopupTheme.subtitleColor(dashboard.stylePreset)
                    font.pixelSize: Math.round(12 * dashboard.fontScale)
                    font.bold: true
                }

                Repeater {
                    model: customModes
                    delegate: Rectangle {
                        required property var modelData
                        radius: 11
                        color: dashboard.customActiveContext === modelData ? "#0F4D52" : PopupTheme.buttonBackground(dashboard.stylePreset)
                        border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                        border.width: 1
                        implicitHeight: 24
                        implicitWidth: chipText.implicitWidth + 16

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            color: dashboard.customActiveContext === modelData ? "#FFFFFF" : PopupTheme.buttonText(dashboard.stylePreset)
                            font.pixelSize: Math.round(11 * dashboard.fontScale)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dashboard.customActiveContext = modelData
                                dashboard.customModesUpdated(dashboard.customModes, dashboard.customActiveContext)
                            }
                        }
                    }
                }

                Rectangle {
                    radius: 11
                    color: PopupTheme.buttonBackground(dashboard.stylePreset)
                    border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                    border.width: 1
                    implicitHeight: 24
                    implicitWidth: 96

                    Text {
                        anchors.centerIn: parent
                        text: "+ Add Mode"
                        color: PopupTheme.buttonText(dashboard.stylePreset)
                        font.pixelSize: Math.round(11 * dashboard.fontScale)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: dashboard.addCustomMode()
                    }
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Item { Layout.fillWidth: true }

                Rectangle {
                    radius: 14
                    color: PopupTheme.buttonBackground(dashboard.stylePreset)
                    border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                    border.width: 1
                    Layout.preferredWidth: 210
                    Layout.preferredHeight: 34

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: dashboard.stylePreset === "projectCore" ? "#0F4D52" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "Default"
                                color: dashboard.stylePreset === "projectCore" ? "#FFFFFF" : PopupTheme.buttonText(dashboard.stylePreset)
                                font.bold: true
                                font.pixelSize: Math.round(12 * dashboard.fontScale)
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: dashboard.presetSelected("projectCore")
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: dashboard.stylePreset === "batNoir" ? "#202634" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "Bat Noire"
                                color: dashboard.stylePreset === "batNoir" ? "#F4C96A" : PopupTheme.buttonText(dashboard.stylePreset)
                                font.bold: true
                                font.pixelSize: Math.round(12 * dashboard.fontScale)
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: dashboard.presetSelected("batNoir")
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                radius: 18
                color: "#0F4D52"
                border.color: "#2A7A73"
                border.width: 1

                Rectangle {
                    visible: dashboard.stylePreset === "batNoir"
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1A1F2A" }
                        GradientStop { position: 1.0; color: "#0F141D" }
                    }
                    opacity: 0.88
                }

                Rectangle {
                    visible: dashboard.stylePreset === "batNoir"
                    width: 180
                    height: 180
                    radius: 90
                    anchors.right: parent.right
                    anchors.rightMargin: 26
                    anchors.top: parent.top
                    anchors.topMargin: -70
                    color: "#F4C96A"
                    opacity: 0.2
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Today's notifications"
                            color: "#D7EEEA"
                            font.pixelSize: Math.round(14 * dashboard.fontScale)
                            font.bold: true
                        }

                        Text {
                            text: needingAttention + " need you right now"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(20 * dashboard.fontScale)
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 102
                            height: 34
                            radius: 17
                            color: "#F4AD2B"

                            Text {
                                anchors.centerIn: parent
                                text: "View All"
                                color: "#2C2C2C"
                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        width: 76
                        height: 76
                        radius: 38
                        color: "#1D6468"
                        border.color: "#F4AD2B"
                        border.width: 6

                        Rectangle {
                            visible: dashboard.stylePreset === "batNoir"
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: width / 2
                            color: "#172230"
                            border.color: "#F4C96A"
                            border.width: 2
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(focusPercent * 100) + "%"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(18 * dashboard.fontScale)
                            font.bold: true
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    radius: 24
                    color: PopupTheme.popupBackground(dashboard.stylePreset, "EMERGENCY")
                    border.color: PopupTheme.popupBorder(dashboard.stylePreset, "EMERGENCY")
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 8

                        Text { text: "Emergency"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "EMERGENCY"); font.bold: true; font.pixelSize: Math.round(12 * dashboard.fontScale) }
                        Text { text: emergencyCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "EMERGENCY"); font.pixelSize: Math.round(48 * dashboard.fontScale); font.bold: true }
                        Text { text: "Needs attention now"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "EMERGENCY"); font.pixelSize: Math.round(10 * dashboard.fontScale) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    radius: 24
                    color: PopupTheme.popupBackground(dashboard.stylePreset, "HIGH")
                    border.color: PopupTheme.popupBorder(dashboard.stylePreset, "HIGH")
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 8

                        Text { text: "High Priority"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "HIGH"); font.bold: true; font.pixelSize: Math.round(12 * dashboard.fontScale) }
                        Text { text: highCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "HIGH"); font.pixelSize: Math.round(48 * dashboard.fontScale); font.bold: true }
                        Text { text: "Respond soon"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "HIGH"); font.pixelSize: Math.round(10 * dashboard.fontScale) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 118
                    radius: 24
                    color: PopupTheme.popupBackground(dashboard.stylePreset, "MEDIUM")
                    border.color: PopupTheme.popupBorder(dashboard.stylePreset, "MEDIUM")
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 6

                        Text { text: "Medium"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "MEDIUM"); font.bold: true; font.pixelSize: Math.round(12 * dashboard.fontScale) }
                        Text { text: mediumCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "MEDIUM"); font.pixelSize: Math.round(44 * dashboard.fontScale); font.bold: true }
                        Text { text: "Keep track"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "MEDIUM"); font.pixelSize: Math.round(10 * dashboard.fontScale) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 118
                    radius: 24
                    color: PopupTheme.popupBackground(dashboard.stylePreset, "LOW")
                    border.color: PopupTheme.popupBorder(dashboard.stylePreset, "LOW")
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 6

                        Text { text: "Low"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "LOW"); font.bold: true; font.pixelSize: Math.round(12 * dashboard.fontScale) }
                        Text { text: lowCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "LOW"); font.pixelSize: Math.round(44 * dashboard.fontScale); font.bold: true }
                        Text { text: "No hurry"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "LOW"); font.pixelSize: Math.round(10 * dashboard.fontScale) }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 126
                    radius: 20
                    color: PopupTheme.panelBackground(dashboard.stylePreset)
                    border.color: PopupTheme.panelBorder(dashboard.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        Text {
                            text: "Custom Mode"
                            color: PopupTheme.titleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(16 * dashboard.fontScale)
                            font.bold: true
                        }

                        Text {
                            text: "Focus preset: " + (customActiveContext.length > 0 ? customActiveContext : "Not set")
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(12 * dashboard.fontScale)
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 14
                            color: "#0F4D52"

                            Text {
                                anchors.centerIn: parent
                                text: "Open Custom Mode"
                                color: "#FFFFFF"
                                font.pixelSize: Math.round(12 * dashboard.fontScale)
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: dashboard.navigateToRoute("customMode")
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 126
                    radius: 20
                    color: PopupTheme.panelBackground(dashboard.stylePreset)
                    border.color: PopupTheme.panelBorder(dashboard.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        Text {
                            text: "Recorded Voice (10s)"
                            color: PopupTheme.titleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(16 * dashboard.fontScale)
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: PopupTheme.buttonBackground(dashboard.stylePreset)
                                border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: dashboard.voicePlaying ? "||" : ">"
                                    color: PopupTheme.buttonText(dashboard.stylePreset)
                                    font.pixelSize: Math.round(12 * dashboard.fontScale)
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: dashboard.voicePlaying = !dashboard.voicePlaying
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: PopupTheme.buttonBackground(dashboard.stylePreset)
                                border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                                border.width: 1

                                Rectangle {
                                    width: parent.width * dashboard.voiceProgress
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#0F4D52"
                                }
                            }

                            Text {
                                text: "00:10"
                                color: PopupTheme.subtitleColor(dashboard.stylePreset)
                                font.pixelSize: Math.round(11 * dashboard.fontScale)
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Cortex Mode"
                                color: PopupTheme.subtitleColor(dashboard.stylePreset)
                                font.pixelSize: Math.round(12 * dashboard.fontScale)
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 56
                                height: 24
                                radius: 12
                                color: dashboard.cortexModeEnabled ? "#0F4D52" : PopupTheme.buttonBackground(dashboard.stylePreset)
                                border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                                border.width: 1

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    y: 2
                                    x: dashboard.cortexModeEnabled ? 34 : 2
                                    color: "#FFFFFF"

                                    Behavior on x {
                                        NumberAnimation { duration: 120 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: dashboard.cortexModeEnabled = !dashboard.cortexModeEnabled
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: dashboard.navigateToRoute("cortexMode")
                    }
                }
            }

            Text {
                text: "Digital Wellbeing"
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: Math.round(38 * dashboard.fontScale)
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 102
                radius: 14
                color: PopupTheme.panelBackground(dashboard.stylePreset)
                border.color: PopupTheme.panelBorder(dashboard.stylePreset)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: "System Runtime"
                            color: PopupTheme.titleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(13 * dashboard.fontScale)
                            font.bold: true
                        }

                        Text {
                            text: systemOsName + " (" + systemArch + ")"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(11 * dashboard.fontScale)
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Kernel " + systemKernel + " | " + systemDesktop + " | " + systemSession
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(11 * dashboard.fontScale)
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                radius: 10
                                color: runtimeHealthColor() + "22"
                                border.color: runtimeHealthColor()
                                border.width: 1
                                implicitWidth: runtimeChipText.implicitWidth + 18
                                implicitHeight: 32

                                Text {
                                    id: runtimeChipText
                                    anchors.centerIn: parent
                                    text: runtimeHealthText()
                                    color: runtimeHealthColor()
                                    font.pixelSize: Math.round(11 * dashboard.fontScale)
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "Load " + systemLoadOne.toFixed(2) + " | RAM " + systemMemUsedPercent + "% | Uptime " + systemUptime
                                color: PopupTheme.subtitleColor(dashboard.stylePreset)
                                font.pixelSize: Math.round(11 * dashboard.fontScale)
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 390
                radius: 28
                color: "#0F4D52"
                border.color: "#2A7A73"
                border.width: 1

                Rectangle {
                    visible: dashboard.stylePreset === "batNoir"
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#161C28" }
                        GradientStop { position: 1.0; color: "#101622" }
                    }
                    opacity: 0.92
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Text {
                        text: "Calendar"
                        color: "#D7EEEA"
                        font.pixelSize: Math.round(13 * dashboard.fontScale)
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: "#1A6469"

                            Text {
                                anchors.centerIn: parent
                                text: "<"
                                color: "#D7EEEA"
                                font.pixelSize: Math.round(14 * dashboard.fontScale)
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: dashboard.moveMonth(-1)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: dashboard.calendarMonthTitle()
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(22 * dashboard.fontScale)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: "#1A6469"

                            Text {
                                anchors.centerIn: parent
                                text: ">"
                                color: "#D7EEEA"
                                font.pixelSize: Math.round(14 * dashboard.fontScale)
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: dashboard.moveMonth(1)
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 6
                        rowSpacing: 6

                        Repeater {
                            model: 7
                            delegate: Text {
                                required property int index
                                text: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][index]
                                color: "#C3E3DF"
                                font.pixelSize: Math.round(11 * dashboard.fontScale)
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }

                        Repeater {
                            model: 42
                            delegate: Rectangle {
                                required property int index
                                readonly property var cellDate: dashboard.calendarCellDate(index)
                                readonly property bool inCurrentMonth: cellDate.getMonth() === dashboard.displayedMonthStart.getMonth()
                                readonly property bool isSelected: dashboard.isSameDate(cellDate, dashboard.selectedCalendarDate)

                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 15
                                color: isSelected ? "#F4AD2B" : (inCurrentMonth ? "#1A6469" : "#134A4E")
                                opacity: inCurrentMonth ? 1.0 : 0.62

                                Text {
                                    anchors.centerIn: parent
                                    text: cellDate.getDate()
                                    color: isSelected ? "#0F4D52" : "#F2F7F7"
                                    font.pixelSize: Math.round(12 * dashboard.fontScale)
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        dashboard.selectedCalendarDate = new Date(cellDate.getFullYear(), cellDate.getMonth(), cellDate.getDate())
                                        if (!inCurrentMonth) {
                                            dashboard.displayedMonthStart = new Date(cellDate.getFullYear(), cellDate.getMonth(), 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: selectedDateLabel()
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: Math.round(22 * dashboard.fontScale)
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 164
                radius: 18
                color: "#0F4D52"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "Notification Load · 7 days"
                        color: "#D7EEEA"
                        font.pixelSize: Math.round(12 * dashboard.fontScale)
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Repeater {
                            model: [
                                { label: "EMG", v: emergencyCount, c: "#F2DFDF" },
                                { label: "HIGH", v: highCount, c: "#F4AD2B" },
                                { label: "MED", v: mediumCount, c: "#8DB8B8" },
                                { label: "LOW", v: lowCount, c: "#5A8C89" }
                            ]

                            delegate: Column {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 4

                                Item {
                                    width: parent.width
                                    height: 88

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 26
                                        height: dashboard.barHeightFor(modelData.v)
                                        radius: 6
                                        color: modelData.c
                                    }
                                }

                                Text {
                                    text: modelData.v
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#F2F7F7"
                                    font.pixelSize: Math.round(10 * dashboard.fontScale)
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.label
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#C3E3DF"
                                    font.pixelSize: Math.round(11 * dashboard.fontScale)
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 14
                    color: PopupTheme.panelBackground(dashboard.stylePreset)
                    border.color: PopupTheme.panelBorder(dashboard.stylePreset)
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: totalCount
                            color: "#0F4D52"
                            font.pixelSize: Math.round(22 * dashboard.fontScale)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Total"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(11 * dashboard.fontScale)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 14
                    color: PopupTheme.panelBackground(dashboard.stylePreset)
                    border.color: PopupTheme.panelBorder(dashboard.stylePreset)
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "-23%"
                            color: "#E08C00"
                            font.pixelSize: Math.round(22 * dashboard.fontScale)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "vs last week"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(11 * dashboard.fontScale)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 14
                    color: PopupTheme.panelBackground(dashboard.stylePreset)
                    border.color: PopupTheme.panelBorder(dashboard.stylePreset)
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: emergencyCount
                            color: "#BD3124"
                            font.pixelSize: Math.round(22 * dashboard.fontScale)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Urgent"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: Math.round(11 * dashboard.fontScale)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 14
                color: "#E8E0C9"
                border.color: "#F4AD2B"
                border.width: 1

                Text {
                    anchors.fill: parent
                    anchors.margins: 12
                    text: "AI Insight: You saved 2.1 hrs this week by reducing low-priority checks."
                    wrapMode: Text.Wrap
                    color: "#8A5A10"
                    font.pixelSize: Math.round(10 * dashboard.fontScale)
                    font.bold: true
                }
            }

                Item {
                    Layout.preferredHeight: 96
                    Layout.fillWidth: true
                }
            }
        }
    }

    Rectangle {
        width: 30
        height: 30
        radius: 15
        color: "#6FD8DF"
        border.color: "#56C6CE"
        border.width: 1
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        z: 11

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: "#FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 6
        }

        Rectangle {
            width: 14
            height: 9
            radius: 4
            color: "#FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
        }

        MouseArea {
            anchors.fill: parent
            onClicked: dashboard.navigateToRoute("profile")
        }
    }

    Item {
        id: fixedCortexLogo
        width: 78
        height: 78
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        z: 10

        Rectangle {
            id: waveRingOuter
            anchors.centerIn: parent
            width: 64
            height: 64
            radius: 32
            color: "transparent"
            border.color: "#6C5CFF"
            border.width: 2
            opacity: 0.28

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.9; duration: 2400; easing.type: Easing.OutCubic }
                NumberAnimation { from: 1.9; to: 1.0; duration: 0 }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.28; to: 0.02; duration: 2400 }
                NumberAnimation { from: 0.02; to: 0.28; duration: 0 }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 64
            height: 64
            radius: 32
            color: "transparent"
            border.color: "#27C8F6"
            border.width: 2
            opacity: 0.24

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.7; duration: 2200; easing.type: Easing.OutCubic }
                NumberAnimation { from: 1.7; to: 1.0; duration: 0 }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.24; to: 0.03; duration: 2200 }
                NumberAnimation { from: 0.03; to: 0.24; duration: 0 }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 66
            height: 66
            radius: 33
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#D4F5FF" }
                GradientStop { position: 0.38; color: "#0CB4E8" }
                GradientStop { position: 0.72; color: "#3E36F6" }
                GradientStop { position: 1.0; color: "#AF4CF4" }
            }
            border.color: "#FFFFFF"
            border.width: 1

            RotationAnimation on rotation {
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 18000
            }
        }
    }

}
