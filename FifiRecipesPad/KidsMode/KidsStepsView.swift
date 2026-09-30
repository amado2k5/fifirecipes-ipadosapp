import SwiftUI

/// Step-by-step cooking mode: one big card per step with progress dots and
/// prev/next, ending on the celebration screen.
struct KidsStepsView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var loader: KidsRecipeLoader
    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kidsSteps")
    }

    @ViewBuilder
    private var content: some View {
        switch loader.state {
        case .loading:
            LoadingView(label: app.s[.loading])
        case .failed:
            ErrorView { loader.reset(); loader.load(lang: app.lang) }
        case .loaded:
            if let recipe = loader.recipe { steps(recipe) }
        }
    }

    @ViewBuilder
    private func steps(_ recipe: KidsRecipeDetail) -> some View {
        let total = recipe.steps.count
        let cur = recipe.steps[min(step, total - 1)]
        let last = step == total - 1

        VStack(spacing: 20) {
            RainbowBar()
            HStack {
                Text(recipe.title)
                    .fifiFont(.title2, weight: .heavy)
                    .foregroundStyle(KidsPalette.ink)
                    .lineLimit(1)
                Spacer()
                progressDots(total: total)
            }

            stepCard(cur, number: step + 1, total: total)
                .id(step)
                .transition(.opacity)
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .top)

            HStack(spacing: 14) {
                if step > 0 {
                    KidsButton(title: "◀ \(app.s[.prev])",
                               gradient: LinearGradient(colors: [.white.opacity(0.9)], startPoint: .top, endPoint: .bottom),
                               border: KidsPalette.chipIdle,
                               foreground: KidsPalette.chipText) {
                        withAnimation(reduceMotion ? .none : .easeOut) { step -= 1 }
                    }
                }
                KidsButton(
                    title: last ? "🎉 \(app.s[.finish])" : "\(app.s[.next]) ▶",
                    gradient: last ? KidsPalette.doneGradient : KidsPalette.goGradient,
                    border: last ? Color(hex: 0xAD1457) : KidsPalette.checkBorder,
                    id: "kidsStepNext"
                ) {
                    if last {
                        app.kidsPath.append(AppRoute.kidsDone(id: recipe.id, title: recipe.title))
                    } else {
                        withAnimation(reduceMotion ? .none : .easeOut) { step += 1 }
                    }
                }
            }
        }
        .padding()
    }

    private func progressDots(total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == step ? KidsPalette.stepOrange
                          : i < step ? KidsPalette.checkGreen : KidsPalette.chipIdle)
                    .frame(width: i == step ? 26 : 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }

    private func stepCard(_ st: KidsStep, number: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Text("\(number)")
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(KidsPalette.stepOrange, in: Circle())
                    .shadow(radius: 4)
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.fill(app.s[.stepOf], ["n": number, "t": total]))
                        .fifiFont(.headline, weight: .bold)
                        .foregroundStyle(KidsPalette.dim)
                    Text(st.text)
                        .fifiFont(.title3, weight: .medium)
                        .foregroundStyle(KidsPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if st.adult != nil {
                        HStack(spacing: 6) {
                            KidsArtView(id: "grown-up").frame(width: 24, height: 24)
                            Text(app.s[.grownUp])
                                .fifiFont(.subheadline, weight: .bold)
                                .foregroundStyle(KidsPalette.warnText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(KidsPalette.warnBg, in: RoundedRectangle(cornerRadius: 10))
                    }
                    if let t = st.timer {
                        Text("⏱ \(t) \(app.s[.minutesShort])")
                            .fifiFont(.subheadline, weight: .bold)
                            .foregroundStyle(KidsPalette.frostText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(KidsPalette.frostBg, in: RoundedRectangle(cornerRadius: 10))
                    }
                    if let items = st.items?.prefix(6) {
                        ForEach(Array(items), id: \.self) { item in
                            KidsArtView(id: item).frame(width: 36, height: 36)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(KidsPalette.cardBorder, lineWidth: 3))
    }
}

/// Celebration screen — confetti of kids-art falling over a pop-in card.
/// Honors Reduce Motion by showing a static arrangement instead.
struct KidsDoneView: View {
    @EnvironmentObject private var app: AppState
    let id: String
    let title: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    private static let confetti = ["star", "bell-pepper", "cherry-tomatoes", "sweet-potato", "egg-cracked", "star"]

    var body: some View {
        ZStack {
            KidsCanvas()
            if !reduceMotion {
                confettiLayer
            }
            VStack(spacing: 14) {
                KidsArtView(id: "chef")
                    .frame(width: 110, height: 110)
                Text(app.s[.doneTitle])
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(KidsPalette.ink)
                    .multilineTextAlignment(.center)
                Text(title)
                    .fifiFont(.title3, weight: .bold)
                    .foregroundStyle(KidsPalette.dim)
                    .multilineTextAlignment(.center)
                Text(app.s[.doneBody])
                    .fifiFont(.body, weight: .medium)
                    .foregroundStyle(KidsPalette.body)
                    .multilineTextAlignment(.center)
                KidsButton(title: "🌈 \(app.s[.cookAgain])") {
                    app.kidsPath = NavigationPath()
                }
                .padding(.top, 10)
            }
            .padding(28)
            .background(.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color(hex: 0xFFD54F), lineWidth: 3))
            .shadow(color: KidsPalette.ink.opacity(0.2), radius: 20)
            .padding(24)
            .scaleEffect(reduceMotion || animate ? 1 : 0.8)
            .opacity(reduceMotion || animate ? 1 : 0)
        }
        .kidsFontScope()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { animate = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kidsDone")
    }

    private var confettiLayer: some View {
        GeometryReader { geo in
            ForEach(Array(Self.confetti.enumerated()), id: \.offset) { i, art in
                KidsArtView(id: art)
                    .frame(width: 44, height: 44)
                    .position(
                        x: geo.size.width * (0.08 + Double(i) * 0.15),
                        y: animate ? geo.size.height + 60 : -60)
                    .animation(
                        .easeIn(duration: 2.8)
                            .repeatCount(1)
                            .delay(Double(i) * 0.25),
                        value: animate)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
