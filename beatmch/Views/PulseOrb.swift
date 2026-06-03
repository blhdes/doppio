import SwiftUI

/// The three ways the beat can come alive around the number. Cycled with a two-finger
/// tap; the choice is remembered between launches. All three keep the steady centre
/// number and the inner=result / outer=source two-rhythm idea — they differ only in how
/// the rhythm is drawn.
enum BeatStyle: String, CaseIterable {
    /// A glowing dot orbits each ring once per beat — a metronome bent into a circle.
    case orbit
    /// Each beat is born at the centre and expands outward as a fading ring.
    case ripple
    /// A bright arc sweeps around each ring once per beat, like a radar.
    case sweep

    /// The next style in the cycle, wrapping back to the first.
    var next: BeatStyle {
        let all = Self.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }
}

/// The hero: the result BPM, huge and rock-steady, with the beat drawn around it.
///
/// The motion always speaks the same two rhythms — the **result** tempo (bold, inner)
/// and the **source** tempo (faint, outer) — so the half/double relationship stays
/// visible as two overlapping rates. `style` only changes *how* that's drawn (see
/// `BeatStyle`). The number itself never scales, so it stays glanceable in a dark booth.
///
/// Under Reduce Motion the drawing holds still and two dots blink (opacity only) on each
/// beat instead, whatever the chosen style.
struct PulseOrb: View {
    let resultBPM: Double
    let sourceBPM: Double
    let displayText: String
    let accent: Color
    /// Text colour for the big number — light on dark themes, dark on light ones.
    let ink: Color
    let reduceMotion: Bool
    /// Which beat motion to draw.
    let style: BeatStyle
    /// True while the user is actively setting the tempo — suppresses the digit-roll so the
    /// rapidly-changing number doesn't flash through dozens of stacked transitions.
    let isAdjusting: Bool

    // Geometry, all measured from the canvas centre. The canvas is a touch larger than the
    // 320pt layout box so glows and ripples can spill past the rings without being clipped.
    private let canvasSize: CGFloat = 360
    private let outerR: CGFloat = 150   // source-tempo radius (fainter)
    private let innerR: CGFloat = 118   // result-tempo radius (bolder)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let resultPulse = beat(bpm: resultBPM, at: t)
            let sourcePulse = beat(bpm: sourceBPM, at: t)

            ZStack {
                if reduceMotion {
                    // Motion off: two still guide rings keep the orb's identity.
                    Circle().strokeBorder(accent.opacity(0.18), lineWidth: 1.5).frame(width: outerR * 2)
                    Circle().strokeBorder(accent.opacity(0.30), lineWidth: 1.5).frame(width: innerR * 2)
                } else {
                    Canvas { ctx, size in
                        draw(in: &ctx, size: size,
                             resultPhase: phase(bpm: resultBPM, at: t),
                             sourcePhase: phase(bpm: sourceBPM, at: t),
                             resultBeat: resultPulse)
                    }
                    .frame(width: canvasSize, height: canvasSize)
                    .allowsHitTesting(false)
                }

                VStack(spacing: 14) {
                    Text(displayText)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ink)
                        .contentTransition(isAdjusting ? .identity : .numericText(value: resultBPM))
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

    // MARK: - Drawing

    /// Paint the active style. A faint heartbeat bloom behind the number ties every style to
    /// the result tempo without moving the number itself.
    private func draw(in ctx: inout GraphicsContext, size: CGSize,
                      resultPhase: Double, sourcePhase: Double, resultBeat: Double) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)

        // Heartbeat bloom — a soft glow that brightens on each result beat.
        let bloomR: CGFloat = 150
        ctx.fill(circlePath(c, bloomR),
                 with: .radialGradient(Gradient(colors: [accent.opacity(0.10 * resultBeat), .clear]),
                                       center: c, startRadius: 0, endRadius: bloomR))

