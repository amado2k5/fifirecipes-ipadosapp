import SwiftUI

/// Native search: system keyboard + .searchable — the TV on-screen keyboard
/// is a TV-only pattern and intentionally not ported. Same matching rule as
/// the TV app: every whitespace-separated term must appear in the haystack.
struct SearchView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var query = ""
    @State private var haystack: SearchIndex?

    private var maxResults: Int { sizeClass == .regular ? 96 : 48 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    if results.isEmpty {
                        Text(app.s[.noResults])
                            .fifiFont(.title3, weight: .medium)
                            .foregroundStyle(Palette.inkDim)
                            .padding()
                            .accessibilityIdentifier("noResults")
                    } else {
                        Text("\(app.s[.resultsFor]) “\(query.trimmingCharacters(in: .whitespaces))”")
                            .fifiFont(.headline, weight: .bold)
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal)
                    }
                }
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: sizeClass == .regular ? 200 : 160), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(results, id: \.self) { id in
                        if let card = app.index[id] {
                            Button {
                                app.searchPath.append(AppRoute.recipe(id))
                            } label: {
                                RecipeCardView(card: card)
                            }
                            .buttonStyle(.plain)
                            .fifiCardActions(recipeID: card.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: 1400)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        // In a NavigationSplitView detail column the drawer only appears
        // reliably with displayMode .always; .automatic can collapse it away
        // entirely and leave users with no field at all.
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: app.s[.searchTitle])
        .task(id: app.lang) { await loadHaystack() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("searchScreen")
    }

    private var results: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty, let haystack else { return [] }
        let terms = q.split(whereSeparator: { $0 == " " })
        var out: [String] = []
        for (id, text) in haystack where terms.allSatisfy({ text.contains($0) }) && app.index[id] != nil {
            out.append(id)
            if out.count >= maxResults { break }
        }
        return out
    }

    private func loadHaystack() async {
        haystack = (try? await APIClient.shared.search(lang: app.lang)) ?? [:]
    }
}
