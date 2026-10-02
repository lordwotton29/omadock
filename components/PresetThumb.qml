import QtQuick
import qs.Commons
import qs.Ui

// A small drawing of a preset's look, built from its values: backdrop,
// dock body (shape, fill or gradient, opacity, border, shadow, split
// panels), placeholder icons in the icon style, dividers and indicator
// dots. It shows the character of a look, not an exact copy; theme colours
// come from the current Omarchy theme, as the dock would use them.
Item {
  id: thumb

  property var rootRef: null
  readonly property var root: rootRef
  property var look: ({})

  implicitWidth: Style.space(160)
  implicitHeight: Style.space(44)

  function val(key, fallback) {
    return (thumb.look && thumb.look[key] !== undefined) ? thumb.look[key] : fallback
  }
  function safeColor(s, fallback) {
    try { return Qt.color(s) } catch (e) { return fallback }
  }

  // Scale from the real dock (about 60 px tall) to this drawing.
  readonly property real k: body.height / 60

  readonly property string bg: String(val("bgColor", "theme"))
  readonly property real opacityValue: {
    var o = val("opacity", "theme")
    if (o === "theme" || typeof o !== "number") return Color.bar.background.a
    return Math.max(0, Math.min(1, o))
  }
  readonly property color fillColor: bg === "none" ? Qt.rgba(0, 0, 0, 0.25)
    : (bg.charAt(0) === "#" ? safeColor(bg, Color.bar.background) : Color.bar.background)
  readonly property color fg: bg.charAt(0) === "#" && root ? root.blackOrWhiteOn(fillColor) : Color.bar.text
  readonly property bool showBg: val("showBackground", true) !== false
  readonly property bool gradient: showBg && val("bgFill", "solid") === "gradient"
  readonly property var gradientColors: {
    var id = String(val("gradientPreset", "theme"))
    var list = root ? root.gradientPresets : []
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i].colors
    return root ? root.themeGradientColors : [Color.accent, Color.accent, Color.accent]
  }
  readonly property real rimAlpha: {
    var b = val("borderOpacity", "theme")
    if (typeof b === "number") return Math.max(0, Math.min(1, b))
    return (opacityValue < 0.25 || bg === "none") ? 0.48 : Math.max(0.24, opacityValue * 0.35)
  }
  readonly property bool border: val("showBorder", true) !== false
  readonly property real borderW: border ? Math.max(1, Number(val("borderWidth", 1.5)) * k) : 0
  readonly property real radius: {
    var s = String(val("shape", "rounded"))
    if (s === "round" || s === "pill") return body.height / 2
    if (s === "square") return 0
    var r = Number(val("cornerRadius", -1))
    if (s === "rounded" && r >= 0) return Math.min(body.height / 2, r * k)
    return Math.min(body.height / 2, 14 * k)
  }
  readonly property bool split: val("splitSections", false) === true
  readonly property string iconStyle: String(val("iconStyle", "original"))
  readonly property color tint: {
    var t = String(val("iconTint", "text"))
    if (t === "accent") return Color.accent
    if (t === "bw" && root) return root.blackOrWhiteOn(fillColor)
    return fg
  }
  readonly property var tileColors: [Color.accent].concat(gradientColors).concat([Color.bar.text, Color.accent])
  readonly property string dividerStyle: String(val("dividerStyle", "simple"))
  readonly property color dividerColor: dividerStyle === "theme" ? Util.alpha(fg, rimAlpha)
    : dividerStyle === "custom" ? Util.alpha(fg, Number(val("dividerOpacity", 0.4)))
    : Util.alpha(fg, 0.3)
  readonly property real dividerW: dividerStyle === "theme" ? Math.max(1, Number(val("borderWidth", 1.5)) * k)
    : dividerStyle === "custom" ? Math.max(1, Number(val("dividerWidth", 1.5)) * k) : 1
  readonly property real dividerH: body.height * Math.max(0.2, Math.min(1, Number(val("dividerHeight", 70)) / 100))

  // Backdrop: two theme colours, so opacity and a missing background show.
  Rectangle {
    anchors.fill: parent
    radius: Style.space(6)
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Qt.darker(Color.accent, 1.6) }
      GradientStop { position: 1; color: Qt.lighter(Color.menu.background, 1.05) }
    }
  }

  Item {
    id: body
    anchors.centerIn: parent
    width: parent.width - Style.space(12)
    height: parent.height - Style.space(12)

    // Panels: one, or three when sections are split.
    Repeater {
      model: thumb.split ? [[0, 0.5], [0.53, 0.83], [0.86, 1]] : [[0, 1]]
      delegate: Item {
        required property var modelData
        x: body.width * modelData[0]
        width: body.width * (modelData[1] - modelData[0])
        height: body.height

        Rectangle {
          visible: thumb.val("showShadow", true) !== false
          anchors.fill: parent
          anchors.topMargin: 1
          anchors.bottomMargin: -2
          radius: thumb.radius
          color: Qt.rgba(0, 0, 0, 0.35 * Number(thumb.val("shadowStrength", 0.4)))
        }
        Rectangle {
          anchors.fill: parent
          radius: thumb.radius
          visible: thumb.showBg && !thumb.gradient
          color: thumb.bg === "none" ? thumb.fillColor : Util.alpha(thumb.fillColor, thumb.opacityValue)
        }
        ShaderEffect {
          anchors.fill: parent
          visible: thumb.gradient
          property color base: Util.alpha(Color.bar.background, thumb.opacityValue)
          property color c1: thumb.gradientColors[0] || Color.accent
          property color c2: thumb.gradientColors[1] || c1
          property color c3: thumb.gradientColors[2] || c2
          property real count: thumb.gradientColors.length > 2 ? 3 : 2
          property real strength: Number(thumb.val("gradientStrength", 0.6))
          property real radius: thumb.radius
          property size size: Qt.size(width, height)
          fragmentShader: Qt.resolvedUrl("../shaders/gradient.frag.qsb")
        }
        Rectangle {
          anchors.fill: parent
          radius: thumb.radius
          color: "transparent"
          border.width: thumb.borderW
          border.color: Util.alpha(thumb.fg, thumb.rimAlpha)
        }
      }
    }

    // Icons in three sections (3, 2, 1) with dividers between them.
    Row {
      anchors.centerIn: parent
      spacing: Style.space(4)
      Repeater {
        model: [0, 1, 2, "|", 3, 4, "|", 5]
        delegate: Item {
          required property var modelData
          required property int index
          readonly property bool isDivider: modelData === "|"
          width: isDivider ? (thumb.split ? Style.space(4) : Style.space(3)) : body.height * 0.52
          height: body.height

          Rectangle {
            visible: parent.isDivider && !thumb.split
            anchors.centerIn: parent
            width: thumb.dividerW
            height: thumb.dividerH
            color: thumb.dividerColor
          }
          Rectangle {
            visible: !parent.isDivider
            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - height) / 2 - Style.space(1)
            width: parent.width
            height: width
            radius: thumb.iconStyle === "pixel" ? 0 : (thumb.iconStyle === "dots" ? width / 2 : width * 0.25)
            color: thumb.iconStyle === "original" || thumb.iconStyle === "pixel"
              ? thumb.tileColors[(typeof parent.modelData === "number" ? parent.modelData : 0) % thumb.tileColors.length]
              : thumb.tint
            opacity: thumb.iconStyle === "dots" ? 0.85 : 1
          }
          Rectangle {
            visible: !parent.isDivider && (parent.modelData === 0 || parent.modelData === 3)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.space(1)
            width: Style.space(3)
            height: width
            radius: thumb.val("indicatorShape", "theme") === "square" ? 0 : width / 2
            color: thumb.fg
          }
        }
      }
    }
  }
}
