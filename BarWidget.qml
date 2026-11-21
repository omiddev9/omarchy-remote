import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: "io.github.omiddev9.omarchy-remote"

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property string status: "stopped"
    property string ip: "unknown"
    property bool busy: false

    readonly property string script: decodeURIComponent(Qt.resolvedUrl("bin/server.sh").toString().replace(/^file:\/\//, ""))
    readonly property bool running: status === "running"

    function refresh() {
        if (!statusProc.running) statusProc.running = true
        if (!ipProc.running) ipProc.running = true
    }

    function toggle() {
        if (busy || actionProc.running) return
        busy = true
        actionProc.command = ["/usr/bin/bash", script, running ? "stop" : "start"]
        actionProc.running = true
    }

    Process {
        id: statusProc
        command: ["/usr/bin/bash", root.script, "status"]
        stdout: StdioCollector {
            id: statusOut
            waitForEnd: true
            onStreamFinished: {
                var value = String(text || "").trim()
                root.status = value.length > 0 ? value : "stopped"
            }
        }
        stderr: StdioCollector { waitForEnd: true }
    }

    Process {
        id: ipProc
        command: ["/usr/bin/bash", root.script, "ip"]
        stdout: StdioCollector {
            id: ipOut
            waitForEnd: true
            onStreamFinished: {
                var value = String(text || "").trim()
                if (value.length > 0) root.ip = value
            }
        }
        stderr: StdioCollector { waitForEnd: true }
    }

    Process {
        id: actionProc
        stdout: StdioCollector { waitForEnd: true }
        stderr: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            root.busy = false
            root.refresh()
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    RowLayout {
        id: row
        spacing: 8

        Text {
            text: root.running ? "󰒋" : "󰒊"
            font.pixelSize: 16
        }

        ColumnLayout {
            spacing: 0
            Text {
                text: "Remote Desk"
                font.pixelSize: 10
                color: "#888"
            }
            Text {
                text: root.ip + (root.running ? ":5900" : "")
                font.pixelSize: 12
                font.bold: true
            }
        }

        Ui.BarIconButton {
            text: root.busy ? "..." : (root.running ? "Stop" : "Start")
            enabled: !root.busy
            onPressed: function(mouseButton) {
                root.toggle()
            }
        }
    }
}
