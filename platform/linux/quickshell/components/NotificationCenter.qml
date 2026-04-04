import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./"
import "PopupTheme.js" as PopupTheme

Rectangle {
    id: notificationCenter

    property var notifications: []
    property bool expanded: true
    property string stylePreset: "projectCore"
    property real hostWidth: parent ? parent.width : 1280

    width: expanded ? Math.max(300, Math.min(420, hostWidth * 0.28)) : 0
    color: PopupTheme.panelBackground(stylePreset)
    border.color: PopupTheme.panelBorder(stylePreset)
    border.width: 1

    Behavior on width {
        NumberAnimation { duration: 180 }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: "NotificationCenter"
            font.pixelSize: 18
            font.bold: true
            color: PopupTheme.titleColor(stylePreset)
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            model: notificationCenter.notifications

            delegate: Rectangle {
                required property var modelData

                width: ListView.view.width
                height: 78
                radius: 10
                color: PopupTheme.cardSurfaceBackground(notificationCenter.stylePreset, modelData.priority)
                border.color: PopupTheme.cardSurfaceBorder(notificationCenter.stylePreset, modelData.priority)
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Row {
                        spacing: 8

                        Text {
                            text: modelData.sender
                            color: PopupTheme.titleColor(notificationCenter.stylePreset)
                            font.pixelSize: 13
                            font.bold: true
                        }

                        PriorityBadge {
                            priority: modelData.priority
                            stylePreset: notificationCenter.stylePreset
                        }
                    }

                    Text {
                        text: modelData.preview
                        color: PopupTheme.bodyColor(notificationCenter.stylePreset)
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }
    }
}
