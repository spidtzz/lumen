import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Page {
    id: page
    title: "Bar"
    description: "Where the bar sits, how it looks, and what it shows."

    // Picture for a tray icon (the button next to the icon name).
    FileDialog {
        id: iconPicker
        property string target: ""
        title: "Choose an icon picture"
        nameFilters: ["Images (*.png *.svg *.jpg *.jpeg *.webp)"]
        currentFolder: "file://" + Theme.home + "/Pictures"
        onAccepted: Tray.setIcon(target, decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
    }

    // Where the bar sits: click an edge of the little screen.
    Card {
        title: "Layout"
        description: "Click an edge to move the bar there."

        Rectangle {
            id: screen
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 340
            Layout.preferredHeight: 200
            radius: Theme.screenCorners ? 16 : Theme.radiusSmall
            color: Theme.bg
            border.width: 1
            border.color: Theme.line
            readonly property bool attached: Theme.barAttached
            readonly property int gap: attached ? 0 : 8
            readonly property int thick: 18

            Repeater {
                model: ["top", "bottom", "left", "right"]
                delegate: Rectangle {
                    id: edge
                    required property string modelData
                    readonly property bool vertical: modelData === "left" || modelData === "right"
                    readonly property bool current: Theme.barPosition === modelData
                    readonly property int g: current ? screen.gap : 8
                    x: modelData === "right" ? screen.width - width - g : g + (vertical ? 0 : (current ? 0 : 22))
                    y: modelData === "bottom" ? screen.height - height - g : g + (vertical ? (current ? 0 : 22) : 0)
                    width: vertical ? screen.thick : screen.width - 2 * g - (current ? 0 : 44)
                    height: vertical ? screen.height - 2 * g - (current ? 0 : 44) : screen.thick
                    radius: current && screen.attached ? 0 : Theme.r(6)
                    color: current ? (Theme.barBlack ? "#000000" : Theme.panel) : edgeHover.hovered ? Theme.field : "transparent"
                    border.width: current ? 1 : edgeHover.hovered ? 1 : 0
                    border.color: current ? Theme.accent : Theme.line
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    // a hint of the workspaces in the middle
                    Row {
                        visible: edge.current && !edge.vertical
                        anchors.centerIn: parent
                        spacing: 3
                        Rectangle { width: 14; height: 5; radius: 2.5; color: Theme.accent }
                        Repeater { model: 3; Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.muted } }
                    }
                    Column {
                        visible: edge.current && edge.vertical
                        anchors.centerIn: parent
                        spacing: 3
                        Rectangle { width: 5; height: 14; radius: 2.5; color: Theme.accent }
                        Repeater { model: 3; Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.muted } }
                    }
                    HoverHandler { id: edgeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Theme.setValue("bar_position", edge.modelData) }
                }
            }
            Txt {
                anchors.centerIn: parent
                text: ({ top: "Top", bottom: "Bottom", left: "Left", right: "Right" })[Theme.barPosition]
                muted: true
                size: 13
            }
        }

        SettingRow {
            icon: "layout"
            label: "Shape"
            description: Theme.barAttached && Theme.screenCorners && Theme.rounded
                ? "Edge to edge: the bar curves into the rounded screen corners."
                : Theme.barAttached ? "Edge to edge. Turn on rounded screen corners (Appearance) for curved ends."
                : "A rounded panel with a gap around it."
            Seg {
                options: [{ label: "Floating", value: "floating" }, { label: "Edge to edge", value: "attached" }]
                value: Theme.barAttached ? "attached" : "floating"
                onPicked: v => Theme.setValue("bar_style", v)
            }
        }
        SettingRow {
            icon: "moon"
            label: "Black bar"
            description: "Pure black with light text and icons, in light and dark mode."
            Toggle {
                checked: Theme.barBlack
                onToggled: c => Theme.setValue("bar_black", c)
            }
        }
    }

    Card {
        title: "Workspaces"
        SettingRow {
            icon: "grid"
            label: "Style"
            description: "How desktops look in the bar."
            Seg {
                options: [
                    { label: "Pills", value: "pills" }, { label: "Boxes", value: "boxes" },
                    { label: "Dots", value: "dots" }, { label: "Numbers", value: "numbers" }
                ]
                value: Theme.conf.ws_style || "pills"
                onPicked: v => Theme.setValue("ws_style", v)
            }
        }
        SettingRow {
            id: wsRow
            readonly property int per: +(Theme.conf.bar_workspaces || 5)
            icon: "monitor"
            label: "Workspaces shown at a time"
            description: "With " + per + ", the bar shows 1–" + per + " until you go to " + (per + 1) + ", then the next " + per + "."
            Btn {
                icon: "minus"
                enabled: wsRow.per > 3
                onClicked: Theme.setValue("bar_workspaces", wsRow.per - 1)
            }
            Txt {
                text: wsRow.per
                size: 18
                strong: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 32
            }
            Btn {
                icon: "plus"
                enabled: wsRow.per < 10
                onClicked: Theme.setValue("bar_workspaces", wsRow.per + 1)
            }
        }
    }

    Card {
        title: "Clock and quick settings"
        SettingRow {
            icon: "clock"
            label: "24-hour clock"
            description: Theme.clock24h ? "14:30" : "2:30 PM"
            Toggle {
                checked: Theme.clock24h
                onToggled: c => Theme.setValue("clock_24h", c)
            }
        }
        SettingRow {
            icon: "music"
            label: "Media controls in quick settings"
            description: "Play, pause and skip for whatever is playing. Shown only while something is open."
            Toggle {
                checked: Theme.conf.qs_media !== "false"
                onToggled: c => Theme.setValue("qs_media", c)
            }
        }
    }

    Card {
        title: "Tray"
        description: "Icons from running apps (Discord, Steam, network applets, ...)."

        SettingRow {
            icon: "app"
            label: "Group tray icons"
            description: "On: pinned icons stay on the bar and the rest open from an arrow, like Windows. Off: every icon on the bar, like GNOME and Plasma."
            Toggle {
                checked: Theme.conf.tray_grouped !== "false"
                onToggled: c => Theme.setValue("tray_grouped", c)
            }
        }

        Txt {
            visible: Tray.items.length === 0
            text: "No apps are showing a tray icon right now. Open one and its icon will appear here."
            muted: true
            size: 13
            Layout.fillWidth: true
        }

        Repeater {
            model: Tray.items
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property string itemId: modelData.id
                property bool editing: false   // the custom icon field is open

                Layout.fillWidth: true
                implicitHeight: rowCol.implicitHeight + 20
                radius: Theme.radiusSmall
                color: Theme.field
                border.width: 1
                border.color: Theme.line

                ColumnLayout {
                    id: rowCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        IconImage {
                            implicitSize: 24
                            source: Tray.iconFor(row.modelData)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Txt {
                                Layout.fillWidth: true
                                text: row.modelData.title || row.modelData.tooltipTitle || row.itemId
                                strong: true
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                            Txt { text: row.itemId; size: 11; muted: true }
                        }
                        Btn {
                            text: (Tray.icons[row.itemId] || "") !== "" ? "Icon: custom" : "Change icon"
                            variant: "ghost"
                            onClicked: row.editing = !row.editing
                        }
                        Txt { text: "Pin"; size: 12; muted: true }
                        Toggle {
                            checked: Tray.isPinned(row.itemId)
                            onToggled: c => Tray.setPinned(row.itemId, c)
                        }
                    }

                    RowLayout {
                        visible: row.editing
                        spacing: 8
                        Field {
                            id: iconField
                            // An icon name from your icon theme, or a picture.
                            readonly property string typed: text.trim()
                            readonly property bool found: typed === "" || typed.startsWith("/")
                                || Quickshell.iconPath(typed, true) !== ""
                            Layout.fillWidth: true
                            placeholderText: "Custom icon: icon name (e.g. discord) or image path"
                            text: Tray.icons[row.itemId] || ""
                            onAccepted: if (found) Tray.setIcon(row.itemId, text)
                        }
                        Btn {
                            icon: "image"
                            variant: "ghost"
                            onClicked: { iconPicker.target = row.itemId; iconPicker.open(); }
                        }
                        Btn {
                            text: "Set"
                            enabled: iconField.found && iconField.text !== (Tray.icons[row.itemId] || "")
                            onClicked: Tray.setIcon(row.itemId, iconField.text)
                        }
                        Btn {
                            text: "Reset"
                            variant: "ghost"
                            enabled: (Tray.icons[row.itemId] || "") !== ""
                            onClicked: { iconField.text = ""; Tray.setIcon(row.itemId, ""); }
                        }
                    }
                    Txt {
                        visible: row.editing && !iconField.found
                        text: "No icon called “" + iconField.typed + "” in your icon theme. Try another name, or pick a picture."
                        size: 12
                        color: Theme.danger
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
