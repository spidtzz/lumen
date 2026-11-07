// lumen — SDDM login theme (Qt 6).
// Same look as the lumen shell: colours come from theme.conf / theme.conf.user,
// which lumen-theme keeps in sync with the desktop theme.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080

    // ---- theme ------------------------------------------------------------
    function cfg(key, fallback) {
        const v = config[key];
        return v !== undefined && v !== null && String(v) !== "" ? String(v) : fallback;
    }
    readonly property color cBg: cfg("bg", "#070f1f")
    readonly property color cPanel: cfg("panel", "#101a2d")
    readonly property color cField: cfg("field", "#0b1423")
    readonly property color cInk: cfg("ink", "#ebeff5")
    readonly property color cMuted: cfg("muted", "#97a5be")
    readonly property color cLine: cfg("line", "#25334c")
    readonly property color cAccent: cfg("accent", "#71a3ff")
    readonly property color cOnAccent: cfg("on_accent", "#081123")
    readonly property color cDanger: cfg("danger", "#f75d59")
    readonly property bool darkMode: cfg("mode", "dark") === "dark"
    readonly property bool squareCorners: cfg("corners", "rounded") === "square"
    function rr(n) { return squareCorners ? 0 : n; }
    readonly property string fontName: fontLoader.status === FontLoader.Ready
        ? fontLoader.name : cfg("font", "sans-serif")

    FontLoader { id: fontLoader; source: "fonts/SpaceGrotesk.ttf" }

    color: cBg

    // ---- state ------------------------------------------------------------
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string errorText: ""
    property bool busy: false
    property string menu: ""          // open menu: "session", "user" or "power"
    property bool manualUser: false   // "Other user…": type a user name

    readonly property var currentUser: users.count > 0 ? users.itemAt(userIndex) : null
    readonly property string currentName: manualUser ? username.text.trim()
        : currentUser ? currentUser.name : userModel.lastUser
    readonly property string displayName: manualUser ? (currentName !== "" ? currentName : "Other user")
        : currentUser && currentUser.realName !== "" ? currentUser.realName : currentName
    readonly property string currentIcon: currentUser && !manualUser ? currentUser.icon : ""
    readonly property var currentSession: sessions.count > 0 ? sessions.itemAt(sessionIndex) : null

    function login() {
        if (busy) return;
        if (currentName === "") { username.forceActiveFocus(); return; }
        errorText = "";
        busy = true;
        sddm.login(currentName, password.text, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.errorText = "Wrong password. Try again.";
            password.text = "";
            password.forceActiveFocus();
            shake.restart();
        }
        function onLoginSucceeded() { root.busy = false; }
    }

    // Hidden model readers: SDDM models expose data only through delegates.
    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
            required property string icon
        }
    }
    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item {
            required property string name
            required property string file
        }
    }

    // The lumen session runs bspwm, so the plain "bspwm" entry (from the bspwm
    // package) would be a second, unthemed way into the same thing: hide it.
    function sessionHidden(i) {
        const it = sessions.itemAt(i);
        if (!it || !String(it.file).endsWith("bspwm.desktop")) return false;
        for (let j = 0; j < sessions.count; j++)
            if (String(sessions.itemAt(j).file).endsWith("lumen.desktop")) return true;
        return false;
    }
    function lumenSession() {
        for (let j = 0; j < sessions.count; j++)
            if (String(sessions.itemAt(j).file).endsWith("lumen.desktop")) return j;
        return 0;
    }

    function pickUser(i) {
        manualUser = i < 0;
        if (i >= 0) userIndex = i;
        errorText = "";
        password.text = "";
        menu = "";
        if (manualUser) { username.text = ""; username.forceActiveFocus(); }
        else password.forceActiveFocus();
    }

    // ---- background: soft accent glows ------------------------------------
    Item {
        id: glow
        anchors.fill: parent
        visible: false
        Rectangle {
            width: root.width * 0.55; height: width; radius: width / 2
            x: -width * 0.25; y: -height * 0.3
            color: root.cAccent
            opacity: root.darkMode ? 0.22 : 0.16
        }
        Rectangle {
            width: root.width * 0.45; height: width; radius: width / 2
            x: root.width - width * 0.7; y: root.height - height * 0.6
            color: root.cAccent
            opacity: root.darkMode ? 0.14 : 0.10
        }
    }
    MultiEffect {
        anchors.fill: glow
        source: glow
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }

    // ---- clock ------------------------------------------------------------
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Column {
        id: clockBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 40
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.cInk
            font.family: root.fontName
            font.pixelSize: 88
            font.weight: Font.Bold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: root.cMuted
            font.family: root.fontName
            font.pixelSize: 18
        }
    }

    // ---- login card -------------------------------------------------------
    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        width: 380
        height: cardCol.implicitHeight + 48
        radius: root.rr(14)
        color: root.cPanel
        border.color: root.cLine
        border.width: 1

        transform: Translate { id: shakeX }
        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: shakeX; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shakeX; property: "x"; to: 10; duration: 80 }
            NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50 }
        }

        Column {
            id: cardCol
            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            spacing: 14

            // avatar
            Item {
                id: avatar
                width: 96; height: 96
                anchors.horizontalCenter: parent.horizontalCenter
                // SDDM's generic default picture ends in "/.face.icon"; show an initial instead.
                readonly property bool hasImage: root.currentIcon !== "" && !root.currentIcon.endsWith("/.face.icon")

                Image {
                    id: avImg
                    anchors.fill: parent
                    source: avatar.hasImage
                        ? (root.currentIcon.startsWith("/") ? "file://" + root.currentIcon : root.currentIcon) : ""
                    sourceSize: Qt.size(192, 192)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: false
                    layer.enabled: true
                }
                Rectangle {
                    id: avMask
                    anchors.fill: parent
                    radius: root.rr(width / 2)
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: avImg
                    maskEnabled: true
                    maskSource: avMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    visible: avImg.status === Image.Ready
                }
                Rectangle {
                    anchors.fill: parent
                    radius: root.rr(width / 2)
                    color: root.cAccent
                    visible: avImg.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: root.displayName.length > 0 ? root.displayName.charAt(0).toUpperCase() : "?"
                        color: root.cOnAccent
                        font.family: root.fontName
                        font.pixelSize: 40
                        font.weight: Font.Bold
                    }
                }
                Rectangle { // ring
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: root.rr(width / 2)
                    color: "transparent"
                    border.color: root.cLine
                    border.width: 2
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.displayName
                color: root.cInk
                font.family: root.fontName
                font.pixelSize: 22
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            // user name, for "Other user…"
            Rectangle {
                visible: root.manualUser
                width: parent.width
                height: 44
                radius: root.rr(9)
                color: root.cField
                border.width: username.activeFocus ? 2 : 1
                border.color: username.activeFocus ? root.cAccent : root.cLine
                TextInput {
                    id: username
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.cInk
                    font.family: root.fontName
                    font.pixelSize: 16
                    clip: true
                    onTextEdited: root.errorText = ""
                    Keys.onReturnPressed: password.forceActiveFocus()
                    Keys.onEnterPressed: password.forceActiveFocus()
                    Keys.onTabPressed: password.forceActiveFocus()
                }
                Text {
                    anchors.fill: username
                    verticalAlignment: Text.AlignVCenter
                    text: "User name"
                    color: root.cMuted
                    font: username.font
                    visible: username.text.length === 0
                }
            }

            // password + submit
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: parent.width - submit.width - parent.spacing
                    height: 44
                    radius: root.rr(9)
                    color: root.cField
                    border.width: password.activeFocus ? 2 : 1
                    border.color: root.errorText !== "" ? root.cDanger
                        : password.activeFocus ? root.cAccent : root.cLine

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.cInk
                        selectionColor: root.cAccent
                        selectedTextColor: root.cOnAccent
                        font.family: root.fontName
                        font.pixelSize: 16
                        clip: true
                        focus: true
                        enabled: !root.busy
                        onTextEdited: root.errorText = ""
                        Keys.onReturnPressed: root.login()
                        Keys.onEnterPressed: root.login()
                        Keys.onEscapePressed: {
                            if (root.menu !== "") root.menu = "";
                            else { text = ""; root.errorText = ""; }
                        }
                    }
                    Text {
                        anchors.fill: password
                        verticalAlignment: Text.AlignVCenter
                        text: "Password"
                        color: root.cMuted
                        font: password.font
                        visible: password.text.length === 0
                    }
                }

                Rectangle {
                    id: submit
                    width: 44; height: 44
                    radius: root.rr(9)
                    color: submitHover.hovered ? Qt.lighter(root.cAccent, 1.08) : root.cAccent
                    scale: submitTap.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "…" : "→"
                        color: root.cOnAccent
                        font.family: root.fontName
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }
                    HoverHandler { id: submitHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: submitTap; onTapped: root.login() }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.family: root.fontName
                font.pixelSize: 13
                readonly property bool caps: typeof keyboard !== "undefined" && keyboard && keyboard.capsLock
                text: root.errorText !== "" ? root.errorText
                    : caps ? "Caps Lock is on"
                    : root.busy ? "Logging in…" : "Press Enter to log in"
                color: root.errorText !== "" ? root.cDanger : caps ? root.cAccent : root.cMuted
            }
        }
    }

    // ---- bottom bar: session and user (left), power (right) ---------------
    Item {
        id: bottomBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        height: 40

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Chip {
                id: sessionBtn
                visible: sessions.count > 0
                label: (root.currentSession ? root.currentSession.name : "Session") + (root.menu === "session" ? "  ▾" : "  ▴")
                selected: root.menu === "session"
                onClicked: root.menu = root.menu === "session" ? "" : "session"
            }
            Chip {
                id: userBtn
                label: root.displayName + (root.menu === "user" ? "  ▾" : "  ▴")
                selected: root.menu === "user"
                onClicked: root.menu = root.menu === "user" ? "" : "user"
            }
        }

        Chip {
            id: powerBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: sddm.canSuspend || sddm.canHibernate || sddm.canReboot || sddm.canPowerOff
            label: "Power" + (root.menu === "power" ? "  ▾" : "  ▴")
            selected: root.menu === "power"
            onClicked: root.menu = root.menu === "power" ? "" : "power"
        }
    }

    // Clicking anywhere else closes an open menu.
    MouseArea {
        anchors.fill: parent
        visible: root.menu !== ""
        onClicked: root.menu = ""
    }

    // ---- menus, opening upward from their button ---------------------------
    DropMenu {
        open: root.menu === "session"
        anchorItem: sessionBtn
        items: {
            const out = [];
            for (let i = 0; i < sessions.count; i++)
                if (!root.sessionHidden(i))
                    out.push({ label: sessions.itemAt(i).name, value: i, checked: i === root.sessionIndex });
            return out;
        }
        onPicked: v => { root.sessionIndex = v; root.menu = ""; password.forceActiveFocus(); }
    }
    DropMenu {
        open: root.menu === "user"
        anchorItem: userBtn
        items: {
            const out = [];
            for (let i = 0; i < users.count; i++) {
                const u = users.itemAt(i);
                out.push({ label: u.realName !== "" ? u.realName + "  ·  " + u.name : u.name, value: i,
                           checked: !root.manualUser && i === root.userIndex });
            }
            out.push({ label: "Other user…", value: -1, checked: root.manualUser });
            return out;
        }
        onPicked: v => root.pickUser(v)
    }
    DropMenu {
        open: root.menu === "power"
        anchorItem: powerBtn
        alignRight: true
        items: [
            { label: "Suspend", value: "suspend", show: sddm.canSuspend },
            { label: "Hibernate", value: "hibernate", show: sddm.canHibernate },
            { label: "Restart", value: "reboot", show: sddm.canReboot },
            { label: "Shut down", value: "poweroff", show: sddm.canPowerOff }
        ].filter(i => i.show)
        onPicked: v => {
            root.menu = "";
            if (v === "suspend") sddm.suspend();
            else if (v === "hibernate") sddm.hibernate();
            else if (v === "reboot") sddm.reboot();
            else if (v === "poweroff") sddm.powerOff();
        }
    }

    component DropMenu: Rectangle {
        id: dm
        property bool open: false
        property Item anchorItem
        property bool alignRight: false
        property var items: []
        signal picked(var value)

        visible: open
        // Measured when it opens.
        readonly property point at: open && anchorItem ? anchorItem.mapToItem(root, 0, 0) : Qt.point(0, 0)
        x: alignRight && anchorItem ? at.x + anchorItem.width - width : at.x
        y: at.y - 8 - height
        width: Math.max(220, dmCol.implicitWidth + 12)
        height: dmCol.implicitHeight + 12
        radius: root.rr(12)
        color: root.cPanel
        border.color: root.cLine
        border.width: 1

        Column {
            id: dmCol
            anchors.centerIn: parent
            width: dm.width - 12
            Repeater {
                model: dm.items
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: dmCol.width
                    implicitWidth: rowText.implicitWidth + 60
                    height: 38
                    radius: root.rr(8)
                    color: rowHover.hovered ? root.cField : "transparent"
                    Text {
                        id: rowText
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        color: root.cInk
                        font.family: root.fontName
                        font.pixelSize: 15
                        font.weight: row.modelData.checked ? Font.Bold : Font.Normal
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                        color: root.cAccent
                        visible: row.modelData.checked === true
                        font.pixelSize: 15
                    }
                    HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: dm.picked(row.modelData.value) }
                }
            }
        }
    }

    // ---- small reusable button in the demo's chip style -------------------
    component Chip: Rectangle {
        id: chip
        property string label
        property bool selected: false
        signal clicked()

        implicitWidth: chipText.implicitWidth + 28
        implicitHeight: 36
        radius: root.rr(999)
        color: selected ? root.cAccent : root.cField
        border.width: 1
        border.color: selected ? root.cAccent : chipHover.hovered ? root.cAccent : root.cLine
        scale: chipTap.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? root.cOnAccent : root.cInk
            font.family: root.fontName
            font.pixelSize: 14
            font.weight: Font.Bold
        }
        HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: chipTap; onTapped: chip.clicked() }
    }

    Component.onCompleted: {
        if (sessionHidden(sessionIndex)) sessionIndex = lumenSession();
        password.forceActiveFocus();
    }
}
