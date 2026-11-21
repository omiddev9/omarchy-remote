import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: "io.github.omiddev9.omarchy-remote"

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property var remoteService: null

    function findService() {
        if (root.remoteService) return
        var shell = root.bar ? root.bar.shell : null
        root.remoteService = shell && typeof shell.serviceFor === "function"
            ? shell.serviceFor(root.moduleName) : null
    }

    Timer {
        interval: 1000
        repeat: true
        running: !root.remoteService
        triggeredOnStart: true
        onTriggered: root.findService()
    }

    onBarChanged: root.findService()

    readonly property string serviceStatus: root.remoteService ? String(root.remoteService.status || "stopped") : "stopped"
    readonly property string serviceIp: root.remoteService ? String(root.remoteService.ip || "0.0.0.0") : "0.0.0.0"
    readonly property bool running: serviceStatus === "running"

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
                text: root.serviceIp
                font.pixelSize: 12
                font.bold: true
            }
        }

        Ui.BarIconButton {
            text: root.running ? "Stop" : "Start"
            onPressed: function(mouseButton) {
                if (root.remoteService && typeof root.remoteService.toggle === "function")
                    root.remoteService.toggle()
            }
        }
    }
}
