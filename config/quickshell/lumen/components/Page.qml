import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.services

// A scrolling Settings page with a title, description and stacked cards.
Flickable {
    id: page

    property string title
    property string description
    default property alias content: col.data

    contentWidth: width
    contentHeight: col.implicitHeight + 64
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    ColumnLayout {
        id: col
        width: Math.min(page.width - 64, 760)
        x: Math.max(32, (page.width - width) / 2)
        y: 32
        spacing: 12

        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            Txt { text: page.title; size: 30; strong: true; Layout.fillWidth: true }
            Txt { text: page.description; muted: true; visible: text !== ""; Layout.fillWidth: true }
        }
    }
}
