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
    /// that actually moves, which becomes the steering finger for the whole gesture.
    @State private var landingY: [SpatialEventCollection.Event.ID: CGFloat] = [:]
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Points of vertical drag that equal 1 BPM in normal mode. Lower = more sensitive.
    private let coarsePointsPerBPM: CGFloat = 7
    /// Fine mode: ~10× more drag per BPM, so a small move nudges just a decimal.
    private let finePointsPerBPM: CGFloat = 70
    /// Movement needed before a touch counts as a swipe — keeps tap-to-flip alive.
    private let dragDeadZone: CGFloat = 8

    var body: some View {
        ZStack {
            TempoMeshBackground(theme: theme, isDoubling: vm.isDoubling, reduceMotion: reduceMotion)

            VStack(spacing: 24) {
                Spacer(minLength: 0)
                modePill
                PulseOrb(
                    resultBPM: vm.result,
                    sourceBPM: vm.bpm,
                    displayText: Self.format(vm.result),
                    accent: accent,
                    ink: ink,
                    reduceMotion: reduceMotion
                )
                sourceLine
                Spacer(minLength: 0)
                hint
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())          // whole screen reacts to touch
            .gesture(adjustGesture)             // one gesture handles swipe, fine-tune, and tap

            swipeScale
                .opacity(isDragging ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: isDragging)
                .allowsHitTesting(false)        // purely visual — never blocks the swipe
        }
        .preferredColorScheme(palette.prefersDarkUI ? .dark : .light)
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
    private var sourceLine: some View {
        HStack(spacing: 6) {
            Text("from")
                .foregroundStyle(ink.opacity(0.6))
            Text(Self.format(vm.bpm))
                .monospacedDigit()
                .foregroundStyle(ink.opacity(0.9))
                .contentTransition(.numericText(value: vm.bpm))
            Text("BPM")
                .foregroundStyle(ink.opacity(0.6))
        }
        .font(.system(size: 18, weight: .medium, design: .rounded))
    }

    private var hint: some View {
        VStack(spacing: 4) {
            // Both messages always occupy their space; fine mode just cross-fades between
            // them (opacity, not insert/remove) so the bottom text never shifts the layout.
            ZStack {
                VStack(spacing: 4) {
                    Text("Swipe ↕ to set BPM   ·   Tap to flip")
                    Text("Hold a 2nd finger to fine-tune (0.1)")
                }
                .opacity(isFineMode ? 0 : 1)

                Text("FINE  ·  0.1 BPM steps")
                    .font(.footnote.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(accent)   // pops so you know slow mode is on
                    .opacity(isFineMode ? 1 : 0)
            }

            Text("Shake to change the theme   ·   \(theme.name)")
                .contentTransition(.opacity)   // the name fades as you shake to a new one
        }
        .font(.footnote)
        .foregroundStyle(ink.opacity(0.6))
        .padding(.bottom, 8)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isFineMode)
    }

    /// A faint vertical tick scale showing where the current BPM sits in the
    /// 20–300 range, with an accent marker. Only visible mid-swipe.
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
        .frame(width: 46)
        .frame(maxWidth: .infinity, maxHeight: 320, alignment: .trailing)
        .padding(.trailing, 10)
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
        if landingY.contains(where: { byID[$0.key] == nil }) {
            landingY = landingY.filter { byID[$0.key] != nil }
        }
        for event in active where landingY[event.id] == nil { landingY[event.id] = event.location.y }
        guard !active.isEmpty else { return }
        if active.count > maxTouches { maxTouches = active.count }

        // A second finger anywhere means fine mode — it only slows the swipe, never steers.
        let fine = active.count >= 2

        // If the steering finger lifted, release the lock and re-measure movement from where
        // the remaining fingers are *now*. That way the next finger you move takes over —
        // even while another finger keeps holding — instead of getting stuck on the held one.
        if let steering = anchorID, byID[steering] == nil {
            anchorID = nil
            for event in active { landingY[event.id] = event.location.y }
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
        abs(event.location.y - (landingY[event.id] ?? event.location.y)) >= dragDeadZone
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
        landingY.removeAll()
        anchorID = nil
        isDragging = false
        isFineMode = false
        maxTouches = 0
    }

    /// Which "notch" a BPM sits on: whole numbers normally, tenths in fine mode.
    private func tickIndex(_ bpm: Double, fine: Bool) -> Int {
        fine ? Int((bpm * 10).rounded()) : Int(bpm.rounded())
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
