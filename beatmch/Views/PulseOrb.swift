import SwiftUI

/// The hero: the result BPM, huge and rock-steady, framed by two pulsing rings.
///
/// The bold inner ring beats at the **result** tempo; the fainter outer ring beats
/// at the **source** tempo — so the half/double relationship is visible as two
/// overlapping rhythms (in HALF mode the outer ring beats twice per inner beat).
/// The number itself never scales, so it stays glanceable in a dark booth.
///
/// Under Reduce Motion the rings hold still and two dots blink (opacity only)
/// on each beat instead.
struct PulseOrb: View {
    let resultBPM: Double
    let sourceBPM: Double
    let displayText: String
    let accent: Color
    /// Text colour for the big number — light on dark themes, dark on light ones.
    let ink: Color
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let resultPulse = beat(bpm: resultBPM, at: t)
            let sourcePulse = beat(bpm: sourceBPM, at: t)

            ZStack {
                // Outer ring — source tempo (fainter).
                Circle()
                    .strokeBorder(accent.opacity(0.22), lineWidth: 2)
                    .frame(width: 320, height: 320)
                    .scaleEffect(reduceMotion ? 1 : 1 + 0.05 * sourcePulse)

                // Inner ring — result tempo (bold), with a beat-synced glow.
                Circle()
                    .strokeBorder(accent.opacity(0.85), lineWidth: 3)
                    .frame(width: 250, height: 250)
                    .scaleEffect(reduceMotion ? 1 : 1 + 0.09 * resultPulse)
                    .shadow(color: accent.opacity(reduceMotion ? 0 : 0.5 * resultPulse), radius: 18)

                VStack(spacing: 14) {
                    Text(displayText)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ink)
                        .contentTransition(.numericText(value: resultBPM))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    if reduceMotion {
                        HStack(spacing: 10) {
                            Circle().fill(accent)
                                .frame(width: 8, height: 8)
                                .opacity(0.2 + 0.8 * resultPulse)
                            Circle().fill(accent.opacity(0.55))
                                .frame(width: 8, height: 8)
                                .opacity(0.15 + 0.7 * sourcePulse)
                        }
                    }
                }
                .frame(width: 230)
            }
        }
        .frame(width: 320, height: 320)
    }

    /// Beat envelope: a sharp spike at each beat onset that decays before the next.
    /// Returns ~1 right on the beat, falling toward 0 in between.
    private func beat(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        let phase = (t * bpm / 60).truncatingRemainder(dividingBy: 1)
        return exp(-phase * 6.5)
    }
}
