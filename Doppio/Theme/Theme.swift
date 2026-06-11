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
        crimson, ember, espresso, velvet, mono,
        paper, pearl, sage, citrus, honey, dune,
        rose, sakura, glacier, daylight, bubblegum
    ]

    // MARK: Dark — cool & electric

    /// The app's original identity. FLIP: warm↔cool — cool sapphire night that travels
    /// indigo → blue → teal in HALF, swapping to a warm amber ember-bed in DOUBLE.
    static let midnight = Theme(
        id: "midnight",
        name: "Midnight",
        half: Palette(
            accent: Color(red: 0.32, green: 0.65, blue: 0.92),
            mesh: Palette.sweep(
                Color(red: 0.03, green: 0.03, blue: 0.11),
                Color(red: 0.03, green: 0.08, blue: 0.21),
                Color(red: 0.03, green: 0.15, blue: 0.21)
            )
        ),
        double: Palette(
            accent: Color(red: 0.95, green: 0.65, blue: 0.26),
            mesh: Palette.sweep(
                Color(red: 0.11, green: 0.05, blue: 0.03),
                Color(red: 0.16, green: 0.09, blue: 0.03),
                Color(red: 0.21, green: 0.13, blue: 0.04)
            )
        )
    )

    /// FLIP: hue clash — deep sapphire blue against a jewel-peridot lime. The two sides
    /// are meant to *fight*, a hard energetic snap rather than a gentle shift.
    static let voltage = Theme(
        id: "voltage",
        name: "Voltage",
        half: Palette(
            accent: Color(red: 0.32, green: 0.54, blue: 1.00),
            mesh: Palette.sweep(
                Color(red: 0.02, green: 0.05, blue: 0.18),
                Color(red: 0.03, green: 0.10, blue: 0.34),
                Color(red: 0.06, green: 0.07, blue: 0.27)
            )
        ),
        double: Palette(
            accent: Color(red: 0.75, green: 0.89, blue: 0.22),
            mesh: Palette.sweep(
                Color(red: 0.08, green: 0.12, blue: 0.02),
                Color(red: 0.14, green: 0.21, blue: 0.03),
                Color(red: 0.10, green: 0.17, blue: 0.02)
            )
        )
    )

    /// FLIP: hue clash — a jewel-emerald poison glow that snaps to deep amethyst violet.
    /// Two near-opposite hues with nothing soft between them; the loudest cool theme.
    static let toxic = Theme(
        id: "toxic",
        name: "Toxic",
        half: Palette(
            accent: Color(red: 0.20, green: 0.84, blue: 0.46),
            mesh: Palette.sweep(
                Color(red: 0.02, green: 0.12, blue: 0.05),
                Color(red: 0.04, green: 0.23, blue: 0.10),
                Color(red: 0.04, green: 0.18, blue: 0.13)
            )
        ),
        double: Palette(
            accent: Color(red: 0.67, green: 0.36, blue: 0.95),
            mesh: Palette.sweep(
                Color(red: 0.10, green: 0.03, blue: 0.16),
                Color(red: 0.17, green: 0.04, blue: 0.27),
                Color(red: 0.13, green: 0.03, blue: 0.22)
            )
        )
    )

    /// The abyss. FLIP: brightness lift — the same blue→teal water travels navy → blue →
    /// teal, then DOUBLE simply charges it brighter toward aqua. Same hue, more energy.
    static let ocean = Theme(
        id: "ocean",
        name: "Ocean",
        half: Palette(
            accent: Color(red: 0.20, green: 0.70, blue: 0.84),
            mesh: Palette.sweep(
                Color(red: 0.01, green: 0.05, blue: 0.13),
                Color(red: 0.02, green: 0.11, blue: 0.23),
                Color(red: 0.02, green: 0.16, blue: 0.21)
            )
        ),
        double: Palette(
            accent: Color(red: 0.30, green: 0.89, blue: 0.85),
            mesh: Palette.sweep(
                Color(red: 0.02, green: 0.11, blue: 0.19),
                Color(red: 0.03, green: 0.19, blue: 0.29),
                Color(red: 0.03, green: 0.24, blue: 0.29)
            )
        )
    )

    /// Northern lights. FLIP: hue shift — a jade-green curtain that travels green → teal →
    /// blue, swapping to an indigo→violet sky. The hue travel *is* the identity here.
    static let aurora = Theme(
        id: "aurora",
        name: "Aurora",
        half: Palette(
            accent: Color(red: 0.38, green: 0.90, blue: 0.64),
            mesh: Palette.sweep(
                Color(red: 0.01, green: 0.10, blue: 0.06),
                Color(red: 0.02, green: 0.15, blue: 0.13),
                Color(red: 0.02, green: 0.10, blue: 0.18)
            )
        ),
        double: Palette(
            accent: Color(red: 0.68, green: 0.48, blue: 0.98),
            mesh: Palette.sweep(
                Color(red: 0.05, green: 0.03, blue: 0.15),
                Color(red: 0.09, green: 0.05, blue: 0.23),
                Color(red: 0.13, green: 0.05, blue: 0.22)
            )
        )
    )

    /// Deep woods. FLIP: brightness lift — a pine→moss canopy that charges brighter toward
    /// a sunlit emerald-lime in DOUBLE. Same green family, more light coming through.
    static let forest = Theme(
        id: "forest",
        name: "Forest",
        half: Palette(
            accent: Color(red: 0.34, green: 0.80, blue: 0.46),
            mesh: Palette.sweep(
                Color(red: 0.01, green: 0.07, blue: 0.03),
                Color(red: 0.03, green: 0.13, blue: 0.06),
                Color(red: 0.02, green: 0.13, blue: 0.10)
            )
        ),
        double: Palette(
            accent: Color(red: 0.60, green: 0.86, blue: 0.30),
            mesh: Palette.sweep(
                Color(red: 0.05, green: 0.12, blue: 0.04),
                Color(red: 0.08, green: 0.18, blue: 0.05),
                Color(red: 0.12, green: 0.19, blue: 0.05)
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
            accent: Color(red: 0.86, green: 0.20, blue: 0.32),
            mesh: Palette.sweep(
                Color(red: 0.14, green: 0.01, blue: 0.05),
                Color(red: 0.23, green: 0.03, blue: 0.08),
                Color(red: 0.19, green: 0.02, blue: 0.12)
            )
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.32, blue: 0.36),
            mesh: Palette.sweep(
                Color(red: 0.25, green: 0.04, blue: 0.10),
                Color(red: 0.38, green: 0.06, blue: 0.13),
                Color(red: 0.31, green: 0.04, blue: 0.18)
            )
        )
    )

    /// Glowing coals. FLIP: brightness lift — dim maroon embers that flare brighter into a
    /// jewel-orange flame. The coals actually glow rather than reading as flat near-black.
    static let ember = Theme(
        id: "ember",
        name: "Ember",
        half: Palette(
            accent: Color(red: 0.92, green: 0.61, blue: 0.30),
            mesh: Palette.sweep(
                Color(red: 0.09, green: 0.03, blue: 0.02),
                Color(red: 0.16, green: 0.07, blue: 0.03),
                Color(red: 0.19, green: 0.10, blue: 0.04)
            )
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.51, blue: 0.22),
            mesh: Palette.sweep(
                Color(red: 0.20, green: 0.07, blue: 0.02),
                Color(red: 0.31, green: 0.11, blue: 0.03),
                Color(red: 0.35, green: 0.15, blue: 0.04)
            )
        )
    )

    /// The house theme — a doppio in a cup. FLIP: brightness lift — a near-black ristretto
    /// roast that pulls lighter into caramel crema on DOUBLE, like milk hitting the shot.
    static let espresso = Theme(
        id: "espresso",
        name: "Espresso",
        half: Palette(
            accent: Color(red: 0.84, green: 0.62, blue: 0.40),
            mesh: Palette.sweep(
                Color(red: 0.07, green: 0.04, blue: 0.03),
                Color(red: 0.11, green: 0.07, blue: 0.05),
                Color(red: 0.13, green: 0.09, blue: 0.07)
            )
        ),
        double: Palette(
            accent: Color(red: 0.96, green: 0.84, blue: 0.66),
            mesh: Palette.sweep(
                Color(red: 0.14, green: 0.09, blue: 0.05),
                Color(red: 0.20, green: 0.13, blue: 0.08),
                Color(red: 0.24, green: 0.17, blue: 0.11)
            )
        )
    )

    /// Theatre curtains. FLIP: warm↔cool — a cool deep-aubergine plum with a dusty orchid
    /// accent that warms into mulberry wine with rose-mauve. The plush, quiet warm dark.
    static let velvet = Theme(
        id: "velvet",
        name: "Velvet",
        half: Palette(
            accent: Color(red: 0.76, green: 0.54, blue: 0.86),
            mesh: Palette.sweep(
                Color(red: 0.08, green: 0.03, blue: 0.12),
                Color(red: 0.12, green: 0.04, blue: 0.18),
                Color(red: 0.09, green: 0.05, blue: 0.20)
            )
        ),
        double: Palette(
            accent: Color(red: 0.94, green: 0.50, blue: 0.62),
            mesh: Palette.sweep(
                Color(red: 0.14, green: 0.03, blue: 0.10),
                Color(red: 0.20, green: 0.04, blue: 0.13),
                Color(red: 0.17, green: 0.05, blue: 0.17)
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

    /// The light twin of Mono. FLIP: warm↔cool — a silvery blue-grey with a graphite accent
    /// that warms into greige with taupe. Duskier and softer than Paper's bright ivory.
    static let pearl = Theme(
        id: "pearl",
        name: "Pearl",
        half: Palette(
            accent: Color(red: 0.20, green: 0.23, blue: 0.28),
            mesh: Palette.sweep(
                Color(red: 0.86, green: 0.88, blue: 0.91),
                Color(red: 0.82, green: 0.85, blue: 0.89),
                Color(red: 0.87, green: 0.89, blue: 0.92)
            )
        ),
        double: Palette(
            accent: Color(red: 0.35, green: 0.28, blue: 0.22),
            mesh: Palette.sweep(
                Color(red: 0.90, green: 0.88, blue: 0.84),
                Color(red: 0.87, green: 0.84, blue: 0.80),
                Color(red: 0.91, green: 0.89, blue: 0.86)
            )
        )
    )

    /// Eucalyptus & pine. FLIP: warm↔cool within green — a cool grey-green wash with a deep
    /// pine accent that warms into olive tea. The botanical, spa-calm light option.
    static let sage = Theme(
        id: "sage",
        name: "Sage",
        half: Palette(
            accent: Color(red: 0.13, green: 0.34, blue: 0.27),
            mesh: Palette.sweep(
                Color(red: 0.88, green: 0.92, blue: 0.88),
                Color(red: 0.84, green: 0.90, blue: 0.86),
                Color(red: 0.88, green: 0.93, blue: 0.91)
            )
        ),
        double: Palette(
            accent: Color(red: 0.36, green: 0.38, blue: 0.14),
            mesh: Palette.sweep(
                Color(red: 0.92, green: 0.93, blue: 0.84),
                Color(red: 0.89, green: 0.90, blue: 0.79),
                Color(red: 0.94, green: 0.94, blue: 0.86)
            )
        )
    )

    /// Zest. FLIP: warm↔cool within citrus — pale lemon with a bronze-ochre accent that
    /// sharpens into lime with deep leaf green. The fresh, tangy light option.
    static let citrus = Theme(
        id: "citrus",
        name: "Citrus",
        half: Palette(
            accent: Color(red: 0.52, green: 0.38, blue: 0.04),
            mesh: Palette.sweep(
                Color(red: 0.98, green: 0.98, blue: 0.76),
                Color(red: 0.96, green: 0.96, blue: 0.66),
                Color(red: 0.99, green: 0.99, blue: 0.80)
            )
        ),
        double: Palette(
            accent: Color(red: 0.16, green: 0.42, blue: 0.10),
            mesh: Palette.sweep(
                Color(red: 0.90, green: 0.96, blue: 0.74),
                Color(red: 0.86, green: 0.94, blue: 0.66),
                Color(red: 0.92, green: 0.97, blue: 0.78)
            )
        )
    )

    /// Warm gold. FLIP: brightness charge — pale honey with an amber-brown accent that
    /// deepens into apricot marmalade with burnt amber. The committed golden light option.
    static let honey = Theme(
        id: "honey",
        name: "Honey",
        half: Palette(
            accent: Color(red: 0.55, green: 0.35, blue: 0.06),
            mesh: Palette.sweep(
                Color(red: 1.00, green: 0.92, blue: 0.72),
                Color(red: 1.00, green: 0.88, blue: 0.62),
                Color(red: 1.00, green: 0.93, blue: 0.76)
            )
        ),
        double: Palette(
            accent: Color(red: 0.62, green: 0.32, blue: 0.08),
            mesh: Palette.sweep(
                Color(red: 1.00, green: 0.87, blue: 0.62),
                Color(red: 0.99, green: 0.82, blue: 0.54),
                Color(red: 1.00, green: 0.89, blue: 0.66)
            )
        )
    )

    /// Desert sand. FLIP: hue shift — noon sand with a terracotta accent that cools into a
    /// mauve-violet dusk settling over the dunes. The earthy, sun-baked light option.
    static let dune = Theme(
        id: "dune",
        name: "Dune",
        half: Palette(
            accent: Color(red: 0.68, green: 0.34, blue: 0.20),
            mesh: Palette.sweep(
                Color(red: 0.96, green: 0.92, blue: 0.84),
                Color(red: 0.94, green: 0.89, blue: 0.79),
                Color(red: 0.97, green: 0.93, blue: 0.87)
            )
        ),
        double: Palette(
            accent: Color(red: 0.44, green: 0.30, blue: 0.52),
            mesh: Palette.sweep(
                Color(red: 0.96, green: 0.87, blue: 0.80),
                Color(red: 0.93, green: 0.85, blue: 0.85),
                Color(red: 0.91, green: 0.86, blue: 0.93)
            )
        )
    )

    /// A glass of rosé. FLIP: warm lift — pale blush with a deep raspberry accent that pours
    /// into rose-gold with burnished copper. The refined, celebratory light option.
    static let rose = Theme(
        id: "rose",
        name: "Rosé",
        half: Palette(
            accent: Color(red: 0.64, green: 0.18, blue: 0.34),
            mesh: Palette.sweep(
                Color(red: 0.99, green: 0.92, blue: 0.93),
                Color(red: 0.98, green: 0.88, blue: 0.90),
                Color(red: 0.99, green: 0.93, blue: 0.96)
            )
        ),
        double: Palette(
            accent: Color(red: 0.70, green: 0.40, blue: 0.28),
            mesh: Palette.sweep(
                Color(red: 1.00, green: 0.92, blue: 0.86),
                Color(red: 0.99, green: 0.88, blue: 0.80),
                Color(red: 1.00, green: 0.93, blue: 0.87)
            )
        )
    )

    /// Cherry blossom. FLIP: hue shift — near-white blossom pink with a deep cherry-plum
    /// accent that turns over into fresh spring leaf green. Petals, then leaves.
    static let sakura = Theme(
        id: "sakura",
        name: "Sakura",
        half: Palette(
            accent: Color(red: 0.55, green: 0.14, blue: 0.30),
            mesh: Palette.sweep(
                Color(red: 1.00, green: 0.95, blue: 0.96),
                Color(red: 0.99, green: 0.92, blue: 0.95),
                Color(red: 0.98, green: 0.94, blue: 0.98)
            )
        ),
        double: Palette(
            accent: Color(red: 0.18, green: 0.45, blue: 0.20),
            mesh: Palette.sweep(
                Color(red: 0.90, green: 0.96, blue: 0.88),
                Color(red: 0.86, green: 0.94, blue: 0.84),
                Color(red: 0.91, green: 0.97, blue: 0.90)
            )
        )
    )

    /// Pack ice. FLIP: brightness charge — frosted mint-white with a deep teal accent that
    /// saturates into open glacial aqua. The crisp, cold light option.
    static let glacier = Theme(
        id: "glacier",
        name: "Glacier",
        half: Palette(
            accent: Color(red: 0.03, green: 0.38, blue: 0.45),
            mesh: Palette.sweep(
                Color(red: 0.88, green: 0.95, blue: 0.96),
                Color(red: 0.84, green: 0.93, blue: 0.94),
                Color(red: 0.89, green: 0.96, blue: 0.96)
            )
        ),
        double: Palette(
            accent: Color(red: 0.00, green: 0.42, blue: 0.52),
            mesh: Palette.sweep(
                Color(red: 0.80, green: 0.93, blue: 0.94),
                Color(red: 0.74, green: 0.91, blue: 0.93),
                Color(red: 0.81, green: 0.95, blue: 0.94)
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
            accent: Color(red: 0.85, green: 0.30, blue: 0.22),
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
            accent: Color(red: 0.52, green: 0.38, blue: 0.90),
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
