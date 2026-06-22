import SwiftUI

/// The states the orb can take. Cycled with a two-finger tap; the choice is remembered
/// between launches. The first four keep the steady centre number and the inner=result /
/// outer=source two-rhythm idea, differing only in how the rhythm is drawn; `bare` strips
/// all of it away, leaving nothing but the number.
enum BeatStyle: String, CaseIterable {
    /// A glowing dot travels around each ring once per bar (four beats) — a slow metronome
    /// hand — its glow ticking brighter on each beat as it passes.
    case orbit
    /// A ring is born at the centre and expands to the edge across a whole bar — a slow
    /// swell of light rather than a per-beat flash.
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

    // Geometry, all measured from the canvas centre. Every glow and ripple stays *inside*
    // the 320pt layout box, so the breathing room the layout promises around the orb is
    // real — nothing paints into the gap between the rings and the labels.
    private let canvasSize: CGFloat = 320
    private let outerR: CGFloat = 138   // source-tempo radius (fainter)
    private let innerR: CGFloat = 108   // result-tempo radius (bolder)

    // The shared ring language: hairline strokes everywhere, with brightness — not
    // thickness — telling the two rhythms apart. Result reads bolder, source fainter.
    private let hairline: CGFloat = 1
    private let sourceGuide = 0.10      // resting opacity of source-tempo guide rings
    private let resultGuide = 0.16      // resting opacity of result-tempo guide rings
    private let sourceLive = 0.50       // moving source elements (dot, comet)

