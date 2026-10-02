import QtQuick
import QtQuick.Effects
import qs.Commons

// Hover effects that keep an item's size, drawn around whatever it hosts (an
// icon, a group tile, a window preview). hoverFx.effect picks one:
//
//   lift    the content rises over a soft shadow left on the floor
//
// Any other value draws the content as is. hoverFx is the dock's object
// (Dock.qml), so every item follows the setting without plumbing of its own.
//
// Content goes inside, or is reparented into contentItem by an item that
// must keep its place in the caller's tree (and its indentation).
Item {
  id: fx

  property bool hovered: false
  property var hoverFx: null

  default property alias content: body.data
  readonly property Item contentItem: body

  readonly property string effect: fx.hoverFx ? fx.hoverFx.effect : ""
  readonly property real minSide: Math.min(fx.width, fx.height)

  // 0..1, follows hovered; the effects scale with it.
  property real hoverLevel: fx.hovered ? 1 : 0
  Behavior on hoverLevel { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

  // Lift: the shadow stays on the floor while the content rises.
  Rectangle {
    visible: fx.effect === "lift" && fx.hoverLevel > 0.01
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.bottom
    width: fx.width * (0.78 - 0.18 * fx.hoverLevel)
    height: Math.max(2, fx.minSide * 0.07)
    radius: height / 2
    color: "#000000"
    opacity: 0.35 * fx.hoverLevel
    layer.enabled: visible
    layer.effect: MultiEffect {
      blurEnabled: true
      blur: 0.7
      blurMax: 16
      autoPaddingEnabled: true
    }
  }

  Item {
    anchors.fill: parent
    transform: Translate { y: fx.effect === "lift" ? -fx.minSide * 0.16 * fx.hoverLevel : 0 }

    Item {
      id: body
      anchors.fill: parent
    }
  }
}
