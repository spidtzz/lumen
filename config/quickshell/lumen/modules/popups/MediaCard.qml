import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services
import qs.components

// Media controls in Quick Settings: whatever is playing (Spotify, a browser
// tab, mpv...) through MPRIS. Hidden when nothing is open, or when turned
// off in Settings > Bar.
Rectangle {
    id: card

    readonly property var players: Mpris.players.values
    property var picked: null   // chosen with the switch button; otherwise the one playing
    readonly property var player: (picked && players.includes(picked)) ? picked
        : (players.find(p => p.isPlaying) ?? players[0] ?? null)

    function time(s) {
        s = Math.max(0, Math.floor(s || 0));
        const h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60, sec = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + sec : m + ":" + sec;
    }

    visible: player !== null && Theme.conf.qs_media !== "false"
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 20
    radius: Theme.r(12)
    color: Theme.field
    border.width: 1
    border.color: Theme.line

    // MPRIS doesn't push the position; ask for it while visible.
    Timer {
        running: card.visible && card.player !== null && card.player.isPlaying
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            card.player.positionChanged();
            if (!seek.pressed) seek.value = card.player.position;
        }
    }
    onPlayerChanged: if (player) seek.value = player.position

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ClippingRectangle {
                implicitWidth: 44
                implicitHeight: 44
                radius: Theme.radiusSmall
                color: Theme.panel
                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    name: "music"
                    size: 22
                    color: Theme.muted
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: card.player ? (card.player.trackArtUrl || "") : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(88, 88)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Txt {
                    Layout.fillWidth: true
                    text: card.player ? (card.player.trackTitle || card.player.identity || "Playing") : ""
                    strong: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
                Txt {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.player ? (card.player.trackArtist || "") : ""
                    size: 12
                    muted: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
                Txt {
                    Layout.fillWidth: true
                    text: card.player ? (card.player.identity || "") : ""
                    size: 11
                    muted: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }

            // More than one player: switch between them.
            Btn {
                visible: card.players.length > 1
                icon: "refresh"
                variant: "ghost"
                implicitWidth: 30; implicitHeight: 30
                onClicked: {
                    const i = card.players.indexOf(card.player);
                    card.picked = card.players[(i + 1) % card.players.length];
                }
            }

            // Previous, play / pause, next.
            Row {
                spacing: 2
                Btn {
                    icon: "skip-back"
                    variant: "ghost"
                    implicitWidth: 30; implicitHeight: 30
                    enabled: card.player !== null && card.player.canGoPrevious
                    onClicked: card.player.previous()
                }
                Btn {
                    icon: card.player && card.player.isPlaying ? "pause" : "play"
                    variant: "primary"
                    implicitWidth: 30; implicitHeight: 30
                    enabled: card.player !== null && card.player.canTogglePlaying
                    onClicked: card.player.togglePlaying()
                }
                Btn {
                    icon: "skip-forward"
                    variant: "ghost"
                    implicitWidth: 30; implicitHeight: 30
                    enabled: card.player !== null && card.player.canGoNext
                    onClicked: card.player.next()
                }
            }
        }

        // Position (only when the player reports one).
        RowLayout {
            visible: card.player !== null && card.player.positionSupported && card.player.lengthSupported && card.player.length > 0
            Layout.fillWidth: true
            spacing: 8
            Txt { text: card.time(seek.value); size: 11; muted: true; Layout.preferredWidth: 38 }
            LSlider {
                id: seek
                Layout.fillWidth: true
                enabled: card.player !== null && card.player.canSeek
                from: 0
                to: card.player ? Math.max(1, card.player.length) : 1
                onCommitted: v => card.player.position = v
            }
            Txt {
                text: card.time(card.player ? card.player.length : 0)
                size: 11
                muted: true
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
