# App Store Connect — Doppio metadata

Copy-paste sources for the App Store listing. Character limits noted in `[brackets]`.
Fill the two `<<…>>` placeholders before submitting.

---

## App information

- **Name** `[30]`: `Doppio`
- **Subtitle** `[30]`: `Half-time & double-time BPM`
  - *Alt (more evocative):* `A living metronome for DJs`
- **Bundle ID**: `app.doppio`
- **SKU** (internal, your choice): `doppio-ios-001`
- **Primary language**: English (U.S.)
- **Primary category**: **Music**
- **Secondary category**: **Utilities**
- **Copyright**: `© 2026 <<your name or company>>`
- **Age rating**: **4+** (no objectionable content — all "None" in the questionnaire)

## URLs

- **Marketing URL**: `https://blhdes.github.io/doppio/`
- **Support URL**: `https://blhdes.github.io/doppio/support.html`
- **Privacy Policy URL**: `https://blhdes.github.io/doppio/privacy.html`

---

## Promotional text `[170]`
*(Editable any time without a new review — use it for timely notes.)*

```
A living metronome for DJs. See your track's tempo and its half/double partner as two overlapping rhythms — read the beat at a glance, no maths mid-mix.
```

## Keywords `[100]`
*(Comma-separated, no spaces. Don't repeat words already in the name/subtitle — Apple indexes those too.)*

```
DJ,tempo,metronome,beatmatch,beat,counter,mixing,DJing,pitch,track,club,set,rave,bpm tool
```

## Description `[4000]`

```
Doppio is a minimalist BPM tool for DJs — a living metronome, not a calculator.

Named after "doppio movimento," the score marking for "play twice as fast," with a nod to the double espresso. Doppio shows your track's tempo and its half-time / double-time partner as two overlapping rhythms, so you can SEE the relationship instead of doing the maths in your head mid-mix.

SETTING THE TEMPO
• Swipe up or down anywhere to set the BPM — fractional, 0.1 steps, 20–300 range.
• A faint scale on the right edge shows where you are while you drag — grab it to jump straight to an absolute BPM.
• Hold a second finger to slip into fine mode: the swipe slows about 10× so a small move nudges just a decimal — handy mid-set when you're moving and dancing.
• A haptic detent ticks on every whole BPM (every 0.1 in fine mode), with a firmer thud on the flip.

READING THE BEAT
• The big number shows HALF of your source tempo by default; a single tap flips to DOUBLE — for the drop. Tap again to go back.
• The motion always speaks two rhythms at once — the result tempo (bold) and your source tempo (faint) — so the half/double relationship is something you can watch, not work out.
• Two-finger tap cycles five beat styles, and your choice is remembered:
   – Orbit: a glowing dot circles once per bar, ticking brighter on each beat.
   – Ripple: a ring swells from the centre to the edge over a whole bar.
   – Sweep: a bright arc sweeps around once per beat, like radar.
   – Pulse: two concentric rings breathe in and out on the beat.
   – Bare: nothing at all — just the number.

LOOK & FEEL
• 12 themes, each a cross-hue journey — the background sweeps through three real hues lit by a jewel accent, and the ×2 / ×½ flip does something deliberate to the colour.
• Shake the phone to change to a random theme; its name surfaces briefly to confirm.
• Your last BPM, mode, beat style, and theme are all remembered between launches.
• Respects Reduce Motion, and fully supports VoiceOver.

QUIET BY DESIGN
No account. No network. No ads. No tracking. Nothing leaves your device — your settings live only on your iPhone.

The big number stays rock-steady and glanceable in a dark booth, because the one thing a DJ needs at the drop is the number, right now.
```

## Description — short alternative `[4000]`
*(Same pitch, trimmed for skimming — the first two lines carry it.)*

```
A living metronome for DJs — not a calculator.

See your track's tempo and its half/double partner as two overlapping rhythms. Read the relationship at a glance — no maths mid-mix.

• Swipe to set the BPM
• Tap to flip ×½ / ×2
• Second finger = decimal-fine
• Haptic tick on every beat
• 5 beat visuals · 12 themes · shake to change

No account. No ads. No tracking. Just the number — rock-steady, glanceable in a dark booth.
```

## What's New (version 1.0) `[4000]`

```
First release. Thanks for trying Doppio — if you have feedback or a request, email agomezurrea@gmail.com.
```

---

## Privacy (App Store Connect → App Privacy)

- **"Do you or your third-party partners collect data from this app?"** → **No**
- Resulting privacy label: **Data Not Collected**
- This matches the in-app `PrivacyInfo.xcprivacy` (no tracking, no collected data types; UserDefaults declared with required reason `CA92.1`).

## Build / version

- **Marketing version**: `1.0`  •  **Build**: `1`  (set in `project.yml`)
- **Encryption**: `ITSAppUsesNonExemptEncryption = false` is in the build, so the export-compliance question is auto-answered as exempt.
