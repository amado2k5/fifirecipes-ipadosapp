import Foundation
import SwiftUI

/// Routes pushed on each section's NavigationStack — one type shared across
/// sections so recipe detail is reachable from Home, Chapters, Search and Kids.
enum AppRoute: Hashable {
    case recipe(String)
    case chapter(Int)
    case kidsReady(String)
    case kidsSteps(String)
    case kidsDone(id: String, title: String)
}

/// Sidebar sections. Named AppSection to avoid colliding with SwiftUI.Tab/Section.
enum AppSection: Hashable { case home, chapters, search, kids, settings }

@MainActor
final class AppState: ObservableObject {
    enum Phase: Equatable {
        case loading
        case pickingLanguage
        case ready
        case failed
    }

    @AppStorage("fifi.language") private var storedLang = ""

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var manifest: TvManifest?
    @Published private(set) var lang = "en"
    @Published private(set) var index: [String: RecipeCard] = [:]
    @Published private(set) var feed = Feed(rows: [])
    @Published private(set) var chapters: [Chapter] = []
    @Published private(set) var kids: [String: KidsCard] = [:]
    @Published private(set) var images: ImagesMap = [:]

    /// Per-section navigation — keeps standard NavigationSplitView +
    /// NavigationStack chrome, which adapts to Split View, Slide Over and
    /// Stage Manager window sizes for free.
    @Published var selectedSection: AppSection = .home
    @Published var homePath = NavigationPath()
    @Published var chaptersPath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var kidsPath = NavigationPath()

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    var s: Strings { Strings(lang: lang) }

    /// Section selection callable from Command menus / keyboard shortcuts,
    /// whose action closures run in a nonisolated context.
    nonisolated func selectSection(_ section: AppSection) {
        Task { @MainActor in self.selectedSection = section }
    }

    /// Site-relative asset path or external URL → absolute, manifest-versioned
    /// URL so a deploy invalidates URLCache entries.
    func assetURL(_ path: String?) -> URL? {
        AssetURL.resolve(path, version: manifest?.version)
    }

    var langInfo: LanguageInfo? { manifest?.languages.first { $0.code == lang } }

    var isRTL: Bool {
        langInfo?.isRTL ?? FifiFonts.rtlLanguages.contains(lang)
    }

    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }

    /// Boot: manifest first (it carries the language list for the picker),
    /// then either the stored language's data or the first-run picker.
    func start() {
        guard phase == .loading else { return }
        Task { await bootstrap() }
    }

    func retry() {
        phase = .loading
        Task { await api.clearCache(); await bootstrap() }
    }

    private func bootstrap() async {
        do {
            if manifest == nil { manifest = try await api.loadManifest() }
            let stored = storedLang
            let known = manifest?.languages.contains(where: { $0.code == stored }) ?? false
            if stored.isEmpty || !known {
                phase = .pickingLanguage
                return
            }
            try await loadLanguageData(stored)
            phase = .ready
        } catch {
            phase = .failed
        }
    }

    func setLanguage(_ code: String) {
        storedLang = code
        phase = .loading
        Task { await switchLanguage(code) }
    }

    private func switchLanguage(_ code: String) async {
        do {
            try await loadLanguageData(code)
            phase = .ready
        } catch {
            phase = .failed
        }
    }

    private func loadLanguageData(_ code: String) async throws {
        lang = code
        async let i = api.index(lang: code)
        async let f = api.feed(lang: code)
        async let c = api.chapters(lang: code)
        async let k = api.kids(lang: code)
        async let im = api.images()
        index = Dictionary(uniqueKeysWithValues: try await i.map { ($0.id, $0) })
        feed = try await f
        chapters = try await c
        kids = Dictionary(uniqueKeysWithValues: try await k.map { ($0.id, $0) })
        images = (try? await im) ?? images
    }

    // MARK: - Universal Links

    /// applinks:fifi.cooking/recipe/{id}, /chapter/{n}, /kids/{id}
    func handleDeepLink(_ url: URL) {
        let parts = url.path.split(separator: "/").map(String.init)
        guard let kind = parts.first, let rawID = parts.dropFirst().first,
              let id = rawID.removingPercentEncoding
        else { return }
        switch kind {
        case "recipe":
            selectedSection = .home
            homePath = NavigationPath()
            homePath.append(AppRoute.recipe(id))
        case "chapter":
            selectedSection = .chapters
            chaptersPath = NavigationPath()
            if let n = Int(id) { chaptersPath.append(AppRoute.chapter(n)) }
        case "kids":
            selectedSection = .kids
            kidsPath = NavigationPath()
            kidsPath.append(AppRoute.kidsReady(id))
        default:
            break
        }
    }
}
