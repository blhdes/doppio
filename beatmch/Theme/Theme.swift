import SwiftUI

/// One "mood" within a theme — everything the UI needs to paint a single tempo state.
///
/// You only ever supply two things: the `accent` highlight colour (rings, pill outline,
/// swipe marker) and the nine `mesh` colours behind everything. The readability bits —
/// `ink` (text colour), `veil` (legibility wash) and `prefersDarkUI` — are *measured*
/// from the mesh by `ThemeContrast`, so every theme stays readable without hand-tuning.
struct Palette: Equatable {
    /// The highlight colour for rings, pill outline and swipe marker.
    let accent: Color

    /// Exactly nine colours for the 3×3 mesh. Anything other than nine won't render.
    let mesh: [Color]

    /// Primary text/marks colour, chosen to contrast the mesh (white or near-black).
    let ink: Color

    /// A translucent wash over the mesh that guarantees the text clears its contrast target.
    let veil: Color

    /// Whether this palette wants a dark system appearance (drives `preferredColorScheme`).
    let prefersDarkUI: Bool

    init(accent: Color, mesh: [Color]) {
        assert(mesh.count == 9, "A Palette mesh needs exactly 9 colours for the 3×3 MeshGradient; got \(mesh.count).")
        self.accent = accent
        self.mesh = mesh
        let plan = ThemeContrast.plan(for: mesh)
        self.ink = plan.ink
        self.veil = plan.veil
        self.prefersDarkUI = plan.prefersDarkUI
    }
}

extension Palette {
    /// Build a 3×3 mesh that **sweeps diagonally across three colours** instead of dimming
    /// one. `a` anchors the top-left corner, `c` the bottom-right, and `b` rides the centre
    /// diagonal between them; the two halfway blends fill the rest. The result is a gradient
    /// that actually *travels* corner-to-corner through real hues (indigo → blue → teal),
    /// rather than the same one-hue vignette every theme used to share.
    ///
    /// Blends are taken in `.device` (plain sRGB) space so the midpoints stay in-gamut and
    /// land exactly where `ThemeContrast`'s sRGB luminance maths expects them.
    static func sweep(_ a: Color, _ b: Color, _ c: Color) -> [Color] {
        let ab = a.mix(with: b, by: 0.5, in: .device)
        let bc = b.mix(with: c, by: 0.5, in: .device)
        return [a,  ab, b,
                ab, b,  bc,
                b,  bc, c]
    }
}

/// One complete visual identity for the app.
///
/// Every theme carries **two** palettes — one for HALF mode, one for DOUBLE. What the
/// ×2 / ×½ flip *does* to the colour is chosen per theme on purpose (a warm↔cool shift,
/// a brightness lift, or a hostile hue clash) and noted in each theme's comment, so the
/// flip always means something deliberate. Switching themes means picking a different
/// `Theme`; flipping tempo means picking a different `Palette` within the current one.
struct Theme: Identifiable, Equatable {
    /// Stable, lowercase key — handy for persistence and `ForEach` in a future picker.
    let id: String
    /// Human-facing name shown in the picker.
    let name: String
    /// The look while the app shows HALF of the dialled-in BPM.
    let half: Palette
    /// The look while the app shows DOUBLE.
    let double: Palette

    /// The palette to paint right now, given the live tempo mode.
    func palette(isDoubling: Bool) -> Palette {
        isDoubling ? double : half
    }

    /// Whether this theme reads as dark overall — drives the 50/50 dark↔light split when
    /// shuffling. Both palettes share a lightness, so the HALF palette decides it.
    var isDark: Bool { half.prefersDarkUI }
}

extension Theme {
    /// The theme with this `id`, or Midnight if the id is unknown or `nil`.
    /// Used to restore the last-picked theme from storage on launch.
    static func named(_ id: String?) -> Theme {
        all.first { $0.id == id } ?? midnight
    }
}

