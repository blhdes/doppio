# Doppio

A minimalist iOS BPM half-time / double-time tool for DJs — a living metronome, not a calculator.

Named after *doppio movimento*, the score marking for "play twice as fast" — with a nod to the double espresso.

## Setting the tempo

- **Swipe up/down** anywhere on screen to set your track's BPM (fractional, 0.1 steps, 20–300 range). A faint vertical scale on the right edge shows where you are while you drag — and you can **grab that bar** and drag it to jump straight to an absolute BPM.
- **Hold a second finger** (anywhere) to slip into fine mode: the swipe slows ~10× so a small move nudges just a decimal — handy mid-set when you're moving and dancing.
- A **haptic detent** ticks on every whole BPM (every 0.1 in fine mode), with a firmer thud on the flip, and a brief on-screen **flash** of the theme's contrary tone partners each tick.

## Reading the beat

- The big number shows **half** of your source BPM by default; a **single tap** flips to **double** (e.g. for the drop). Tap again to go back.
- The motion always speaks two rhythms at once — the **result** tempo (bold) and your **source** tempo (faint) — so you can *see* the half/double relationship as two overlapping rates.
- **Two-finger tap** cycles the beat style; the choice is remembered:
  - **Orbit** — a glowing dot circles each ring once per beat, a metronome bent into a circle.
  - **Ripple** — each beat is born at the centre and expands outward as a fading ring.
  - **Sweep** — a bright arc sweeps around each ring once per beat, like radar.
  - **Pulse** *(default)* — two concentric rings breathe in and out on the beat, the inner one glowing.
  - **Bare** — nothing at all, just the number.

## Look & feel

- **12 themes**, each a *cross-hue journey* — the mesh-gradient background sweeps diagonally through three real hues (e.g. indigo → blue → teal) instead of dimming a single one, lit by a jewel accent. Every theme shifts between a HALF and a DOUBLE palette, and the ×2 / ×½ flip does something deliberate to the colour (a warm↔cool swap, a brightness lift, or a hue clash), crossfading as it goes.
- **Shake** the phone to change to a random theme; its name surfaces briefly to confirm.
- Your last BPM, mode, beat style, and theme are all remembered between launches.

Respects **Reduce Motion**: the background freezes and the rings hold still, with small dots blinking on each beat instead. (The *Bare* style stops the animation loop entirely — nothing but a still number.)

## Open the project

This project has no committed `.xcodeproj` — it's generated from `project.yml`
with [xcodegen](https://github.com/yonsm/XcodeGen):

```bash
cd beatmch             # the repo folder keeps the old name for now
xcodegen generate      # creates Doppio.xcodeproj
open Doppio.xcodeproj
```

Then press ▶ (set your signing team under *Signing & Capabilities* first if
running on a real device — haptics only fire on hardware, not the Simulator).

Requires Xcode 26+ / iOS 18+. Liquid Glass surfaces light up on iOS 26 and fall
back to a frosted material on iOS 18–25.

## Layout

```
Doppio/
├── DoppioApp.swift                   # app entry point
├── Views/
│   ├── ContentView.swift             # the whole screen: gestures, themes, composes the pieces
│   ├── PulseOrb.swift                # the beating hero: steady number + the five beat styles
│   └── TempoMeshBackground.swift     # drifting per-theme mesh, reduce-motion aware
├── ViewModels/BPMViewModel.swift     # state, math, persistence
├── Services/HapticsEngine.swift      # primed haptic generators
├── Theme/
│   ├── Theme.swift                   # the 12 themes + their HALF/DOUBLE palettes
│   └── ThemeContrast.swift           # contrast-aware ink so text stays readable
├── Helpers/
│   ├── GlassSurface.swift            # Liquid Glass (iOS 26) with material fallback
│   └── ShakeDetector.swift           # shake-to-change-theme bridge to UIKit
└── Assets.xcassets                   # accent color + app icon slot
```
