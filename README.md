# beatmch

A minimalist iOS BPM half-time / double-time tool for DJs — a living metronome, not a calculator.

- **Swipe up/down** anywhere on screen to set your track's BPM (fractional, 0.1 steps). A faint vertical scale reveals where you are in the 20–300 range while you drag.
- The big number shows **half** of that BPM by default, framed by a ring that **pulses to the beat**.
- **Single tap** flips to **double** (e.g. for the drop). Tap again to go back.
- A second, fainter ring beats at your *source* tempo, so you can **see** the half/double relationship — in half-time the original groove pulses twice for every beat of the result.
- The background is a deep mesh that leans **cyan** for HALF and **amber** for DOUBLE, crossfading on the flip.
- Haptic detent on every whole BPM while swiping; a firmer thud on the flip.
- Your last BPM and mode are remembered between launches.

Respects **Reduce Motion**: the background freezes and the rings hold still, with a small dot blinking on each beat instead.

## Open the project

This project has no committed `.xcodeproj` — it's generated from `project.yml`
with [xcodegen](https://github.com/yonsm/XcodeGen):

```bash
cd beatmch
xcodegen generate      # creates beatmch.xcodeproj
open beatmch.xcodeproj
```

Then press ▶ (set your signing team under *Signing & Capabilities* first if
running on a real device — haptics only fire on hardware, not the Simulator).

Requires Xcode 26+ / iOS 18+. Liquid Glass surfaces light up on iOS 26 and fall
back to a frosted material on iOS 18–25.

## Layout

```
beatmch/
├── BeatmchApp.swift                  # app entry point
├── Views/
│   ├── ContentView.swift             # the whole screen: swipe + tap, composes the pieces
│   ├── PulseOrb.swift                # the beating hero: stable number + dual pulse rings
│   └── TempoMeshBackground.swift     # drifting cyan/amber mesh, reduce-motion aware
├── ViewModels/BPMViewModel.swift     # state, math, persistence
├── Services/HapticsEngine.swift      # primed haptic generators
├── Helpers/GlassSurface.swift        # Liquid Glass (iOS 26) with material fallback
└── Assets.xcassets                   # accent color + app icon slot
```