extension Theme {
    /// Every built-in theme, in display order — a journey from deep-dark to bright-light.
    /// A curated set: one strong identity per lane, no near-duplicates. Adding another is
    /// literally appending one more entry here.
    static let all: [Theme] = [
        midnight, voltage, toxic, ocean, aurora, forest,
        crimson, ember, mono,
        paper, daylight, bubblegum
    ]

    // MARK: Dark — cool & electric

    /// The app's original identity. FLIP: warm↔cool — cool sapphire night that travels
    /// indigo → blue → teal in HALF, swapping to a warm amber ember-bed in DOUBLE.
    static let midnight = Theme(
        id: "midnight",
        name: "Midnight",
        half: Palette(
            accent: Color(red: 0.18, green: 0.62, blue: 0.85),
            mesh: Palette.sweep(
                Color(red: 0.04, green: 0.03, blue: 0.12),
                Color(red: 0.02, green: 0.06, blue: 0.15),
                Color(red: 0.02, green: 0.11, blue: 0.15)
            )
        ),
        double: Palette(
            accent: Color(red: 0.95, green: 0.62, blue: 0.20),
            mesh: Palette.sweep(
                Color(red: 0.10, green: 0.05, blue: 0.04),
                Color(red: 0.14, green: 0.08, blue: 0.03),
                Color(red: 0.17, green: 0.10, blue: 0.03)
            )
        )
    )

    /// FLIP: hue clash — deep sapphire blue against a jewel-peridot acid lime. The two
    /// sides are meant to *fight*, a hard energetic snap rather than a gentle shift.
    static let voltage = Theme(
        id: "voltage",
        name: "Voltage",
        half: Palette(
            accent: Color(red: 0.22, green: 0.45, blue: 0.98),
            mesh: Palette.sweep(
                Color(red: 0.03, green: 0.06, blue: 0.20),
                Color(red: 0.02, green: 0.09, blue: 0.30),
                Color(red: 0.05, green: 0.06, blue: 0.24)
            )
        ),
        double: Palette(
            accent: Color(red: 0.80, green: 0.92, blue: 0.12),
            mesh: Palette.sweep(
                Color(red: 0.10, green: 0.14, blue: 0.02),
                Color(red: 0.15, green: 0.21, blue: 0.03),
                Color(red: 0.09, green: 0.17, blue: 0.02)
            )
        )
    )

    /// FLIP: hue clash — a jewel-emerald poison glow that snaps to deep amethyst violet.
    /// Two near-opposite hues with nothing soft between them; the loudest cool theme.
    static let toxic = Theme(
        id: "toxic",
        name: "Toxic",
        half: Palette(
            accent: Color(red: 0.20, green: 0.85, blue: 0.42),
            mesh: Palette.sweep(
                Color(red: 0.03, green: 0.14, blue: 0.06),
                Color(red: 0.04, green: 0.23, blue: 0.10),
                Color(red: 0.05, green: 0.18, blue: 0.13)
            )
        ),
        double: Palette(
            accent: Color(red: 0.70, green: 0.30, blue: 0.96),
            mesh: Palette.sweep(
                Color(red: 0.12, green: 0.03, blue: 0.18),
                Color(red: 0.18, green: 0.04, blue: 0.27),
                Color(red: 0.14, green: 0.03, blue: 0.22)
            )
        )
    )

    /// The abyss. FLIP: brightness lift — the same blue→teal water travels navy → blue →
    /// teal, then DOUBLE simply charges it brighter toward aqua. Same hue, more energy.
    static let ocean = Theme(
        id: "ocean",
        name: "Ocean",
        half: Palette(
            accent: Color(red: 0.16, green: 0.68, blue: 0.82),
            mesh: Palette.sweep(
                Color(red: 0.02, green: 0.06, blue: 0.14),
                Color(red: 0.03, green: 0.11, blue: 0.22),
                Color(red: 0.02, green: 0.15, blue: 0.20)
            )
        ),
        double: Palette(
            accent: Color(red: 0.26, green: 0.88, blue: 0.84),
            mesh: Palette.sweep(
                Color(red: 0.02, green: 0.11, blue: 0.18),
                Color(red: 0.03, green: 0.18, blue: 0.27),
                Color(red: 0.03, green: 0.23, blue: 0.28)
            )
        )
    )

