import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Wallpaper: the current picture on top, then your pictures grouped by
// folder with their names, searchable. Thumbnails are made once (a small
// JPEG per picture in ~/.cache/lumen/wallpaper-thumbs) so the page opens fast
// the next time; a picture that changes gets a new one.
Page {
    id: page
    title: "Wallpaper"
    description: "A picture or the theme colour behind your windows. The lock screen shows it too."

    readonly property string current: Theme.conf.wallpaper || ""
    readonly property string mode: Theme.conf.wallpaper_mode || "fill"
    readonly property string folder: Theme.home + "/Pictures/Wallpapers"
    readonly property bool subfolders: Theme.conf.wallpaper_subfolders !== "false"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Theme.home + "/.cache") + "/lumen/wallpaper-thumbs"

    property var found: []      // [{ path, mtime, name, group }] in your Wallpapers folder
    property var system: []     // shipped with the system
    property var cached: ({})   // thumbnail names already made
    property bool scanning: true
    property string query: ""

    function choose(path) { Theme.setValue("wallpaper", path); }
    function rescan() { scanning = true; finder.running = false; finder.running = true; }
    onSubfoldersChanged: rescan()

    // "mountain_lake-02.jpg" -> "mountain lake 02"
    function prettyName(path) {
        const base = path.slice(path.lastIndexOf("/") + 1).replace(/\.[^.]+$/, "");
        return base.replace(/[_\-.]+/g, " ").replace(/\s+/g, " ").trim() || base;
    }
    function entry(line, root) {
        const tab = line.lastIndexOf("\t");
        const path = tab > 0 ? line.slice(0, tab) : line;
        const rel = root !== "" && path.startsWith(root + "/") ? path.slice(root.length + 1) : "";
        const slash = rel.lastIndexOf("/");
        return { path: path, mtime: tab > 0 ? line.slice(tab + 1) : "", name: prettyName(path), group: slash > 0 ? rel.slice(0, slash) : "" };
    }
    function matches(e) {
        const q = query.trim().toLowerCase();
        return q === "" || e.name.toLowerCase().includes(q) || e.group.toLowerCase().includes(q);
    }
    // [{ name, files }], top-level pictures first, then each folder.
    function groups(list) {
        const by = {};
        for (const e of list.filter(matches)) (by[e.group] = by[e.group] || []).push(e);
        return Object.keys(by).sort((a, b) => a === "" ? -1 : b === "" ? 1 : a.localeCompare(b))
            .map(k => ({ name: k, files: by[k] }));
    }
    readonly property var currentEntry: found.concat(system).find(e => e.path === current) ?? null

    // Pictures in ~/Pictures/Wallpapers (and its subfolders if chosen), then
    // the system wallpaper folders, then the thumbnails made so far.
    Process {
        id: finder
        running: true
        command: ["sh", "-c",
            "d=\"$1\"; c=\"$3\"; mkdir -p \"$d\" \"$c\"; " +
            "find -L \"$d\" $2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "-printf '%p\\t%T@\\n' 2>/dev/null | sort | head -n 500; echo ---; " +
            "find /usr/share/backgrounds /usr/share/wallpapers -maxdepth 4 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) -printf '%p\\t%T@\\n' 2>/dev/null | sort | head -n 80; " +
            "echo ---; ls \"$c\"",
            "sh", page.folder, page.subfolders ? "-mindepth 1" : "-maxdepth 1", page.cacheDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---\n");
                const lines = t => (t || "").split("\n").filter(l => l !== "" && !l.includes("~"));
                const c = {};
                for (const n of lines(parts[2])) c[n.replace(/\.jpg$/, "")] = true;
                page.cached = c;
                page.found = lines(parts[0]).map(l => page.entry(l, page.folder));
                page.system = lines(parts[1]).map(l => page.entry(l, ""));
                page.scanning = false;
            }
        }
    }

    // One picture: thumbnail, name, a check when it's the wallpaper.
    component Thumb: Item {
        id: thumb
        required property var modelData
        readonly property bool selected: modelData.path === page.current
        readonly property string key: Qt.md5(modelData.path + "|" + modelData.mtime)
        readonly property string thumbFile: page.cacheDir + "/" + key + ".jpg"
        property bool fromCache: page.cached[key] === true
        property bool saved: false

        // four to a row, the same size however many there are
        Layout.preferredWidth: parent ? (parent.width - 36) / 4 : 160
        implicitHeight: frame.height + 6 + label.implicitHeight

        Rectangle {
            id: frame
            width: parent.width
            height: width * 9 / 16
            radius: Theme.radiusSmall
            color: Theme.field
            border.width: thumb.selected ? 3 : 1
            border.color: thumb.selected || hover.hovered ? Theme.accent : Theme.line
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            // Fades in on the wrapper, so the saved thumbnail is never half see-through.
            Item {
                anchors.fill: parent
                anchors.margins: frame.border.width
                opacity: img.status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
            Image {
                id: img
                anchors.fill: parent
                clip: true
                asynchronous: true
                cache: false
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(384, 216)
                source: "file://" + (thumb.fromCache ? thumb.thumbFile : thumb.modelData.path)
                onStatusChanged: {
                    if (status === Image.Error && thumb.fromCache) {
                        thumb.fromCache = false;   // thumbnail gone: use the picture
                    } else if (status === Image.Ready && !thumb.fromCache && !thumb.saved) {
                        // Keep a small copy for next time.
                        thumb.saved = true;
                        Qt.callLater(() => img.grabToImage(r => {
                            if (r.saveToFile(thumb.thumbFile)) page.cached[thumb.key] = true;
                        }, Qt.size(384, 216)));
                    }
                }
            }
            }
            // check mark on the current wallpaper
            Rectangle {
                visible: thumb.selected
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                width: 24; height: 24
                radius: 12
                color: Theme.accent
                Icon { anchors.centerIn: parent; name: "check"; size: 14; color: Theme.accentFg; stroke: 2.6 }
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: page.choose(thumb.modelData.path) }
        }
        Txt {
            id: label
            y: frame.height + 6
            width: parent.width
            text: thumb.modelData.name
            size: 12
            strong: thumb.selected
            color: thumb.selected ? Theme.accent : Theme.ink
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            ToolTipLike { visible: hover.hovered && label.truncated; text: thumb.modelData.name }
        }
    }

    // Full name over a cut-off label.
    component ToolTipLike: Rectangle {
        property string text
        y: -height - 4
        width: tipText.implicitWidth + 12
        height: tipText.implicitHeight + 6
        radius: Theme.r(6)
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        z: 10
        Txt { id: tipText; anchors.centerIn: parent; text: parent.text; size: 12 }
    }

    // Pictures of one folder under a heading.
    component Group: ColumnLayout {
        id: group
        property string name
        property var files: []
        property bool showHeading: true
        Layout.fillWidth: true
        spacing: 10
        RowLayout {
            visible: group.showHeading
            spacing: 8
            Icon { name: "folder"; size: 15; color: Theme.muted }
            Txt { text: group.name === "" ? "Wallpapers" : group.name; strong: true; size: 14 }
            Txt { text: String(group.files.length); muted: true; size: 13 }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 14
            columnSpacing: 12
            Repeater {
                model: group.files
                delegate: Thumb {}
            }
        }
    }

    FileDialog {
        id: picker
        title: "Choose a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        currentFolder: "file://" + page.folder
        onAccepted: page.choose(decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
    }

    // ---- current ----
    Card {
        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Rectangle {
                Layout.preferredWidth: 300
                Layout.preferredHeight: 300 * 9 / 16
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
                    sourceSize: Qt.size(600, 338)
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Txt { text: "Current"; muted: true; size: 12 }
                Txt {
                    Layout.fillWidth: true
                    text: page.current === "" ? "Theme colour" : page.currentEntry ? page.currentEntry.name : page.prettyName(page.current)
                    size: 18
                    strong: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
                Txt {
                    Layout.fillWidth: true
                    visible: page.current !== ""
                    text: page.current.replace(Theme.home, "~")
                    muted: true
                    size: 12
                    elide: Text.ElideMiddle
                    wrapMode: Text.NoWrap
                }
                Item { Layout.preferredHeight: 8 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Btn { text: "Choose a picture…"; icon: "image"; variant: "primary"; onClicked: picker.open() }
                    Btn { text: "Use the theme colour"; variant: "ghost"; enabled: page.current !== ""; onClicked: page.choose("") }
                }
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
    }

    // ---- your pictures ----
    Card {
        title: "Your wallpapers"
        description: page.scanning ? "Looking in ~/Pictures/Wallpapers…"
            : page.found.length > 0
            ? page.found.length + (page.found.length === 1 ? " picture" : " pictures") + " in ~/Pictures/Wallpapers."
            : "Put pictures in ~/Pictures/Wallpapers and they show up here."

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Field {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search by name or folder"
                onTextChanged: page.query = text
                Keys.onEscapePressed: event => { if (text !== "") { text = ""; event.accepted = true; } else event.accepted = false; }
            }
            Btn { text: "Open folder"; icon: "folder"; onClicked: Quickshell.execDetached(["gio", "open", page.folder]) }
            Btn { icon: "refresh"; text: "Refresh"; variant: "ghost"; onClicked: page.rescan() }
        }

        SettingRow {
            label: "Include subfolders"
            description: "Each folder inside Wallpapers gets its own group."
            Toggle {
                checked: page.subfolders
                onToggled: c => Theme.setValue("wallpaper_subfolders", c)
            }
        }

        Repeater {
            model: page.groups(page.found)
            delegate: Group {
                required property var modelData
                name: modelData.name
                files: modelData.files
                showHeading: page.subfolders
            }
        }

        Txt {
            visible: !page.scanning && page.found.length > 0 && page.groups(page.found).length === 0
            text: "Nothing called “" + page.query + "”."
            muted: true
        }
    }

    // ---- system ----
    Card {
        visible: page.system.some(e => page.matches(e))
        title: "System wallpapers"
        Group { files: page.system.filter(e => page.matches(e)); showHeading: false }
    }
}
