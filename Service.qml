import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services

Service {
    id: remoteService
    
    readonly property string script: "./bin/server.sh"
    property string status: "stopped"
    property string ip: "0.0.0.0"

    function updateStatus() {
        Shell.execute([script, "status"], (exitCode, stdout) => {
            status = stdout.trim();
        });
        Shell.execute([script, "ip"], (exitCode, stdout) => {
            ip = stdout.trim();
        });
    }

    function toggle() {
        let cmd = status === "running" ? "stop" : "start";
        Shell.execute([script, cmd], () => {
            updateStatus();
        });
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: remoteService.updateStatus()
    }
}
