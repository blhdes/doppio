import SwiftUI

/// A deep, slowly-drifting mesh gradient behind the whole screen.
///
/// The hue leans cool/cyan in HALF mode and warm/amber in DOUBLE mode, crossfading
/// when you flip. The drift is gentle (one wandering centre point); under Reduce
/// Motion the whole thing freezes to a single static frame.
struct TempoMeshBackground: View {
    let isDoubling: Bool
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? .infinity : 1.0 / 30.0)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let points = meshPoints(at: t)

            ZStack {
                MeshGradient(width: 3, height: 3, points: points, colors: Self.halfColors)
                MeshGradient(width: 3, height: 3, points: points, colors: Self.doubleColors)
                    .opacity(isDoubling ? 1 : 0)
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: isDoubling)
            .overlay(Color.black.opacity(0.25))   // veil keeps text crisp over the gradient
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

    // Deep, dark palettes so the mesh reads as ambient atmosphere, never garish.
    private static let halfColors: [Color] = [
        Color(red: 0.02, green: 0.03, blue: 0.06), Color(red: 0.03, green: 0.06, blue: 0.11), Color(red: 0.02, green: 0.04, blue: 0.07),
        Color(red: 0.03, green: 0.08, blue: 0.14), Color(red: 0.04, green: 0.13, blue: 0.20), Color(red: 0.02, green: 0.07, blue: 0.12),
        Color(red: 0.01, green: 0.02, blue: 0.05), Color(red: 0.02, green: 0.05, blue: 0.09), Color(red: 0.01, green: 0.02, blue: 0.04)
    ]
    private static let doubleColors: [Color] = [
        Color(red: 0.06, green: 0.03, blue: 0.02), Color(red: 0.11, green: 0.06, blue: 0.02), Color(red: 0.07, green: 0.04, blue: 0.02),
        Color(red: 0.15, green: 0.08, blue: 0.03), Color(red: 0.21, green: 0.12, blue: 0.04), Color(red: 0.12, green: 0.06, blue: 0.02),
        Color(red: 0.05, green: 0.02, blue: 0.01), Color(red: 0.09, green: 0.05, blue: 0.02), Color(red: 0.04, green: 0.02, blue: 0.01)
    ]
}
