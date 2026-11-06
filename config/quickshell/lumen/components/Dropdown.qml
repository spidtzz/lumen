import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.services

// The demo's dropdown: a field that opens a list. Arrow keys, Enter and
// Escape work; `searchable` adds a filter field for long lists.
// options: [{ label, value }]
Rectangle {
    id: dd

    property var options: []
    property var value
    property string placeholder: "Choose…"
    property bool searchable: false
    signal picked(var value)

    readonly property var current: options.find(o => o.value === value)
    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        return q === "" ? options : options.filter(o => String(o.label).toLowerCase().includes(q));
    }

    implicitWidth: 260
    implicitHeight: 40
    radius: Theme.radiusSmall
    color: Theme.field
    opacity: enabled ? 1 : 0.5
    border.width: popup.opened || dd.activeFocus ? 2 : 1
    border.color: popup.opened || hover.hovered || dd.activeFocus ? Theme.accent : Theme.line
    activeFocusOnTab: true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8
        Txt {
            Layout.fillWidth: true
            text: dd.current ? dd.current.label : dd.placeholder
            muted: !dd.current
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
        Icon {
            name: "chevron-down"
            size: 16
            color: Theme.muted
            rotation: popup.opened ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.animFast } }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: dd.toggle() }
    Keys.onSpacePressed: toggle()
    Keys.onReturnPressed: toggle()
    Keys.onDownPressed: toggle()

    function toggle() {
        if (popup.opened) { popup.close(); return; }
        search.text = "";
        list.currentIndex = Math.max(0, filtered.findIndex(o => o.value === value));
        popup.open();
        if (searchable) search.forceActiveFocus(); else list.forceActiveFocus();
        list.positionViewAtIndex(list.currentIndex, ListView.Center);
    }

    function choose(i) {
        const o = filtered[i];
        if (!o) return;
        popup.close();
        dd.forceActiveFocus();
        if (o.value !== value) picked(o.value);
    }

    Popup {
        id: popup
        y: dd.height + 6
        width: Math.max(dd.width, 220)
        height: Math.min(contentCol.implicitHeight + 12, 340)
        padding: 6
        margins: 10
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 12
            color: Theme.panel
            border.width: 1
            border.color: Theme.line
        }

        contentItem: ColumnLayout {
            id: contentCol
            spacing: 6

            Field {
                id: search
                visible: dd.searchable
                Layout.fillWidth: true
                placeholderText: "Search"
                onTextChanged: list.currentIndex = 0
                Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                Keys.onReturnPressed: dd.choose(list.currentIndex)
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: contentHeight
                clip: true
                model: dd.filtered
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                ScrollBar.vertical: ScrollBar { policy: list.contentHeight > list.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }

                Keys.onReturnPressed: dd.choose(currentIndex)
                Keys.onSpacePressed: dd.choose(currentIndex)
                Keys.onUpPressed: currentIndex = Math.max(0, currentIndex - 1)
                Keys.onDownPressed: currentIndex = Math.min(count - 1, currentIndex + 1)

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    required property int index
                    width: ListView.view.width - 8
                    height: 38
                    radius: 8
                    color: index === list.currentIndex ? Theme.field : "transparent"

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.right: check.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: item.modelData.label
                        strong: item.modelData.value === dd.value
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Icon {
                        id: check
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        name: "check"
                        size: 15
                        color: Theme.accent
                        visible: item.modelData.value === dd.value
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) list.currentIndex = item.index
                    }
                    TapHandler { onTapped: dd.choose(item.index) }
                }
            }

            Txt {
                visible: dd.filtered.length === 0
                text: "Nothing found."
                muted: true
                size: 13
                Layout.margins: 8
            }
        }
    }
}