    var body: some View {
        // The number lives *outside* the timeline: it depends only on the BPM, so it's
        // diffed when the value changes, not 30 times a second. The 30fps loop is scoped
        // to the motion layer alone — and in the bare state no timeline exists at all.
        ZStack {
            if style != .bare {
                motionLayer
                    // Each style is its own view identity, so an animated style change
                    // crossfades the old drawing into the new one instead of snapping.
                    .id(style)
                    .transition(.opacity)
            }

            // The number stands alone in the ZStack so it always shares the rings'
            // exact centre.
            Text(displayText)
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ink)
                .contentTransition(isAdjusting ? .identity : .numericText(value: resultBPM))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: 210)   // just inside the inner ring, so digits never touch it
        }
        .frame(width: 320, height: 320)
    }

    /// The animated beat drawing — everything that re-renders per frame. Under Reduce
    /// Motion the drawing holds still and two dots blink (opacity only) on each beat,
    /// offset downward so they sit below the number instead of pushing it off-centre.
    @ViewBuilder private var motionLayer: some View {
        if reduceMotion {
            reduceMotionLayer
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { ctx, size in
                    draw(in: &ctx, size: size, at: timeline.date.timeIntervalSinceReferenceDate)
                }
                .frame(width: canvasSize, height: canvasSize)
                .allowsHitTesting(false)
            }
        }
    }

    /// Motion off: two still guide rings keep the orb's identity while two dots blink (opacity
    /// only) on each beat. The rings never change, so they sit *outside* the timeline — only
    /// the blinking dots need the 30fps clock.
    private var reduceMotionLayer: some View {
        ZStack {
            Circle().strokeBorder(accent.opacity(0.18), lineWidth: hairline).frame(width: outerR * 2)
            Circle().strokeBorder(accent.opacity(0.30), lineWidth: hairline).frame(width: innerR * 2)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(spacing: 10) {
                    Circle().fill(accent)
                        .frame(width: 8, height: 8)
                        .opacity(0.2 + 0.8 * beat(bpm: resultBPM, at: t))
                    Circle().fill(accent.opacity(0.55))
                        .frame(width: 8, height: 8)
                        .opacity(0.15 + 0.7 * beat(bpm: sourceBPM, at: t))
                }
                .offset(y: 76)
            }
        }
    }

    // MARK: - Drawing

    /// Paint the active style. Each style carries its own beat feedback through its motion —
    /// there's no shared behind-the-number bloom, which popped in on every completed circle.
    /// Each case derives exactly the timing inputs it uses (phase or envelope) from `t`.
    private func draw(in ctx: inout GraphicsContext, size: CGSize, at t: TimeInterval) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)

        switch style {
        case .orbit:
            // The dot travels once per bar (four beats) — a slow hand — but its glow still
            // pulses on each beat, so the motion is paused while the tempo stays legible.
            strokeRing(&ctx, c, outerR, accent.opacity(sourceGuide), hairline)
            strokeRing(&ctx, c, innerR, accent.opacity(resultGuide), hairline)
            orbitDot(&ctx, c, outerR, barPhase(bpm: sourceBPM, at: t), accent.opacity(sourceLive),
                     dot: 5, glow: 10, pulse: beat(bpm: sourceBPM, at: t))
            orbitDot(&ctx, c, innerR, barPhase(bpm: resultBPM, at: t), accent,
                     dot: 7, glow: 14, pulse: beat(bpm: resultBPM, at: t))

        case .ripple:
            // One slow swell per bar at the real tempo: a ring born at the centre and
            // expanding to the edge over four beats, brightening in then out (see `ripples`)
            // so the expansion reads as a calm wave rather than a flash.
            ripples(&ctx, c, barPhase(bpm: sourceBPM, at: t), accent, strength: 0.40)
            ripples(&ctx, c, barPhase(bpm: resultBPM, at: t), accent, strength: 0.85)

        case .sweep:
            // One turn per beat at the real tempo. The trail lengthens with speed (honest
            // motion blur), so quick tempos smear into a smooth ring instead of strobing.
            strokeRing(&ctx, c, outerR, accent.opacity(sourceGuide), hairline)
            strokeRing(&ctx, c, innerR, accent.opacity(resultGuide), hairline)
            sweepArc(&ctx, c, outerR, phase(bpm: sourceBPM, at: t), accent.opacity(sourceLive), width: 1.5, span: sweepSpan(bpm: sourceBPM))
            sweepArc(&ctx, c, innerR, phase(bpm: resultBPM, at: t), accent, width: 2, span: sweepSpan(bpm: resultBPM))

        case .pulse:
            // The original look: two rings breathing in and out on the beat. The faint
            // outer ring rides the source tempo; the bold inner ring (result) swells more
            // and carries a glow that brightens right on each beat, then fades. The swell
            // and glow stay small on purpose — the beat should whisper, not flash.
            let outer = outerR * (1 + 0.04 * beat(bpm: sourceBPM, at: t))
            let resultBeat = beat(bpm: resultBPM, at: t)
            let inner = innerR * (1 + 0.06 * resultBeat)
            strokeRing(&ctx, c, outer, accent.opacity(0.18), hairline)
            ctx.drawLayer { layer in
                layer.addFilter(.shadow(color: accent.opacity(0.35 * resultBeat), radius: 10))
                layer.stroke(circlePath(c, inner), with: .color(accent.opacity(0.85)), lineWidth: 1.5)
            }

        case .bare:
            break   // unreachable — the motion layer isn't mounted in the bare state
        }
    }

    /// A glowing dot sitting at `phase` of the way clockwise around the ring from 12 o'clock.
    /// `pulse` (0…1, peaking on each beat) swells the glow's size and brightness, so the slow
    /// once-per-bar travel still ticks visibly with the tempo.
    private func orbitDot(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat,
                          _ phase: Double, _ color: Color, dot: CGFloat, glow: CGFloat, pulse: Double) {
        let p = point(c, r, angle(phase))
        let g = glow * (1 + 0.4 * pulse)
        ctx.fill(circlePath(p, g),
                 with: .radialGradient(Gradient(colors: [color.opacity(0.35 + 0.45 * pulse), .clear]),
                                       center: p, startRadius: 0, endRadius: g))
        ctx.fill(circlePath(p, dot / 2), with: .color(color))
    }

    /// A comet whose bright leading edge sits at `phase` and fades into a tail of length
    /// `span` radians behind it: one arc stroked with a conic gradient whose ramp runs
    /// clear at the tail → full at the head, then cuts off so nothing paints past the lead.
    private func sweepArc(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat,
                          _ phase: Double, _ color: Color, width: CGFloat, span: Double) {
        let lead = angle(phase)
        let tail = lead - span
        var arc = Path()
        arc.addArc(center: c, radius: r,
                   startAngle: .radians(tail), endAngle: .radians(lead), clockwise: false)
        let head = span / (2 * .pi)   // the head's fraction of the gradient's full turn
        let ramp = Gradient(stops: [
            .init(color: color.opacity(0), location: 0),
            .init(color: color, location: head),
            .init(color: color.opacity(0), location: min(head + 0.001, 1)),
        ])
        ctx.stroke(arc, with: .conicGradient(ramp, center: c, angle: .radians(tail)),
                   style: StrokeStyle(lineWidth: width, lineCap: .round))
        // Bright head to anchor the leading edge (also covers the cut-off head cap).
        ctx.fill(circlePath(point(c, r, lead), width), with: .color(color))
    }

    /// Two rings per tempo, born at the centre and expanding outward — offset half a bar
    /// apart so a ripple is always mid-flight. The brightness swells in then out across the
    /// bar (a smooth arch) instead of popping in at the centre, so the expansion reads as a
    /// calm wave of light rather than a hard flash.
    private func ripples(_ ctx: inout GraphicsContext, _ c: CGPoint,
                         _ phase: Double, _ color: Color, strength: Double) {
        let r0: CGFloat = 64, rMax: CGFloat = 152   // dies before the layout box edge (160)
        for offset in [0.0, 0.5] {
            let age = (phase + offset).truncatingRemainder(dividingBy: 1)
            let r = r0 + CGFloat(age) * (rMax - r0)
            let fade = sin(.pi * age) * strength      // 0 → peak → 0 across the beat
            strokeRing(&ctx, c, r, color.opacity(fade), 0.75 + CGFloat(1 - age) * 0.75)
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

    /// Beat envelope: ~1 right on the beat, falling toward 0 in between. The onset is a
    /// short smoothed rise rather than an instantaneous jump, so the pulse breathes in
    /// before it decays — organic instead of clicky.
    private func beat(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        let phase = (t * bpm / 60).truncatingRemainder(dividingBy: 1)
        let attack = 0.06
        if phase < attack {
            let f = phase / attack
            return f * f * (3 - 2 * f)    // smoothstep up to the peak
        }
        return exp(-(phase - attack) / (1 - attack) * 5.5)
    }

    /// Where we are within the current beat: 0 at the onset, climbing toward 1 just before
    /// the next. One full turn per beat, locked to the real tempo. Drives the sweep comet.
    private func phase(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        return (t * bpm / 60).truncatingRemainder(dividingBy: 1)
    }

    /// Beats in one bar. The app assumes common time (4/4), so the paused motions complete
    /// one gesture every four beats.
    private let beatsPerBar = 4.0

    /// Where we are within the current 4/4 bar: 0 at the downbeat, climbing toward 1 just
    /// before the next. One full turn per bar — four times slower than `phase` — so the orbit
    /// dot and the ripples read as one calm gesture per bar instead of a flicker per beat.
    private func barPhase(bpm: Double, at t: TimeInterval) -> Double {
        guard bpm > 0 else { return 0 }
        return (t * bpm / 60 / beatsPerBar).truncatingRemainder(dividingBy: 1)
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
