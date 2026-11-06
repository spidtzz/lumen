import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Page {
    id: page
    title: "Wallpaper"
    description: "A picture or the theme colour behind your windows. The lock screen shows it too."

    readonly property string current: Theme.conf.wallpaper || ""
    readonly property string mode: Theme.conf.wallpaper_mode || "fill"
    property var found: []

    function choose(path) { Theme.setValue("wallpaper", path); }

    // Pictures in the usual places.
    Process {
        id: finder
        running: true
        command: ["sh", "-c",
            "find \"$HOME/Pictures\" /usr/share/backgrounds /usr/share/wallpapers -maxdepth 4 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) 2>/dev/null | head -n 60"]
        stdout: StdioCollector {
            onStreamFinished: page.found = text.split("\n").filter(l => l !== "" && !l.includes("~"))
        }
    }

    FileDialog {
        id: picker
        title: "Choose a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg)"]
        currentFolder: "file://" + Theme.home + "/Pictures"
        onAccepted: page.choose(decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
    }

    Card {
        // Preview with the current mode
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 9 / 16
            radius: Theme.radiusSmall
            color: Theme.bg
            border.width: 1
            border.color: Theme.line
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 1
                visible: page.current !== ""
                source: page.current !== "" ? "file://" + page.current : ""
                asynchronous: true
                sourceSize: Qt.size(960, 540)
                fillMode: page.mode === "fit" ? Image.PreserveAspectFit
                        : page.mode === "center" ? Image.Pad
                        : page.mode === "tile" ? Image.Tile
                        : page.mode === "stretch" ? Image.Stretch
                        : Image.PreserveAspectCrop
            }
            Txt {
                anchors.centerIn: parent
                visible: page.current === ""
                text: "Theme colour"
                muted: true
            }
        }

        SettingRow {
            label: "Fit"
            Seg {
                enabled: page.current !== ""
                opacity: enabled ? 1 : 0.5
                options: [
                    { label: "Fill", value: "fill" }, { label: "Fit", value: "fit" },
                    { label: "Centre", value: "center" }, { label: "Tile", value: "tile" },
                    { label: "Stretch", value: "stretch" }
                ]
                value: page.mode
                onPicked: v => Theme.setValue("wallpaper_mode", v)
            }
        }

        RowLayout {
            spacing: 8
            Btn { text: "Choose a picture…"; icon: "image"; variant: "primary"; onClicked: picker.open() }
            Btn { text: "Use the theme colour"; variant: "ghost"; enabled: page.current !== ""; onClicked: page.choose("") }
        }
    }

    Card {
        title: "Pictures"
        description: page.found.length > 0 ? "From Pictures and the system wallpaper folders."
                                           : "No pictures found in ~/Pictures. Use “Choose a picture” or put some there."

        GridLayout {
            visible: page.found.length > 0
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: page.found
                delegate: Rectangle {
                    id: thumb
                    required property string modelData
                    readonly property bool selected: modelData === page.current

                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16
                    radius: Theme.radiusSmall
                    color: Theme.field
                    clip: true
                    border.width: selected ? 3 : 1
                    border.color: selected ? Theme.accent : thumbHover.hovered ? Theme.accent : Theme.line

                    Image {
                        anchors.fill: parent
                        anchors.margins: thumb.border.width
                        source: "file://" + thumb.modelData
                        asynchronous: true
                        sourceSize: Qt.size(320, 180)
                        fillMode: Image.PreserveAspectCrop
                    }
                    HoverHandler { id: thumbHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: page.choose(thumb.modelData) }
                }
            }
        }
    }
}
