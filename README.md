# beatmch

A minimalist iOS BPM half-time / double-time tool for DJs.

- **Swipe up/down** anywhere on screen to set your track's BPM (fractional, 0.1 steps).
- The big number shows **half** of that BPM by default.
- **Single tap** flips to **double** (e.g. for the drop). Tap again to go back.
- Haptic detent on every whole BPM while swiping; a firmer thud on the flip.
- Your last BPM and mode are remembered between launches.

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

## Layout

```
beatmch/
├── BeatmchApp.swift           # app entry point
├── Views/ContentView.swift    # the whole screen: swipe + tap
├── ViewModels/BPMViewModel.swift  # state, math, persistence
├── Services/HapticsEngine.swift   # primed haptic generators
└── Assets.xcassets            # accent color + app icon slot
```
