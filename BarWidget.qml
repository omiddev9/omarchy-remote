import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: "io.github.omiddev9.omarchy-remote"

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property string pluginDir: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")).replace(/\/+$/, "")
    readonly property string script: root.pluginDir + "/bin/server.sh"

    property string status: "stopped"
    property string ip: ""
    property string port: ""

    readonly property bool running: root.status === "running"
    readonly property string displayIp: root.ip === "0.0.0.0" ? "" : root.ip
    readonly property string displayAddress: root.displayIp === "" ? ""
        : root.displayIp + (root.port !== "" ? ":" + root.port : "")

    function refresh() {
        if (!statusProc.running) statusProc.running = true
        if (!ipProc.running) ipProc.running = true
        if (!portProc.running) portProc.running = true
    }

    function toggle() {
        if (actionProc.running) return
        actionProc.command = ["/usr/bin/bash", root.script, root.running ? "stop" : "start"]
        actionProc.running = true
    }

    Process {
        id: statusProc
        command: ["/usr/bin/bash", root.script, "status"]
        stdout: StdioCollector {
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
            waitForEnd: true
            onStreamFinished: {
                var value = String(text || "").trim()
                root.ip = (value.length > 0 && value !== "0.0.0.0") ? value : ""
            }
        }
        stderr: StdioCollector { waitForEnd: true }
    }

    Process {
        id: portProc
        command: ["/usr/bin/bash", root.script, "port"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var value = String(text || "").trim()
                root.port = /^[0-9]+$/.test(value) ? value : ""
            }
        }
        stderr: StdioCollector { waitForEnd: true }
    }

    Process {
        id: actionProc
        stdout: StdioCollector { waitForEnd: true }
        stderr: StdioCollector { waitForEnd: true }
        onExited: root.refresh()
    }

    Timer {
        interval: 5000
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
                visible: root.displayAddress !== ""
                text: root.displayAddress
                font.pixelSize: 12
                font.bold: true
            }
        }

        Ui.BarIconButton {
            text: root.running ? "Stop" : "Start"
            onPressed: function(mouseButton) {
                root.toggle()
            }
        }
    }
}
