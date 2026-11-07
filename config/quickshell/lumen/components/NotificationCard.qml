import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services

// One notification. Used for popups and in the Quick Settings history.
Rectangle {
    id: card

    required property var notification
    property bool popup: false
    readonly property var n: notification
    readonly property bool critical: n && n.urgency === NotificationUrgency.Critical
    readonly property string iconSource: !n ? ""
        : n.image !== "" ? n.image
        : n.appIcon !== "" ? (n.appIcon.startsWith("/") ? "file://" + n.appIcon : Quickshell.iconPath(n.appIcon, true))
        : ""
    property bool expanded: false

    signal dismissed()

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 24
    radius: Theme.r(12)
    color: popup ? Theme.panel : Theme.field
    border.width: critical ? 2 : 1
    border.color: critical ? Theme.danger : Theme.line

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            Item {
                implicitWidth: 32
                implicitHeight: 32
                IconImage {
                    anchors.fill: parent
                    source: card.iconSource
                    visible: card.iconSource !== "" && status === Image.Ready
                    asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.r(9)
                    color: Theme.accent
                    visible: card.iconSource === ""
                    Icon { anchors.centerIn: parent; name: "bell"; size: 16; color: Theme.accentFg }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                RowLayout {
                    Layout.fillWidth: true
                    Txt {
                        Layout.fillWidth: true
                        text: card.n ? (card.n.appName || "Notification") : ""
                        size: 11
                        muted: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Txt { text: card.n ? Notifs.timeOf(card.n) : ""; size: 11; muted: true }
                }
                Txt {
                    Layout.fillWidth: true
                    text: card.n ? card.n.summary : ""
                    strong: true
                    size: 14
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                width: 24; height: 24; radius: Theme.r(12)
                color: xHover.hovered ? Theme.line : "transparent"
                Icon { anchors.centerIn: parent; name: "x"; size: 13; color: Theme.muted }
                HoverHandler { id: xHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.dismissed() }
            }
        }

        Txt {
            Layout.fillWidth: true
            visible: text !== ""
            text: card.n ? card.n.body : ""
            size: 13
            muted: true
            maximumLineCount: card.expanded ? 12 : 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: card.n && card.n.actions.length > 0
            Repeater {
                model: card.n ? card.n.actions : []
                delegate: Btn {
                    required property var modelData
                    text: modelData.text
                    implicitHeight: 32
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    HoverHandler { id: cardHover }
    TapHandler { onTapped: card.expanded = !card.expanded }
    readonly property bool hovered: cardHover.hovered
}
