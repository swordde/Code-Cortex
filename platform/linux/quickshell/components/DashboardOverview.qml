import QtQuick 2.15
import QtQuick.Layouts 1.15
import "PopupTheme.js" as PopupTheme

Rectangle {
    id: dashboard

    property string stylePreset: "projectCore"
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

    signal presetSelected(string preset)

    color: "transparent"

    readonly property int contentMaxWidth: 920
    readonly property int contentMinWidth: 360

    Item {
        anchors.fill: parent

        ColumnLayout {
            width: Math.max(contentMinWidth, Math.min(contentMaxWidth, parent.width - 24))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Text {
                text: "Custom"
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: 24
                font.bold: false
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: ["W", "H", "N"]
                    delegate: Rectangle {
                        required property var modelData
                        width: 30
                        height: 30
                        radius: 15
                        color: PopupTheme.buttonBackground(dashboard.stylePreset)
                        border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: PopupTheme.buttonText(dashboard.stylePreset)
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                }

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
                                font.pixelSize: 12
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
                                font.pixelSize: 12
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
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Text {
                            text: needingAttention + " need you right now"
                            color: "#FFFFFF"
                            font.pixelSize: 20
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
                            font.pixelSize: 18
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

                        Text { text: "Emergency"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "EMERGENCY"); font.bold: true; font.pixelSize: 12 }
                        Text { text: emergencyCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "EMERGENCY"); font.pixelSize: 48; font.bold: true }
                        Text { text: "Needs attention now"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "EMERGENCY"); font.pixelSize: 10 }
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

                        Text { text: "High Priority"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "HIGH"); font.bold: true; font.pixelSize: 12 }
                        Text { text: highCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "HIGH"); font.pixelSize: 48; font.bold: true }
                        Text { text: "Respond soon"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "HIGH"); font.pixelSize: 10 }
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

                        Text { text: "Medium"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "MEDIUM"); font.bold: true; font.pixelSize: 12 }
                        Text { text: mediumCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "MEDIUM"); font.pixelSize: 44; font.bold: true }
                        Text { text: "Keep track"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "MEDIUM"); font.pixelSize: 10 }
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

                        Text { text: "Low"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "LOW"); font.bold: true; font.pixelSize: 12 }
                        Text { text: lowCount; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "LOW"); font.pixelSize: 44; font.bold: true }
                        Text { text: "No hurry"; color: PopupTheme.countColorByPriority(dashboard.stylePreset, "LOW"); font.pixelSize: 10 }
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
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            text: "Focus preset: Study"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: 12
                        }

                        RowLayout {
                            spacing: 6

                            Repeater {
                                model: ["College", "Office", "Gaming"]

                                delegate: Rectangle {
                                    required property var modelData
                                    radius: 10
                                    color: PopupTheme.buttonBackground(dashboard.stylePreset)
                                    border.color: PopupTheme.buttonBorder(dashboard.stylePreset)
                                    border.width: 1
                                    implicitHeight: 26
                                    implicitWidth: chipLabel.implicitWidth + 12

                                    Text {
                                        id: chipLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: PopupTheme.buttonText(dashboard.stylePreset)
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }
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
                                font.pixelSize: 12
                                font.bold: true
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
                            font.pixelSize: 16
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
                                    font.pixelSize: 12
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
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Cortex Mode"
                                color: PopupTheme.subtitleColor(dashboard.stylePreset)
                                font.pixelSize: 12
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
                }
            }

            Text {
                text: "Digital Wellbeing"
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: 34
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 206
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
                    spacing: 10

                    Text {
                        text: "swipe up to return"
                        color: "#D7EEEA"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: "Digital\nWellbeing"
                        color: "#FFFFFF"
                        font.pixelSize: 38
                        font.bold: true
                        lineHeight: 0.95
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        Repeater {
                            model: [
                                { day: "M", num: "1", selected: false },
                                { day: "T", num: "2", selected: false },
                                { day: "W", num: "3", selected: false },
                                { day: "T", num: "4", selected: false },
                                { day: "F", num: "5", selected: true }
                            ]
                            delegate: Column {
                                required property var modelData
                                spacing: 4

                                Text {
                                    text: modelData.day
                                    color: "#C3E3DF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.num
                                    color: modelData.selected ? "#0F4D52" : "#F2F7F7"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Rectangle {
                                    visible: modelData.selected
                                    width: 34
                                    height: 34
                                    radius: 17
                                    color: "#F4AD2B"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    z: -1
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "Saturday, April 5th"
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: 22
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
                        font.pixelSize: 12
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Repeater {
                            model: [
                                { label: "EMG", h: 32, c: "#F2DFDF" },
                                { label: "HIGH", h: 54, c: "#F4AD2B" },
                                { label: "MED", h: 68, c: "#8DB8B8" },
                                { label: "LOW", h: 76, c: "#5A8C89" }
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
                                        height: modelData.h
                                        radius: 6
                                        color: modelData.c
                                    }
                                }

                                Text {
                                    text: modelData.label
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#C3E3DF"
                                    font.pixelSize: 11
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
                            font.pixelSize: 22
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Total"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: 11
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
                            font.pixelSize: 22
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "vs last week"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: 11
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
                            font.pixelSize: 22
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Urgent"
                            color: PopupTheme.subtitleColor(dashboard.stylePreset)
                            font.pixelSize: 11
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
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 78
                height: 78

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

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
