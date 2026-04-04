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
                            color: dashboard.stylePreset === "projectCore" ? "#1F6F68" : "transparent"

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
                color: "#1F6F68"
                border.color: "#3CB7AE"
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
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 94
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
                        color: "#2A7A73"
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

            Text {
                text: "Digital Wellbeing"
                color: PopupTheme.titleColor(dashboard.stylePreset)
                font.pixelSize: 44
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 206
                radius: 28
                color: "#1F6F68"
                border.color: "#3CB7AE"
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
                        font.pixelSize: 28
                        font.bold: true
                        lineHeight: 0.9
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
                                    color: modelData.selected ? "#1F6F68" : "#F2F7F7"
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
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
