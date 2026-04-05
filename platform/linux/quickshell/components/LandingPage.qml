import QtQuick 2.15
import QtQuick.Layouts 1.15
import "PopupTheme.js" as PopupTheme

Item {
    id: page

    property string stylePreset: "projectCore"
    readonly property real fontScale: 1.25

    signal createAccountRequested
    signal skipRequested

    Rectangle {
        anchors.fill: parent
        color: PopupTheme.panelBackground(page.stylePreset)
        border.color: PopupTheme.panelBorder(page.stylePreset)
        border.width: 1
        radius: 18

        Flickable {
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            contentWidth: width
            contentHeight: layoutRow.implicitHeight

            RowLayout {
                id: layoutRow
                width: Math.min(parent.width, 1120)
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(560, mainContent.implicitHeight + 48)
                    radius: 16
                    color: PopupTheme.buttonBackground(page.stylePreset)
                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        id: mainContent
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                    Text {
                        Layout.fillWidth: true
                        text: "Welcome to Cortex"
                        horizontalAlignment: Text.AlignLeft
                        color: PopupTheme.titleColor(page.stylePreset)
                        font.pixelSize: Math.round(42 * page.fontScale)
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Create your account with voice setup before using AI services."
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.Wrap
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(16 * page.fontScale)
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        width: 220
                        height: 48
                        radius: 24
                        color: "#0F4D52"

                        Text {
                            anchors.centerIn: parent
                            text: "Create Account"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(15 * page.fontScale)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: page.createAccountRequested()
                        }
                    }

                    Rectangle {
                        width: 120
                        height: 36
                        radius: 18
                        color: "transparent"
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Skip"
                            color: PopupTheme.subtitleColor(page.stylePreset)
                            font.pixelSize: Math.round(12 * page.fontScale)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: page.skipRequested()
                        }
                    }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: Math.max(560, sidePanel.implicitHeight + 36)
                    Layout.preferredWidth: 320
                    visible: page.width > 980
                    radius: 16
                    color: PopupTheme.panelBackground(page.stylePreset)
                    border.color: PopupTheme.panelBorder(page.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        id: sidePanel
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                    Text {
                        text: "What You Get"
                        color: PopupTheme.titleColor(page.stylePreset)
                        font.pixelSize: Math.round(16 * page.fontScale)
                        font.bold: true
                    }

                    Text {
                        text: "Smart notification triage"
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(13 * page.fontScale)
                    }

                    Text {
                        text: "Voice-based account context"
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(13 * page.fontScale)
                    }

                    Text {
                        text: "Digital wellbeing and runtime status"
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(13 * page.fontScale)
                    }
                    }
                }
            }
        }
    }
}
