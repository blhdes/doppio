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

/// One complete visual identity for the app.
///
/// Every theme carries **two** palettes — one for HALF mode, one for DOUBLE — so the
/// cool→warm shift that signals a tempo flip is preserved in every theme, not just the
/// original cyan/amber one. Switching themes later means picking a different `Theme`;
/// flipping tempo means picking a different `Palette` within the current one.
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
    /// Adding another is literally appending one more entry here.
    static let all: [Theme] = [
        midnight, neon, vapor, voltage, toxic, magma, crimson,
        sunset, ember, aurora, forest, ocean,
        mono, slate, paper,
        daylight, sky, mint, sand, bubblegum
    ]

    // MARK: Dark — the originals & the moody ones

    /// The app's original identity: cool cyan in HALF, warm amber in DOUBLE, over deep
    /// near-black mesh gradients. Colours kept byte-identical to the first build.
    static let midnight = Theme(
        id: "midnight",
        name: "Midnight",
        half: Palette(
            accent: .cyan,
            mesh: [
                Color(red: 0.02, green: 0.03, blue: 0.06), Color(red: 0.03, green: 0.06, blue: 0.11), Color(red: 0.02, green: 0.04, blue: 0.07),
                Color(red: 0.03, green: 0.08, blue: 0.14), Color(red: 0.04, green: 0.13, blue: 0.20), Color(red: 0.02, green: 0.07, blue: 0.12),
                Color(red: 0.01, green: 0.02, blue: 0.05), Color(red: 0.02, green: 0.05, blue: 0.09), Color(red: 0.01, green: 0.02, blue: 0.04)
            ]
        ),
        double: Palette(
            accent: .orange,
            mesh: [
                Color(red: 0.06, green: 0.03, blue: 0.02), Color(red: 0.11, green: 0.06, blue: 0.02), Color(red: 0.07, green: 0.04, blue: 0.02),
                Color(red: 0.15, green: 0.08, blue: 0.03), Color(red: 0.21, green: 0.12, blue: 0.04), Color(red: 0.12, green: 0.06, blue: 0.02),
                Color(red: 0.05, green: 0.02, blue: 0.01), Color(red: 0.09, green: 0.05, blue: 0.02), Color(red: 0.04, green: 0.02, blue: 0.01)
            ]
        )
    )

    /// Synthwave: an almost-black canvas so the electric accents scream. Cyan → magenta.
    static let neon = Theme(
        id: "neon",
        name: "Neon",
        half: Palette(
            accent: Color(red: 0.00, green: 0.95, blue: 1.00),
            mesh: [
                Color(red: 0.01, green: 0.02, blue: 0.05), Color(red: 0.01, green: 0.03, blue: 0.08), Color(red: 0.01, green: 0.02, blue: 0.05),
                Color(red: 0.02, green: 0.03, blue: 0.10), Color(red: 0.02, green: 0.05, blue: 0.14), Color(red: 0.01, green: 0.03, blue: 0.09),
                Color(red: 0.00, green: 0.01, blue: 0.03), Color(red: 0.01, green: 0.02, blue: 0.06), Color(red: 0.00, green: 0.01, blue: 0.03)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.10, blue: 0.62),
            mesh: [
                Color(red: 0.05, green: 0.01, blue: 0.05), Color(red: 0.08, green: 0.01, blue: 0.08), Color(red: 0.05, green: 0.01, blue: 0.05),
                Color(red: 0.10, green: 0.02, blue: 0.10), Color(red: 0.14, green: 0.02, blue: 0.14), Color(red: 0.09, green: 0.01, blue: 0.09),
                Color(red: 0.03, green: 0.00, blue: 0.03), Color(red: 0.06, green: 0.01, blue: 0.06), Color(red: 0.03, green: 0.00, blue: 0.03)
            ]
        )
    )

    /// Dusk into fire: a purple-blue evening sky in HALF, a blazing horizon in DOUBLE.
    static let sunset = Theme(
        id: "sunset",
        name: "Sunset",
        half: Palette(
            accent: Color(red: 1.00, green: 0.42, blue: 0.62),
            mesh: [
                Color(red: 0.06, green: 0.03, blue: 0.10), Color(red: 0.10, green: 0.04, blue: 0.14), Color(red: 0.05, green: 0.03, blue: 0.09),
                Color(red: 0.12, green: 0.05, blue: 0.16), Color(red: 0.20, green: 0.07, blue: 0.20), Color(red: 0.09, green: 0.04, blue: 0.13),
                Color(red: 0.04, green: 0.02, blue: 0.08), Color(red: 0.08, green: 0.03, blue: 0.11), Color(red: 0.03, green: 0.02, blue: 0.06)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.78, blue: 0.28),
            mesh: [
                Color(red: 0.12, green: 0.04, blue: 0.02), Color(red: 0.18, green: 0.06, blue: 0.02), Color(red: 0.10, green: 0.03, blue: 0.02),
                Color(red: 0.20, green: 0.07, blue: 0.02), Color(red: 0.28, green: 0.10, blue: 0.03), Color(red: 0.16, green: 0.05, blue: 0.02),
                Color(red: 0.09, green: 0.03, blue: 0.01), Color(red: 0.14, green: 0.04, blue: 0.02), Color(red: 0.07, green: 0.02, blue: 0.01)
            ]
        )
    )

    /// Glowing coals: a warm, near-monochrome ember bed. Moody, but lifted enough that
    /// the coals actually glow instead of reading as flat near-black.
    static let ember = Theme(
        id: "ember",
        name: "Ember",
        half: Palette(
            accent: Color(red: 0.95, green: 0.65, blue: 0.30),
            mesh: [
                Color(red: 0.08, green: 0.04, blue: 0.02), Color(red: 0.13, green: 0.07, blue: 0.03), Color(red: 0.08, green: 0.04, blue: 0.02),
                Color(red: 0.15, green: 0.08, blue: 0.04), Color(red: 0.20, green: 0.11, blue: 0.05), Color(red: 0.12, green: 0.07, blue: 0.03),
                Color(red: 0.06, green: 0.03, blue: 0.02), Color(red: 0.10, green: 0.05, blue: 0.03), Color(red: 0.05, green: 0.02, blue: 0.01)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.45, blue: 0.20),
            mesh: [
                Color(red: 0.16, green: 0.06, blue: 0.02), Color(red: 0.24, green: 0.10, blue: 0.03), Color(red: 0.14, green: 0.05, blue: 0.02),
                Color(red: 0.28, green: 0.12, blue: 0.04), Color(red: 0.36, green: 0.16, blue: 0.05), Color(red: 0.22, green: 0.09, blue: 0.03),
                Color(red: 0.12, green: 0.04, blue: 0.02), Color(red: 0.19, green: 0.07, blue: 0.03), Color(red: 0.10, green: 0.04, blue: 0.01)
            ]
        )
    )

    /// Northern lights: a teal-green night curtain that turns to indigo-violet.
    static let aurora = Theme(
        id: "aurora",
        name: "Aurora",
        half: Palette(
            accent: Color(red: 0.40, green: 1.00, blue: 0.74),
            mesh: [
                Color(red: 0.01, green: 0.06, blue: 0.06), Color(red: 0.02, green: 0.10, blue: 0.09), Color(red: 0.01, green: 0.05, blue: 0.06),
                Color(red: 0.02, green: 0.12, blue: 0.11), Color(red: 0.03, green: 0.18, blue: 0.15), Color(red: 0.01, green: 0.09, blue: 0.10),
                Color(red: 0.01, green: 0.04, blue: 0.05), Color(red: 0.01, green: 0.07, blue: 0.07), Color(red: 0.00, green: 0.03, blue: 0.04)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.70, green: 0.50, blue: 1.00),
            mesh: [
                Color(red: 0.05, green: 0.03, blue: 0.10), Color(red: 0.08, green: 0.04, blue: 0.16), Color(red: 0.04, green: 0.02, blue: 0.09),
                Color(red: 0.10, green: 0.05, blue: 0.18), Color(red: 0.14, green: 0.07, blue: 0.24), Color(red: 0.07, green: 0.03, blue: 0.14),
                Color(red: 0.03, green: 0.02, blue: 0.08), Color(red: 0.06, green: 0.03, blue: 0.12), Color(red: 0.02, green: 0.01, blue: 0.06)
            ]
        )
    )

    /// Deep woods: a forest-green canopy in HALF, sunlit olive/chartreuse in DOUBLE.
    static let forest = Theme(
        id: "forest",
        name: "Forest",
        half: Palette(
            accent: Color(red: 0.62, green: 0.95, blue: 0.35),
            mesh: [
                Color(red: 0.02, green: 0.05, blue: 0.02), Color(red: 0.03, green: 0.08, blue: 0.03), Color(red: 0.02, green: 0.05, blue: 0.02),
                Color(red: 0.04, green: 0.10, blue: 0.04), Color(red: 0.05, green: 0.14, blue: 0.05), Color(red: 0.03, green: 0.08, blue: 0.03),
                Color(red: 0.01, green: 0.04, blue: 0.02), Color(red: 0.02, green: 0.06, blue: 0.02), Color(red: 0.01, green: 0.03, blue: 0.01)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.85, green: 0.85, blue: 0.25),
            mesh: [
                Color(red: 0.06, green: 0.06, blue: 0.02), Color(red: 0.09, green: 0.09, blue: 0.03), Color(red: 0.05, green: 0.06, blue: 0.02),
                Color(red: 0.11, green: 0.11, blue: 0.03), Color(red: 0.15, green: 0.14, blue: 0.04), Color(red: 0.08, green: 0.09, blue: 0.03),
                Color(red: 0.04, green: 0.05, blue: 0.02), Color(red: 0.07, green: 0.07, blue: 0.02), Color(red: 0.03, green: 0.04, blue: 0.01)
            ]
        )
    )

    /// The abyss: a deep blue that warms toward aqua. Lifted and widened so the water
    /// has depth, and the HALF→DOUBLE blue→teal shift is now clearly visible.
    static let ocean = Theme(
        id: "ocean",
        name: "Ocean",
        half: Palette(
            accent: Color(red: 0.20, green: 0.80, blue: 0.85),
            mesh: [
                Color(red: 0.02, green: 0.06, blue: 0.12), Color(red: 0.03, green: 0.10, blue: 0.19), Color(red: 0.02, green: 0.06, blue: 0.13),
                Color(red: 0.03, green: 0.12, blue: 0.23), Color(red: 0.04, green: 0.17, blue: 0.30), Color(red: 0.03, green: 0.09, blue: 0.20),
                Color(red: 0.01, green: 0.04, blue: 0.09), Color(red: 0.02, green: 0.07, blue: 0.15), Color(red: 0.01, green: 0.03, blue: 0.07)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.30, green: 0.95, blue: 0.85),
            mesh: [
                Color(red: 0.02, green: 0.10, blue: 0.13), Color(red: 0.03, green: 0.16, blue: 0.20), Color(red: 0.02, green: 0.10, blue: 0.13),
                Color(red: 0.03, green: 0.19, blue: 0.24), Color(red: 0.04, green: 0.26, blue: 0.32), Color(red: 0.03, green: 0.14, blue: 0.21),
                Color(red: 0.01, green: 0.07, blue: 0.10), Color(red: 0.02, green: 0.12, blue: 0.16), Color(red: 0.01, green: 0.05, blue: 0.08)
            ]
        )
    )

    // MARK: Dark — vivid & loud

    /// Vaporwave: saturated teal/indigo that flips to hot magenta-purple. Brighter and
    /// far more colourful than Neon — built to be loud while still reading as one mood.
    static let vapor = Theme(
        id: "vapor",
        name: "Vapor",
        half: Palette(
            accent: Color(red: 0.10, green: 0.95, blue: 1.00),
            mesh: [
                Color(red: 0.04, green: 0.10, blue: 0.18), Color(red: 0.06, green: 0.16, blue: 0.26), Color(red: 0.05, green: 0.08, blue: 0.20),
                Color(red: 0.05, green: 0.18, blue: 0.30), Color(red: 0.08, green: 0.26, blue: 0.40), Color(red: 0.06, green: 0.14, blue: 0.28),
                Color(red: 0.03, green: 0.07, blue: 0.14), Color(red: 0.05, green: 0.12, blue: 0.22), Color(red: 0.03, green: 0.05, blue: 0.12)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.15, blue: 0.70),
            mesh: [
                Color(red: 0.16, green: 0.04, blue: 0.18), Color(red: 0.24, green: 0.05, blue: 0.26), Color(red: 0.18, green: 0.04, blue: 0.20),
                Color(red: 0.28, green: 0.05, blue: 0.30), Color(red: 0.38, green: 0.07, blue: 0.40), Color(red: 0.22, green: 0.04, blue: 0.26),
                Color(red: 0.12, green: 0.03, blue: 0.14), Color(red: 0.20, green: 0.04, blue: 0.22), Color(red: 0.10, green: 0.02, blue: 0.12)
            ]
        )
    )

    /// High-voltage clash: deep electric blue against acid yellow-lime. The two palettes
    /// are meant to *fight* — a hard, energetic flip rather than a gentle warm shift.
    static let voltage = Theme(
        id: "voltage",
        name: "Voltage",
        half: Palette(
            accent: Color(red: 0.20, green: 0.45, blue: 1.00),
            mesh: [
                Color(red: 0.02, green: 0.05, blue: 0.18), Color(red: 0.03, green: 0.08, blue: 0.28), Color(red: 0.02, green: 0.05, blue: 0.20),
                Color(red: 0.03, green: 0.10, blue: 0.34), Color(red: 0.04, green: 0.15, blue: 0.46), Color(red: 0.03, green: 0.08, blue: 0.30),
                Color(red: 0.01, green: 0.03, blue: 0.14), Color(red: 0.02, green: 0.06, blue: 0.24), Color(red: 0.01, green: 0.03, blue: 0.12)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.85, green: 1.00, blue: 0.10),
            mesh: [
                Color(red: 0.10, green: 0.12, blue: 0.02), Color(red: 0.16, green: 0.20, blue: 0.03), Color(red: 0.11, green: 0.13, blue: 0.02),
                Color(red: 0.18, green: 0.24, blue: 0.03), Color(red: 0.26, green: 0.34, blue: 0.04), Color(red: 0.14, green: 0.18, blue: 0.02),
                Color(red: 0.07, green: 0.09, blue: 0.01), Color(red: 0.13, green: 0.16, blue: 0.02), Color(red: 0.06, green: 0.08, blue: 0.01)
            ]
        )
    )

    /// Radioactive: a poison-green glow that mutates into ultraviolet. The loudest of the
    /// cool themes — two toxic hues with nothing soft between them.
    static let toxic = Theme(
        id: "toxic",
        name: "Toxic",
        half: Palette(
            accent: Color(red: 0.50, green: 1.00, blue: 0.15),
            mesh: [
                Color(red: 0.03, green: 0.12, blue: 0.04), Color(red: 0.04, green: 0.20, blue: 0.06), Color(red: 0.03, green: 0.13, blue: 0.04),
                Color(red: 0.05, green: 0.24, blue: 0.07), Color(red: 0.07, green: 0.34, blue: 0.10), Color(red: 0.04, green: 0.18, blue: 0.06),
                Color(red: 0.02, green: 0.09, blue: 0.03), Color(red: 0.03, green: 0.15, blue: 0.05), Color(red: 0.02, green: 0.07, blue: 0.02)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.85, green: 0.10, blue: 1.00),
            mesh: [
                Color(red: 0.12, green: 0.02, blue: 0.18), Color(red: 0.18, green: 0.03, blue: 0.28), Color(red: 0.13, green: 0.02, blue: 0.20),
                Color(red: 0.20, green: 0.03, blue: 0.32), Color(red: 0.28, green: 0.05, blue: 0.44), Color(red: 0.16, green: 0.03, blue: 0.26),
                Color(red: 0.09, green: 0.01, blue: 0.14), Color(red: 0.15, green: 0.02, blue: 0.22), Color(red: 0.07, green: 0.01, blue: 0.11)
            ]
        )
    )

    /// Molten: a deep volcanic violet that erupts into blazing red-orange lava. The
    /// classic cool→warm flip, pushed to its most extreme.
    static let magma = Theme(
        id: "magma",
        name: "Magma",
        half: Palette(
            accent: Color(red: 0.75, green: 0.30, blue: 0.95),
            mesh: [
                Color(red: 0.08, green: 0.02, blue: 0.12), Color(red: 0.12, green: 0.03, blue: 0.18), Color(red: 0.09, green: 0.02, blue: 0.13),
                Color(red: 0.14, green: 0.03, blue: 0.20), Color(red: 0.20, green: 0.05, blue: 0.28), Color(red: 0.11, green: 0.03, blue: 0.16),
                Color(red: 0.06, green: 0.01, blue: 0.09), Color(red: 0.10, green: 0.02, blue: 0.14), Color(red: 0.05, green: 0.01, blue: 0.07)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.35, blue: 0.05),
            mesh: [
                Color(red: 0.20, green: 0.04, blue: 0.02), Color(red: 0.30, green: 0.07, blue: 0.02), Color(red: 0.22, green: 0.05, blue: 0.02),
                Color(red: 0.34, green: 0.08, blue: 0.02), Color(red: 0.46, green: 0.13, blue: 0.03), Color(red: 0.28, green: 0.06, blue: 0.02),
                Color(red: 0.16, green: 0.03, blue: 0.01), Color(red: 0.26, green: 0.05, blue: 0.02), Color(red: 0.14, green: 0.03, blue: 0.01)
            ]
        )
    )

    /// Blood & neon: a deep scarlet bed that flushes into hot pink. An all-red theme that
    /// stays saturated and aggressive across the flip.
    static let crimson = Theme(
        id: "crimson",
        name: "Crimson",
        half: Palette(
            accent: Color(red: 1.00, green: 0.20, blue: 0.25),
            mesh: [
                Color(red: 0.16, green: 0.02, blue: 0.05), Color(red: 0.24, green: 0.03, blue: 0.08), Color(red: 0.18, green: 0.02, blue: 0.06),
                Color(red: 0.28, green: 0.04, blue: 0.10), Color(red: 0.38, green: 0.06, blue: 0.13), Color(red: 0.22, green: 0.03, blue: 0.08),
                Color(red: 0.12, green: 0.02, blue: 0.04), Color(red: 0.20, green: 0.03, blue: 0.07), Color(red: 0.10, green: 0.01, blue: 0.03)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.25, blue: 0.55),
            mesh: [
                Color(red: 0.20, green: 0.03, blue: 0.12), Color(red: 0.30, green: 0.04, blue: 0.18), Color(red: 0.22, green: 0.03, blue: 0.13),
                Color(red: 0.34, green: 0.05, blue: 0.20), Color(red: 0.46, green: 0.07, blue: 0.28), Color(red: 0.28, green: 0.04, blue: 0.17),
                Color(red: 0.15, green: 0.02, blue: 0.09), Color(red: 0.24, green: 0.03, blue: 0.14), Color(red: 0.13, green: 0.02, blue: 0.07)
            ]
        )
    )

    // MARK: Neutral & monochrome

    /// Graphite: a near-grayscale slate. Cool grey warms a shade — the quiet, dark one.
    /// Value range widened so the gradient actually reads instead of looking like a flat fill.
    static let mono = Theme(
        id: "mono",
        name: "Mono",
        half: Palette(
            accent: Color(red: 0.85, green: 0.90, blue: 0.95),
            mesh: [
                Color(red: 0.05, green: 0.06, blue: 0.07), Color(red: 0.09, green: 0.10, blue: 0.12), Color(red: 0.05, green: 0.06, blue: 0.07),
                Color(red: 0.11, green: 0.12, blue: 0.14), Color(red: 0.17, green: 0.18, blue: 0.21), Color(red: 0.09, green: 0.10, blue: 0.12),
                Color(red: 0.04, green: 0.04, blue: 0.05), Color(red: 0.07, green: 0.08, blue: 0.09), Color(red: 0.03, green: 0.03, blue: 0.04)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.98, green: 0.92, blue: 0.80),
            mesh: [
                Color(red: 0.07, green: 0.06, blue: 0.05), Color(red: 0.12, green: 0.10, blue: 0.08), Color(red: 0.07, green: 0.06, blue: 0.05),
                Color(red: 0.14, green: 0.12, blue: 0.10), Color(red: 0.20, green: 0.17, blue: 0.14), Color(red: 0.12, green: 0.10, blue: 0.08),
                Color(red: 0.05, green: 0.05, blue: 0.04), Color(red: 0.09, green: 0.08, blue: 0.06), Color(red: 0.04, green: 0.03, blue: 0.03)
            ]
        )
    )

    /// Concrete: a cool, almost-white grey with a faint blue cast that neutralises on the
    /// flip. The light counterpart to Mono — calm, monochrome, no hue to speak of.
    static let slate = Theme(
        id: "slate",
        name: "Slate",
        half: Palette(
            accent: Color(red: 0.30, green: 0.40, blue: 0.55),
            mesh: [
                Color(red: 0.90, green: 0.92, blue: 0.94), Color(red: 0.88, green: 0.91, blue: 0.94), Color(red: 0.91, green: 0.93, blue: 0.95),
                Color(red: 0.87, green: 0.90, blue: 0.93), Color(red: 0.84, green: 0.88, blue: 0.92), Color(red: 0.89, green: 0.91, blue: 0.94),
                Color(red: 0.92, green: 0.93, blue: 0.95), Color(red: 0.88, green: 0.90, blue: 0.93), Color(red: 0.93, green: 0.94, blue: 0.96)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.42, green: 0.40, blue: 0.46),
            mesh: [
                Color(red: 0.93, green: 0.92, blue: 0.91), Color(red: 0.92, green: 0.91, blue: 0.89), Color(red: 0.94, green: 0.93, blue: 0.92),
                Color(red: 0.91, green: 0.90, blue: 0.88), Color(red: 0.89, green: 0.87, blue: 0.85), Color(red: 0.92, green: 0.91, blue: 0.90),
                Color(red: 0.94, green: 0.93, blue: 0.92), Color(red: 0.91, green: 0.90, blue: 0.89), Color(red: 0.95, green: 0.94, blue: 0.93)
            ]
        )
    )

    /// Paper: a warm ivory that deepens a touch toward cream. A near-monochrome light
    /// theme with an inky accent — the most minimal, low-key look in the set.
    static let paper = Theme(
        id: "paper",
        name: "Paper",
        half: Palette(
            accent: Color(red: 0.25, green: 0.22, blue: 0.20),
            mesh: [
                Color(red: 0.96, green: 0.94, blue: 0.90), Color(red: 0.97, green: 0.95, blue: 0.91), Color(red: 0.96, green: 0.94, blue: 0.89),
                Color(red: 0.97, green: 0.95, blue: 0.91), Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.96, green: 0.94, blue: 0.90),
                Color(red: 0.95, green: 0.93, blue: 0.88), Color(red: 0.96, green: 0.94, blue: 0.90), Color(red: 0.94, green: 0.92, blue: 0.87)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.45, green: 0.28, blue: 0.15),
            mesh: [
                Color(red: 0.96, green: 0.92, blue: 0.85), Color(red: 0.97, green: 0.93, blue: 0.86), Color(red: 0.96, green: 0.92, blue: 0.84),
                Color(red: 0.97, green: 0.93, blue: 0.86), Color(red: 0.98, green: 0.94, blue: 0.87), Color(red: 0.96, green: 0.92, blue: 0.85),
                Color(red: 0.95, green: 0.91, blue: 0.83), Color(red: 0.96, green: 0.92, blue: 0.85), Color(red: 0.94, green: 0.90, blue: 0.82)
            ]
        )
    )

    // MARK: Light

    /// Broad daylight: a pale-blue sky in HALF, warm peach noon in DOUBLE. Dark ink,
    /// saturated accents — the high-contrast light option.
    static let daylight = Theme(
        id: "daylight",
        name: "Daylight",
        half: Palette(
            accent: Color(red: 0.10, green: 0.45, blue: 0.95),
            mesh: [
                Color(red: 0.86, green: 0.92, blue: 0.98), Color(red: 0.80, green: 0.89, blue: 0.99), Color(red: 0.88, green: 0.93, blue: 0.98),
                Color(red: 0.82, green: 0.90, blue: 1.00), Color(red: 0.74, green: 0.86, blue: 1.00), Color(red: 0.85, green: 0.91, blue: 0.99),
                Color(red: 0.90, green: 0.94, blue: 0.99), Color(red: 0.84, green: 0.91, blue: 0.99), Color(red: 0.92, green: 0.95, blue: 1.00)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.95, green: 0.30, blue: 0.15),
            mesh: [
                Color(red: 1.00, green: 0.92, blue: 0.82), Color(red: 1.00, green: 0.88, blue: 0.74), Color(red: 1.00, green: 0.93, blue: 0.84),
                Color(red: 1.00, green: 0.86, blue: 0.70), Color(red: 1.00, green: 0.80, blue: 0.62), Color(red: 1.00, green: 0.89, blue: 0.76),
                Color(red: 1.00, green: 0.94, blue: 0.86), Color(red: 1.00, green: 0.90, blue: 0.80), Color(red: 1.00, green: 0.95, blue: 0.88)
            ]
        )
    )

    /// Open sky: an airy aqua-blue noon that warms to soft gold. A calmer, more saturated
    /// light theme than Daylight — less postcard-blue, more washed sunlight.
    static let sky = Theme(
        id: "sky",
        name: "Sky",
        half: Palette(
            accent: Color(red: 0.00, green: 0.55, blue: 0.75),
            mesh: [
                Color(red: 0.80, green: 0.95, blue: 0.97), Color(red: 0.70, green: 0.93, blue: 0.98), Color(red: 0.83, green: 0.96, blue: 0.97),
                Color(red: 0.72, green: 0.94, blue: 0.98), Color(red: 0.62, green: 0.91, blue: 0.97), Color(red: 0.78, green: 0.94, blue: 0.96),
                Color(red: 0.84, green: 0.97, blue: 0.99), Color(red: 0.74, green: 0.93, blue: 0.97), Color(red: 0.87, green: 0.98, blue: 0.99)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.95, green: 0.62, blue: 0.05),
            mesh: [
                Color(red: 1.00, green: 0.95, blue: 0.80), Color(red: 1.00, green: 0.92, blue: 0.70), Color(red: 1.00, green: 0.96, blue: 0.82),
                Color(red: 1.00, green: 0.90, blue: 0.66), Color(red: 1.00, green: 0.86, blue: 0.56), Color(red: 1.00, green: 0.93, blue: 0.74),
                Color(red: 1.00, green: 0.96, blue: 0.84), Color(red: 1.00, green: 0.92, blue: 0.74), Color(red: 1.00, green: 0.97, blue: 0.86)
            ]
        )
    )

    /// Fresh mint: a pale cool green that turns to soft coral. A bright, clean light theme
    /// built on a green base — the only one in the set that starts cool-green.
    static let mint = Theme(
        id: "mint",
        name: "Mint",
        half: Palette(
            accent: Color(red: 0.10, green: 0.65, blue: 0.45),
            mesh: [
                Color(red: 0.86, green: 0.97, blue: 0.92), Color(red: 0.80, green: 0.97, blue: 0.89), Color(red: 0.88, green: 0.98, blue: 0.93),
                Color(red: 0.82, green: 0.98, blue: 0.90), Color(red: 0.74, green: 0.96, blue: 0.86), Color(red: 0.85, green: 0.97, blue: 0.91),
                Color(red: 0.89, green: 0.98, blue: 0.94), Color(red: 0.83, green: 0.97, blue: 0.91), Color(red: 0.91, green: 0.99, blue: 0.95)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.98, green: 0.40, blue: 0.40),
            mesh: [
                Color(red: 1.00, green: 0.92, blue: 0.86), Color(red: 1.00, green: 0.88, blue: 0.82), Color(red: 1.00, green: 0.93, blue: 0.87),
                Color(red: 1.00, green: 0.89, blue: 0.83), Color(red: 1.00, green: 0.84, blue: 0.78), Color(red: 1.00, green: 0.91, blue: 0.85),
                Color(red: 1.00, green: 0.94, blue: 0.88), Color(red: 1.00, green: 0.90, blue: 0.84), Color(red: 1.00, green: 0.95, blue: 0.90)
            ]
        )
    )

    /// Sand: a warm desert beige that deepens toward terracotta. A near-monochrome *warm*
    /// light theme — earthy and quiet, the daylight cousin of Ember.
    static let sand = Theme(
        id: "sand",
        name: "Sand",
        half: Palette(
            accent: Color(red: 0.80, green: 0.45, blue: 0.25),
            mesh: [
                Color(red: 0.96, green: 0.92, blue: 0.84), Color(red: 0.97, green: 0.90, blue: 0.80), Color(red: 0.96, green: 0.93, blue: 0.85),
                Color(red: 0.97, green: 0.91, blue: 0.81), Color(red: 0.98, green: 0.88, blue: 0.76), Color(red: 0.96, green: 0.91, blue: 0.83),
                Color(red: 0.97, green: 0.93, blue: 0.86), Color(red: 0.96, green: 0.91, blue: 0.82), Color(red: 0.98, green: 0.94, blue: 0.87)
            ]
        ),
        double: Palette(
            accent: Color(red: 0.85, green: 0.35, blue: 0.15),
            mesh: [
                Color(red: 0.94, green: 0.86, blue: 0.74), Color(red: 0.95, green: 0.83, blue: 0.69), Color(red: 0.94, green: 0.87, blue: 0.75),
                Color(red: 0.95, green: 0.84, blue: 0.70), Color(red: 0.96, green: 0.80, blue: 0.63), Color(red: 0.94, green: 0.85, blue: 0.72),
                Color(red: 0.95, green: 0.87, blue: 0.76), Color(red: 0.94, green: 0.84, blue: 0.71), Color(red: 0.96, green: 0.88, blue: 0.78)
            ]
        )
    )

    /// Bubblegum: soft lavender drifting to peachy coral. The gentle, low-contrast light
    /// option — pastel and easy on the eyes, with the saturation nudged up so the hues
    /// actually show through the legibility wash.
    static let bubblegum = Theme(
        id: "bubblegum",
        name: "Bubblegum",
        half: Palette(
            accent: Color(red: 0.55, green: 0.35, blue: 0.95),
            mesh: [
                Color(red: 0.90, green: 0.84, blue: 0.99), Color(red: 0.93, green: 0.80, blue: 0.98), Color(red: 0.89, green: 0.85, blue: 0.99),
                Color(red: 0.94, green: 0.81, blue: 0.98), Color(red: 0.97, green: 0.77, blue: 0.97), Color(red: 0.91, green: 0.83, blue: 0.99),
                Color(red: 0.88, green: 0.86, blue: 0.99), Color(red: 0.92, green: 0.82, blue: 0.98), Color(red: 0.87, green: 0.88, blue: 1.00)
            ]
        ),
        double: Palette(
            accent: Color(red: 1.00, green: 0.42, blue: 0.52),
            mesh: [
                Color(red: 1.00, green: 0.86, blue: 0.84), Color(red: 1.00, green: 0.81, blue: 0.80), Color(red: 1.00, green: 0.87, blue: 0.85),
                Color(red: 1.00, green: 0.80, blue: 0.79), Color(red: 1.00, green: 0.75, blue: 0.75), Color(red: 1.00, green: 0.83, blue: 0.82),
                Color(red: 1.00, green: 0.88, blue: 0.86), Color(red: 1.00, green: 0.83, blue: 0.82), Color(red: 1.00, green: 0.89, blue: 0.87)
            ]
        )
    )
}
