import SwiftUI
import UIKit

/// A small WCAG-style contrast helper, so the theme system *measures* readability
/// instead of guessing it. Given a palette's background mesh, it works out the text
/// colour and the legibility veil that together clear a target contrast ratio — on
/// every theme, automatically.
enum ThemeContrast {
    /// The two text colours we ever pick between.
    static let lightInk = Color.white
    static let darkInk = Color(red: 0.08, green: 0.08, blue: 0.11)

    /// Contrast ratio we insist on for primary text (WCAG AAA ≈ 7:1).
    private static let target = 7.0
    /// A starting veil strength so each theme keeps its intended mood even when the
    /// contrast maths alone wouldn't ask for one.
    private static let baselineVeil = 0.22
    /// Never let the veil swallow the gradient completely.
    private static let maxVeil = 0.6

    /// Everything the UI needs to paint text legibly over one background mesh.
    struct Plan {
        let ink: Color          // best text colour over the gradient
        let veil: Color         // black/white wash that guarantees the target contrast
        let prefersDarkUI: Bool // drives `preferredColorScheme`
    }

    /// Analyse a nine-colour mesh and decide ink + veil.
    static func plan(for mesh: [Color]) -> Plan {
        let lums = mesh.map(luminance)
        let brightest = lums.max() ?? 0
        let darkest = lums.min() ?? 0

        // Would white or near-black text read better at the gradient's *worst* spot?
        // (White fails on bright areas; dark fails on dark areas.)
        let whiteWorst = ratio(1.0, brightest)
        let darkWorst = ratio(darkest, luminance(darkInk))
        let inkIsLight = whiteWorst >= darkWorst

        // How strong must the veil be to drag that worst spot up to the target?
        let needed: Double
        if inkIsLight {
            // Black veil darkens the bright spot toward the text.
            let cap = max(0, 1.05 / target - 0.05)          // bg luminance we must reach
            needed = brightest > 0 ? 1 - cap / brightest : 0
        } else {
            // White veil lightens the dark spot toward the text.
            let floor = target * (luminance(darkInk) + 0.05) - 0.05
            needed = darkest < 1 ? (floor - darkest) / (1 - darkest) : 0
        }
        let alpha = min(maxVeil, max(baselineVeil, needed))

        return Plan(
            ink: inkIsLight ? lightInk : darkInk,
            veil: (inkIsLight ? Color.black : Color.white).opacity(alpha),
            prefersDarkUI: inkIsLight
        )
    }

    /// The text colour — white or near-black — that reads best directly on `background`.
    /// Use for solid colour chips where the surface colour is known exactly.
    static func ink(on background: Color) -> Color {
        let bg = luminance(background)
        return ratio(1.0, bg) >= ratio(bg, luminance(darkInk)) ? lightInk : darkInk
    }

    // MARK: - WCAG maths

    /// WCAG relative luminance (0 = black … 1 = white) of a colour in sRGB.
    static func luminance(_ color: Color) -> Double {
        func linear(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Non-RGB colour (pattern/dynamic): fall back to its grayscale brightness rather
            // than silently reading 0 and mis-picking ink. Harmless for today's sRGB meshes.
            var white: CGFloat = 0
            ui.getWhite(&white, alpha: &a)
            return linear(white)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// Contrast ratio between two luminances (order doesn't matter).
    private static func ratio(_ a: Double, _ b: Double) -> Double {
        let hi = max(a, b), lo = min(a, b)
        return (hi + 0.05) / (lo + 0.05)
    }
}
