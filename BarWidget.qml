import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services

BarWidget {
    id: root
    
    // Reference the service defined in the manifest
    property var remoteService: Quickshell.services.get("omarchy-remote")

    RowLayout {
        spacing: 8
        
        Icon {
            name: remoteService.status === "running" ? "network-server-symbolic" : "network-offline-symbolic"
            color: remoteService.status === "running" ? "#4CAF50" : "#F44336"
        }

        ColumnLayout {
            spacing: 0
            Text {
                text: "Remote Desk"
                font.pixelSize: 10
                color: "#888"
            }
            Text {
                text: remoteService.ip
                font.pixelSize: 12
                font.bold: true
            }
        }

        Button {
            text: remoteService.status === "running" ? "Stop" : "Start"
            onClicked: remoteService.toggle()
        }
    }
}
