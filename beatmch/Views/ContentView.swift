import SwiftUI

struct ContentView: View {

    @State private var vm = BPMViewModel()
    @State private var haptics = HapticsEngine()

    /// The active visual theme — restored from the last shake, or Midnight on a
    /// fresh install. A shake swaps it for a random different one.
    @State private var theme = Theme.named(UserDefaults.standard.string(forKey: ContentView.themeKey))

    /// Where the last-picked theme id is remembered between launches.
    private static let themeKey = "beatmch.theme"

    // MARK: Drag state
    //
    // We read raw multi-touch through `SpatialEventGesture` (iOS 18+) so a second
    // finger held on screen can switch the swipe into a slow, decimal-precise mode.

    /// Where each finger currently on glass first landed — used to spot the first one
    /// that actually moves (the steering finger), and to tell a drag that began on the
    /// pitch bar from one that began anywhere else.
    @State private var landing: [SpatialEventCollection.Event.ID: CGPoint] = [:]
    /// The steering finger the BPM math is measured from. Locked once a drag starts.
    @State private var anchorID: SpatialEventCollection.Event.ID?
    /// BPM at the moment we last (re)anchored — dragging is relative to this.
    @State private var bpmAtAnchor: Double = 0
    /// Screen Y at the moment we last (re)anchored — removes any jump.
    @State private var anchorY: CGFloat = 0
    /// Last detent index we played a haptic tick for (whole BPM, or 0.1 in fine mode).
    @State private var lastTick = 0
    /// Most fingers seen at once this gesture — lets us tell a 1-finger tap from a hold.
    @State private var maxTouches = 0
    /// True once a swipe clears the dead zone — reveals the vertical BPM scale.
    @State private var isDragging = false
    /// True while a second finger is held — the swipe moves ~10× slower.
    @State private var isFineMode = false
    /// True while the active drag began on the right pitch bar — the BPM then follows the
    /// finger's position directly instead of using the relative swipe maths.
    @State private var isBarDrag = false
    /// Size of the gesture surface, captured live so we can locate the pitch bar in the
    /// same coordinates the touches arrive in.
    @State private var containerSize: CGSize = .zero

    // MARK: Hint visibility
    //
    // The bottom hint is a first-run teacher, not permanent chrome. It fades out the
    // instant you touch the screen so nothing competes with the number while you work,
    // then drifts back only after the screen has sat quiet for a while.

    /// Whether the bottom hint is currently shown.
    @State private var showHint = true
    /// Pending "bring the hint back" job — cancelled and restarted on every interaction.
    @State private var hintReveal: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Points of vertical drag that equal 1 BPM in normal mode. Lower = more sensitive.
    private let coarsePointsPerBPM: CGFloat = 7
    /// Fine mode: ~10× more drag per BPM, so a small move nudges just a decimal.
    private let finePointsPerBPM: CGFloat = 70
    /// Movement needed before a touch counts as a swipe — keeps tap-to-flip alive.
    private let dragDeadZone: CGFloat = 8
    /// How long the screen must stay untouched before the hint drifts back in.
    private let hintIdleDelay: Duration = .seconds(45)
    /// Geometry of the right-edge pitch bar — shared by the drawing and the hit test so a
    /// drag that starts on the bar maps onto exactly the marks you see.
    private let scaleWidth: CGFloat = 46
    private let scaleHeight: CGFloat = 320
    private let scaleTrailingPad: CGFloat = 10

