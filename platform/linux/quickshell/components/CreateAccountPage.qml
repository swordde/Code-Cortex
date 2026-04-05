import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCore
import QtMultimedia
import "PopupTheme.js" as PopupTheme

Item {
    id: page

    property string stylePreset: "projectCore"
    readonly property real fontScale: 1.25
    property bool voiceRecorded: false
    property string typedName: ""
    property bool isRecording: false
    property int recordingElapsedMs: 0
    property string recordingStatus: "Voice not recorded yet"
    property url recordingOutputUrl: ""

    signal backRequested
    signal continueRequested(string name)

    function outputDirectory() {
        var base = StandardPaths.writableLocation(StandardPaths.MusicLocation)
        if (!base || base.length === 0) {
            base = StandardPaths.writableLocation(StandardPaths.HomeLocation)
        }
        if (!base || base.length === 0) {
            base = "/tmp"
        }
        return base
    }

    function formatDuration(ms) {
        var total = Math.floor(ms / 1000)
        var sec = (total % 60).toString()
        if (sec.length < 2) sec = "0" + sec
        return "00:" + sec
    }

    function startVoiceRecording() {
        var stamp = Date.now().toString()
        recordingOutputUrl = "file://" + outputDirectory() + "/cortex_voice_" + stamp + ".m4a"
        recordingElapsedMs = 0
        recordingStatus = "Recording..."
        isRecording = true
        recorder.record()
        recordingTimer.start()
    }

    function stopVoiceRecording(markAsReady) {
        if (isRecording) {
            recorder.stop()
            recordingTimer.stop()
            isRecording = false
        }

        if (markAsReady) {
            voiceRecorded = true
            recordingStatus = "Voice saved: " + recordingOutputUrl.toString().replace("file://", "")
        } else if (!voiceRecorded) {
            recordingStatus = "Voice not recorded yet"
        }
    }

    Timer {
        id: recordingTimer
        interval: 100
        repeat: true
        running: false
        onTriggered: {
            recordingElapsedMs += interval
            if (recordingElapsedMs >= 10000) {
                page.stopVoiceRecording(true)
            }
        }
    }

    CaptureSession {
        id: captureSession
        audioInput: AudioInput { id: audioInput }
        recorder: MediaRecorder {
            id: recorder
            outputLocation: page.recordingOutputUrl
            onErrorOccurred: {
                page.recordingTimer.stop()
                page.isRecording = false
                page.voiceRecorded = false
                page.recordingStatus = "Recording failed: " + errorString
            }
        }
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
            contentHeight: formRow.implicitHeight

            RowLayout {
                id: formRow
                width: Math.min(parent.width, 1120)
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(620, accountContent.implicitHeight + 36)
                    radius: 16
                    color: PopupTheme.buttonBackground(page.stylePreset)
                    border.color: PopupTheme.buttonBorder(page.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        id: accountContent
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
                    text: "Create Account"
                    color: PopupTheme.titleColor(page.stylePreset)
                    font.pixelSize: Math.round(16 * page.fontScale)
                    font.bold: true
                }
                    }

                    Text {
                        text: "Enter your name"
                        color: PopupTheme.titleColor(page.stylePreset)
                        font.pixelSize: Math.round(14 * page.fontScale)
                        font.bold: true
                    }

                    TextField {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        text: page.typedName
                        onTextChanged: page.typedName = text
                        placeholderText: "Your name"
                        color: PopupTheme.titleColor(page.stylePreset)
                        placeholderTextColor: PopupTheme.subtitleColor(page.stylePreset)
                        background: Rectangle {
                            radius: 6
                            color: "transparent"
                            border.color: PopupTheme.buttonBorder(page.stylePreset)
                            border.width: 1
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 12
                        color: PopupTheme.panelBackground(page.stylePreset)
                        border.color: PopupTheme.buttonBorder(page.stylePreset)
                        border.width: 1
                        implicitHeight: 136

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Record your voice (10s)"
                        color: PopupTheme.titleColor(page.stylePreset)
                        font.pixelSize: Math.round(14 * page.fontScale)
                        font.bold: true
                    }

                    Text {
                        text: "For privacy, AI replies and actions are tied to this recorded voice profile."
                        wrapMode: Text.Wrap
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(12 * page.fontScale)
                    }

                    Rectangle {
                        width: 180
                        height: 40
                        radius: 20
                        color: page.isRecording ? "#BD3124" : "#0F4D52"

                        Text {
                            anchors.centerIn: parent
                            text: page.isRecording ? "Stop Recording" : "Record 10s Voice"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(13 * page.fontScale)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (page.isRecording) {
                                    page.stopVoiceRecording(true)
                                } else {
                                    page.startVoiceRecording()
                                }
                            }
                        }
                    }

                    Text {
                        text: page.recordingStatus
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(12 * page.fontScale)
                        wrapMode: Text.Wrap
                    }

                    Text {
                        text: "Duration: " + page.formatDuration(page.recordingElapsedMs)
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(12 * page.fontScale)
                    }
                }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 23
                        color: (page.voiceRecorded && page.typedName.trim().length > 0) ? "#0F4D52" : "#8EA7AA"

                        Text {
                            anchors.centerIn: parent
                            text: "Continue"
                            color: "#FFFFFF"
                            font.pixelSize: Math.round(14 * page.fontScale)
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: page.voiceRecorded && page.typedName.trim().length > 0
                            onClicked: page.continueRequested(page.typedName.trim())
                        }
                    }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: Math.max(620, progressPanel.implicitHeight + 36)
                    Layout.preferredWidth: 320
                    visible: page.width > 980
                    radius: 16
                    color: PopupTheme.panelBackground(page.stylePreset)
                    border.color: PopupTheme.panelBorder(page.stylePreset)
                    border.width: 1

                    ColumnLayout {
                        id: progressPanel
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                    Text {
                        text: "Setup Progress"
                        color: PopupTheme.titleColor(page.stylePreset)
                        font.pixelSize: Math.round(16 * page.fontScale)
                        font.bold: true
                    }

                    Text {
                        text: "1. Enter your name"
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(13 * page.fontScale)
                    }

                    Text {
                        text: "2. Record your 10s voice sample"
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(13 * page.fontScale)
                    }

                    Text {
                        text: "3. Continue to dashboard"
                        color: PopupTheme.subtitleColor(page.stylePreset)
                        font.pixelSize: Math.round(13 * page.fontScale)
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: page.voiceRecorded ? "Voice verification ready" : "Waiting for voice recording"
                        color: page.voiceRecorded ? "#2E7D7D" : "#B56D00"
                        font.pixelSize: Math.round(12 * page.fontScale)
                        font.bold: true
                    }
                    }
                }
            }
        }
    }
}
