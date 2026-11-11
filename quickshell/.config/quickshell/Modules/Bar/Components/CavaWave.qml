import QtQuick
import QtQuick.Shapes
import qs.Core
import qs.Core.Services

// Audio visualizer for the bar: a bundle of Bézier curves pinned to the middle line that
// bend with the music, after the bar visualizer in karol-broda/nixos-config.
// Colors run from the wallpaper accent to a paler shade of it.
Item {
    id: root

    property int segments: 10
    // how far the control points swing sideways with loud bands
    property real spread: 2
    // vertical swing of the curves relative to half the height
    property real gain: 2
    property bool isPlaying: MprisService.isPlaying
    // the accent faded toward the text color, so the curves don't glare on the dark bar
    property color colorStart: Theme.accent
    property color colorEnd: Qt.tint(Theme.accent, Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5))

    function level(index) {
        let data = CavaService.cavaData;
        if (!root.isPlaying || !data || data.length === 0)
            return 0;

        let i = Math.min(data.length - 1, Math.floor(index * data.length / root.segments));
        return Math.min(1, (data[i] || 0) / 100 * 1.5);
    }

    function curveColor(index) {
        let t = index / Math.max(1, root.segments - 1);
        let c = Qt.rgba(colorStart.r + (colorEnd.r - colorStart.r) * t, colorStart.g + (colorEnd.g - colorStart.g) * t, colorStart.b + (colorEnd.b - colorStart.b) * t, 1);
        // every other curve darker, so the bundle reads as layered strands
        return index % 2 === 0 ? Qt.darker(c, 1.6) : c;
    }

    implicitWidth: 90
    implicitHeight: Constants.size3Xl

    Shape {
        id: shape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        Instantiator {
            model: root.segments
            onObjectAdded: (index, object) => {
                shape.data.push(object);
            }

            delegate: ShapePath {
                id: curve

                required property int index
                readonly property real audio: root.level(index)
                readonly property real mid: shape.height / 2

                strokeWidth: 2 - 0.5 * audio
                strokeColor: root.curveColor(index)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 0
                startY: mid

                PathCubic {
                    x: shape.width
                    y: curve.mid
                    // the first control point carries the motion: sideways by band loudness,
                    // up for the outer quarters of the bundle and down for the middle;
                    // kept inside the item so the curves don't spill past its edges
                    control1X: {
                        let dir = curve.index > root.segments / 2 ? 1 : -1;
                        let x = (curve.index - 1) / root.segments + dir * curve.audio * root.spread / root.segments;
                        return Math.max(0, Math.min(1, x)) * shape.width;
                    }
                    control1Y: {
                        let outer = curve.index < root.segments / 4 || curve.index > root.segments * 3 / 4;
                        return curve.mid + (outer ? -1 : 1) * curve.mid * curve.audio * root.gain;
                    }
                    // the second one swings the other way, turning the bend into a wave
                    control2X: Math.min(1, (curve.index + 2) / root.segments) * shape.width
                    control2Y: {
                        let outer = curve.index < root.segments / 4 || curve.index > root.segments * 3 / 4;
                        return curve.mid - (outer ? -1 : 1) * curve.mid * curve.audio * root.gain * 0.6;
                    }
                }

            }

        }

    }

}