    var body: some View {
        ZStack {
            TempoMeshBackground(theme: theme, isDoubling: vm.isDoubling, reduceMotion: reduceMotion)
                .equatable()   // BPM drags don't change it — skip re-layout so it never resizes mid-swipe

            VStack(spacing: 24) {
                Spacer(minLength: 0)
                modePill
                    .frame(height: 76)   // match the "from" row's band so the orb sits dead-centre between them
                PulseOrb(
                    resultBPM: vm.result,
                    sourceBPM: vm.bpm,
                    displayText: Self.format(vm.result),
                    accent: accent,
                    ink: ink,
                    reduceMotion: reduceMotion,
                    isAdjusting: isDragging
                )
                sourceLine
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { containerSize = $0 })
            .contentShape(Rectangle())          // whole screen reacts to touch
            .gesture(adjustGesture)             // one gesture handles swipe, drag-the-bar, fine-tune, and tap

            swipeScale
                .opacity(isDragging ? 1 : 0.22)   // a faint live readout at rest; a grab target you can drag
                .animation(.easeOut(duration: 0.25), value: isDragging)
                .allowsHitTesting(false)          // the shared gesture reads it; this layer never blocks touch
        }
        .overlay(alignment: .bottom) {
            // The hint floats over the bottom rather than sitting in the VStack flow — so when
            // it's faded out it reserves no space, and the orb cluster stays truly centred.
            hint
                .padding(.horizontal)
                .allowsHitTesting(false)   // never blocks a swipe that starts near the bottom
        }
        .preferredColorScheme(palette.prefersDarkUI ? .dark : .light)
        .statusBarHidden(true)          // zero distractions — no clock, no battery
        .background(ShakeDetector(onShake: shuffleTheme))
        .onAppear { haptics.prepare() }
    }

    // MARK: - Subviews

    /// The mode indicator — also the visible cue for the tap-to-flip gesture.
    private var modePill: some View {
        HStack(spacing: 8) {
            Text(vm.modeLabel)
                .font(.headline.weight(.heavy))
                .tracking(4)
            Text(vm.isDoubling ? "×2" : "×½")
                .font(.headline.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(ink)   // ink, not accent, so the label always contrasts the chip
        .contentTransition(.opacity)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .glassSurface(in: Capsule())   // neutral glass tracks the background; accent stays the outline
        .overlay(Capsule().strokeBorder(accent.opacity(0.5), lineWidth: 1))
    }

    /// The tempo you dialled in — the "from X BPM" half of the relationship.
    ///
    /// At rest the number stays small so the *result* up top is the hero. The moment
    /// you start swiping it swells, tints to the accent, and lifts onto a faint glass
    /// capsule so the value you're setting is easy to read mid-drag; then it settles back
    /// down when you let go. The row keeps a constant, generous height so the swelling
    /// number grows in place — and `zIndex` keeps it above the orb's pulsing rings, which
    /// render beyond their frame and would otherwise clip its top.
    private var sourceLine: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("from")
                .foregroundStyle(ink.opacity(0.6))
            // The number grows from its centre, not the baseline. Two layers cooperate:
            //  • A hidden "000.0" template — sized to the widest value — alone defines the slot.
            //    Its font animates 18↔46 so the row reflows (tight at rest, roomy mid-drag) and
            //    "from"/"BPM" make room. It's the fixed-width slot that keeps content-width changes
            //    (2↔3 digits, the decimal appearing in fine mode) from bumping the labels — and
            //    being hidden, the baseline-anchored way an animated font grows is never seen.
            //  • The visible number is drawn once at the large size and *scaled* about its centre,
            //    so it swells symmetrically from the middle and stays crisp (a big glyph scaled
            //    down, never a small one scaled up and blurred). Centred in the slot, its own width
            //    changes spread evenly about the middle, so the digits never bump sideways either.
            Text("000.0")
                .font(.system(size: isDragging ? 46 : 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .hidden()
                .overlay {
                    // Roll the digits only for occasional changes (a tap-flip). While dragging, the
                    // value changes every tick — animating each one stacks into a flashing blur.
                    Text(Self.format(vm.bpm))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isDragging ? accent : ink.opacity(0.9))
                        .fixedSize()
                        .scaleEffect(isDragging ? 1 : 18.0 / 46.0, anchor: .center)
                        .contentTransition(isDragging ? .identity : .numericText(value: vm.bpm))
                }
            Text("BPM")
                .foregroundStyle(ink.opacity(0.6))
        }
        .font(.system(size: 18, weight: .medium, design: .rounded))
        .frame(height: 76)   // generous constant band: no orb shift
        .background {
            // A FIXED-size glass capsule. Its geometry never tracks the number's width, so it
            // can't resize or flash as the value changes each tick mid-drag. Neutral glass + a
            // faint accent outline (the mode-pill recipe) — a *tinted* fill rendered as a solid
            // accent blob on the iOS 26.2 SDK and swallowed the number. Fades via opacity.
            Color.clear
                .frame(width: 260, height: 60)
                .glassSurface(in: Capsule())
                .overlay(Capsule().strokeBorder(accent.opacity(0.5), lineWidth: 1))
                .opacity(isDragging ? 1 : 0)
        }
        .zIndex(1)           // stay above the orb's pulse, which draws past its own frame
        .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: isDragging)
    }

