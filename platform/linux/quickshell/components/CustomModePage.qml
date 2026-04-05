import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCore
import Qt.labs.folderlistmodel 2.15
import "PopupTheme.js" as PopupTheme

Item {
    id: page

    property string stylePreset: "projectCore"
    readonly property real fontScale: 1.4
    property string activeContext: ""
    property var contexts: []
    property bool contactsEnabled: true
    property bool keywordsEnabled: true
    property bool appPriorityEnabled: true
    property var priorityContacts: ["Mom (Emergency)", "Professor (High)", "Team Lead (Medium)"]
    property var keywordRules: ["urgent -> Emergency", "deadline -> High", "meeting -> High"]
    property var allApps: []
    property var appPriorities: []

    signal backRequested
    signal saveRequested(var contexts, string activeContext, bool contactsEnabled, bool keywordsEnabled, bool appPriorityEnabled)

    function appendTo(arrayValue, text) {
        var t = text.trim()
        if (t.length === 0) return arrayValue
        return arrayValue.concat([t])
    }

    function hasAppPriority(appName) {
        return appPriorities.indexOf(appName) !== -1
    }

    function toggleAppPriority(appName) {
        var copy = appPriorities.slice(0)
        var idx = copy.indexOf(appName)
        if (idx === -1) {
            copy.push(appName)
        } else {
            copy.splice(idx, 1)
        }
        appPriorities = copy
    }

    function addContextName(nameText) {
        var name = nameText.trim()
        if (name.length === 0) return

        for (var i = 0; i < contexts.length; i++) {
            if (contexts[i].toLowerCase() === name.toLowerCase()) {
                activeContext = contexts[i]
                return
            }
        }

        contexts = contexts.concat([name])
        activeContext = name
    }

    function desktopFileToAppName(fileName) {
        var name = fileName
        if (name.endsWith(".desktop")) {
            name = name.substring(0, name.length - 8)
        }
        name = name.replace(/^org\.[^.]+\./, "")
        name = name.replace(/^com\.[^.]+\./, "")
        name = name.replace(/^io\.[^.]+\./, "")
        name = name.replace(/[-_]+/g, " ").trim()
        if (name.length > 0) {
            name = name.charAt(0).toUpperCase() + name.slice(1)
        }
        return name.length > 0 ? name : fileName
    }

    function collectAppsFromModel(model, map, apps) {
        for (var i = 0; i < model.count; i++) {
            var fileName = model.get(i, "fileName")
            var appName = desktopFileToAppName(fileName)
            var key = appName.toLowerCase()
            if (!map[key]) {
                map[key] = true
                apps.push(appName)
            }
        }
    }

    function refreshSystemApps() {
        var map = {}
        var apps = []

        collectAppsFromModel(systemAppsModel, map, apps)
        collectAppsFromModel(localAppsModel, map, apps)
        collectAppsFromModel(localSystemAppsModel, map, apps)
        collectAppsFromModel(localFlatpakAppsModel, map, apps)
        collectAppsFromModel(systemFlatpakAppsModel, map, apps)

        apps.sort(function(a, b) {
            return a.localeCompare(b)
        })

        allApps = apps

        var selected = []
        for (var k = 0; k < appPriorities.length; k++) {
            if (map[appPriorities[k].toLowerCase()]) {
                selected.push(appPriorities[k])
            }
        }
        appPriorities = selected
    }

    FolderListModel {
        id: systemAppsModel
        folder: "file:///usr/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: page.refreshSystemApps()
    }

    FolderListModel {
        id: localAppsModel
        folder: "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: page.refreshSystemApps()
    }

    FolderListModel {
        id: localSystemAppsModel
        folder: "file:///usr/local/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: page.refreshSystemApps()
    }

    FolderListModel {
        id: localFlatpakAppsModel
        folder: "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/flatpak/exports/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: page.refreshSystemApps()
    }

    FolderListModel {
        id: systemFlatpakAppsModel
        folder: "file:///var/lib/flatpak/exports/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: page.refreshSystemApps()
    }

    Component.onCompleted: refreshSystemApps()

    Rectangle {
        anchors.fill: parent
        color: PopupTheme.panelBackground(page.stylePreset)

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 24, 1140)
            height: Math.min(parent.height - 24, 820)
            radius: 18
            color: PopupTheme.buttonBackground(page.stylePreset)
            border.color: PopupTheme.buttonBorder(page.stylePreset)
            border.width: 1

            Flickable {
                anchors.fill: parent
                anchors.margins: 22
                clip: true
                contentWidth: width
                contentHeight: mainColumn.implicitHeight

                ColumnLayout {
                    id: mainColumn
                    width: parent.width
                    spacing: 18

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "<"
                        color: PopupTheme.titleColor(page.stylePreset)
                        font.pixelSize: Math.round(20 * page.fontScale)
                        font.bold: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                page.saveRequested(page.contexts, page.activeContext, page.contactsEnabled, page.keywordsEnabled, page.appPriorityEnabled)
                                page.backRequested()
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Custom Mode"
                            color: PopupTheme.titleColor(page.stylePreset)
                            font.pixelSize: Math.round(18 * page.fontScale)
                            font.bold: true
                        }

                        Text {
                            text: "Manage contexts, contacts, keywords, and app priorities."
                            color: PopupTheme.subtitleColor(page.stylePreset)
                            font.pixelSize: Math.round(12 * page.fontScale)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 12
                    color: PopupTheme.panelBackground(page.stylePreset)
                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            visible: page.contexts.length === 0
                            Layout.fillWidth: true
                            text: "No custom modes yet. Add one below."
                            color: PopupTheme.subtitleColor(page.stylePreset)
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Math.round(11 * page.fontScale)
                            font.bold: true
                        }

                        Repeater {
                            model: page.contexts
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: page.activeContext === modelData ? "#0F4D52" : PopupTheme.buttonBackground(page.stylePreset)
                                border.color: PopupTheme.buttonBorder(page.stylePreset)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: page.activeContext === modelData ? "#FFFFFF" : PopupTheme.buttonText(page.stylePreset)
                                    font.pixelSize: Math.round(12 * page.fontScale)
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: page.activeContext = modelData
                                }
                            }
                        }
                    }
                }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                    TextField {
                        id: addModeInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        placeholderText: "Add custom mode name"
                        color: PopupTheme.titleColor(page.stylePreset)
                        placeholderTextColor: PopupTheme.subtitleColor(page.stylePreset)
                        background: Rectangle {
                            radius: 9
                            color: "transparent"
                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                            border.width: 1
                        }
                        onAccepted: {
                            page.addContextName(text)
                            text = ""
                        }
                    }

                    Rectangle {
                        width: 120
                        height: 38
                        radius: 9
                        color: "#0F4D52"

                        Text {
                            anchors.centerIn: parent
                            text: "+ Add Mode"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(11 * page.fontScale)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                page.addContextName(addModeInput.text)
                                addModeInput.text = ""
                            }
                        }
                    }
                }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                    Repeater {
                        model: [
                            { label: "Priority Contacts", value: page.contactsEnabled },
                            { label: "Keyword Triggers", value: page.keywordsEnabled },
                            { label: "App Priority Rules", value: page.appPriorityEnabled }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 10
                            color: PopupTheme.panelBackground(page.stylePreset)
                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: PopupTheme.titleColor(page.stylePreset)
                                    font.pixelSize: Math.round(12 * page.fontScale)
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.value ? "ON" : "OFF"
                                    color: modelData.value ? "#2E7D7D" : "#BD3124"
                                    font.pixelSize: Math.round(11 * page.fontScale)
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.label === "Priority Contacts") {
                                        page.contactsEnabled = !page.contactsEnabled
                                    } else if (modelData.label === "Keyword Triggers") {
                                        page.keywordsEnabled = !page.keywordsEnabled
                                    } else {
                                        page.appPriorityEnabled = !page.appPriorityEnabled
                                    }
                                }
                            }
                        }
                    }
                }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: PopupTheme.panelBackground(page.stylePreset)
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "Priority Contacts"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: Math.round(13 * page.fontScale)
                                font.bold: true
                            }

                            Repeater {
                                model: Math.min(4, page.priorityContacts.length)
                                delegate: Text {
                                    required property int index
                                    text: "• " + page.priorityContacts[index]
                                    color: PopupTheme.subtitleColor(page.stylePreset)
                                    font.pixelSize: Math.round(11 * page.fontScale)
                                    elide: Text.ElideRight
                                }
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                TextField {
                                    id: addContactInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    placeholderText: "Add contact + priority"
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
                                    width: 62
                                    height: 36
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
                                            page.priorityContacts = page.appendTo(page.priorityContacts, addContactInput.text)
                                            addContactInput.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: PopupTheme.panelBackground(page.stylePreset)
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "Keywords"
                                color: PopupTheme.titleColor(page.stylePreset)
                                font.pixelSize: Math.round(13 * page.fontScale)
                                font.bold: true
                            }

                            Flow {
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: Math.min(8, page.keywordRules.length)
                                    delegate: Rectangle {
                                        required property int index
                                        radius: 10
                                        color: PopupTheme.buttonBackground(page.stylePreset)
                                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                                        border.width: 1
                                        implicitHeight: 24
                                        implicitWidth: keywordText.implicitWidth + 12

                                        Text {
                                            id: keywordText
                                            anchors.centerIn: parent
                                            text: page.keywordRules[index]
                                            color: PopupTheme.buttonText(page.stylePreset)
                                            font.pixelSize: Math.round(10 * page.fontScale)
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                TextField {
                                    id: addKeywordInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    placeholderText: "Add keyword rule"
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
                                    width: 62
                                    height: 36
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
                                            page.keywordRules = page.appendTo(page.keywordRules, addKeywordInput.text)
                                            addKeywordInput.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(220, appFlow.implicitHeight + 92)
                    radius: 10
                    color: PopupTheme.panelBackground(page.stylePreset)
                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Text {
                            text: "App Priorities"
                            color: PopupTheme.titleColor(page.stylePreset)
                            font.pixelSize: Math.round(13 * page.fontScale)
                            font.bold: true
                        }

                        Text {
                            text: "Click apps to toggle priority (" + page.appPriorities.length + " selected)"
                            color: PopupTheme.subtitleColor(page.stylePreset)
                            font.pixelSize: Math.round(11 * page.fontScale)
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: appFlow.implicitHeight

                            Flow {
                                id: appFlow
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: page.allApps
                                    delegate: Rectangle {
                                        required property var modelData
                                        radius: 10
                                        color: page.hasAppPriority(modelData)
                                            ? "#0F4D52"
                                            : PopupTheme.buttonBackground(page.stylePreset)
                                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                                        border.width: 1
                                        implicitHeight: 30
                                        implicitWidth: Math.min(220, appText.implicitWidth + 18)

                                        Text {
                                            id: appText
                                            anchors.centerIn: parent
                                            width: Math.min(200, implicitWidth)
                                            text: modelData
                                            color: page.hasAppPriority(modelData)
                                                ? "#FFFFFF"
                                                : PopupTheme.buttonText(page.stylePreset)
                                            font.pixelSize: Math.round(11 * page.fontScale)
                                            font.bold: true
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: page.toggleAppPriority(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 12
                        color: "#0F4D52"

                    Text {
                        anchors.centerIn: parent
                        text: "Apply & Return"
                        color: "#FFFFFF"
                        font.pixelSize: Math.round(13 * page.fontScale)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            page.saveRequested(page.contexts, page.activeContext, page.contactsEnabled, page.keywordsEnabled, page.appPriorityEnabled)
                            page.backRequested()
                        }
                    }
                    }
                }
            }
        }
    }
}