        switch style {
        case .orbit:
            strokeRing(&ctx, c, outerR, accent.opacity(0.10), 1.5)
            strokeRing(&ctx, c, innerR, accent.opacity(0.14), 1.5)
            orbitDot(&ctx, c, outerR, sourcePhase, accent.opacity(0.55), dot: 7, glow: 15)
            orbitDot(&ctx, c, innerR, resultPhase, accent, dot: 10, glow: 22)

        case .ripple:
            ripples(&ctx, c, sourcePhase, accent, strength: 0.40)
            ripples(&ctx, c, resultPhase, accent, strength: 0.85)

        case .sweep:
            strokeRing(&ctx, c, outerR, accent.opacity(0.10), 1.5)
            strokeRing(&ctx, c, innerR, accent.opacity(0.14), 1.5)
            sweepArc(&ctx, c, outerR, sourcePhase, accent.opacity(0.55), width: 3)
            sweepArc(&ctx, c, innerR, resultPhase, accent, width: 4)
        }
    }

    /// A glowing dot sitting at `phase` of the way clockwise around the ring from 12 o'clock.
    private func orbitDot(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat,
                          _ phase: Double, _ color: Color, dot: CGFloat, glow: CGFloat) {
        let p = point(c, r, angle(phase))
        ctx.fill(circlePath(p, glow),
                 with: .radialGradient(Gradient(colors: [color.opacity(0.6), .clear]),
                                       center: p, startRadius: 0, endRadius: glow))
        ctx.fill(circlePath(p, dot / 2), with: .color(color))
    }

    /// A wedge whose bright leading edge sits at `phase` and fades into a tail behind it.
    /// Built from short chords so the opacity ramp is clean regardless of arc direction.
    private func sweepArc(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat,
                          _ phase: Double, _ color: Color, width: CGFloat) {
        let lead = angle(phase)
        let span = Double.pi / 2          // a 90° tail
        let segments = 18
        var prev = point(c, r, lead - span)
        for i in 1...segments {
            let f = Double(i) / Double(segments)      // 0 at tail → 1 at head
            let pt = point(c, r, lead - span * (1 - f))
            var seg = Path()
            seg.move(to: prev)
            seg.addLine(to: pt)
            ctx.stroke(seg, with: .color(color.opacity(f)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
            prev = pt
        }
        // Bright head to anchor the leading edge.
        ctx.fill(circlePath(prev, width), with: .color(color))
    }

    /// Two rings per tempo, born at the centre and expanding outward as they fade — offset
    /// half a beat apart so a ripple is always mid-flight.
    private func ripples(_ ctx: inout GraphicsContext, _ c: CGPoint,
                         _ phase: Double, _ color: Color, strength: Double) {
        let r0: CGFloat = 70, rMax: CGFloat = 165
        for offset in [0.0, 0.5] {
            let age = (phase + offset).truncatingRemainder(dividingBy: 1)
            let r = r0 + CGFloat(age) * (rMax - r0)
            let fade = (1 - age) * strength
            strokeRing(&ctx, c, r, color.opacity(fade), 1.0 + CGFloat(1 - age) * 1.5)
        }
    }

    // MARK: - Geometry helpers

    /// Angle in radians for a beat phase: 0 → straight up, advancing clockwise.
    private func angle(_ phase: Double) -> Double { -Double.pi / 2 + phase * 2 * .pi }

    /// A point on a circle of radius `r` around `c` at angle `a`.
    private func point(_ c: CGPoint, _ r: CGFloat, _ a: Double) -> CGPoint {
        CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
    }

    /// A circle path of radius `r` centred on `p`.
    private func circlePath(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }

    private func strokeRing(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat,
                            _ color: Color, _ lineWidth: CGFloat) {
        ctx.stroke(circlePath(c, r), with: .color(color), lineWidth: lineWidth)
    }

    // MARK: - Timing

    /// Beat envelope: a sharp spike at each beat onset that decays before the next.
    /// Returns ~1 right on the beat, falling toward 0 in between.
    private func beat(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        let phase = (t * bpm / 60).truncatingRemainder(dividingBy: 1)
        return exp(-phase * 6.5)
    }

    /// Where we are within the current beat: 0 at the onset, climbing toward 1 just before
    /// the next. Drives the orbiting dot and the sweep arc.
    private func phase(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        return (t * bpm / 60).truncatingRemainder(dividingBy: 1)
    }
}
