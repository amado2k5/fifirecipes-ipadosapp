import SwiftUI

/// Chapters tab: grid of chapter cards.
struct ChaptersView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: sizeClass == .regular ? 300 : 240), spacing: 16)],
                spacing: 16
            ) {
                ForEach(app.chapters) { chapter in
                    Button {
                        app.chaptersPath.append(AppRoute.chapter(chapter.id))
                    } label: {
                        ChapterCardView(chapter: chapter)
                    }
                    .buttonStyle(.plain)
                    .fifiCardActions()
                }
            }
            .padding()
            .frame(maxWidth: 1400)
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chaptersScreen")
    }
}

/// Chapter detail: virtualized grid of the chapter's recipes — chapters can
/// hold 300+ cards, so LazyVGrid does the windowing.
struct ChapterDetailView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    let chapterID: Int

    private var cards: [RecipeCard] {
        app.index.values.filter { $0.chapter == chapterID }
            .sorted { $0.id < $1.id }
    }

    private var title: String {
        app.chapters.first { $0.id == chapterID }?.name
            ?? cards.first?.chapterName
            ?? app.s[.chapters]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .fifiFont(.title, weight: .heavy)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: sizeClass == .regular ? 200 : 160), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(cards) { card in
                        Button {
                            app.chaptersPath.append(AppRoute.recipe(card.id))
                        } label: {
                            RecipeCardView(card: card)
                        }
                        .buttonStyle(.plain)
                        .fifiCardActions(recipeID: card.id)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: 1400)
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text("\(cards.count)")
                    .fifiFont(.callout, weight: .medium)
                    .foregroundStyle(Palette.leafDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Palette.leafSoft, in: Capsule())
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chapterDetail")
    }
}
