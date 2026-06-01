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

    /// Points of vertical drag that equal 1 BPM. Lower = more sensitive.
    private let pointsPerBPM: CGFloat = 7

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 28) {
                Spacer()
                inputReadout
                outputReadout
                Spacer()
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
        }
        .preferredColorScheme(.dark)
        .onAppear { haptics.prepare() }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.06, blue: 0.10), .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var inputReadout: some View {
        VStack(spacing: 4) {
            Text("YOUR BPM")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
            Text(Self.format(vm.bpm))
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var outputReadout: some View {
        VStack(spacing: 8) {
            Text(vm.modeLabel)
                .font(.headline.weight(.heavy))
                .tracking(4)
                .foregroundStyle(accent)

            Text(Self.format(vm.result))
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: vm.result))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private var hint: some View {
        Text("Swipe ↕ to set BPM   ·   Tap to flip")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
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
