import QtQuick 2.15
import QtQuick.Layouts 1.15
import "PopupTheme.js" as PopupTheme

Item {
    id: actionBar
    property string stylePreset: "densePro"

    signal replyClicked
    signal dismissClicked
    signal snoozeClicked
    signal delegateClicked

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        spacing: 8

        Repeater {
            model: [
                { label: "Reply", action: "reply" },
                { label: "Dismiss", action: "dismiss" },
                { label: "Snooze", action: "snooze" },
                { label: "Cortex", action: "delegate" }
            ]

            delegate: Rectangle {
                required property var modelData

                radius: 8
                color: PopupTheme.buttonBackground(actionBar.stylePreset)
                border.color: PopupTheme.buttonBorder(actionBar.stylePreset)
                border.width: 1
                implicitWidth: 78
                implicitHeight: 30

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: PopupTheme.buttonText(actionBar.stylePreset)
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.action === "reply") actionBar.replyClicked()
                        else if (modelData.action === "dismiss") actionBar.dismissClicked()
                        else if (modelData.action === "snooze") actionBar.snoozeClicked()
                        else actionBar.delegateClicked()
                    }
                    onEntered: parent.color = PopupTheme.buttonHoverBackground(actionBar.stylePreset)
                    onExited: parent.color = PopupTheme.buttonBackground(actionBar.stylePreset)
                }
            }
        }
    }
}