    /// Northern lights. FLIP: hue shift — a jade-green curtain that travels green → teal →
    /// blue, swapping to an indigo→violet sky. The hue travel *is* the identity here.
    static let aurora = Theme(
        id: "aurora",
        name: "Aurora",
        half: Palette(
            accent: Color(red: 0.35, green: 0.90, blue: 0.62),
            mesh: Palette.sweep(
                Color(red: 0.01, green: 0.10, blue: 0.07),
                Color(red: 0.02, green: 0.14, blue: 0.13),
                Color(red: 0.02, green: 0.10, blue: 0.17)
            )
        ),
        double: Palette(
            accent: Color(red: 0.66, green: 0.45, blue: 0.98),
            mesh: Palette.sweep(
                Color(red: 0.06, green: 0.04, blue: 0.16),
                Color(red: 0.09, green: 0.05, blue: 0.22),
                Color(red: 0.12, green: 0.05, blue: 0.21)
            )
        )
    )

    /// Deep woods. FLIP: brightness lift — a pine→moss canopy that charges brighter toward
    /// a sunlit emerald-lime in DOUBLE. Same green family, more light coming through.
    static let forest = Theme(
        id: "forest",
        name: "Forest",
        half: Palette(
            accent: Color(red: 0.30, green: 0.80, blue: 0.42),
            mesh: Palette.sweep(
                Color(red: 0.02, green: 0.08, blue: 0.04),
                Color(red: 0.03, green: 0.12, blue: 0.06),
                Color(red: 0.02, green: 0.12, blue: 0.09)
            )
        ),
        double: Palette(
            accent: Color(red: 0.58, green: 0.85, blue: 0.25),
            mesh: Palette.sweep(
                Color(red: 0.05, green: 0.12, blue: 0.04),
                Color(red: 0.08, green: 0.17, blue: 0.05),
                Color(red: 0.11, green: 0.18, blue: 0.05)
            )
        )
    )

    // MARK: Dark — warm

