import UIKit

/// Small wrapper around the system haptic generators.
///
/// We keep the generators "primed" with `prepare()` so the buzz fires with no
/// delay even during a fast swipe. Haptics only play on a real device — on the
/// Simulator these calls simply do nothing (which is safe).
final class HapticsEngine {

    private let selection = UISelectionFeedbackGenerator()
    private let impact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    /// Warm up the haptic hardware. Call once when the view appears.
    func prepare() {
        selection.prepare()
        impact.prepare()
        notification.prepare()
    }

    /// Light tick — played each time the BPM crosses a whole number while swiping.
    func tick() {
        selection.selectionChanged()
        selection.prepare()        // re-prime for the next tick
    }

    /// Firmer thud — played for the half/double toggle tap.
    func toggle() {
        impact.impactOccurred()
        impact.prepare()
    }

    /// Celebratory pattern — played when a shake lands on a new theme.
    func shuffle() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
}
