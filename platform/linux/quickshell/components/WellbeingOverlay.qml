import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: wellbeingOverlay

    property int emergencyCount: 0
    property int highCount: 0
    property int mediumCount: 0
    property int lowCount: 0

    width: 320
    height: 170
    radius: 12
    color: "#172331"
    border.color: "#2d4257"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: "Wellbeing Today"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            Text { text: "Emergency"; color: "#f59ea6" }
            Text { text: emergencyCount; color: "#ffffff" }

            Text { text: "High"; color: "#ffc06d" }
            Text { text: highCount; color: "#ffffff" }

            Text { text: "Medium"; color: "#84c2ff" }
            Text { text: mediumCount; color: "#ffffff" }

            Text { text: "Low"; color: "#b9c4cf" }
            Text { text: lowCount; color: "#ffffff" }
        }
    }
}
