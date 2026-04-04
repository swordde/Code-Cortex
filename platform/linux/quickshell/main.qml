import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: popupOnlyMode ? 420 : 1280
    height: popupOnlyMode ? 220 : 760
    title: popupOnlyMode ? "SNP Popup Preview" : "SNP QuickShell"
    color: popupOnlyMode ? "#00000000" : "#0b1118"

    // Presets: densePro, cleanGlass, neonGamer
    property string popupPreset: "densePro"
    property int popupDurationMs: 5000
    property bool popupOnlyMode: isPopupOnlyMode()
    property bool demoMode: isDemoMode()

    property var notificationHistory: []
    property var popupQueue: []
    property var activePopup: null

    flags: popupOnlyMode
        ? (Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint)
        : Qt.Window

    function isDemoMode() {
        var args = Qt.application.arguments
        for (var i = 0; i < args.length; i++) {
            if (args[i] === "--demo") {
                return true
            }
        }
        return false
    }

    function isPopupOnlyMode() {
        var args = Qt.application.arguments
        for (var i = 0; i < args.length; i++) {
            if (args[i] === "--popup-only") {
                return true
            }
        }
        return false
    }

    function seedDemoNotifications() {
        ingestNotificationFromBackend({
            sender: "Mom",
            app: "Signal",
            preview: "Call me when you can.",
            priority: "EMERGENCY",
            timestamp: "09:11"
        })

        ingestNotificationFromBackend({
            sender: "Team Lead",
            app: "Slack",
            preview: "Need the release status in 10 mins.",
            priority: "HIGH",
            timestamp: "09:14"
        })

        ingestNotificationFromBackend({
            sender: "Calendar",
            app: "System",
            preview: "Study session starts in 15 minutes.",
            priority: "MEDIUM",
            timestamp: "09:19"
        })

        ingestNotificationFromBackend({
            sender: "Promo",
            app: "Shopping",
            preview: "Weekend sale now live.",
            priority: "LOW",
            timestamp: "09:21"
        })
    }

    Component.onCompleted: {
        if (popupOnlyMode) {
            if (activePopup && activePopup.priority === "EMERGENCY") {
                x = (Screen.width - width) / 2
                y = (Screen.height - height) / 2
            } else {
                x = Screen.width - width - 20
                y = Screen.height - height - 20
            }
        }

        if (demoMode) {
            seedDemoNotifications()
        }
    }

    Timer {
        id: popupTimer
        interval: root.popupDurationMs
        repeat: false
        running: false
        onTriggered: {
            root.activePopup = null
            root.showNextPopup()

            if (root.popupOnlyMode && root.demoMode && root.popupQueue.length === 0 && root.activePopup === null) {
                Qt.quit()
            }
        }
    }

    Rectangle {
        visible: !root.popupOnlyMode
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#101a25" }
            GradientStop { position: 1.0; color: "#0b1118" }
        }
    }

    NotificationCenter {
        id: centerPanel
        visible: !root.popupOnlyMode
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        notifications: root.notificationHistory
        expanded: true
    }

    WellbeingOverlay {
        id: wellbeing
        visible: !root.popupOnlyMode
        anchors.left: centerPanel.right
        anchors.leftMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        emergencyCount: countHistoryPriority("EMERGENCY")
        highCount: countHistoryPriority("HIGH")
        mediumCount: countHistoryPriority("MEDIUM")
        lowCount: countHistoryPriority("LOW")
    }

    NotificationPopup {
        id: activeNotificationPopup
        visible: root.activePopup !== null
        width: 360
        x: {
            if (root.popupOnlyMode) return (root.width - width) / 2
            if (!root.activePopup) return root.width - width - 16
            if (root.activePopup.priority === "EMERGENCY") return (root.width - width) / 2
            return root.width - width - 16
        }
        y: {
            if (root.popupOnlyMode) return (root.height - height) / 2
            if (!root.activePopup) return 16
            if (root.activePopup.priority === "EMERGENCY") return (root.height - height) / 2
            if (root.activePopup.priority === "HIGH") return 16
            return root.height - height - 16
        }

        sender: root.activePopup ? root.activePopup.sender : ""
        app: root.activePopup ? root.activePopup.app : ""
        preview: root.activePopup ? root.activePopup.preview : ""
        priority: root.activePopup ? root.activePopup.priority : "LOW"
        timestamp: root.activePopup ? root.activePopup.timestamp : ""
        stylePreset: root.popupPreset

        onDismissed: {
            popupTimer.stop()
            root.activePopup = null
            root.showNextPopup()

            if (root.popupOnlyMode && root.demoMode && root.popupQueue.length === 0 && root.activePopup === null) {
                Qt.quit()
            }
        }
    }

    function ingestNotificationFromBackend(n) {
        if (!n || !n.priority) {
            return
        }

        var row = {
            sender: n.sender || "Unknown",
            app: n.app || "System",
            preview: n.preview || "",
            priority: n.priority,
            timestamp: n.timestamp || Qt.formatTime(new Date(), "hh:mm")
        }

        notificationHistory = [row].concat(notificationHistory).slice(0, 200)

        popupQueue.push(row)
        if (!activePopup) {
            showNextPopup()
        }
    }

    function showNextPopup() {
        if (popupQueue.length === 0) {
            activePopup = null
            return
        }

        activePopup = popupQueue.shift()

        if (popupOnlyMode) {
            if (activePopup.priority === "EMERGENCY") {
                x = (Screen.width - width) / 2
                y = (Screen.height - height) / 2
            } else {
                x = Screen.width - width - 20
                y = Screen.height - height - 20
            }
        }

        popupTimer.restart()
    }

    function countHistoryPriority(p) {
        var total = 0
        for (var i = 0; i < notificationHistory.length; i++) {
            if (notificationHistory[i].priority === p) {
                total++
            }
        }
        return total
    }
}