    /// Blood & jewel. FLIP: brightness lift — a deep garnet bed that simply burns brighter
    /// into a bright ruby-scarlet on DOUBLE. One committed red mood, charged up.
    static let crimson = Theme(
        id: "crimson",
        name: "Crimson",
        half: Palette(
            accent: Color(red: 0.85, green: 0.18, blue: 0.30),
            mesh: Palette.sweep(
                Color(red: 0.16, green: 0.02, blue: 0.06),
                Color(red: 0.22, green: 0.03, blue: 0.08),
                Color(red: 0.18, green: 0.02, blue: 0.11)
            )
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.28, blue: 0.32),
            mesh: Palette.sweep(
                Color(red: 0.26, green: 0.04, blue: 0.10),
                Color(red: 0.37, green: 0.06, blue: 0.13),
                Color(red: 0.30, green: 0.04, blue: 0.17)
            )
        )
    )

    /// Glowing coals. FLIP: brightness lift — dim maroon embers that flare brighter into a
    /// jewel-orange flame. The coals actually glow rather than reading as flat near-black.
    static let ember = Theme(
        id: "ember",
        name: "Ember",
        half: Palette(
            accent: Color(red: 0.92, green: 0.60, blue: 0.28),
            mesh: Palette.sweep(
                Color(red: 0.10, green: 0.04, blue: 0.03),
                Color(red: 0.16, green: 0.07, blue: 0.03),
                Color(red: 0.18, green: 0.09, blue: 0.04)
            )
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.48, blue: 0.18),
            mesh: Palette.sweep(
                Color(red: 0.20, green: 0.07, blue: 0.02),
                Color(red: 0.30, green: 0.11, blue: 0.03),
                Color(red: 0.34, green: 0.14, blue: 0.04)
            )
        )
    )

    // MARK: Neutral

    /// Graphite. FLIP: warm↔cool — a near-grayscale slate with the faintest temperature
    /// journey: a cool blue-grey in HALF that warms a shade in DOUBLE. The quiet dark one.
    static let mono = Theme(
        id: "mono",
        name: "Mono",
        half: Palette(
            accent: Color(red: 0.82, green: 0.88, blue: 0.95),
            mesh: Palette.sweep(
                Color(red: 0.06, green: 0.07, blue: 0.09),
                Color(red: 0.11, green: 0.12, blue: 0.15),
                Color(red: 0.07, green: 0.08, blue: 0.10)
            )
        ),
        double: Palette(
            accent: Color(red: 0.96, green: 0.90, blue: 0.78),
            mesh: Palette.sweep(
                Color(red: 0.09, green: 0.08, blue: 0.06),
                Color(red: 0.14, green: 0.12, blue: 0.09),
                Color(red: 0.10, green: 0.08, blue: 0.06)
            )
        )
    )

    // MARK: Light

    /// Paper. FLIP: warm↔cool — a cool ivory that drifts toward a warm cream, with an inky
    /// accent that warms to sepia. The most minimal, low-key look in the set.
    static let paper = Theme(
        id: "paper",
        name: "Paper",
        half: Palette(
            accent: Color(red: 0.22, green: 0.20, blue: 0.24),
            mesh: Palette.sweep(
                Color(red: 0.92, green: 0.94, blue: 0.97),
                Color(red: 0.96, green: 0.96, blue: 0.93),
                Color(red: 0.94, green: 0.95, blue: 0.97)
            )
        ),
        double: Palette(
            accent: Color(red: 0.42, green: 0.27, blue: 0.16),
            mesh: Palette.sweep(
                Color(red: 0.98, green: 0.94, blue: 0.86),
                Color(red: 0.97, green: 0.93, blue: 0.84),
                Color(red: 0.99, green: 0.95, blue: 0.88)
            )
        )
    )

    /// Broad daylight. FLIP: warm↔cool — a pale sky that travels blue → cyan → lavender,
    /// swapping to a warm noon of gold → peach → rose. The high-contrast light option.
    static let daylight = Theme(
        id: "daylight",
        name: "Daylight",
        half: Palette(
            accent: Color(red: 0.10, green: 0.42, blue: 0.92),
            mesh: Palette.sweep(
                Color(red: 0.82, green: 0.90, blue: 0.99),
                Color(red: 0.86, green: 0.94, blue: 0.99),
                Color(red: 0.89, green: 0.89, blue: 0.99)
            )
        ),
        double: Palette(
            accent: Color(red: 0.92, green: 0.28, blue: 0.20),
            mesh: Palette.sweep(
                Color(red: 1.00, green: 0.93, blue: 0.82),
                Color(red: 1.00, green: 0.90, blue: 0.78),
                Color(red: 1.00, green: 0.91, blue: 0.86)
            )
        )
    )

    /// Bubblegum. FLIP: warm↔cool — a soft lavender→periwinkle that drifts to peachy coral.
    /// The gentle, low-contrast pastel option, with an amethyst accent that warms to coral.
    static let bubblegum = Theme(
        id: "bubblegum",
        name: "Bubblegum",
        half: Palette(
            accent: Color(red: 0.55, green: 0.35, blue: 0.92),
            mesh: Palette.sweep(
                Color(red: 0.90, green: 0.85, blue: 0.99),
                Color(red: 0.93, green: 0.86, blue: 0.98),
                Color(red: 0.88, green: 0.88, blue: 0.99)
            )
        ),
        double: Palette(
            accent: Color(red: 0.98, green: 0.42, blue: 0.50),
            mesh: Palette.sweep(
                Color(red: 1.00, green: 0.87, blue: 0.85),
                Color(red: 1.00, green: 0.83, blue: 0.82),
                Color(red: 1.00, green: 0.89, blue: 0.88)
            )
        )
    )
}
