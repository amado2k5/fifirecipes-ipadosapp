import SwiftUI

/// Full recipe page — hero, meta chips, nutrition, tappable ingredient
/// checklist, numbered steps, grouped alternative methods, tips, the
/// "From Fatma's notebook" cultural-notes card and the videos row.
struct RecipeDetailView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    let id: String

    @State private var file: RecipeFile?
    @State private var videos: [VideoItem] = []
    @State private var failed = false
    @State private var ticked: Set<Int> = []
    @State private var shownVideo: VideoItem?
    @State private var zoomedHero = false
    /// Actual rendered width — the two-column layout only engages when the
    /// detail column is genuinely wide (portrait with the sidebar open is
    /// regular-width but only ~500pt, too narrow to split).
    @State private var detailWidth: CGFloat = 0

    private var isWide: Bool { sizeClass == .regular && detailWidth >= 720 }

    var body: some View {
        Group {
            if failed {
                ErrorView { load() }
            } else if let loc {
                content(loc)
            } else {
                LoadingView(label: app.s[.loading])
            }
        }
        .navigationTitle(file.map { RecipeLocalization.localize($0, lang: app.lang).title } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(id)|\(app.lang)") { load() }
        .fifiMeasureWidth($detailWidth)
        .sheet(item: $shownVideo) { VideoSheet(video: $0).environmentObject(app) }
        .fullScreenCover(isPresented: $zoomedHero) {
            ZoomableImageView(url: heroURL).environmentObject(app)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recipeDetail")
    }

    private var loc: RecipeLocalization.Localized? {
        file.map { RecipeLocalization.localize($0, lang: app.lang) }
    }

    private func load() {
        failed = false
        file = nil
        let api = APIClient.shared
        Task {
            do { file = try await api.recipe(id: id) }
            catch { failed = true }
        }
        Task {
            videos = (try? await api.videos(id: id))
                .map { APIClient.pickVideos($0, lang: app.lang) } ?? []
        }
    }

    @ViewBuilder
    private func content(_ loc: RecipeLocalization.Localized) -> some View {
        ScrollView {
            if isWide {
                // iPad canvas: editorial two-column page — hero + title block
                // side by side, ingredients pinned in the leading column and
                // the long-form steps flowing in the wider trailing column.
                VStack(alignment: .leading, spacing: 26) {
                    wideHeader(loc)
                    if let notes = loc.culturalNotes {
                        culturalCard(notes)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        ingredientsSection(loc)
                            .frame(minWidth: 280, idealWidth: 360, maxWidth: 420)
                        VStack(alignment: .leading, spacing: 22) {
                            stepsSection(loc)
                            alternativeSection(loc)
                            tipsSection(loc)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    videosSection
                }
                .frame(maxWidth: 1240)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
            } else {
                VStack(alignment: .leading, spacing: 22) {
                    compactHeader(loc)
                    if let notes = loc.culturalNotes {
                        culturalCard(notes)
                    }
                    ingredientsSection(loc)
                    stepsSection(loc)
                    alternativeSection(loc)
                    tipsSection(loc)
                    videosSection
                }
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Hero + meta

    /// Tapping the hero opens the full-screen pinch-to-zoom viewer.
    private func heroImage(title: String) -> some View {
        Button {
            zoomedHero = true
        } label: {
            RemoteImage(url: heroURL, cornerRadius: 20)
                .frame(maxWidth: .infinity)
                .frame(height: isWide ? 340 : 240)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Palette.ink.opacity(0.5), in: Circle())
                        .padding(12)
                }
        }
        .buttonStyle(.plain)
        .shadow(color: Palette.ink.opacity(0.10), radius: 12, y: 6)
        .fifiCardActions(recipeID: id)
        .accessibilityLabel(title)
    }

    private func metaBlock(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let chapter = loc.chapter {
                Text(chapter)
                    .fifiFont(.subheadline, weight: .bold)
                    .foregroundStyle(Palette.leafDeep)
            }
            Text(loc.title)
                .fifiFont(.largeTitle, weight: .heavy)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let sub = loc.subtitle {
                Text(sub)
                    .fifiFont(.title3)
                    .italic()
                    .foregroundStyle(Palette.inkDim)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let v = loc.prepTime { MetaChip(label: app.s[.prep], text: v, tone: .leaf) }
                    if let v = loc.cookTime { MetaChip(label: app.s[.cook], text: v, tone: .tomato) }
                    if let v = loc.servings { MetaChip(label: app.s[.servings], text: v, tone: .sun) }
                    if let v = loc.category { MetaChip(text: v, tone: .leaf) }
                    if let v = loc.cookingMethod { MetaChip(text: v, tone: .tomato) }
                }
            }
            if let est = file?.estimate, est.kcal != nil || est.protein != nil || est.carbs != nil || est.fat != nil {
                HStack(spacing: 12) {
                    if let v = est.kcal { Text("\(v) \(app.s[.kcal])") }
                    if let v = est.protein { Text("· \(v)g \(app.s[.protein])") }
                    if let v = est.carbs { Text("· \(v)g \(app.s[.carbs])") }
                    if let v = est.fat { Text("· \(v)g \(app.s[.fat])") }
                }
                .fifiFont(.footnote)
                .foregroundStyle(Palette.inkDim)
            }
        }
    }

    private func compactHeader(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            heroImage(title: loc.title)
                .padding(.horizontal)
            metaBlock(loc)
                .titlePanel()
                // Lift the panel over the bottom of the photo, inset so the
                // picture frames it.
                .padding(.top, -44)
                .padding(.horizontal, 28)
        }
    }

    private func wideHeader(_ loc: RecipeLocalization.Localized) -> some View {
        HStack(alignment: .top, spacing: 26) {
            // Pin the media column to ~45% — relying on two flexible children
            // to split evenly squeezes the text column when the image's ideal
            // width wins.
            heroImage(title: loc.title)
                .frame(width: min(560, detailWidth * 0.45))
            metaBlock(loc)
                .titlePanel()
        }
        .padding(.horizontal)
    }

    private var heroURL: URL? {
        let info = app.images[id]
        return app.assetURL(info?.full2x ?? info?.full ?? app.index[id]?.image)
    }

    private func culturalCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(app.s[.culturalNotes])
                .fifiFont(.headline, weight: .bold)
                .foregroundStyle(Palette.leafDeep)
            Text(notes)
                .fifiFont(.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.sunSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            Palette.sun
                .frame(width: 5)
                .clipShape(UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 16, bottomLeading: 16)))
        }
        .padding(.horizontal)
    }

    // MARK: - Sections

    private func sectionTitle(_ text: String, dot: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(dot).frame(width: 14, height: 14)
            Text(text)
                .fifiFont(.title2, weight: .bold)
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal)
    }

    private func ingredientsSection(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(app.s[.ingredients], dot: Palette.leaf)
            VStack(spacing: 0) {
                ForEach(Array(loc.ingredients.enumerated()), id: \.offset) { i, ing in
                    let isOn = ticked.contains(i)
                    Button {
                        if isOn { ticked.remove(i) } else { ticked.insert(i) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isOn ? Palette.leaf : Palette.cardBorder)
                                .frame(width: 28, height: 28)
                            // Amount sits under the name, not beside it: amounts can be whole
                            // phrases ("500g fresh leaves, finely chopped with Makhrata") that
                            // would otherwise squeeze the name into a narrow column.
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ing.name)
                                    .fifiFont(.body, weight: .medium)
                                    .foregroundStyle(Palette.ink)
                                    .strikethrough(isOn)
                                    .opacity(isOn ? 0.6 : 1)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let amount = ing.amount {
                                    Text(amount)
                                        .fifiFont(.body, weight: .bold)
                                        .foregroundStyle(Palette.leafDeep)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    if i < loc.ingredients.count - 1 {
                        Palette.cardBorder.frame(height: 1).padding(.leading, 14)
                    }
                }
            }
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Palette.cardBorder, lineWidth: 1.5))
            .padding(.horizontal)
            .accessibilityHint(app.s[.tickHint])
        }
    }

    private var coreSteps: [RecipeLocalization.Step] {
        (loc?.steps ?? []).filter { $0.alternative == nil }
    }

    private var alternativeGroups: [(label: String, steps: [RecipeLocalization.Step])] {
        var order: [String] = []
        var map: [String: [RecipeLocalization.Step]] = [:]
        for st in loc?.steps ?? [] {
            guard let alt = st.alternative else { continue }
            if map[alt] == nil { order.append(alt); map[alt] = [] }
            map[alt]?.append(st)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private var tips: [RecipeLocalization.Step] {
        (loc?.steps ?? []).filter(\.isTip)
    }

    private func stepCard(_ st: RecipeLocalization.Step) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(st.n)")
                .fifiFont(.headline, weight: .heavy)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Palette.leaf, in: Circle())
            Text(st.text)
                .fifiFont(.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 1.5))
    }

    private func stepsSection(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(app.s[.steps], dot: Palette.tomato)
            VStack(spacing: 10) {
                ForEach(coreSteps, id: \.n) { st in stepCard(st) }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func alternativeSection(_ loc: RecipeLocalization.Localized) -> some View {
        if !alternativeGroups.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(app.s[.alternativeMethods], dot: Palette.berry)
                VStack(spacing: 10) {
                    ForEach(alternativeGroups, id: \.label) { group in
                        ForEach(group.steps, id: \.n) { st in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.label)
                                    .fifiFont(.footnote, weight: .bold)
                                    .foregroundStyle(Palette.berry)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Palette.berry.opacity(0.15), in: Capsule())
                                Text(st.text)
                                    .fifiFont(.body)
                                    .foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.tomatoSoft.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Palette.berry.opacity(0.3), lineWidth: 1.5))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func tipsSection(_ loc: RecipeLocalization.Localized) -> some View {
        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(app.s[.tips], dot: Palette.sun)
                VStack(spacing: 10) {
                    ForEach(tips, id: \.n) { st in
                        Text("💡 \(st.text)")
                            .fifiFont(.body, weight: .medium)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.sunSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Palette.cardBorder, lineWidth: 1.5))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var videosSection: some View {
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(app.s[.videos], dot: Palette.tomato)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos, id: \.id) { v in
                            Button { shownVideo = v } label: {
                                VideoCardView(video: v)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
