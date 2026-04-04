import QtQuick 2.15
import QtQuick.Layouts 1.15
import "PopupTheme.js" as PopupTheme

Rectangle {
    id: wellbeingOverlay

    property int emergencyCount: 0
    property int highCount: 0
    property int mediumCount: 0
    property int lowCount: 0
    property string stylePreset: "projectCore"
    property real hostWidth: parent ? parent.width : 1280

    width: Math.max(280, Math.min(380, hostWidth * 0.24))
    height: 170
    radius: 14
    color: PopupTheme.panelBackground(stylePreset)
    border.color: PopupTheme.panelBorder(stylePreset)
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: "Wellbeing Today"
            color: PopupTheme.titleColor(stylePreset)
            font.pixelSize: 16
            font.bold: true
        }

        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            Text { text: "Emergency"; color: PopupTheme.subtitleColor(stylePreset) }
            Text { text: emergencyCount; color: PopupTheme.countColorByPriority(stylePreset, "EMERGENCY") }

            Text { text: "High"; color: PopupTheme.subtitleColor(stylePreset) }
            Text { text: highCount; color: PopupTheme.countColorByPriority(stylePreset, "HIGH") }

            Text { text: "Medium"; color: PopupTheme.subtitleColor(stylePreset) }
            Text { text: mediumCount; color: PopupTheme.countColorByPriority(stylePreset, "MEDIUM") }

            Text { text: "Low"; color: PopupTheme.subtitleColor(stylePreset) }
            Text { text: lowCount; color: PopupTheme.countColorByPriority(stylePreset, "LOW") }
        }
    }
}
