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
    property string searchQuery: ""
    property string selectedPriority: "ALL"
    property var filteredNotifications: []

    width: expanded ? Math.max(300, Math.min(420, hostWidth * 0.28)) : 0
    color: PopupTheme.panelBackground(stylePreset)
    border.color: PopupTheme.panelBorder(stylePreset)
    border.width: 1

    Behavior on width {
        NumberAnimation { duration: 180 }
    }

    onNotificationsChanged: applyFilters()
    onSearchQueryChanged: applyFilters()
    onSelectedPriorityChanged: applyFilters()

    Component.onCompleted: applyFilters()

    function applyFilters() {
        var results = []
        var query = searchQuery.toLowerCase().trim()

        for (var i = 0; i < notifications.length; i++) {
            var n = notifications[i]
            if (!n) {
                continue
            }

            if (selectedPriority !== "ALL" && n.priority !== selectedPriority) {
                continue
            }

            if (query.length > 0) {
                var haystack = ((n.sender || "") + " " + (n.preview || "") + " " + (n.app || "")).toLowerCase()
                if (haystack.indexOf(query) === -1) {
                    continue
                }
            }

            results.push(n)
        }

        filteredNotifications = results
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

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search sender, app, or content"
            color: PopupTheme.titleColor(notificationCenter.stylePreset)
            placeholderTextColor: PopupTheme.subtitleColor(notificationCenter.stylePreset)
            text: notificationCenter.searchQuery
            onTextChanged: notificationCenter.searchQuery = text
            background: Rectangle {
                radius: 10
                color: PopupTheme.buttonBackground(notificationCenter.stylePreset)
                border.color: PopupTheme.buttonBorder(notificationCenter.stylePreset)
                border.width: 1
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ["ALL", "EMERGENCY", "HIGH", "MEDIUM", "LOW"]

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool selected: notificationCenter.selectedPriority === modelData

                    radius: 10
                    color: selected
                        ? PopupTheme.countColorByPriority(notificationCenter.stylePreset, modelData === "ALL" ? "LOW" : modelData)
                        : PopupTheme.buttonBackground(notificationCenter.stylePreset)
                    border.color: PopupTheme.buttonBorder(notificationCenter.stylePreset)
                    border.width: 1
                    implicitHeight: 28
                    implicitWidth: filterLabel.implicitWidth + 16

                    Text {
                        id: filterLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 11
                        font.bold: true
                        color: selected ? "#ffffff" : PopupTheme.buttonText(notificationCenter.stylePreset)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: notificationCenter.selectedPriority = modelData
                    }
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            model: notificationCenter.filteredNotifications

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

        Text {
            visible: notificationCenter.filteredNotifications.length === 0
            text: "No notifications match current filters"
            color: PopupTheme.subtitleColor(notificationCenter.stylePreset)
            font.pixelSize: 12
        }
    }
}
