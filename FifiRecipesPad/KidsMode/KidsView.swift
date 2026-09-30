import SwiftUI

/// Kids home: polka-dot canvas, rainbow strip, group filter chips and the
/// kids card grid. Scoped to the kids font faces via .kidsFontScope().
struct KidsView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var group = "all"
    @State private var noCookOnly = false

    private static let groups = ["breakfast", "snack", "savoury", "sweet", "drink"]

    private var cards: [KidsCard] {
        app.kids.values
            .filter { (group == "all" || $0.group == group) && (!noCookOnly || $0.noCook) }
            .sorted { $0.id < $1.id }
    }

    var body: some View {
        ZStack {
            KidsCanvas()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RainbowBar()
                    header
                    filterChips
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: sizeClass == .regular ? 200 : 160), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(cards) { card in
                            Button {
                                app.kidsPath.append(AppRoute.kidsReady(card.id))
                            } label: {
                                KidsCardView(card: card, minutesLabel: app.s[.minutesShort])
                            }
                            .buttonStyle(.plain)
                            .fifiCardActions()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 1400)
                .frame(maxWidth: .infinity)
            }
        }
        .kidsFontScope()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kidsScreen")
    }

    private var header: some View {
        HStack(spacing: 14) {
            KidsArtView(id: "chef")
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.s[.kids])
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(KidsPalette.ink)
                Text(app.s[.tagline])
                    .fifiFont(.subheadline, weight: .medium)
                    .foregroundStyle(KidsPalette.dim)
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                kidsChip(id: "all", label: app.s[.all], emoji: "🌈",
                         active: group == "all" && !noCookOnly,
                         color: KidsPalette.purple) {
                    group = "all"; noCookOnly = false
                }
                ForEach(Self.groups, id: \.self) { g in
                    let st = KidsGroupStyle.forGroup(g)
                    kidsChip(id: g, label: groupLabel(g), emoji: st.emoji,
                             active: group == g && !noCookOnly,
                             color: st.chip) {
                        group = g; noCookOnly = false
                    }
                }
                kidsChip(id: "nocook", label: app.s[.noCook], emoji: "❄️",
                         active: noCookOnly,
                         color: Color(hex: 0x4FC3F7)) {
                    noCookOnly.toggle()
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func groupLabel(_ group: String) -> String {
        switch group {
        case "breakfast": return app.s[.groupBreakfast]
        case "snack": return app.s[.groupSnack]
        case "savoury": return app.s[.groupSavoury]
        case "sweet": return app.s[.groupSweet]
        case "drink": return app.s[.groupDrink]
        default: return group
        }
    }

    private func kidsChip(
        id: String, label: String, emoji: String, active: Bool,
        color: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text("\(emoji) \(label)")
                .fifiFont(.headline, weight: .bold)
                .foregroundStyle(active ? .white : KidsPalette.chipText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(active ? color : .white.opacity(0.8), in: Capsule())
                .overlay(Capsule().stroke(active ? color : KidsPalette.chipIdle, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("kidsFilter-\(id)")
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
