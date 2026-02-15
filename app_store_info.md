# Blue Screen of Death — App Store Submission Info

Everything you need to copy-paste for App Store Connect submission.

---

## App Name

**Blue Screen of Death** (20 characters)

Alternatives if rejected:
- Blue Screen Breaks
- BSoD: Screen Break Timer

## Subtitle (max 30 chars)

**Nostalgic Screen Break Timer** (28 chars)

## Bundle ID

`com.winsim.bluescreenofdeath`

## Version

1.0.0 (Build 1)

## Category

- **Primary:** Lifestyle
- **Secondary:** Utilities

## Age Rating

**4+** — No objectionable content. No violence, no mature themes, no user-generated content, no web access.

## Pricing

Free (no in-app purchases)

---

## Promotional Text (max 170 chars)

> Your eyes deserve a break. Blue Screen of Death turns computing nostalgia into a mindfulness tool — 5 retro styles, smart scheduling, and zero data collection. Free forever.

---

## Description (max 4000 chars)

> Your eyes weren't designed for screens. Every 20 minutes of close-up focus, optometrists recommend looking at something 20 feet away for 20 seconds — the 20-20-20 rule. But who actually remembers to do that?
>
> Blue Screen of Death does.
>
> At the interval you choose, a full-screen blue screen overlay gently interrupts your work, reminding you to look away, refocus your eyes, and take a breath. Press any key or click anywhere to dismiss it instantly. Then get back to what you were doing — with fresher eyes.
>
> What makes it different? Instead of yet another boring notification bubble, your screen breaks arrive as lovingly recreated retro crash screens. Each one is procedurally generated, so no two are ever the same.
>
> FIVE VISUAL STYLES
>
> • Modern: The iconic :( emoticon with a progress percentage and QR code. Clean, minimal, unmistakable.
> • Classic: The legendary wall of white-on-blue text advising you to "restart your computer." Nostalgia in its purest form.
> • Classic Dump: Dense hex dumps and driver tables straight from the NT4/2000 era. For the technically nostalgic.
> • Mojibake: A screen full of garbled Unicode — katakana, Cyrillic, box-drawing characters, and symbols in beautiful chaos.
> • CyberWin 2070: A retrofuturistic fever dream. Neon pink and cyan syntax-highlighted stack traces over procedurally generated backgrounds — wireframe mountains, outrun sunsets, cyberpunk cityscapes, or perspective grids. CRT scan lines complete the look.
>
> Choose a style, or set it to Random and be surprised every time.
>
> SMART SCHEDULING
>
> • Preset intervals: 20 minutes, 1 hour, 2 hours, or 3 hours
> • Random intervals: centered around ~1.5 hours or ~3 hours for natural variation
> • Custom interval: any value from 1 to 240 minutes
> • Custom schedule: pick which days and hours are active (e.g., weekdays 9 AM–5 PM only)
> • Lunch reminder: a separate daily reminder at a time you choose
>
> DESIGNED FOR REAL LIFE
>
> • Screen share suppression: automatically detects Zoom, Teams, Slack, and other conferencing apps, and pauses reminders so you are never embarrassed in a meeting
> • Instant dismiss: any keypress or mouse click closes the overlay immediately
> • Menu bar only: lives as a tiny "0x" icon in your menu bar. No dock icon, no windows, no clutter
> • Style preview: hover over style names in the menu to see a live preview
>
> PRIVACY BY DESIGN
>
> Blue Screen of Death collects zero data. None. It makes no network requests, has no analytics, no tracking, no accounts, and no ads. Your preferences are stored locally on your Mac and nowhere else.
>
> UNIQUE EVERY TIME
>
> All crash text, hex dumps, error codes, stack traces, QR codes, and background scenes are procedurally generated at display time. The QR codes encode randomized wellness messages like "look at the sky" and "remember to blink." You will never see the same screen twice.
>
> REQUIREMENTS
>
> • macOS 13 Ventura or later
> • Lives in the menu bar — no dock icon
>
> Take a break. Your eyes will thank you.

---

## Keywords (max 100 chars)

```
screen break,eye care,20-20-20,blue screen,BSOD,retro,nostalgia,break timer,eye strain,wellbeing
```

(98 characters)

---

## What's New (Version 1.0)

> Hello, world.
>
> Blue Screen of Death is a screen break reminder for your eyes, disguised as computing nostalgia. Here's what's inside:
>
> • 5 visual styles: Modern, Classic, Classic Dump, Mojibake, and CyberWin 2070
> • Configurable intervals from 20 minutes to 4 hours, plus random and custom options
> • Custom schedule: choose active days and hours
> • Screen share suppression: auto-pauses during Zoom, Teams, and other conferencing apps
> • Lunch reminder: a separate daily nudge at the time you choose
> • Style preview on hover
> • Zero data collection, zero network access
>
> Take a break. Your eyes will thank you.

---

## Review Notes (for App Store reviewers)

```
WHAT THIS APP IS

Blue Screen of Death is a screen break reminder app for eye health,
inspired by the 20-20-20 rule recommended by optometrists. It displays
full-screen overlays at configurable intervals to remind users to look
away from their screens. The overlays are styled as nostalgic,
retro-computing-themed screens as a humorous and engaging alternative
to standard notification-based reminders.

The app is NOT a prank app, crash simulator, or system tool. It does
not interact with the operating system in any way beyond displaying
its own overlay window and reading the list of running applications
(to detect screen sharing). It cannot cause any system instability.

HOW TO TEST

1. Launch the app. A "0x" icon appears in the menu bar. No dock icon
   will appear (this is intentional — it uses .accessory activation
   policy / LSUIElement).

2. Left-click the "0x" menu bar icon to trigger an immediate blue
   screen overlay. Press any key or click anywhere to dismiss it.

3. Right-click the "0x" icon to open the configuration menu:
   - Toggle "Enabled" on/off
   - Change the visual style (hover over style names to see live
     previews)
   - Set the interval (preset or custom)
   - Configure a custom schedule (days and hours)
   - Toggle screen share suppression
   - Configure the lunch reminder

4. To see all 5 styles: right-click > Style > select each one, then
   left-click the icon. Styles: Modern, Classic, Classic Dump,
   Mojibake, CyberWin 2070.

ADDRESSING POTENTIAL CONCERNS

- Name: "Blue Screen of Death" is a generic, colloquial computing
  term in common usage since the 1990s. It is not trademarked.
  Microsoft's official terminology is "Stop error" or "bug check."

- Misleading content: The app does not simulate an actual system
  crash. The overlay is clearly an app window (it appears above all
  other windows but dismisses instantly on any input). All displayed
  text uses the fictional "Winsome" brand — no Microsoft, Windows,
  or Apple trademarks appear anywhere in the app.

- Screen-level overlay: The window uses NSWindow.Level.screenSaver
  and dismisses on any keyDown, leftMouseDown, or rightMouseDown
  event. It cannot trap the user.

- Privacy: The app makes zero network requests. It has no networking
  entitlements. The only system API beyond standard AppKit is
  NSWorkspace.shared.runningApplications to detect conferencing apps
  for the screen share suppression feature.

- QR codes: The QR codes encode randomized wellness-themed URLs on
  the fictional domain "insights.vom" (e.g.,
  "https://insights.vom/lookatthesky/takeadeepbreath"). These URLs
  do not resolve to real websites.
```

---

## Privacy Policy

```
Privacy Policy for Blue Screen of Death

Last updated: February 15, 2026

Blue Screen of Death ("the App") is developed by [Your Name / Entity].

DATA COLLECTION

The App does not collect, store, transmit, or share any personal data
or usage data whatsoever. Specifically:

- No personal information is collected (name, email, location, device
  identifiers, etc.)
- No usage analytics or crash reporting data is collected
- No data is transmitted over the network. The App makes zero network
  requests.
- No cookies, tracking pixels, or advertising identifiers are used
- No third-party SDKs, analytics frameworks, or advertising frameworks
  are included

USER PREFERENCES

The App stores your configuration preferences (such as your chosen
interval, visual style, and schedule settings) locally on your device
using macOS UserDefaults. This data never leaves your device and is not
accessible to the developer or any third party.

THIRD-PARTY SERVICES

The App does not integrate with any third-party services.

CHILDREN'S PRIVACY

The App does not collect any data from any user, including children.

CHANGES TO THIS POLICY

If this policy changes, the updated version will be posted at the
support URL. Since the App collects no data, material changes are
unlikely.

CONTACT

If you have questions about this privacy policy, contact
[your email address].
```

---

## App Store Privacy Questionnaire

When filling out the App Privacy section in App Store Connect:

- **Do you or your third-party partners collect data from this app?** → **No**

That's it. No further questions needed since no data is collected.

---

## Support URL

Recommended: Create a GitHub Pages site or simple landing page with:
- Brief app description
- Privacy policy (copy from above)
- Contact email
- FAQ

Example: `https://[username].github.io/blue-screen-of-death`

---

## Screenshots (5 recommended)

1. **Modern Style (full screen)** — Caption: "A gentle reminder to look away. Dismiss with any keypress."
2. **CyberWin 2070 Style (full screen)** — Caption: "CyberWin 2070: procedurally generated retrowave. Never the same twice."
3. **Menu Bar Configuration** — Caption: "All settings in your menu bar. No dock clutter, no fuss."
4. **Classic or Mojibake Style (full screen)** — Caption: "The classic wall of text. A love letter to computing history."
5. **Custom Schedule View** — Caption: "Smart scheduling: active hours, screen share suppression, lunch reminders."

Screenshot sizes needed for Mac App Store:
- 1280 x 800 pixels
- 1440 x 900 pixels
- 2560 x 1600 pixels
- 2880 x 1800 pixels

---

## App Store Compliance Checklist

### Already Done
- [x] App Sandbox enabled
- [x] No trademarked terms in app content (uses "Winsome" brand)
- [x] Privacy Manifest (`PrivacyInfo.xcprivacy`) with UserDefaults `CA92.1`
- [x] `LSApplicationCategoryType` added to Info.plist (`public.app-category.lifestyle`)
- [x] `LSUIElement` = true (menu bar only app)
- [x] `LSMinimumSystemVersion` = 13.0
- [x] App icon (.icns) with all required sizes (16-1024px)
- [x] 68 unit tests passing
- [x] Zero network access
- [x] No third-party dependencies

### Still Needed Before Submission
- [ ] Apple Developer Program membership ($99/year)
- [ ] Create Xcode project (for signing, archiving, and uploading)
- [ ] Enable Hardened Runtime in Xcode
- [ ] Code signing with "3rd Party Mac Developer Application" certificate
- [ ] Provisioning profile for `com.winsim.bluescreenofdeath`
- [ ] Build universal binary (arm64 + x86_64)
- [ ] Privacy policy hosted at a public URL
- [ ] Support URL hosted at a public URL
- [ ] Take screenshots at required sizes
- [ ] Archive and upload via Xcode Organizer or Transporter

### Recommended Before Submission
- [ ] Add small "Screen break — press any key" text at bottom of overlays
- [ ] Consider first-launch onboarding dialog explaining what the app does

---

## Creating the Xcode Project

The project uses SPM but needs an Xcode project for App Store submission:

1. Open Xcode → File → New → Project → macOS → App
2. Product Name: `BlueScreenOfDeath`, Org ID: `com.winsim`
3. Delete auto-generated source files
4. Drag existing `Sources/BlueScreenOfDeath/*.swift` into the project (don't copy)
5. Add `Info.plist`, `BlueScreenOfDeath.entitlements`, `PrivacyInfo.xcprivacy`, and `Resources/AppIcon.icns`
6. Configure Build Settings:
   - `INFOPLIST_FILE` = `Sources/BlueScreenOfDeath/Info.plist`
   - `CODE_SIGN_ENTITLEMENTS` = `Sources/BlueScreenOfDeath/BlueScreenOfDeath.entitlements`
   - `ENABLE_HARDENED_RUNTIME` = `YES`
   - `MACOSX_DEPLOYMENT_TARGET` = `13.0`
   - `ONLY_ACTIVE_ARCH` = `NO` (for release builds)
7. Select your Team for automatic signing
8. Product → Archive → Distribute App → App Store Connect

Keep the `Package.swift` and `Makefile` for development/testing workflows.

---

## Key Risks and Mitigations

| Risk | Level | Mitigation |
|------|-------|------------|
| Name "Blue Screen of Death" rejected | Medium | Not trademarked; prepare alternatives. Clear description emphasizes wellness. |
| Full-screen overlay flagged as deceptive | Medium-High | Add "screen break" dismissal hint text. Detailed review notes. |
| Crash-simulation text too realistic | Medium | Uses fictional "Winsome" brand. Consider softening Modern style text. |
| Missing privacy manifest | Resolved | `PrivacyInfo.xcprivacy` created with `CA92.1` for UserDefaults |
| No Xcode project | Action needed | Create `.xcodeproj` following steps above |
| No hardened runtime | Action needed | Enable in Xcode project |
