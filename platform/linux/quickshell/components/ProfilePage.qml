import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "PopupTheme.js" as PopupTheme

Item {
    id: page

    property string stylePreset: "projectCore"
    readonly property real fontScale: 1.0
    property string displayName: "S"
    property bool cortexEnabled: true
    property bool voicePlaying: false
    property var extraVoices: ["Backup Voice 1", "Backup Voice 2"]

    signal backRequested
    signal openCortexRequested

    function addVoice() {
        var nextName = "Extra Voice " + (extraVoices.length + 1)
        extraVoices = extraVoices.concat([nextName])
    }

    function initialsFromName(name) {
        var text = (name || "").trim()
        if (text.length === 0) {
            return "U"
        }
        var parts = text.split(/\s+/)
        if (parts.length === 1) {
            return parts[0].charAt(0).toUpperCase()
        }
        return (parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase()
    }

    Rectangle {
        anchors.fill: parent
        color: PopupTheme.panelBackground(page.stylePreset)
        border.color: PopupTheme.panelBorder(page.stylePreset)
        border.width: 1
        radius: 18

        Flickable {
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            contentWidth: width
            contentHeight: shellColumn.implicitHeight

            ColumnLayout {
                id: shellColumn
                width: Math.min(parent.width, 1120)
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88
                    radius: 14
                    color: PopupTheme.buttonBackground(page.stylePreset)
                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: PopupTheme.panelBackground(page.stylePreset)
                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "<"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: 16
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: page.backRequested()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Profile"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: 24
                                font.bold: true
                            }

                            Text {
                                text: "Identity, voice profile, and Cortex controls"
                                color: PopupTheme.subtitleColor(page.stylePreset)
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: profileColumn.implicitHeight + 30
                        radius: 16
                        color: PopupTheme.buttonBackground(page.stylePreset)
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1

                        ColumnLayout {
                            id: profileColumn
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 126
                                radius: 14
                                color: PopupTheme.panelBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 14

                                    Rectangle {
                                        Layout.preferredWidth: 70
                                        Layout.preferredHeight: 70
                                        radius: 35
                                        color: PopupTheme.countColorByPriority(page.stylePreset, "MEDIUM")

                                        Text {
                                            anchors.centerIn: parent
                                            text: initialsFromName(displayName)
                                            color: "#FFFFFF"
                                            font.pixelSize: 24
                                            font.bold: true
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: displayName
                                            color: PopupTheme.titleColor(page.stylePreset)
                                            font.pixelSize: 26
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "Primary account"
                                            color: PopupTheme.subtitleColor(page.stylePreset)
                                            font.pixelSize: 12
                                        }

                                        RowLayout {
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredHeight: 24
                                                Layout.preferredWidth: 110
                                                radius: 12
                                                color: PopupTheme.cardSurfaceBackground(page.stylePreset, "MEDIUM")
                                                border.color: PopupTheme.cardSurfaceBorder(page.stylePreset, "MEDIUM")
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Voice ready"
                                                    color: PopupTheme.bodyColor(page.stylePreset)
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredHeight: 24
                                                Layout.preferredWidth: 120
                                                radius: 12
                                                color: PopupTheme.cardSurfaceBackground(page.stylePreset, page.cortexEnabled ? "HIGH" : "LOW")
                                                border.color: PopupTheme.cardSurfaceBorder(page.stylePreset, page.cortexEnabled ? "HIGH" : "LOW")
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: page.cortexEnabled ? "Cortex on" : "Cortex off"
                                                    color: PopupTheme.bodyColor(page.stylePreset)
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 164
                                radius: 12
                                color: PopupTheme.panelBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    Text {
                                        text: "Voice Profile"
                                        color: PopupTheme.titleColor(page.stylePreset)
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 14
                                            color: PopupTheme.buttonBackground(page.stylePreset)
                                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: page.voicePlaying ? "||" : ">"
                                                color: PopupTheme.buttonText(page.stylePreset)
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: page.voicePlaying = !page.voicePlaying
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 8
                                            radius: 4
                                            color: PopupTheme.buttonBackground(page.stylePreset)
                                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                                            border.width: 1

                                            Rectangle {
                                                width: parent.width * (page.voicePlaying ? 0.58 : 0.0)
                                                height: parent.height
                                                radius: parent.radius
                                                color: PopupTheme.countColorByPriority(page.stylePreset, "MEDIUM")
                                            }
                                        }

                                        Text {
                                            text: "00:10"
                                            color: PopupTheme.subtitleColor(page.stylePreset)
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Add another voice sample"
                                            color: PopupTheme.subtitleColor(page.stylePreset)
                                            font.pixelSize: 12
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 90
                                            Layout.preferredHeight: 30
                                            radius: 10
                                            color: PopupTheme.countColorByPriority(page.stylePreset, "MEDIUM")

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Add Voice"
                                                color: "#FFFFFF"
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: page.addVoice()
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(94, (extraVoices.length * 24) + 40)
                                radius: 12
                                color: PopupTheme.panelBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 4

                                    Text {
                                        text: "Additional Voices"
                                        color: PopupTheme.titleColor(page.stylePreset)
                                        font.pixelSize: 14
                                        font.bold: true
                                    }

                                    Repeater {
                                        model: extraVoices

                                        delegate: RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true

                                            Text {
                                                Layout.fillWidth: true
                                                text: "• " + modelData
                                                color: PopupTheme.subtitleColor(page.stylePreset)
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: "00:10"
                                                color: PopupTheme.subtitleColor(page.stylePreset)
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 86
                                radius: 12
                                color: PopupTheme.panelBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "Cortex Mode"
                                            color: PopupTheme.titleColor(page.stylePreset)
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Text {
                                            text: page.cortexEnabled ? "AI actions are active for this account" : "Turn on Cortex to enable AI actions"
                                            color: PopupTheme.subtitleColor(page.stylePreset)
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        width: 56
                                        height: 24
                                        radius: 12
                                        color: page.cortexEnabled ? PopupTheme.countColorByPriority(page.stylePreset, "MEDIUM") : PopupTheme.buttonBackground(page.stylePreset)
                                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                                        border.width: 1

                                        Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 10
                                            y: 2
                                            x: page.cortexEnabled ? 34 : 2
                                            color: "#FFFFFF"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: page.cortexEnabled = !page.cortexEnabled
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: page.openCortexRequested()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: summaryColumn.implicitHeight + 30
                        visible: page.width > 980
                        radius: 16
                        color: PopupTheme.panelBackground(page.stylePreset)
                        border.color: PopupTheme.panelBorder(page.stylePreset)
                        border.width: 1

                        ColumnLayout {
                            id: summaryColumn
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10

                            Text {
                                text: "Account Summary"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 78
                                radius: 10
                                color: PopupTheme.buttonBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 2

                                    Text {
                                        text: "Name"
                                        color: PopupTheme.subtitleColor(page.stylePreset)
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        text: displayName
                                        color: PopupTheme.titleColor(page.stylePreset)
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: 10
                                color: PopupTheme.buttonBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Voice profile"
                                        color: PopupTheme.subtitleColor(page.stylePreset)
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: "Registered"
                                        color: PopupTheme.titleColor(page.stylePreset)
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: 10
                                color: PopupTheme.buttonBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Cortex status"
                                        color: PopupTheme.subtitleColor(page.stylePreset)
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: page.cortexEnabled ? "Enabled" : "Disabled"
                                        color: page.cortexEnabled
                                            ? PopupTheme.countColorByPriority(page.stylePreset, "MEDIUM")
                                            : PopupTheme.subtitleColor(page.stylePreset)
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
