import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var shell: null
    property var manifest: null

    readonly property string pluginDir: {
        if (manifest && manifest.__sourceDir)
            return String(manifest.__sourceDir)
        return decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")).replace(/\/+$/, "")
    }
    readonly property string script: pluginDir + "/bin/server.sh"

    property string status: "stopped"
    property string ip: "0.0.0.0"
    property bool busy: false

    function updateStatus() {
        if (!statusProc.running) statusProc.running = true
        if (!ipProc.running) ipProc.running = true
    }

    function toggle() {
        if (actionProc.running || busy) return
        busy = true
        actionProc.command = ["/usr/bin/bash", script, status === "running" ? "stop" : "start"]
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
        onExited: function(code) {
            if (code !== 0 && root.status === "")
                root.status = "stopped"
        }
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
            root.updateStatus()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateStatus()
    }
}
