# Doppio — submission runbook

Ordered steps to get Doppio live. ✅ = already done in the repo. 👉 = you do it.

## 0. Status

- ✅ App is feature-complete; build is green.
- ✅ Privacy manifest (`Doppio/PrivacyInfo.xcprivacy`) — UserDefaults required-reason, no data collected.
- ✅ `ITSAppUsesNonExemptEncryption = false` (in `project.yml` → generated Info.plist).
- ✅ App icon: light / dark / tinted.
- ✅ Version 1.0, build 1; portrait-locked; iPhone-only.
- ✅ Website written in `docs/` (landing + privacy + support).
- ✅ Listing text ready in `store/METADATA.md`.
- ✅ You're enrolled in the Apple Developer Program.

## 1. Publish the website 👉

1. Push the repo (the `docs/` folder must be on the default branch).
2. GitHub → repo **Settings → Pages** → **Source: Deploy from a branch** → branch `main`, folder **`/docs`** → Save.
3. Wait ~1 min, then confirm these load:
   - `https://blhdes.github.io/doppio/`
   - `https://blhdes.github.io/doppio/privacy.html`
   - `https://blhdes.github.io/doppio/support.html`

> ⚠️ Free GitHub Pages requires a **public** repo. If Doppio is private and you're not on
> GitHub Pro, either make it public or host `docs/` in a separate public repo (and update
> the URLs in `store/METADATA.md` to match).

## 2. Screenshots 👉

Follow `store/SCREENSHOTS.md` — capture 5 on your device. (Offer: I can resize them to the exact 6.9" pixels.)

## 3. Build & upload 👉 (on your Mac)

1. `xcodegen generate` (regenerates `Doppio.xcodeproj` from `project.yml`).
2. Open `Doppio.xcodeproj`. Signing team is already `56BK7T2JG7`, automatic signing.
3. Select destination **Any iOS Device (arm64)**.
4. **Product → Archive**.
5. In the **Organizer**: select the archive → **Distribute App → App Store Connect → Upload**.
   - Export-compliance question won't appear (handled by the encryption flag).

## 4. Create the app record 👉 (appstoreconnect.apple.com)

1. **My Apps → + → New App**: Platform iOS, Name **Doppio**, Primary language English (U.S.),
   Bundle ID **app.doppio**, SKU `doppio-ios-001`.
2. Paste everything from `store/METADATA.md`:
   - Subtitle, promotional text, description, keywords.
   - Support URL, Marketing URL.
   - Category: **Music** (primary), **Utilities** (secondary).
   - Copyright (fill your name), Age rating → run the questionnaire, all "None" → **4+**.
3. **App Privacy**: "Do you collect data?" → **No** → label becomes *Data Not Collected*.
   Add the **Privacy Policy URL** (`…/privacy.html`).
4. Upload the **5 screenshots** to the 6.9" slot.
5. **Build**: select the build you uploaded in step 3 (may take ~15 min to finish processing).
6. Pricing → **Free**.
7. **Add for Review → Submit**.

## 5. After approval 👉

- Grab the App Store URL for Doppio.
- In `docs/index.html`, change the `<a class="badge soon" href="#">Coming to the App Store</a>`
  to the real link (and drop the `soon` class so it turns magenta). Re-push.
- Update README if you want a download badge.

---

### Quick reference
- Bundle ID: `app.doppio` • Team: `56BK7T2JG7` • Version/build: `1.0 (1)`
- Privacy: Data Not Collected • Category: Music / Utilities • Age: 4+
- Site: `https://blhdes.github.io/doppio/`
