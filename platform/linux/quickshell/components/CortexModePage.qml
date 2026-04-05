import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "PopupTheme.js" as PopupTheme

Item {
    id: page

    property string stylePreset: "projectCore"
    readonly property real fontScale: 1.25
    property bool autoReplyEnabled: true
    property bool scheduleEnabled: true
    property bool safeModeEnabled: false
    property var savedReplies: ["I'll call you back shortly", "In a meeting, will respond later", "On my way!"]
    property var scheduledMessages: ["Goodnight - family @ 9:30 PM", "Morning check-in @ 7:00 AM"]

    signal backRequested
    signal saveRequested(bool autoReplyEnabled, bool scheduleEnabled, bool safeModeEnabled)

    function addReply(text) {
        var t = text.trim()
        if (t.length === 0) return
        savedReplies = savedReplies.concat([t])
    }

    function removeReply(index) {
        if (index < 0 || index >= savedReplies.length) return
        var copy = savedReplies.slice(0)
        copy.splice(index, 1)
        savedReplies = copy
    }

    function addSchedule(text) {
        var t = text.trim()
        if (t.length === 0) return
        scheduledMessages = scheduledMessages.concat([t])
    }

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
            contentHeight: outerColumn.implicitHeight

            ColumnLayout {
                id: outerColumn
                width: Math.min(parent.width, 980)
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(680, cortexContent.implicitHeight + 36)
                    radius: 16
                    color: PopupTheme.buttonBackground(page.stylePreset)
                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        id: cortexContent
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "<"
                    color: PopupTheme.titleColor(page.stylePreset)
                    font.pixelSize: Math.round(20 * page.fontScale)
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.backRequested()
                    }
                }

                Text {
                    text: "Cortex Mode"
                    color: PopupTheme.titleColor(page.stylePreset)
                    font.pixelSize: Math.round(16 * page.fontScale)
                    font.bold: true
                }
            }

                    Text {
                        text: "Configure live AI behavior for notifications and actions."
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        wrapMode: Text.Wrap
                        font.pixelSize: Math.round(12 * page.fontScale)
                    }

                    Repeater {
                        model: [
                            { label: "Auto Reply", value: page.autoReplyEnabled },
                            { label: "Scheduled Actions", value: page.scheduleEnabled },
                            { label: "Safe Mode", value: page.safeModeEnabled }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            radius: 12
                            color: PopupTheme.panelBackground(page.stylePreset)
                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: PopupTheme.titleColor(page.stylePreset)
                                    font.pixelSize: Math.round(13 * page.fontScale)
                                    font.bold: true
                                }

                                Rectangle {
                                    width: 56
                                    height: 24
                                    radius: 12
                                    color: modelData.value ? "#0F4D52" : PopupTheme.buttonBackground(page.stylePreset)
                                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                                    border.width: 1

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        y: 2
                                        x: modelData.value ? 34 : 2
                                        color: "#FFFFFF"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.label === "Auto Reply") {
                                        page.autoReplyEnabled = !page.autoReplyEnabled
                                    } else if (modelData.label === "Scheduled Actions") {
                                        page.scheduleEnabled = !page.scheduleEnabled
                                    } else {
                                        page.safeModeEnabled = !page.safeModeEnabled
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 118
                        radius: 12
                        color: PopupTheme.panelBackground(page.stylePreset)
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 5

                            Text {
                                text: "Saved Replies"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: Math.round(13 * page.fontScale)
                                font.bold: true
                            }

                            Repeater {
                                model: Math.min(3, page.savedReplies.length)
                                delegate: RowLayout {
                                    required property int index
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: "• " + page.savedReplies[index]
                                        color: PopupTheme.subtitleColor(page.stylePreset)
                                        font.pixelSize: Math.round(11 * page.fontScale)
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "x"
                                        color: "#BD3124"
                                        font.bold: true
                                        font.pixelSize: Math.round(12 * page.fontScale)

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: page.removeReply(index)
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                TextField {
                                    id: addReplyInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    placeholderText: "Add reply"
                                    color: PopupTheme.titleColor(page.stylePreset)
                                    placeholderTextColor: PopupTheme.subtitleColor(page.stylePreset)
                                    background: Rectangle {
                                        radius: 8
                                        color: "transparent"
                                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                                        border.width: 1
                                    }
                                }

                                Rectangle {
                                    width: 46
                                    height: 30
                                    radius: 8
                                    color: "#0F4D52"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Add"
                                        color: "#FFFFFF"
                                        font.pixelSize: Math.round(11 * page.fontScale)
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            page.addReply(addReplyInput.text)
                                            addReplyInput.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96
                        radius: 12
                        color: PopupTheme.panelBackground(page.stylePreset)
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 5

                            Text {
                                text: "Scheduled Messages"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: Math.round(13 * page.fontScale)
                                font.bold: true
                            }

                            Repeater {
                                model: Math.min(2, page.scheduledMessages.length)
                                delegate: Text {
                                    required property int index
                                    text: "• " + page.scheduledMessages[index]
                                    color: PopupTheme.subtitleColor(page.stylePreset)
                                    font.pixelSize: Math.round(11 * page.fontScale)
                                    elide: Text.ElideRight
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                TextField {
                                    id: addScheduleInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    placeholderText: "Add schedule"
                                    color: PopupTheme.titleColor(page.stylePreset)
                                    placeholderTextColor: PopupTheme.subtitleColor(page.stylePreset)
                                    background: Rectangle {
                                        radius: 8
                                        color: "transparent"
                                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                                        border.width: 1
                                    }
                                }

                                Rectangle {
                                    width: 46
                                    height: 30
                                    radius: 8
                                    color: "#0F4D52"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Add"
                                        color: "#FFFFFF"
                                        font.pixelSize: Math.round(11 * page.fontScale)
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            page.addSchedule(addScheduleInput.text)
                                            addScheduleInput.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Active: "
                              + (page.autoReplyEnabled ? "Auto Reply" : "")
                              + ((page.autoReplyEnabled && page.scheduleEnabled) ? " · " : "")
                              + (page.scheduleEnabled ? "Scheduled Actions" : "")
                              + ((page.safeModeEnabled && (page.autoReplyEnabled || page.scheduleEnabled)) ? " · " : "")
                              + (page.safeModeEnabled ? "Safe Mode" : "")
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(12 * page.fontScale)
                        wrapMode: Text.Wrap
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 12
                        color: "#0F4D52"

                        Text {
                            anchors.centerIn: parent
                            text: "Save & Return"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(13 * page.fontScale)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                page.saveRequested(page.autoReplyEnabled, page.scheduleEnabled, page.safeModeEnabled)
                                page.backRequested()
                            }
                        }
                    }
                    }
                }
            }
        }
    }
}
