import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        content
            .background { PaperBackground() }
            // The palette is light-only. In dark mode the system chrome (search
            // keyboard, search field, nav titles) draws white over the cream
            // paper and becomes unreadable, so pin the whole app to light.
            .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var content: some View {
        switch app.phase {
        case .loading:
            SplashView()
        case .failed:
            ErrorView { app.retry() }
        case .pickingLanguage:
            LanguagePickerView()
        case .ready:
            AdaptiveNavigation()
        }
    }
}

/// Universal shell: regular widths (iPad full screen, wide Split View,
/// Stage Manager) get the sidebar split view; compact widths (iPhone,
/// iPad Slide Over, narrow Split View) get the classic bottom tab bar.
private struct AdaptiveNavigation: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            MainSplitView()
        } else {
            MainTabs()
        }
    }
}

/// Compact shell: the original bottom tab bar — one NavigationStack per
/// section so each keeps its own back stack, exactly like the split view.
struct MainTabs: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        TabView(selection: $app.selectedSection) {
            NavigationStack(path: $app.homePath) {
                HomeView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.home])
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(app.s[.home], systemImage: "house.fill") }
            .tag(AppSection.home)

            NavigationStack(path: $app.chaptersPath) {
                ChaptersView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.chapters])
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(app.s[.chapters], systemImage: "books.vertical.fill") }
            .tag(AppSection.chapters)

            NavigationStack(path: $app.searchPath) {
                SearchView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.search])
            }
            .tabItem { Label(app.s[.search], systemImage: "magnifyingglass") }
            .tag(AppSection.search)

            NavigationStack(path: $app.kidsPath) {
                KidsView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.kids])
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(app.s[.kids], systemImage: "face.smiling.inverse") }
            .tag(AppSection.kids)

            NavigationStack {
                SettingsView()
                    .navigationTitle(app.s[.settings])
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(app.s[.settings], systemImage: "gearshape.fill") }
            .tag(AppSection.settings)
        }
        .tint(Palette.leaf)
    }
}

/// Splash shown while the manifest/first payload loads.
struct SplashView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image("Emblem")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)
            Text(app.s[.appName])
                .fifiFont(.largeTitle, weight: .heavy)
                .foregroundStyle(Palette.leafDeep)
            Text(app.s[.tagline])
                .fifiFont(.title3)
                .foregroundStyle(Palette.inkDim)
            ProgressView()
                .tint(Palette.leafDeep)
                .padding(.top, 8)
                .accessibilityLabel(app.s[.loading])
        }
        .padding()
    }
}

/// iPad shell: branded sidebar (collapsible via the split-view control or the
/// ⌘ shortcuts) + a detail column with an independent NavigationStack per
/// section, so each keeps its own back stack exactly like the iPhone tabs.
/// In compact widths (Slide Over, narrow Split View) the split view collapses
/// and the sidebar is revealed with the standard back chevron / edge swipe.
struct MainSplitView: View {
    @EnvironmentObject private var app: AppState
    /// Sidebar always on in regular widths (portrait AND landscape — iPad
    /// users expect it); collapses automatically in compact (Slide Over,
    /// narrow Split View) where the leading swipe reveals it again.
    @State private var columns: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            SidebarView()
        } detail: {
            detail
        }
        .tint(Palette.tomato)
        .accessibilityIdentifier("mainSplitView")
    }

    @ViewBuilder
    private var detail: some View {
        switch app.selectedSection {
        case .home:
            NavigationStack(path: $app.homePath) {
                HomeView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.home])
                    .fifiRootChrome()
            }
        case .chapters:
            NavigationStack(path: $app.chaptersPath) {
                ChaptersView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.chapters])
                    .fifiRootChrome()
            }
        case .search:
            NavigationStack(path: $app.searchPath) {
                SearchView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.search])
            }
        case .kids:
            NavigationStack(path: $app.kidsPath) {
                KidsView()
                    .fifiDestinations()
                    .navigationTitle(app.s[.kids])
                    .fifiRootChrome()
            }
        case .settings:
            NavigationStack {
                SettingsView()
                    .navigationTitle(app.s[.settings])
                    .fifiRootChrome()
            }
        }
    }
}

extension View {
    /// Root screens hide their nav bar in regular width (the sidebar is
    /// always visible and screens carry their own headers). In compact
    /// widths the bar stays visible so the system back-to-sidebar affordance
    /// exists.
    @ViewBuilder
    func fifiRootChrome() -> some View {
        RootChrome { self }
    }

    /// Shared navigation destinations for every section stack.
    func fifiDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .recipe(let id):
                RecipeDetailView(id: id)
            case .chapter(let id):
                ChapterDetailView(chapterID: id)
            case .kidsReady(let id):
                KidsReadyView(id: id)
            case .kidsSteps(let id):
                KidsStepsView(id: id)
            case .kidsDone(let id, let title):
                KidsDoneView(id: id, title: title)
            }
        }
    }
}

/// Hides the navigation bar in regular width only. In compact widths the bar
/// stays so collapsed split views still expose the back-to-sidebar chevron.
private struct RootChrome<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ViewBuilder var content: () -> Content

    var body: some View {
        if sizeClass == .regular {
            content().toolbar(.hidden, for: .navigationBar)
        } else {
            content()
        }
    }
}
