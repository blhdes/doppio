import SwiftUI

struct ContentView: View {

    @State private var vm = BPMViewModel()
    @State private var haptics = HapticsEngine()

    /// BPM captured when a swipe starts, so dragging is relative to it.
    @State private var bpmAtDragStart: Double?
    /// Vertical position where the swipe started (removes the initial jump).
    @State private var dragStartY: CGFloat = 0
    /// Last whole BPM we played a haptic tick for.
    @State private var lastTickedBPM = 0
    /// True while a swipe is in progress — reveals the vertical BPM scale.
    @State private var isDragging = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Points of vertical drag that equal 1 BPM. Lower = more sensitive.
    private let pointsPerBPM: CGFloat = 7

    var body: some View {
        ZStack {
            TempoMeshBackground(isDoubling: vm.isDoubling, reduceMotion: reduceMotion)

            VStack(spacing: 24) {
                Spacer(minLength: 0)
                modePill
                PulseOrb(
                    resultBPM: vm.result,
                    sourceBPM: vm.bpm,
                    displayText: Self.format(vm.result),
                    accent: accent,
                    reduceMotion: reduceMotion
                )
                sourceLine
                Spacer(minLength: 0)
                hint
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())          // whole screen reacts to touch
            .gesture(swipeGesture)
            .onTapGesture {
                withAnimation(.snappy) { vm.toggleMode() }
                haptics.toggle()
            }

            swipeScale
                .opacity(isDragging ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: isDragging)
                .allowsHitTesting(false)        // purely visual — never blocks the swipe
        }
        .preferredColorScheme(.dark)
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
        .foregroundStyle(accent)
        .contentTransition(.opacity)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .glassSurface(in: Capsule(), tint: accent)
        .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))
    }

    /// The tempo you dialled in — the "from X BPM" half of the relationship.
    private var sourceLine: some View {
        HStack(spacing: 6) {
            Text("from")
                .foregroundStyle(.secondary)
            Text(Self.format(vm.bpm))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
                .contentTransition(.numericText(value: vm.bpm))
            Text("BPM")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 18, weight: .medium, design: .rounded))
    }

    private var hint: some View {
        Text("Swipe ↕ to set BPM   ·   Tap to flip")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
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
                ctx.stroke(tick, with: .color(.white.opacity(major ? 0.35 : 0.18)),
                           lineWidth: major ? 1.5 : 1)
            }
            // bottom = min BPM, top = max BPM (matches "swipe up = faster").
            let markerY = size.height * (1 - frac)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: markerY))
            line.addLine(to: CGPoint(x: size.width, y: markerY))
            ctx.stroke(line, with: .color(accent), lineWidth: 2)
            ctx.fill(Circle().path(in: CGRect(x: -5, y: markerY - 5, width: 10, height: 10)),
                     with: .color(accent))
        }
        .frame(width: 46)
        .frame(maxWidth: .infinity, maxHeight: 320, alignment: .trailing)
        .padding(.trailing, 10)
    }

    private var accent: Color { vm.isDoubling ? .orange : .cyan }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if bpmAtDragStart == nil {
                    bpmAtDragStart = vm.bpm
                    dragStartY = value.translation.height
                    lastTickedBPM = Int(vm.bpm)
                    isDragging = true
                }
                let base = bpmAtDragStart ?? vm.bpm
                // Dragging up (negative height) raises the BPM.
                let delta = Double(-(value.translation.height - dragStartY) / pointsPerBPM)
                vm.setBPM(base + delta)

                // Fire a haptic "detent" each time we cross a whole BPM.
                let nowWhole = Int(vm.bpm)
                if nowWhole != lastTickedBPM {
                    lastTickedBPM = nowWhole
                    haptics.tick()
                }
            }
            .onEnded { _ in
                bpmAtDragStart = nil
                isDragging = false
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
