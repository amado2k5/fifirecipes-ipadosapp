# FiFi Recipes — iOS & iPadOS (universal)

Native SwiftUI companion to [fifi.cooking](https://fifi.cooking), the
recipe site by Dr. Fatma / FiFi. Not a WebView wrapper: every screen is real
SwiftUI consuming the static JSON API at `https://fifi.cooking/data/` — the
same contract the Fire TV app uses (`docs/tv-api.md` in the `fifirecipes`
repo, reference client in `fifirecipes-amazonfire`). One universal binary:
iPhone gets the bottom tab bar, iPad gets the sidebar split view, and iPad
compact widths (Slide Over, narrow Split View) fall back to tabs.

- **Bundle ID:** `cooking.fifi.ipados` · **Min iOS/iPadOS:** 16 · **Swift:** 6
- **Devices:** iPhone + iPad (`TARGETED_DEVICE_FAMILY="1,2"`) — iPad, iPad
  mini, iPad Air, iPad Pro 11"/13", iPhone, portrait + landscape
- **Dependencies:** none — URLSession, WebKit, Foundation only

> [!NOTE]
> **This repo replaces [fifirecipes-ios](https://github.com/amado2k5/fifirecipes-ios),
> which is being archived.** That iPhone-only app (`cooking.fifi.ios`) has
> been folded in here: the iPhone tab-bar shell, its fixes and its
> translations all live in this universal app, CI runs the tests on both an
> iPad and an iPhone 17 simulator, and the support/privacy pages at
> `ipadosapp.fifi.cooking` cover iPhone and iPad. Make iPhone changes here.

## Build & test

```sh
# Build (simulator)
xcodebuild -project FifiRecipesPad.xcodeproj -scheme FifiRecipesPad \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' \
  build CODE_SIGNING_ALLOWED=NO

# Unit + UI tests
xcodebuild -project FifiRecipesPad.xcodeproj -scheme FifiRecipesPad \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' \
  test CODE_SIGNING_ALLOWED=NO
```

UI tests hit the live `fifi.cooking` API (the product is online-only).
Launch arguments supported for tests/screenshots:

| Arg | Effect |
|-----|--------|
| `-fifi.reset 1` | Clear persisted language → first-run picker |
| `-fifi.language ar` | Preselect a language |
| `-fifi.apiOrigin <url>` | Point the API elsewhere (offline test) |

## Architecture

```
FifiRecipesPad/
├── App/            @main App (+ CommandMenu shortcuts), RootView (phase
│                   router → NavigationSplitView), AppState (section +
│                   per-section NavigationPaths, Universal-Link routing)
├── API/            APIClient — actor; manifest-driven endpoint templates,
│                   ?v= versioned requests, in-flight + URLCache caching,
│                   kids English-fallback on 404; AssetURL resolver
├── Models/         Codable models mirroring src/api/types.ts
├── Localization/   Strings (25 languages from bundled ui-strings.json,
│                   allergen map) + RecipeLocalization (ar master-fallback,
│                   never-English cultural notes, ui.text/textEn precedence)
├── Theme/          Palette (fresh-market colors) + FifiFont
│                   (per-language OFL faces, Dynamic Type via text styles)
├── Components/     RemoteImage (AsyncImage + branded placeholder), cards,
│                   error/skeleton states, ZoomableImage (pinch/double-tap),
│                   YouTubePlayer (WKWebView sheet), CardActions (context
│                   menu + hover), Compat (iPadOS-16 API shims)
├── Screens/        SidebarView (branded column), LanguagePicker, Home,
│                   Chapters(+detail), Search, RecipeDetail, Settings
└── KidsMode/       Kids catalogue, ready checklist, step-by-step,
                    celebration, 190 bundled PNG illustrations, Baloo fonts
```

## iPad features

- **`NavigationSplitView` shell** — branded sidebar (`SidebarView`) +
  per-section `NavigationStack` detail. Sidebar stays visible in regular
  width in both orientations (`.doubleColumn`); in compact widths (Slide
  Over, narrow Split View) it collapses with the standard back chevron /
  edge swipe, and root screens keep their nav bar so the affordance is
  always reachable.
- **Keyboard & trackpad** — ⌘1–⌘5 switch sections, ⌘F jumps to search
  (`CommandMenu` in `FifiRecipesPadApp`), `.hoverEffect` on cards and
  sidebar rows, context menus with a ShareLink, and drag-to-other-apps
  carrying the recipe's Universal Link — handy in Split View.
- **Adaptive layout** — `LazyVGrid(.adaptive)` and size-class-driven card
  widths; two-column recipe detail (media/meta left, ingredients+steps
  right) when there's room; content max-widths keep lines readable on 13".
- **Multitasking** — multi-scene (`UIApplicationSupportsMultipleScenes`),
  all orientations, resizable down to Slide Over width.
- **Pinch-to-zoom** — recipe hero images zoom via `ZoomableImage`
  (pinch + double-tap).

### Localization

25 languages, RTL (`ar`, `ur`, `fa`, `ps`, `he`, `ku`) flips layout via
`.environment(\.layoutDirection)` — the sidebar mirrors to the trailing
edge automatically. UI strings and allergen names are bundled from the TV
repo's `strings.ts` (via `scripts/export-strings.cjs` → `ui-strings.json`,
with iPad wording overrides). Fonts are bundled OFL Google Fonts selected
per language: Plus Jakarta Sans (Latin), Tajawal (ar/RTL), Vazirmatn (fa),
Noto Nastaliq Urdu (ur), Heebo (he), Baloo 2/Baloo Bhaijaan 2 (kids mode) —
all through Dynamic Type text styles, no fixed point sizes for body text.

### iPad adaptivity notes

- Size-class-driven layout everywhere; no `UIScreen.main.bounds`, no
  `userInterfaceIdiom`, no orientation checks.
- Manual adaptivity checklist: iPad mini portrait+landscape, iPad, Air 11"
  and 13", Pro 11" and 13", Split View (~1/3 and ~2/3), Stage Manager
  window sizes, largest Dynamic Type.
- `.searchable` uses `.navigationBarDrawer(displayMode: .always)` — in a
  split-view detail column the default drawer mode can collapse the field
  away entirely.
- iPadOS 16 shims live in `Components/Compat.swift` (e.g.
  `scrollTargetBehavior` fallback).

### Videos

Recipe videos are YouTube. In-app playback uses a `WKWebView` sheet loading
`https://www.youtube-nocookie.com/embed/{id}?rel=0&playsinline=1`
(fullscreen-capable), with an "Open in YouTube" secondary action. The
nocookie domain avoids tracking cookies until the user presses play — see
`site/privacy.html`.

## Privacy posture

No accounts, no analytics, no crash SDKs, no tracking. App Store privacy
label: **Data Not Collected**. On-device storage is limited to the selected
language (UserDefaults) and URL caches. `PrivacyInfo.xcprivacy` is bundled;
`ITSAppUsesNonExemptEncryption=false` (plain HTTPS).

## CI

- `.github/workflows/pages.yml` — deploys `site/` to GitHub Pages
  (`ipadosapp.fifi.cooking`) on pushes to `main`.
- `.github/workflows/ipad-ci.yml` — builds and runs the full test suite on
  `macos-latest` on an iPad simulator. Note: private repos get limited free
  GitHub Actions minutes and macOS runners bill at 10× — the workflow is
  also `workflow_dispatch`-able so it can be run on demand.

## Repo layout

```
site/           Static Pages site (landing, support.html, privacy.html,
                CNAME → ipadosapp.fifi.cooking)
docs/           screenshots/ contact sheet
scripts/        resource generators (ui-strings export, kids-art render)
STORE.md        App Store submission checklist + current answers
```

## App Store status

See `STORE.md`. Summary: app is build- and feature-complete for a 1.0
submission; remaining items need an Apple Developer account (Team ID for
AASA/Universal Links, screenshots from a real device, App Store Connect
record).