    private var hint: some View {
        VStack(spacing: 6) {
            // Both messages always occupy their space; fine mode just cross-fades between
            // them (opacity, not insert/remove) so the bottom text never shifts the layout.
            ZStack {
                VStack(spacing: 4) {
                    Text("Swipe up or down to set the tempo")
                    Text("Tap to flip ×2 / ×½")
                    Text("Hold a second finger to fine-tune")
                }
                .opacity(isFineMode ? 0 : 1)

                Text("Fine-tuning  ·  0.1 BPM steps")
                    .font(.footnote.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(accent)   // pops so you know slow mode is on
                    .opacity(isFineMode ? 1 : 0)
            }

            Text("Shake to change the theme  ·  \(theme.name)")
                .contentTransition(.opacity)   // the name fades as you shake to a new one
        }
        .font(.footnote)
        .foregroundStyle(ink.opacity(0.6))
        .padding(.bottom, 8)
        .opacity(showHint ? 1 : 0)             // fades away the moment you start playing
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isFineMode)
    }

    /// A vertical tick scale showing where the current BPM sits in the 20–300 range, with an
    /// accent marker. Faint at rest — a live position readout you can also grab and drag —
    /// and full-strength mid-drag.
    private var swipeScale: some View {
        let frac = (vm.bpm - vm.minBPM) / (vm.maxBPM - vm.minBPM)
        return Canvas { ctx, size in
            let steps = 14
            for i in 0...steps {
                let y = size.height * CGFloat(i) / CGFloat(steps)
                let major = i % 7 == 0
                let len: CGFloat = major ? 18 : 9
                var tick = Path()
                tick.move(to: CGPoint(x: size.width - len, y: y))
                tick.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(tick, with: .color(ink.opacity(major ? 0.35 : 0.18)),
                           lineWidth: major ? 1.5 : 1)
            }
            // bottom = min BPM, top = max BPM (matches "swipe up = faster").
            let markerY = size.height * (1 - frac)
            let lineWidth: CGFloat = isFineMode ? 3 : 2   // fine mode reads as bolder
            let dot: CGFloat = isFineMode ? 14 : 10
            var line = Path()
            line.move(to: CGPoint(x: 0, y: markerY))
            line.addLine(to: CGPoint(x: size.width, y: markerY))
            ctx.stroke(line, with: .color(accent), lineWidth: lineWidth)
            ctx.fill(Circle().path(in: CGRect(x: -dot / 2, y: markerY - dot / 2, width: dot, height: dot)),
                     with: .color(accent))
        }
        .frame(width: scaleWidth)
        .frame(maxWidth: .infinity, maxHeight: scaleHeight, alignment: .trailing)
        .padding(.trailing, scaleTrailingPad)
    }

    /// The palette to paint right now — depends on the live HALF/DOUBLE mode.
    private var palette: Palette { theme.palette(isDoubling: vm.isDoubling) }
    private var accent: Color { palette.accent }
    private var ink: Color { palette.ink }

    // MARK: - Theme

