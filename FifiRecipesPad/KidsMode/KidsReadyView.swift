import SwiftUI

/// Loads a kids recipe detail (shared by the ready and steps screens).
@MainActor
final class KidsRecipeLoader: ObservableObject {
    enum State { case loading, loaded, failed }
    @Published private(set) var state = State.loading
    @Published private(set) var recipe: KidsRecipeDetail?
    private let id: String
    private var loadedLang = ""

    init(id: String) { self.id = id }

    func load(lang: String) {
        guard recipe == nil || loadedLang != lang else { return }
        loadedLang = lang
        state = .loading
        Task {
            do {
                recipe = try await APIClient.shared.kidsRecipe(lang: lang, id: id)
                state = .loaded
            } catch {
                state = .failed
            }
        }
    }
}

/// "Get ready" screen: hero card, ready checklist, tickable ingredients,
/// tools, allergen banner, steps preview and the Let's cook button.
struct KidsReadyView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @StateObject private var loader: KidsRecipeLoader
    @State private var ticked: Set<Int> = []
    /// Actual rendered width — the two-column prep layout needs real room;
    /// portrait-with-sidebar is regular-width but only ~500pt.
    @State private var detailWidth: CGFloat = 0

    init(id: String) {
        _loader = StateObject(wrappedValue: KidsRecipeLoader(id: id))
    }

    var body: some View {
        ZStack {
            KidsCanvas()
            content
        }
        .kidsFontScope()
        .navigationBarTitleDisplayMode(.inline)
        .task(id: app.lang) { loader.load(lang: app.lang) }
        .fifiMeasureWidth($detailWidth)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kidsReady")
    }

    @ViewBuilder
    private var content: some View {
        switch loader.state {
        case .loading:
            LoadingView(label: app.s[.loading])
        case .failed:
            ErrorView { loader.reset(); loader.load(lang: app.lang) }
        case .loaded:
            if let recipe = loader.recipe { ready(recipe) }
        }
    }

    @ViewBuilder
    private func ready(_ recipe: KidsRecipeDetail) -> some View {
        let style = KidsGroupStyle.forGroup(recipe.group)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RainbowBar()
                if sizeClass == .regular && detailWidth >= 720 {
                    // iPad: prep work on the leading side, the step preview
                    // and Let's-cook CTA flowing in the wider trailing column.
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 18) {
                            heroCard(recipe, style: style)
                            readyRow
                            ingredientsSection(recipe)
                        }
                        .frame(minWidth: 300, idealWidth: 380, maxWidth: 440)
                        VStack(alignment: .leading, spacing: 18) {
                            stepsPreview(recipe)
                            KidsButton(title: "🍳 \(app.s[.letsCook])", id: "kidsStartCooking") {
                                app.kidsPath.append(AppRoute.kidsSteps(recipe.id))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    heroCard(recipe, style: style)
                    readyRow
                    ingredientsSection(recipe)
                    stepsPreview(recipe)
                    KidsButton(title: "🍳 \(app.s[.letsCook])", id: "kidsStartCooking") {
                        app.kidsPath.append(AppRoute.kidsSteps(recipe.id))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: 1300)
            .frame(maxWidth: .infinity)
        }
    }

    private func heroCard(_ recipe: KidsRecipeDetail, style: KidsGroupStyle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                KidsArtView(id: recipe.cover)
                    .frame(width: 96, height: 96)
                    .padding(10)
                    .background(.white.opacity(0.9), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text(app.s[.getReady])
                        .fifiFont(.subheadline, weight: .bold)
                        .foregroundStyle(KidsPalette.dim)
                    Text(recipe.title)
                        .fifiFont(.title, weight: .heavy)
                        .foregroundStyle(KidsPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let intro = recipe.intro {
                        Text(intro)
                            .fifiFont(.callout)
                            .foregroundStyle(KidsPalette.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    kidsMeta("\(app.s[.ages]) \(recipe.ages)")
                    kidsMeta("⏱ \(recipe.minutes) \(app.s[.minutesShort])")
                    if let srv = recipe.servings { kidsMeta("🍽 \(srv) \(app.s[.servings])") }
                    if recipe.noCook {
                        kidsMeta("❄ \(app.s[.noCook])", bg: KidsPalette.frostBg, fg: KidsPalette.frostText)
                    } else {
                        kidsMeta("👨‍👧 \(app.s[.grownUp])", bg: KidsPalette.hotBg, fg: KidsPalette.hotText)
                    }
                }
            }
            if let allergens = recipe.allergens, !allergens.isEmpty {
                Text("⚠ \(app.s[.contains]): " +
                     allergens.map { Strings.allergenName(lang: app.lang, code: $0) }.joined(separator: ", "))
                    .fifiFont(.subheadline, weight: .bold)
                    .foregroundStyle(KidsPalette.warnText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(KidsPalette.warnBg, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("allergenBanner")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.card.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(style.border, lineWidth: 3))
    }

    private func kidsMeta(_ text: String, bg: Color = KidsPalette.meta, fg: Color = KidsPalette.ink) -> some View {
        Text(text)
            .fifiFont(.subheadline, weight: .bold)
            .foregroundStyle(fg)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(bg, in: Capsule())
    }

    private var readyRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                readyPill(art: "wash-hands", label: app.s[.washHands])
                readyPill(art: "apron", label: app.s[.wearApron])
                readyPill(art: "grown-up", label: app.s[.grownUp])
            }
        }
    }

    private func readyPill(art: String, label: String) -> some View {
        HStack(spacing: 8) {
            KidsArtView(id: art).frame(width: 30, height: 30)
            Text(label)
                .fifiFont(.subheadline, weight: .bold)
                .foregroundStyle(KidsPalette.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.85), in: Capsule())
        .overlay(Capsule().stroke(KidsPalette.cardBorder, lineWidth: 3))
    }

    private func ingredientsSection(_ recipe: KidsRecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(app.s[.ingredients])
                .fifiFont(.title2, weight: .heavy)
                .foregroundStyle(KidsPalette.ink)
            Text(app.s[.tickHint])
                .fifiFont(.footnote, weight: .medium)
                .foregroundStyle(KidsPalette.dim)
            VStack(spacing: 8) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, ing in
                    let on = ticked.contains(i)
                    Button {
                        if on { ticked.remove(i) } else { ticked.insert(i) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(on ? KidsPalette.checkGreen : KidsPalette.chipIdle)
                                .frame(width: 32, height: 32)
                            KidsArtView(id: ing.art).frame(width: 34, height: 34)
                            Text(ing.text)
                                .fifiFont(.body, weight: .medium)
                                .foregroundStyle(KidsPalette.ink)
                                .strikethrough(on)
                                .opacity(on ? 0.6 : 1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(minHeight: 52)
                        .background(on ? KidsPalette.checkSoft : .white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(on ? KidsPalette.checkGreen : KidsPalette.cardBorder, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                }
            }
            if let tools = recipe.tools, !tools.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(app.s[.tools])
                        .fifiFont(.headline, weight: .bold)
                        .foregroundStyle(KidsPalette.dim)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(tools, id: \.self) { tool in
                                KidsArtView(id: tool).frame(width: 44, height: 44)
                            }
                        }
                    }
                }
                .padding(14)
                .background(.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(KidsPalette.cardBorder, lineWidth: 3))
            }
        }
    }

    private func stepsPreview(_ recipe: KidsRecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(app.s[.steps])
                .fifiFont(.title2, weight: .heavy)
                .foregroundStyle(KidsPalette.ink)
            Text(Strings.fill(app.s[.stepOf], ["n": 1, "t": recipe.steps.count]))
                .fifiFont(.subheadline, weight: .medium)
                .foregroundStyle(KidsPalette.dim)
            VStack(spacing: 8) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, st in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)")
                            .fifiFont(.headline, weight: .heavy)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(KidsPalette.stepOrange, in: Circle())
                        VStack(alignment: .leading, spacing: 6) {
                            Text(st.text)
                                .fifiFont(.body, weight: .medium)
                                .foregroundStyle(KidsPalette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            stepBadges(st)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(KidsPalette.cardBorder, lineWidth: 3))
                }
            }
            if let tip = recipe.tip {
                Text("⭐ \(app.s[.tip]): \(tip)")
                    .fifiFont(.callout, weight: .bold)
                    .foregroundStyle(KidsPalette.tipText)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KidsPalette.tipBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func stepBadges(_ st: KidsStep) -> some View {
        HStack(spacing: 10) {
            if st.adult != nil {
                HStack(spacing: 5) {
                    KidsArtView(id: "grown-up").frame(width: 20, height: 20)
                    Text(app.s[.grownUp])
                        .fifiFont(.footnote, weight: .bold)
                        .foregroundStyle(KidsPalette.warnText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(KidsPalette.warnBg, in: RoundedRectangle(cornerRadius: 8))
            }
            if let items = st.items?.prefix(5) {
                ForEach(Array(items), id: \.self) { item in
                    KidsArtView(id: item).frame(width: 28, height: 28)
                }
            }
        }
    }
}

extension KidsRecipeLoader {
    func reset() {
        recipe = nil
        loadedLang = ""
    }
}
