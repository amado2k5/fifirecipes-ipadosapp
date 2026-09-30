# App Store submission checklist — FiFi Recipes (universal) 1.0

## Identity

| Item | Value |
|------|-------|
| Name | FiFi Recipes |
| Bundle ID | `cooking.fifi.ipados` |
| Version | 1.0 |
| Category | **Food & Drink** (NOT Kids — kids mode is a feature, app is for grown-ups) |
| Copyright | © 2026 Dr. Fatma / FiFi |
| Support URL | https://ipadosapp.fifi.cooking/support.html |
| Privacy URL | https://ipadosapp.fifi.cooking/privacy.html |
| Marketing URL | https://ipadosapp.fifi.cooking |

## Technical compliance (done in-repo)

- [x] Native SwiftUI app, not a hosted WebView (Guideline 4.2)
- [x] Universal iPhone + iPad (`TARGETED_DEVICE_FAMILY="1,2"`), min iOS 16
- [x] Adaptive navigation: `TabView` on compact (iPhone, Slide Over),
      `NavigationSplitView` sidebar on regular width
- [x] `PrivacyInfo.xcprivacy` — no required-reason APIs beyond declarations
- [x] `ITSAppUsesNonExemptEncryption = false` (plain HTTPS only)
- [x] `UILaunchScreen` configured
- [x] All four orientations; `UIApplicationSupportsMultipleScenes` for
      Split View / Stage Manager / multi-window
- [x] `NavigationSplitView` iPad-native navigation (not a scaled-up iPhone
      tab bar); resizable down to Slide Over width
- [x] App icon: single 1024×1024 modern icon, no alpha channel
- [x] No third-party SDKs, no analytics, no tracking
- [x] External keyboard shortcuts (⌘1–5 sections, ⌘F search), pointer hover,
      context menus, drag-out — iPad hardware affordances per HIG

## Accessibility

- [x] Dynamic Type via text styles (bundled fonts scale with system)
- [x] VoiceOver labels/hints on cards and controls; sidebar rows are single
      accessible elements (icon merged in)
- [x] RTL mirroring for ar/ur/fa/ps/he/ku — sidebar mirrors to trailing edge
- [x] ≥44×44pt hit targets, ≥4.5:1 contrast on the cream palette
- [x] Reduce Motion honored (confetti/shimmer disabled); Reduce Transparency

## Age rating answers

- Objectionable content: **none**
- Unrestricted web access: **NO** — content is curated JSON from
  fifi.cooking plus controlled youtube-nocookie.com embeds
- User-generated content / social: **none**
- Kids category: **NO**

## Privacy nutrition label

**Data Not Collected** — no accounts, identifiers, usage data, or
diagnostics leave the device. YouTube embeds use `youtube-nocookie.com`
(privacy-enhanced mode); Google's policy applies inside the player once the
user presses play — disclosed in `site/privacy.html`. Verify at submission
that no embed/analytics have crept in.

## Blocked on Apple Developer account

- [ ] Enroll ($99/yr, individual or org + D-U-N-S)
- [ ] Real **Team ID** → replace `TEAMID` placeholder in the backend repo
      (`scripts/generate-public-index.ts`, `APPLE_TEAM_ID`) and redeploy —
      the AASA file already claims `/recipe/*`, `/chapter/*`, `/kids/*`
      (shared by both app variants; `cooking.fifi.ios` +
      `cooking.fifi.ipados` are both listed so either build opens links)
- [ ] App Store Connect app record (SKU: `cooking.fifi.ipados`)
- [ ] Signing + archive + upload via Xcode
- [ ] Screenshots: ready in `store/` — **iPhone 6.9" (1320×2868)**,
      **iPhone 6.5" (1284×2778)**, **iPad 13" (2064×2752)**
- [ ] App Review notes: mention test account not needed (no login),
      videos require network