    /// Shake handler: jump to a random *different* theme, remember it, and celebrate.
    /// Filtering out the current theme guarantees every shake visibly changes something.
    private func shuffleTheme() {
        let next = Theme.all.filter { $0.id != theme.id }.randomElement() ?? theme
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.6)) {
            theme = next
        }
        UserDefaults.standard.set(next.id, forKey: Self.themeKey)
        haptics.shuffle()
        dismissHint()          // a shake is interaction too — hide, then re-arm the timer
        scheduleHintReveal()
    }

    // MARK: - Hint timing

    /// Hide the hint the instant the user does anything — keeps the screen calm mid-task.
    private func dismissHint() {
        hintReveal?.cancel()
        guard showHint else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { showHint = false }
    }

    /// Bring the hint back, but only after the screen stays untouched for `hintIdleDelay`.
    /// Any new interaction cancels this and starts the wait over.
    private func scheduleHintReveal() {
        hintReveal?.cancel()
        hintReveal = Task { @MainActor in
            do { try await Task.sleep(for: hintIdleDelay) } catch { return }
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.6)) { showHint = true }
        }
    }

    // MARK: - Gesture

    /// One gesture drives the whole BPM dial. It tracks *all* fingers on screen so a
    /// finger held down (anywhere) flips the swipe into slow, decimal-fine mode — the
    /// classic "hold to fine-tune" trick, handy mid-set when you're moving and dancing.
    private var adjustGesture: some Gesture {
        SpatialEventGesture()
            .onChanged { handleTouches($0) }
            .onEnded { _ in endAdjust() }
    }

    /// Called on every touch update with the full set of live fingers.
    private func handleTouches(_ events: SpatialEventCollection) {
        let active = events.filter { $0.phase == .active }
        let byID = Dictionary(active.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        // Remember where each finger landed; forget any that have lifted. Both writes are gated
        // so a steady drag (no finger added or lifted) doesn't reassign @State every tick — with
        // setBPM also guarded, body then re-evaluates only when the BPM moves, not per touch event.
        if landing.contains(where: { byID[$0.key] == nil }) {
            landing = landing.filter { byID[$0.key] != nil }
        }
        for event in active where landing[event.id] == nil { landing[event.id] = event.location }
        guard !active.isEmpty else { return }
        dismissHint()   // any touch means "I'm working" — clear the instructions
        if active.count > maxTouches { maxTouches = active.count }

        // Absolute pitch bar takes priority. A drag that *began* on the right bar moves the BPM
        // straight to the finger — no swipe maths. Everything else keeps the relative swipe.
        if isBarDrag {
            if let driver = anchorID.flatMap({ byID[$0] }) {
                trackBar(driver)
                return
            }
            // The bar finger lifted: drop bar mode and let any remaining finger resume a swipe
            // from where it sits now (re-baseline so it isn't treated as already-moved).
            isBarDrag = false
            anchorID = nil
            for event in active { landing[event.id] = event.location }
        } else if !isDragging, let driver = active.first(where: { landedInBar($0) }) {
            beginBarDrag(driver)
            trackBar(driver)
            return
        }

        // A second finger anywhere means fine mode — it only slows the swipe, never steers.
        let fine = active.count >= 2

        // If the steering finger lifted, release the lock and re-measure movement from where
        // the remaining fingers are *now*. That way the next finger you move takes over —
        // even while another finger keeps holding — instead of getting stuck on the held one.
        if let steering = anchorID, byID[steering] == nil {
            anchorID = nil
            for event in active { landing[event.id] = event.location }
        }

        // Choose the steering finger:
        //  • the locked finger if it's still down (a freshly added still finger can't steal it)
        //  • otherwise the first finger to move past the dead zone takes over
        //  • otherwise nobody's moving yet → bail (a still touch can still flip on release)
        let driver: SpatialEventCollection.Event
        if let locked = anchorID.flatMap({ byID[$0] }) {
            driver = locked
        } else if let mover = active.first(where: { movedPastDeadZone($0) }) {
            driver = mover
        } else {
            return
        }

        // (Re)anchor when the drag first arms, when we cross the fine/coarse line, or when a
        // new finger takes over steering — so the BPM never jumps at those moments.
        if !isDragging || driver.id != anchorID || fine != isFineMode {
            isDragging = true
            reanchor(to: driver, fine: fine)
        }

        // Swiping up (smaller Y) raises the BPM. Fine mode just needs more travel per BPM.
        let pointsPerBPM = fine ? finePointsPerBPM : coarsePointsPerBPM
        vm.setBPM(bpmAtAnchor + Double(-(driver.location.y - anchorY) / pointsPerBPM))

        // Haptic "detent" on every whole BPM — or every 0.1 BPM while fine-tuning.
        let tick = tickIndex(vm.bpm, fine: fine)
        if tick != lastTick {
            lastTick = tick
            haptics.tick()
        }
    }

    /// Has this finger moved far enough from where it landed to count as a swipe?
    private func movedPastDeadZone(_ event: SpatialEventCollection.Event) -> Bool {
        abs(event.location.y - (landing[event.id] ?? event.location).y) >= dragDeadZone
    }

    /// Pin the BPM math to the steering finger's current spot, with no value jump.
    private func reanchor(to driver: SpatialEventCollection.Event, fine: Bool) {
        anchorID = driver.id
        anchorY = driver.location.y
        bpmAtAnchor = vm.bpm
        isFineMode = fine
        lastTick = tickIndex(vm.bpm, fine: fine)
    }

    /// All fingers lifted. A still single-finger touch (never a real swipe) flips the mode.
    private func endAdjust() {
        if !isDragging && maxTouches == 1 {
            withAnimation(.snappy) { vm.toggleMode() }
            haptics.toggle()
        }
        landing.removeAll()
        anchorID = nil
        isDragging = false
        isFineMode = false
        isBarDrag = false
        maxTouches = 0
        scheduleHintReveal()   // start the quiet-time countdown that brings the hint back
    }

    /// Which "notch" a BPM sits on: whole numbers normally, tenths in fine mode.
    private func tickIndex(_ bpm: Double, fine: Bool) -> Int {
        fine ? Int((bpm * 10).rounded()) : Int(bpm.rounded())
    }

    // MARK: - Pitch bar (absolute)

    /// Did this finger land inside the right-edge pitch bar? Only a drag that *starts* there
    /// switches to direct, follow-the-finger control; everything else stays a relative swipe.
    private func landedInBar(_ event: SpatialEventCollection.Event) -> Bool {
        guard containerSize.width > 0 else { return false }
        let p = landing[event.id] ?? event.location
        let barHeight = min(containerSize.height, scaleHeight)
        let topY = (containerSize.height - barHeight) / 2
        let left = containerSize.width - (scaleWidth + scaleTrailingPad)
        return p.x >= left && p.y >= topY && p.y <= topY + barHeight
    }

    /// Map a finger's Y on the bar straight to a BPM: top of the bar = max, bottom = min —
    /// the same mapping the visible marker uses, so the mark sits under your fingertip.
    private func bpmForBarY(_ y: CGFloat) -> Double {
        let barHeight = min(containerSize.height, scaleHeight)
        guard barHeight > 0 else { return vm.bpm }
        let topY = (containerSize.height - barHeight) / 2
        let frac = min(max(1 - (y - topY) / barHeight, 0), 1)
        return vm.minBPM + frac * (vm.maxBPM - vm.minBPM)
    }

    /// Lock this finger as an absolute bar drag (always coarse — direct control, never fine).
    private func beginBarDrag(_ driver: SpatialEventCollection.Event) {
        isDragging = true
        isBarDrag = true
        isFineMode = false
        anchorID = driver.id
        lastTick = tickIndex(vm.bpm, fine: false)
    }

    /// Move the BPM to wherever the bar finger sits now, ticking once per whole BPM crossed.
    private func trackBar(_ driver: SpatialEventCollection.Event) {
        vm.setBPM(bpmForBarY(driver.location.y))
        let tick = tickIndex(vm.bpm, fine: false)
        if tick != lastTick {
            lastTick = tick
            haptics.tick()
        }
    }

    // MARK: - Helpers

    /// Whole numbers show with no decimals; fractional BPMs show one decimal.
    static func format(_ value: Double) -> String {
        value.rounded() == value
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

#Preview {
    ContentView()
}
