import QtQuick
import qs.services

// Base for bar buttons: rounded hover background, highlighted while its
// popup is open.
Rectangle {
    id: btn

    property bool vertical: false
    property bool open: false
    property int padding: 10
    default property alias content: inner.data
    signal clicked()
    signal rightClicked()

    implicitWidth: vertical ? 26 : inner.childrenRect.width + padding * 2
    implicitHeight: vertical ? inner.childrenRect.height + padding * 2 : 26
    radius: 13
    color: open ? Theme.accent : hover.hovered ? Theme.field : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Item {
        id: inner
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: btn.clicked() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: btn.rightClicked() }
}
