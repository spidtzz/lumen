import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Page {
    id: page
    title: "Bar"
    description: "Position, workspaces, clock and tray icons. The bar shows the focused app on the left, workspaces in the middle, and tray, time and quick settings on the right."

    Card {
        title: "Position"
        SettingRow {
            label: "Edge"
            description: "Also: super + shift + arrow keys."
            Seg {
                options: [
                    { label: "Top", value: "top" }, { label: "Bottom", value: "bottom" },
                    { label: "Left", value: "left" }, { label: "Right", value: "right" }
                ]
                value: Theme.barPosition
                onPicked: v => Theme.setValue("bar_position", v)
            }
        }
    }

    Card {
        title: "Workspaces"
        SettingRow {
            id: wsRow
            readonly property int per: +(Theme.conf.bar_workspaces || 5)
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
        title: "Clock"
        SettingRow {
            label: "24-hour clock"
            Toggle {
                checked: Theme.clock24h
                onToggled: c => Theme.setValue("clock_24h", c)
            }
        }
    }

    Card {
        title: "Tray"
        description: "Icons from running apps (Discord, Steam, network applets, ...)."

        SettingRow {
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
                        Txt { text: "Pin to bar"; size: 12; muted: true }
                        Toggle {
                            checked: Tray.isPinned(row.itemId)
                            onToggled: c => Tray.setPinned(row.itemId, c)
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Field {
                            id: iconField
                            Layout.fillWidth: true
                            placeholderText: "Custom icon: icon name (e.g. discord) or image path"
                            text: Tray.icons[row.itemId] || ""
                            onAccepted: Tray.setIcon(row.itemId, text)
                        }
                        Btn {
                            text: "Set"
                            enabled: iconField.text !== (Tray.icons[row.itemId] || "")
                            onClicked: Tray.setIcon(row.itemId, iconField.text)
                        }
                        Btn {
                            text: "Reset"
                            variant: "ghost"
                            enabled: (Tray.icons[row.itemId] || "") !== ""
                            onClicked: { iconField.text = ""; Tray.setIcon(row.itemId, ""); }
                        }
                    }
                }
            }
        }
    }
}
