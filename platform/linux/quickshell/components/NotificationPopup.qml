import QtQuick 2.15
import QtQuick.Layouts 1.15
import "./"
import "PopupTheme.js" as PopupTheme

Rectangle {
    id: notificationPopup

    property string sender: "Unknown"
    property string app: "System"
    property string preview: "Notification preview"
    property string priority: "LOW"
    property string timestamp: "now"
    property string stylePreset: "densePro"

    signal dismissed

    width: 360
    height: contentColumn.implicitHeight + 20
    radius: PopupTheme.popupRadius(stylePreset)
    color: PopupTheme.popupBackground(stylePreset, priority)
    border.color: PopupTheme.popupBorder(stylePreset, priority)
    border.width: 1

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: sender
                    color: PopupTheme.titleColor(stylePreset)
                    font.pixelSize: PopupTheme.titleSize(stylePreset)
                    font.bold: true
                }

                Text {
                    text: app + "  •  " + timestamp
                    color: PopupTheme.subtitleColor(stylePreset)
                    font.pixelSize: PopupTheme.subtitleSize(stylePreset)
                }
            }

            PriorityBadge {
                priority: notificationPopup.priority
                stylePreset: notificationPopup.stylePreset
            }
        }

        Text {
            Layout.fillWidth: true
            text: preview
            wrapMode: Text.Wrap
            color: PopupTheme.bodyColor(stylePreset)
            font.pixelSize: PopupTheme.bodySize(stylePreset)
        }

        ActionBar {
            Layout.fillWidth: true
            stylePreset: notificationPopup.stylePreset
            onDismissClicked: notificationPopup.dismissed()
        }
    }
}
