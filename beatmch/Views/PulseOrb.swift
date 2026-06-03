import SwiftUI

/// The states the orb can take. Cycled with a two-finger tap; the choice is remembered
/// between launches. The first four keep the steady centre number and the inner=result /
/// outer=source two-rhythm idea, differing only in how the rhythm is drawn; `bare` strips
/// all of it away, leaving nothing but the number.
enum BeatStyle: String, CaseIterable {
    /// A glowing dot orbits each ring once per beat — a metronome bent into a circle.
    case orbit
    /// Each beat is born at the centre and expands outward as a fading ring.
    case ripple
    /// A bright arc sweeps around each ring once per beat, like a radar.
    case sweep
    /// The original: two concentric rings breathe — scale in and out — on each beat,
    /// the bold inner ring (result) carrying a soft glow, the faint outer one the source.
    case pulse
    /// Nothing at all — no rings, no motion, just the number. The calmest, stillest read.
    case bare

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
        // The bare state never animates, so freeze the timeline to a single static frame —
        // no 30fps loop running just to hold a still number.
        TimelineView(.animation(minimumInterval: style == .bare ? .infinity : 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let resultPulse = beat(bpm: resultBPM, at: t)
            let sourcePulse = beat(bpm: sourceBPM, at: t)

            ZStack {
                if style != .bare {
                    if reduceMotion {
                        // Motion off: two still guide rings keep the orb's identity.
                        Circle().strokeBorder(accent.opacity(0.18), lineWidth: 1.5).frame(width: outerR * 2)
                        Circle().strokeBorder(accent.opacity(0.30), lineWidth: 1.5).frame(width: innerR * 2)
                    } else {
                        Canvas { ctx, size in
                            draw(in: &ctx, size: size,
                                 resultPhase: phase(bpm: resultBPM, at: t),
                                 sourcePhase: phase(bpm: sourceBPM, at: t),
                                 resultBeat: resultPulse,
                                 sourceBeat: sourcePulse)
                        }
                        .frame(width: canvasSize, height: canvasSize)
                        .allowsHitTesting(false)
                    }
                }

                // The number stands alone in the ZStack so it always shares the rings'
                // exact centre. The Reduce-Motion blink dots are a separate layer, offset
                // downward — they sit below the number instead of pushing it up off-centre.
                Text(displayText)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                    .contentTransition(isAdjusting ? .identity : .numericText(value: resultBPM))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: 230)

                if reduceMotion && style != .bare {
                    HStack(spacing: 10) {
                        Circle().fill(accent)
                            .frame(width: 8, height: 8)
                            .opacity(0.2 + 0.8 * resultPulse)
                        Circle().fill(accent.opacity(0.55))
                            .frame(width: 8, height: 8)
                            .opacity(0.15 + 0.7 * sourcePulse)
                    }
                    .offset(y: 76)
                }
            }
        }
        .frame(width: 320, height: 320)
    }

    // MARK: - Drawing

    /// Paint the active style. Each style carries its own beat feedback through its motion —
    /// there's no shared behind-the-number bloom, which popped in on every completed circle.
    private func draw(in ctx: inout GraphicsContext, size: CGSize,
                      resultPhase: Double, sourcePhase: Double,
                      resultBeat: Double, sourceBeat: Double) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)

        switch style {
        case .orbit:
            strokeRing(&ctx, c, outerR, accent.opacity(0.10), 1.5)
            strokeRing(&ctx, c, innerR, accent.opacity(0.14), 1.5)
            orbitDot(&ctx, c, outerR, sourcePhase, accent.opacity(0.55), dot: 7, glow: 15)
            orbitDot(&ctx, c, innerR, resultPhase, accent, dot: 10, glow: 22)

        case .ripple:
            // Honest one-ripple-per-beat at the real tempo; the brightness swells in then
            // out across the beat (see `ripples`) so fast beats read as a pulse, not a flash.
            ripples(&ctx, c, sourcePhase, accent, strength: 0.40)
            ripples(&ctx, c, resultPhase, accent, strength: 0.85)

        case .sweep:
            // One turn per beat at the real tempo. The trail lengthens with speed (honest
            // motion blur), so quick tempos smear into a smooth ring instead of strobing.
            strokeRing(&ctx, c, outerR, accent.opacity(0.10), 1.5)
            strokeRing(&ctx, c, innerR, accent.opacity(0.14), 1.5)
            sweepArc(&ctx, c, outerR, sourcePhase, accent.opacity(0.55), width: 3, span: sweepSpan(bpm: sourceBPM))
            sweepArc(&ctx, c, innerR, resultPhase, accent, width: 4, span: sweepSpan(bpm: resultBPM))

        case .pulse:
            // The original look: two rings breathing in and out on the beat. The faint
            // outer ring rides the source tempo; the bold inner ring (result) swells more
            // and carries a glow that brightens right on each beat, then fades.
            let outer = outerR * (1 + 0.05 * sourceBeat)
            let inner = innerR * (1 + 0.09 * resultBeat)
            strokeRing(&ctx, c, outer, accent.opacity(0.22), 2)
            ctx.drawLayer { layer in
                layer.addFilter(.shadow(color: accent.opacity(0.5 * resultBeat), radius: 18))
                layer.stroke(circlePath(c, inner), with: .color(accent.opacity(0.85)), lineWidth: 3)
            }

        case .bare:
            break   // nothing to draw — the Canvas isn't even mounted in this state
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

    /// A comet whose bright leading edge sits at `phase` and fades into a tail of length
    /// `span` radians behind it. Built from short chords so the opacity ramp stays clean.
    private func sweepArc(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat,
                          _ phase: Double, _ color: Color, width: CGFloat, span: Double) {
        let lead = angle(phase)
        let segments = 36
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

    /// Two rings per tempo, born at the centre and expanding outward — offset half a beat
    /// apart so a ripple is always mid-flight. The brightness swells in then out across the
    /// beat (a smooth arch) instead of popping in at the centre, so fast tempos read as a
    /// pulse of light rather than a hard flash.
    private func ripples(_ ctx: inout GraphicsContext, _ c: CGPoint,
                         _ phase: Double, _ color: Color, strength: Double) {
        let r0: CGFloat = 70, rMax: CGFloat = 165
        for offset in [0.0, 0.5] {
            let age = (phase + offset).truncatingRemainder(dividingBy: 1)
            let r = r0 + CGFloat(age) * (rMax - r0)
            let fade = sin(.pi * age) * strength      // 0 → peak → 0 across the beat
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
    /// the next. One full turn per beat, locked to the real tempo. Drives the orbiting dot,
    /// the sweep comet, and the ripples.
    private func phase(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        return (t * bpm / 60).truncatingRemainder(dividingBy: 1)
    }

    /// Length, in radians, of the sweep comet's trail — the angle its head covers in a fixed
    /// ~0.28s of afterglow. Honest motion blur: the rate is still one turn per beat, but a
    /// quick tempo smears the head into a long, near-full-ring streak that reads calmly
    /// instead of strobing. Clamped so slow tempos keep a visible comet and fast ones don't
    /// quite close the loop onto their own tail.
    private func sweepSpan(bpm: Double) -> Double {
        let persistence = 0.28                       // seconds of afterglow
        let span = bpm / 60 * persistence * 2 * .pi  // angle the head covers in that time
        return min(1.9 * .pi, max(.pi / 3, span))
    }
}
