import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Page {
    id: page
    title: "Users"
    description: "Your picture, name and password."

    property string realName: ""
    property string status: ""

    Process {
        command: ["getent", "passwd", Theme.userName]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.realName = (text.split(":")[4] || "").split(",")[0]
        }
    }

    Process {
        id: avatarProc
        stderr: StdioCollector { id: avatarErr }
        onExited: code => {
            page.status = code === 0 ? "" : (avatarErr.text.trim().replace(/^lumen-avatar: /, "") || "Couldn't change the picture.");
            Theme.avatarRevision++;
        }
    }

    FileDialog {
        id: picker
        title: "Choose a picture"
        nameFilters: ["Images (*.png *.jpg *.jpeg)"]
        currentFolder: "file://" + Theme.home + "/Pictures"
        onAccepted: {
            avatarProc.command = ["lumen-avatar", "set", decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""))];
            avatarProc.running = true;
        }
    }

    Card {
        RowLayout {
            spacing: 20
            Layout.fillWidth: true

            Avatar { size: 96 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt { text: page.realName !== "" ? page.realName : Theme.userName; size: 24; strong: true }
                Txt { text: Theme.userName; muted: true }
                RowLayout {
                    Layout.topMargin: 10
                    spacing: 8
                    Btn { text: "Change picture…"; icon: "image"; variant: "primary"; busy: avatarProc.running; onClicked: picker.open() }
                    Btn {
                        text: "Remove"
                        variant: "ghost"
                        onClicked: { avatarProc.command = ["lumen-avatar", "clear"]; avatarProc.running = true; }
                    }
                }
            }
        }
        Txt {
            visible: page.status !== ""
            text: page.status
            color: Theme.danger
            size: 13
        }
        Txt {
            Layout.fillWidth: true
            text: "The picture also appears on the login screen; saving it there asks for your password."
            muted: true
            size: 12
        }
    }

    Card {
        title: "Password"
        SettingRow {
            label: "Change password"
            description: "Opens a terminal running passwd."
            Btn {
                text: "Change…"
                icon: "lock"
                onClicked: Quickshell.execDetached(["kitty", "--title", "Change password", "--hold", "passwd"])
            }
        }
    }
}
