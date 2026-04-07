import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtCore
import "components"
import "components/PopupTheme.js" as PopupTheme

ApplicationWindow {
    id: root
    visible: true
    width: popupOnlyMode ? 420 : 1280
    height: popupOnlyMode ? 220 : 760
    title: popupOnlyMode ? "Cortex Popup Preview" : "Cortex QuickShell"
    color: popupOnlyMode
        ? "#00000000"
        : (popupPreset === "batNoir" ? "#0D111A" : "#F2F2F2")

    // Presets: projectCore, batNoir, densePro, cleanGlass, neonGamer
    property string popupPreset: "projectCore"
    readonly property var availablePresets: ["projectCore", "batNoir", "densePro", "cleanGlass", "neonGamer"]
    property int popupDurationMs: popupOnlyMode ? 12000 : 5000
    property bool popupOnlyMode: isPopupOnlyMode()
    property bool popupOnceMode: argumentValue("--popup-once", "0") === "1"
    property bool demoMode: isDemoMode()
    property string currentRoute: "dashboard"
    property string systemOsName: argumentValue("--sys-os", "Linux")
    property string systemKernel: argumentValue("--sys-kernel", "unknown")
    property string systemArch: argumentValue("--sys-arch", "unknown")
    property string systemDesktop: argumentValue("--sys-desktop", "unknown")
    property string systemSession: argumentValue("--sys-session", "unknown")
    property string backendHost: argumentValue("--backend-host", "localhost")
    property string backendPort: argumentValue("--backend-port", "8080")
    property bool useSystemNotifications: argumentValue("--use-system-notifications", "0") === "1"
    readonly property string backendBaseUrl: "http://" + backendHost + ":" + backendPort
    property real systemLoadOne: parseFloat(argumentValue("--sys-load1", "0"))
    property int systemMemUsedPercent: parseInt(argumentValue("--sys-mem-used", "0"))
    property string systemUptime: argumentValue("--sys-uptime", "0h 0m")
    property bool cortexAutoReplyEnabled: true
    property bool cortexScheduleEnabled: true
    property bool cortexSafeModeEnabled: false
    property string customActiveContext: ""
    property var customModes: []
    property bool customContactsEnabled: true
    property bool customKeywordsEnabled: true
    property bool customAppPriorityEnabled: true
    property var customModeIdsByName: ({})
    property string customModeSyncStatus: "idle"
    property string popupSenderArg: argumentValue("--popup-sender", "")
    property string popupAppArg: argumentValue("--popup-app", "")
    property string popupPreviewArg: argumentValue("--popup-preview", "")
    property string popupPriorityArg: argumentValue("--popup-priority", "LOW")
    property string popupTimestampArg: argumentValue("--popup-timestamp", "")

    property var notificationHistory: []
    property var popupQueue: []
    property var activePopup: null
    property var seenNotificationIds: ({})
    property bool notificationsPrimed: false

    TextEdit {
        id: clipboardBuffer
        visible: false
    }

    property int emergencyCount: countHistoryPriority("EMERGENCY")
    property int highCount: countHistoryPriority("HIGH")
    property int mediumCount: countHistoryPriority("MEDIUM")
    property int lowCount: countHistoryPriority("LOW")
    property int totalCount: emergencyCount + highCount + mediumCount + lowCount
    property int needingAttention: emergencyCount + highCount
    property real focusPercent: totalCount === 0
        ? 0.0
        : Math.min(1.0, (emergencyCount * 1.0 + highCount * 0.75 + mediumCount * 0.45) / totalCount)

    flags: popupOnlyMode
        ? (Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint)
        : Qt.Window

    Settings {
        id: userSettings
        category: "dashboard"
        property string savedPreset: "projectCore"
    }

    Settings {
        id: profileSettings
        category: "profile"
        property string userName: ""
        property bool voiceRegistered: false
    }

    Settings {
        id: customModeSettings
        category: "customMode"
        property string modesJson: "[]"
        property string activeContext: ""
        property bool contactsEnabled: true
        property bool keywordsEnabled: true
        property bool appPriorityEnabled: true
    }

    onPopupPresetChanged: {
        if (isSupportedPreset(popupPreset)) {
            userSettings.savedPreset = popupPreset
        }
    }

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

    function isSupportedPreset(presetName) {
        for (var i = 0; i < availablePresets.length; i++) {
            if (availablePresets[i] === presetName) {
                return true
            }
        }
        return false
    }

    function hasRegisteredUser() {
        return profileSettings.userName.trim().length > 0 && profileSettings.voiceRegistered
    }

    function argumentValue(flagName, fallback) {
        var args = Qt.application.arguments
        for (var i = 0; i < args.length - 1; i++) {
            if (args[i] === flagName) {
                return args[i + 1]
            }
        }
        return fallback
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
        if (isSupportedPreset(userSettings.savedPreset)) {
            popupPreset = userSettings.savedPreset
        }

        var savedModes = []
        try {
            var parsedModes = JSON.parse(customModeSettings.modesJson)
            if (parsedModes && parsedModes.length !== undefined) {
                savedModes = parsedModes
            }
        } catch (modeParseError) {
            savedModes = []
        }

        customModes = savedModes
        customActiveContext = customModeSettings.activeContext
        customContactsEnabled = customModeSettings.contactsEnabled
        customKeywordsEnabled = customModeSettings.keywordsEnabled
        customAppPriorityEnabled = customModeSettings.appPriorityEnabled

        if (customActiveContext.length === 0 && customModes.length > 0) {
            customActiveContext = customModes[0]
        }

        if (popupOnlyMode) {
            if (activePopup && activePopup.priority === "EMERGENCY") {
                x = (Screen.width - width) / 2
                y = (Screen.height - height) / 2
            } else {
                x = Screen.width - width - 20
                y = Screen.height - height - 20
            }
            root.raise()
            root.requestActivate()
        }

        if (demoMode) {
            seedDemoNotifications()
        }

        if (popupOnlyMode && popupPreviewArg.length > 0) {
            activePopup = {
                sender: popupSenderArg.length > 0 ? popupSenderArg : "Unknown",
                app: popupAppArg.length > 0 ? popupAppArg : "System",
                preview: popupPreviewArg,
                priority: (popupPriorityArg.length > 0 ? popupPriorityArg : "LOW").toUpperCase(),
                timestamp: popupTimestampArg.length > 0 ? popupTimestampArg : Qt.formatTime(new Date(), "hh:mm")
            }
            popupTimer.restart()
        }

        currentRoute = hasRegisteredUser() ? "dashboard" : "landing"
        syncBackendState()
    }

    Timer {
        id: popupTimer
        interval: root.popupDurationMs
        repeat: false
        running: false
        onTriggered: {
            root.activePopup = null
            root.showNextPopup()

            if (root.popupOnlyMode && (root.demoMode || root.popupOnceMode) && root.popupQueue.length === 0 && root.activePopup === null) {
                Qt.quit()
            }
        }
    }

    Timer {
        id: backendPollTimer
        interval: 10000
        repeat: true
        running: !root.popupOnlyMode
        triggeredOnStart: true
        onTriggered: {
            if (!root.demoMode) {
                root.refreshNotificationsFromBackend()
            }
        }
    }

    Rectangle {
        visible: !root.popupOnlyMode
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.popupPreset === "batNoir" ? "#101520" : "#F4F4F5"
            }
            GradientStop {
                position: 1.0
                color: root.popupPreset === "batNoir" ? "#0B111C" : "#ECEDEF"
            }
        }
    }

    NotificationCenter {
        id: centerPanel
        visible: !root.popupOnlyMode && root.currentRoute === "dashboard"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        notifications: root.notificationHistory
        expanded: true
        stylePreset: root.popupPreset
        hostWidth: root.width
        onReplyRequested: (notificationId) => {
            root.generateReplyCopyAndOpenWhatsApp(notificationId)
        }
    }

    DashboardOverview {
        id: dashboardOverview
        visible: !root.popupOnlyMode && root.currentRoute === "dashboard"
        anchors.left: centerPanel.right
        anchors.leftMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        stylePreset: root.popupPreset
        emergencyCount: root.emergencyCount
        highCount: root.highCount
        mediumCount: root.mediumCount
        lowCount: root.lowCount
        totalCount: root.totalCount
        needingAttention: root.needingAttention
        focusPercent: root.focusPercent
        systemOsName: root.systemOsName
        systemKernel: root.systemKernel
        systemArch: root.systemArch
        systemDesktop: root.systemDesktop
        systemSession: root.systemSession
        systemLoadOne: root.systemLoadOne
        systemMemUsedPercent: root.systemMemUsedPercent
        systemUptime: root.systemUptime
        cortexAutoReplyEnabled: root.cortexAutoReplyEnabled
        cortexScheduleEnabled: root.cortexScheduleEnabled
        cortexSafeModeEnabled: root.cortexSafeModeEnabled
        customModes: root.customModes
        customActiveContext: root.customActiveContext
        customContactsEnabled: root.customContactsEnabled
        customKeywordsEnabled: root.customKeywordsEnabled
        customAppPriorityEnabled: root.customAppPriorityEnabled
        onPresetSelected: (preset) => {
            root.popupPreset = preset
        }
        onNavigateToRoute: (route) => {
            root.currentRoute = route
        }
        onCustomModesUpdated: (modes, activeContext) => {
            root.customModes = modes
            root.customActiveContext = activeContext
            root.persistCustomLocalState()
            root.pushCustomModesToBackend()
        }
    }

    Rectangle {
        id: routeSurface
        visible: !root.popupOnlyMode && root.currentRoute !== "dashboard"
        anchors.fill: parent
        color: root.popupPreset === "batNoir" ? "#0D111A" : "#F2F2F2"

        Loader {
            anchors.fill: parent
            anchors.margins: 12
            sourceComponent: {
                if (root.currentRoute === "landing") return landingPageComponent
                if (root.currentRoute === "createAccount") return createAccountPageComponent
                if (root.currentRoute === "profile") return profilePageComponent
                if (root.currentRoute === "cortexMode") return cortexModePageComponent
                if (root.currentRoute === "customMode") return customModePageComponent
                return landingPageComponent
            }
        }
    }

    Component {
        id: landingPageComponent

        LandingPage {
            stylePreset: root.popupPreset
            onCreateAccountRequested: root.currentRoute = "createAccount"
            onSkipRequested: root.currentRoute = root.hasRegisteredUser() ? "dashboard" : "createAccount"
        }
    }

    Component {
        id: createAccountPageComponent

        CreateAccountPage {
            stylePreset: root.popupPreset
            onBackRequested: root.currentRoute = "landing"
            onContinueRequested: (name) => {
                profileSettings.userName = name
                profileSettings.voiceRegistered = true
                root.pushProfileToBackend(name)
                root.currentRoute = "dashboard"
            }
        }
    }

    Component {
        id: profilePageComponent

        ProfilePage {
            stylePreset: root.popupPreset
            displayName: profileSettings.userName.trim().length > 0 ? profileSettings.userName : "S"
            onBackRequested: root.currentRoute = "dashboard"
            onOpenCortexRequested: root.currentRoute = "cortexMode"
        }
    }

    Component {
        id: cortexModePageComponent

        CortexModePage {
            stylePreset: root.popupPreset
            autoReplyEnabled: root.cortexAutoReplyEnabled
            scheduleEnabled: root.cortexScheduleEnabled
            safeModeEnabled: root.cortexSafeModeEnabled
            onSaveRequested: (autoReplyEnabled, scheduleEnabled, safeModeEnabled) => {
                root.cortexAutoReplyEnabled = autoReplyEnabled
                root.cortexScheduleEnabled = scheduleEnabled
                root.cortexSafeModeEnabled = safeModeEnabled
                root.pushCortexConfigToBackend()
            }
            onBackRequested: root.currentRoute = "dashboard"
        }
    }

    Component {
        id: customModePageComponent

        CustomModePage {
            stylePreset: root.popupPreset
            contexts: root.customModes
            activeContext: root.customActiveContext
            contactsEnabled: root.customContactsEnabled
            keywordsEnabled: root.customKeywordsEnabled
            appPriorityEnabled: root.customAppPriorityEnabled
            onSaveRequested: (contexts, activeContext, contactsEnabled, keywordsEnabled, appPriorityEnabled) => {
                root.customModes = contexts
                root.customActiveContext = activeContext
                root.customContactsEnabled = contactsEnabled
                root.customKeywordsEnabled = keywordsEnabled
                root.customAppPriorityEnabled = appPriorityEnabled
                root.persistCustomLocalState()
                root.pushCustomModesToBackend()
            }
            onBackRequested: root.currentRoute = "dashboard"
        }
    }

    NotificationPopup {
        id: activeNotificationPopup
        visible: root.popupOnlyMode && !root.useSystemNotifications && root.activePopup !== null
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
        notificationId: root.activePopup ? (root.activePopup.id || "") : ""
        stylePreset: root.popupPreset

        onReplyRequested: (notificationId) => {
            root.generateReplyCopyAndOpenWhatsApp(notificationId)
        }

        onDismissed: {
            popupTimer.stop()
            root.activePopup = null
            root.showNextPopup()

            if (root.popupOnlyMode && (root.demoMode || root.popupOnceMode) && root.popupQueue.length === 0 && root.activePopup === null) {
                Qt.quit()
            }
        }
    }

    Window {
        id: floatingPopupWindow
        visible: !root.popupOnlyMode && !root.useSystemNotifications && root.activePopup !== null
        width: 372
        height: floatingNotificationPopup.height + 12
        color: "#00000000"
        flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint

        onVisibleChanged: {
            if (visible) {
                floatingPopupWindow.raise()
                floatingPopupWindow.requestActivate()
            }
        }

        x: {
            if (!root.activePopup) return Screen.width - width - 20
            if (root.activePopup.priority === "EMERGENCY") return (Screen.width - width) / 2
            return Screen.width - width - 20
        }

        y: {
            if (!root.activePopup) return Screen.height - height - 20
            if (root.activePopup.priority === "EMERGENCY") return (Screen.height - height) / 2
            if (root.activePopup.priority === "HIGH") return 20
            return Screen.height - height - 20
        }

        NotificationPopup {
            id: floatingNotificationPopup
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            sender: root.activePopup ? root.activePopup.sender : ""
            app: root.activePopup ? root.activePopup.app : ""
            preview: root.activePopup ? root.activePopup.preview : ""
            priority: root.activePopup ? root.activePopup.priority : "LOW"
            timestamp: root.activePopup ? root.activePopup.timestamp : ""
            notificationId: root.activePopup ? (root.activePopup.id || "") : ""
            stylePreset: root.popupPreset

            onReplyRequested: (notificationId) => {
                root.generateReplyCopyAndOpenWhatsApp(notificationId)
            }

            onDismissed: {
                popupTimer.stop()
                root.activePopup = null
                root.showNextPopup()
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

        if (useSystemNotifications) {
            return
        }

        popupQueue.push(row)
        if (!activePopup) {
            showNextPopup()
        }
    }

    function backendRequest(method, path, payload, onSuccess, onError) {
        var xhr = new XMLHttpRequest()
        xhr.open(method, backendBaseUrl + path)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return
            }

            var body = null
            if (xhr.responseText && xhr.responseText.length > 0) {
                try {
                    body = JSON.parse(xhr.responseText)
                } catch (parseError) {
                    body = xhr.responseText
                }
            }

            if (xhr.status >= 200 && xhr.status < 300) {
                if (onSuccess) {
                    onSuccess(body, xhr.status)
                }
            } else {
                if (onError) {
                    onError(xhr.status, body)
                } else {
                    console.warn("backendRequest failed", method, path, xhr.status)
                }
            }
        }
        xhr.send(payload ? JSON.stringify(payload) : null)
    }

    function rowFromNotification(n) {
        var when = Qt.formatTime(new Date(), "hh:mm")
        if (n.timestamp) {
            var ts = new Date(n.timestamp)
            if (!isNaN(ts.getTime())) {
                when = Qt.formatTime(ts, "hh:mm")
            }
        }

        return {
            id: n.id || "",
            sender: n.sender_name || "Unknown",
            app: n.app_name || n.app_package || "System",
            preview: n.content || "",
            priority: (n.priority || "LOW").toUpperCase(),
            timestamp: when,
            generatedReply: ""
        }
    }

    function updateGeneratedReplyInHistory(notificationId, replyText) {
        if (!notificationId || notificationId.length === 0) {
            return
        }

        var updated = []
        for (var i = 0; i < notificationHistory.length; i++) {
            var row = notificationHistory[i]
            if ((row.id || "") === notificationId) {
                row.generatedReply = replyText
            }
            updated.push(row)
        }
        notificationHistory = updated

        if (centerPanel.selectedNotification && (centerPanel.selectedNotification.id || "") === notificationId) {
            centerPanel.selectedNotification.generatedReply = replyText
        }
    }

    function copyTextToClipboard(text) {
        if (!text || text.length === 0) {
            return
        }
        clipboardBuffer.text = text
        clipboardBuffer.selectAll()
        clipboardBuffer.copy()
        clipboardBuffer.deselect()
    }

    function openWhatsAppWithText(text) {
        if (!text || text.length === 0) {
            Qt.openUrlExternally("https://web.whatsapp.com")
            return
        }

        var target = "https://web.whatsapp.com/send?text=" + encodeURIComponent(text)
        Qt.openUrlExternally(target)
    }

    function generateReplyCopyAndOpenWhatsApp(notificationId) {
        if (!notificationId || notificationId.length === 0) {
            var quickFallback = ""
            if (activePopup && activePopup.preview) {
                quickFallback = String(activePopup.preview)
            }
            if (quickFallback.length > 0) {
                copyTextToClipboard(quickFallback)
                openWhatsAppWithText(quickFallback)
            }
            return
        }

        backendRequest("POST", "/api/notifications/" + notificationId + "/reply", null, function(res) {
            var replyText = ""
            if (res && res.reply) {
                replyText = String(res.reply)
            }

            if (replyText.length === 0) {
                replyText = "Cortex could not generate a reply for this notification."
            }

            updateGeneratedReplyInHistory(notificationId, replyText)
            copyTextToClipboard(replyText)
            openWhatsAppWithText(replyText)
        }, function(status) {
            var fallback = "Failed to generate Cortex reply (" + status + ")."
            updateGeneratedReplyInHistory(notificationId, fallback)
        })
    }

    function syncBackendState() {
        if (popupOnlyMode || demoMode) {
            return
        }
        syncProfileFromBackend()
        syncCortexFromBackend()
        syncModesFromBackend()
        refreshNotificationsFromBackend()
    }

    function refreshNotificationsFromBackend() {
        backendRequest("GET", "/api/notifications", null, function(items) {
            if (!items || items.length === undefined) {
                return
            }
            var rows = []
            var latestIds = ({})
            var newRows = []
            for (var i = 0; i < items.length; i++) {
                var row = rowFromNotification(items[i])
                rows.push(row)
                if (row.id && row.id.length > 0) {
                    latestIds[row.id] = true
                    if (notificationsPrimed && !seenNotificationIds[row.id]) {
                        newRows.push(row)
                    }
                }
            }
            notificationHistory = rows.slice(0, 200)
            seenNotificationIds = latestIds

            if (!notificationsPrimed) {
                notificationsPrimed = true
                return
            }

            if (useSystemNotifications) {
                return
            }

            for (var j = newRows.length - 1; j >= 0; j--) {
                popupQueue.push(newRows[j])
            }
            if (!activePopup && popupQueue.length > 0) {
                showNextPopup()
            }
        })
    }

    function syncProfileFromBackend() {
        backendRequest("GET", "/api/profile", null, function(profile) {
            if (!profile || !profile.display_name) {
                return
            }
            profileSettings.userName = profile.display_name
            profileSettings.voiceRegistered = true
            if (currentRoute === "landing") {
                currentRoute = "dashboard"
            }
        })
    }

    function pushProfileToBackend(name) {
        backendRequest("PUT", "/api/profile", {
            display_name: name,
            avatar_path: "",
            notif_permission: true,
            theme_mode: "system",
            linked_accounts: []
        })
    }

    function syncCortexFromBackend() {
        backendRequest("GET", "/api/cortex/config", null, function(config) {
            if (!config) {
                return
            }
            cortexAutoReplyEnabled = !!config.auto_reply
            cortexScheduleEnabled = config.scope !== "off"
            cortexSafeModeEnabled = false
        })
    }

    function pushCortexConfigToBackend() {
        backendRequest("PUT", "/api/cortex/config", {
            enabled: cortexAutoReplyEnabled || cortexScheduleEnabled,
            auto_reply: cortexAutoReplyEnabled,
            scope: cortexScheduleEnabled ? "global" : "off"
        })
    }

    function syncModesFromBackend() {
        backendRequest("GET", "/api/modes", null, function(items) {
            if (!items || items.length === undefined) {
                return
            }

            var names = []
            var ids = ({})
            var active = ""

            for (var i = 0; i < items.length; i++) {
                var mode = items[i]
                var modeName = (mode.name || "").trim()
                if (modeName.length === 0) {
                    continue
                }

                ids[modeName.toLowerCase()] = mode.id || ""

                if (!mode.is_preset) {
                    names.push(modeName)
                }

                if (mode.is_active) {
                    active = modeName
                }
            }

            customModeIdsByName = ids
            customModes = names
            if (active.length > 0) {
                customActiveContext = active
            } else if (names.length > 0 && customActiveContext.length === 0) {
                customActiveContext = names[0]
            }
            persistCustomLocalState()
        })
    }

    function persistCustomLocalState() {
        customModeSettings.modesJson = JSON.stringify(customModes)
        customModeSettings.activeContext = customActiveContext
        customModeSettings.contactsEnabled = customContactsEnabled
        customModeSettings.keywordsEnabled = customKeywordsEnabled
        customModeSettings.appPriorityEnabled = customAppPriorityEnabled
    }

    function fetchModesSnapshot(onDone, onError) {
        backendRequest("GET", "/api/modes", null, function(items) {
            if (!items || items.length === undefined) {
                if (onDone) onDone({ ids: ({}), customNames: [], active: "" })
                return
            }

            var ids = ({})
            var customNames = []
            var active = ""
            for (var i = 0; i < items.length; i++) {
                var mode = items[i]
                var name = (mode.name || "").trim()
                if (name.length === 0) continue
                ids[name.toLowerCase()] = mode.id || ""
                if (!mode.is_preset) customNames.push(name)
                if (mode.is_active) active = name
            }

            if (onDone) {
                onDone({ ids: ids, customNames: customNames, active: active })
            }
        }, function(status, body) {
            if (onError) {
                onError(status, body)
            }
        })
    }

    function createModeOnBackend(modeName, onDone) {
        backendRequest("POST", "/api/modes", {
            name: modeName,
            is_active: false,
            is_preset: false,
            app_caps: [],
            keywords: [],
            contact_ids: [],
            cortex_level: "off",
            schedule_start: "",
            schedule_end: "",
            schedule_days: []
        }, function(created) {
            if (created && created.id) {
                var mapCopy = customModeIdsByName
                mapCopy[modeName.toLowerCase()] = created.id
                customModeIdsByName = mapCopy
            }
            if (onDone) {
                onDone(true)
            }
        }, function(status) {
            customModeSyncStatus = "create failed: " + modeName + " (" + status + ")"
            console.warn(customModeSyncStatus)
            if (onDone) {
                onDone(false)
            }
        })
    }

    function activateModeById(modeId, onDone) {
        if (!modeId || modeId.length === 0) {
            if (onDone) onDone(false)
            return
        }
        backendRequest("PUT", "/api/modes/" + modeId + "/activate", null, function() {
            customModeSyncStatus = "active mode synced"
            if (onDone) onDone(true)
        }, function(status) {
            customModeSyncStatus = "activate failed (" + status + ")"
            console.warn(customModeSyncStatus)
            if (onDone) onDone(false)
        })
    }

    function activateModeOnBackend(modeName) {
        var id = customModeIdsByName[modeName.toLowerCase()]
        if (!id || id.length === 0) {
            fetchModesSnapshot(function(snapshot) {
                customModeIdsByName = snapshot.ids
                var fetchedId = snapshot.ids[modeName.toLowerCase()]
                activateModeById(fetchedId)
            }, function() {
                customModeSyncStatus = "activate failed: no mode id for " + modeName
                console.warn(customModeSyncStatus)
            })
            return
        }
        activateModeById(id)
    }

    function pushCustomModesToBackend() {
        customModeSyncStatus = "syncing custom modes"
        fetchModesSnapshot(function(snapshot) {
            customModeIdsByName = snapshot.ids

            var missing = []
            for (var i = 0; i < customModes.length; i++) {
                var modeName = customModes[i]
                if (!customModeIdsByName[modeName.toLowerCase()]) {
                    missing.push(modeName)
                }
            }

            function createNext(index, done) {
                if (index >= missing.length) {
                    done()
                    return
                }
                createModeOnBackend(missing[index], function() {
                    createNext(index + 1, done)
                })
            }

            createNext(0, function() {
                fetchModesSnapshot(function(latest) {
                    customModeIdsByName = latest.ids
                    if (customActiveContext.length > 0) {
                        var activeId = latest.ids[customActiveContext.toLowerCase()]
                        activateModeById(activeId, function() {
                            syncModesFromBackend()
                        })
                    } else {
                        syncModesFromBackend()
                    }
                }, function() {
                    customModeSyncStatus = "sync complete (backend refresh failed)"
                    console.warn(customModeSyncStatus)
                })
            })
        }, function(status) {
            customModeSyncStatus = "sync failed (" + status + ")"
            console.warn(customModeSyncStatus)
            if (customActiveContext.length > 0) {
                activateModeOnBackend(customActiveContext)
            }
        })
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
            root.raise()
            root.requestActivate()
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
