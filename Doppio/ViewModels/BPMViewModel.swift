import Foundation
import Observation

/// Holds the BPM the DJ dials in and works out the half-time / double-time value.
///
/// Marked `@Observable` so any SwiftUI view that reads its properties redraws
/// automatically when they change (the modern replacement for `ObservableObject`).
@Observable
final class BPMViewModel {

    // MARK: Stored state

    /// The BPM you dial in by swiping. Fractional values are allowed (0.1 steps).
    var bpm: Double {
        didSet { persist() }
    }

    /// `false` → screen shows HALF of `bpm`. `true` → screen shows DOUBLE.
    /// A single tap flips this — handy at the drop.
    var isDoubling: Bool {
        didSet { persist() }
    }

    // MARK: Limits

    let minBPM: Double = 20
    let maxBPM: Double = 300

    // MARK: Persistence keys

    private let bpmKey = "doppio.bpm"
    private let modeKey = "doppio.isDoubling"

    init() {
        let defaults = UserDefaults.standard
        let saved = defaults.double(forKey: bpmKey)   // returns 0 if nothing saved yet
        bpm = saved > 0 ? saved : 128                  // 128 is a sensible default
        isDoubling = defaults.bool(forKey: modeKey)    // false if nothing saved yet
    }

    // MARK: Derived values

    /// The number shown big on screen.
    var result: Double { isDoubling ? bpm * 2 : bpm / 2 }

    /// Label describing what `result` represents right now.
    var modeLabel: String { isDoubling ? "DOUBLE" : "HALF" }

    // MARK: Actions

    /// Set the BPM, clamped to the allowed range and rounded to one decimal place.
    func setBPM(_ value: Double) {
        let clamped = min(max(value, minBPM), maxBPM)
        let rounded = (clamped * 10).rounded() / 10
        guard rounded != bpm else { return }   // skip redundant notify + persist during in-step finger jitter
        bpm = rounded
    }

    /// Flip between half-time and double-time.
    func toggleMode() { isDoubling.toggle() }

    // MARK: Private

    /// `didSet` calls this on every change so the latest BPM/mode survive a relaunch.
    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(bpm, forKey: bpmKey)
        defaults.set(isDoubling, forKey: modeKey)
    }
}
