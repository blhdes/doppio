import SwiftUI
import UIKit

/// Reports the system **shake** gesture to SwiftUI.
///
/// This listens for UIKit's built-in motion event (the same one iOS uses for
/// "shake to undo"), which the OS only fires for a deliberate shake — a gentle
/// bump, or the phone riding in a pocket, won't trigger it. That makes it far less
/// twitchy than reading the raw accelerometer ourselves.
///
/// Drop it behind your content: `.background(ShakeDetector { ... })`.
struct ShakeDetector: UIViewRepresentable {
    /// Called once per shake.
    let onShake: () -> Void

    func makeUIView(context: Context) -> ShakeSensingView {
        let view = ShakeSensingView()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ view: ShakeSensingView, context: Context) {
        view.onShake = onShake
    }
}

/// A tiny invisible view that makes itself first responder so it receives motion
/// events from the responder chain. (We have no text fields, so nothing ever steals
/// first-responder status back from it.)
final class ShakeSensingView: UIView {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Claim first-responder status once we're actually on screen.
        if window != nil { becomeFirstResponder() }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        onShake?()
    }
}
