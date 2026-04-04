import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./"

Rectangle {
    id: notificationCenter

    property var notifications: []
    property bool expanded: true

    width: expanded ? 360 : 0
    color: "#111922"
    border.color: "#2e3a4a"
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
            color: "#ffffff"
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
                color: "#182430"
                border.color: "#304357"

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Row {
                        spacing: 8

                        Text {
                            text: modelData.sender
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        PriorityBadge {
                            priority: modelData.priority
                        }
                    }

                    Text {
                        text: modelData.preview
                        color: "#cad8ea"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }
    }
}
