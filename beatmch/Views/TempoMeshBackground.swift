import SwiftUI

/// A deep, slowly-drifting mesh gradient behind the whole screen.
///
/// The hue leans cool/cyan in HALF mode and warm/amber in DOUBLE mode, crossfading
/// when you flip. The drift is gentle (one wandering centre point); under Reduce
/// Motion the whole thing freezes to a single static frame.
struct TempoMeshBackground: View {
    /// The active theme — supplies both the HALF and DOUBLE mesh palettes so the
    /// flip can crossfade between them.
    let theme: Theme
    let isDoubling: Bool
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? .infinity : 1.0 / 30.0)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let points = meshPoints(at: t)

            ZStack {
                MeshGradient(width: 3, height: 3, points: points, colors: theme.half.mesh)
                MeshGradient(width: 3, height: 3, points: points, colors: theme.double.mesh)
                    .opacity(isDoubling ? 1 : 0)
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: isDoubling)
            .overlay(theme.palette(isDoubling: isDoubling).veil)   // veil keeps text crisp over the gradient
            .ignoresSafeArea()
        }
    }

    /// 3×3 control grid. All eight border points are anchored; only the centre
    /// wanders on a slow Lissajous curve. Amplitude 0.08 keeps every point well
    /// inside [0, 1], so the mesh never tears into transparent diagonal voids.
    private func meshPoints(at t: TimeInterval) -> [SIMD2<Float>] {
        let cx = Float(0.5 + 0.08 * sin(t * 0.42))
        let cy = Float(0.5 + 0.08 * cos(t * 0.31))
        return [
            SIMD2(0, 0),   SIMD2(0.5, 0),  SIMD2(1, 0),
            SIMD2(0, 0.5), SIMD2(cx, cy),  SIMD2(1, 0.5),
            SIMD2(0, 1),   SIMD2(0.5, 1),  SIMD2(1, 1)
        ]
    }
}
