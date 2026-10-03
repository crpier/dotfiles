import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Omarchy's built-in idle service is kept in Stay Awake mode to prevent
// automatic locking. This independent monitor handles suspend only.
ShellRoot {
    Component.onCompleted: console.log("Idle suspend monitor loaded: 3600 seconds, idle inhibitors respected.")

    IdleMonitor {
        enabled: true
        timeout: 3600
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle && !suspendProcess.running) {
                console.log("Idle for one hour; requesting suspend without locking.")
                suspendProcess.running = true
            }
        }
    }

    Process {
        id: suspendProcess
        command: ["/usr/bin/systemctl", "suspend"]
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("Suspend request failed with exit code " + exitCode)
        }
    }
}
