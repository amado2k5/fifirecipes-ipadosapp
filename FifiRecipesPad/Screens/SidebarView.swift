import SwiftUI

/// Branded iPad sidebar — the fresh-market header up top, then the five
/// sections as a selectable List. Mirrors automatically in RTL.
/// Rows carry stable identifiers for UI tests and keyboard navigation.
struct SidebarView: View {
    @EnvironmentObject private var app: AppState

    /// `List(selection:)` single-select binds `Selection?` — map through so
    /// tapping the current row (nil) never deselects the visible section.
    private var selection: Binding<AppSection?> {
        Binding(
            get: { app.selectedSection },
            set: { if let s = $0 { app.selectedSection = s } }
        )
    }

    var body: some View {
        List(selection: selection) {
            Section {
                row(.home, title: app.s[.home], icon: "house.fill")
                row(.chapters, title: app.s[.chapters], icon: "books.vertical.fill")
                row(.search, title: app.s[.search], icon: "magnifyingglass")
                row(.kids, title: app.s[.kids], icon: "face.smiling.inverse")
                row(.settings, title: app.s[.settings], icon: "gearshape.fill")
            } header: {
                header
            } footer: {
                if let version = app.manifest?.version {
                    Text("fifi.cooking · \(version)")
                        .fifiFont(.caption)
                        .foregroundStyle(Palette.inkDim)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
            }
        }
        .listStyle(.sidebar)
        .tint(Palette.leaf)
        .navigationTitle(app.s[.appName])
        .accessibilityIdentifier("sidebar")
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image("Emblem")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Palette.ink.opacity(0.12), radius: 8, y: 4)
                .accessibilityHidden(true)
            Text(app.s[.appName])
                .fifiFont(.title2, weight: .heavy)
                .foregroundStyle(Palette.leafDeep)
            Text(app.s[.tagline])
                .fifiFont(.footnote)
                .foregroundStyle(Palette.inkDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .textCase(nil)
    }

    private func row(_ section: AppSection, title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .fifiFont(.headline, weight: .medium)
            .foregroundStyle(Palette.ink)
            .padding(.vertical, 4)
            // Merge label + icon into ONE row element so the identifier lands
            // on a hittable element (not the 22pt icon image) and VoiceOver
            // reads just the section title rather than the symbol name.
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .tag(section)
            .accessibilityIdentifier("nav-\(name(of: section))")
    }

    private func name(of section: AppSection) -> String {
        switch section {
        case .home: return "home"
        case .chapters: return "chapters"
        case .search: return "search"
        case .kids: return "kids"
        case .settings: return "settings"
        }
    }
}
