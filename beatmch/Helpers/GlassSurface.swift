import SwiftUI

extension View {
    /// Liquid Glass on iOS 26+, with an `.ultraThinMaterial` fallback on iOS 18–25.
    /// Centralises the OS gating so every call site stays a one-liner.
    @ViewBuilder
    func glassSurface<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            modifier(GlassSurfaceModifier(shape: shape, tint: tint))
        } else {
            background {
                shape.fill(.ultraThinMaterial)
                    .overlay(shape.fill(tint?.opacity(0.18) ?? .clear))
            }
        }
    }
}

@available(iOS 26.0, *)
private struct GlassSurfaceModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?

    func body(content: Content) -> some View {
        var effect: Glass = .regular
        if let tint { effect = effect.tint(tint) }
        return content.glassEffect(effect, in: shape)
    }
}
