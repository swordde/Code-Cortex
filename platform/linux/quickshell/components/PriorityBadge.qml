import QtQuick 2.15
import "PopupTheme.js" as PopupTheme

Rectangle {
    id: priorityBadge

    property string priority: "LOW"
    property string stylePreset: "densePro"

    implicitHeight: 24
    implicitWidth: Math.max(72, badgeText.implicitWidth + 18)
    radius: 12
    color: PopupTheme.badgeColor(priority, stylePreset)

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: priority
        font.pixelSize: 11
        font.bold: true
        color: "#ffffff"
    }
}
