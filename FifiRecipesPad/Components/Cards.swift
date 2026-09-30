import SwiftUI

/// Chip styling, matching the TV app's MetaPill tones.
enum ChipTone {
    case leaf, tomato, sun

    var bg: Color {
        switch self {
        case .leaf: return Palette.leafSoft
        case .tomato: return Palette.tomatoSoft
        case .sun: return Palette.sunSoft
        }
    }

    var fg: Color {
        switch self {
        case .leaf: return Palette.leafDeep
        case .tomato: return Palette.tomato
        case .sun: return Palette.ink
        }
    }
}

struct MetaChip: View {
    var label: String?
    let text: String
    var tone: ChipTone = .leaf

    var body: some View {
        HStack(spacing: 4) {
            if let label {
                Text(label)
                    .opacity(0.7)
            }
            Text(text)
        }
        .fifiFont(.subheadline, weight: .medium)
        .foregroundStyle(tone.fg)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(tone.bg, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Recipe card used in rails, grids and search results.
struct RecipeCardView: View {
    let card: RecipeCard
    @EnvironmentObject private var app: AppState
    /// Reserved height for the 2-line title + 1-line meta block so every card
    /// in a LazyHStack rail measures identically — otherwise the rail locks
    /// its row height from the first realized card and clips taller siblings.
    @ScaledMetric(relativeTo: .headline) private var titleBlock = 44
    @ScaledMetric(relativeTo: .footnote) private var metaLine = 17

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay { RemoteImage(url: imageURL) }
                .clipped()
                .overlay(alignment: .topTrailing) {
                    if card.hasVideo == true {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Palette.tomato, in: Circle())
                            .shadow(radius: 4)
                            .padding(8)
                    }
                }
                .clipped()
            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .fifiFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(card.cookingMethod ?? card.category ?? " ")
                    .fifiFont(.footnote)
                    .foregroundStyle(Palette.inkDim)
                    .lineLimit(1)
            }
            .frame(minHeight: titleBlock + metaLine + 2, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 1.5))
        .shadow(color: Palette.ink.opacity(0.08), radius: 7, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(card.title)
        .accessibilityHint(card.cookingMethod ?? card.category ?? "")
        .accessibilityAddTraits(.isButton)
    }

    private var imageURL: URL? {
        // Retina-aware: card2x beats the 800px card thumbnail when present.
        let info = app.images[card.id]
        return app.assetURL(info?.card2x ?? card.image)
    }
}

/// Chapter card for the Chapters grid.
struct ChapterCardView: View {
    let chapter: Chapter
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay { RemoteImage(url: app.assetURL(chapter.coverImage)) }
                .clipped()
            HStack {
                Text(chapter.name)
                    .fifiFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text("\(chapter.recipeCount)")
                    .fifiFont(.footnote, weight: .medium)
                    .foregroundStyle(Palette.leafDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Palette.leafSoft, in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 1.5))
        .shadow(color: Palette.ink.opacity(0.08), radius: 7, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chapter.name), \(chapter.recipeCount)")
        .accessibilityAddTraits(.isButton)
    }
}

/// Kids-mode card: group-colored card + kids-art cover + meta line.
struct KidsCardView: View {
    let card: KidsCard
    let minutesLabel: String
    @ScaledMetric(relativeTo: .callout) private var titleLines = 40

    var body: some View {
        let style = KidsGroupStyle.forGroup(card.group)
        VStack(spacing: 8) {
            KidsArtView(id: card.cover)
                .frame(width: 88, height: 88)
                .padding(10)
                .background(.white.opacity(0.9), in: Circle())
            Text(card.title)
                .fifiFont(.callout, weight: .bold)
                .foregroundStyle(KidsPalette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: titleLines)
            Text(metaLine)
                .fifiFont(.footnote, weight: .medium)
                .foregroundStyle(KidsPalette.dim)
                .padding(.bottom, 10)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .background(style.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(style.border, lineWidth: 3))
        .shadow(color: KidsPalette.ink.opacity(0.18), radius: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.title), \(metaLine)")
        .accessibilityAddTraits(.isButton)
    }

    private var metaLine: String {
        var s = "\(card.ages) · \(card.minutes) \(minutesLabel)"
        if card.noCook { s += " · ❄" }
        return s
    }
}

/// YouTube video row card.
struct VideoCardView: View {
    let video: VideoItem
    @ScaledMetric(relativeTo: .subheadline) private var titleBlock = 38
    @ScaledMetric(relativeTo: .footnote) private var metaLine = 17

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay { RemoteImage(url: URL(string: "https://i.ytimg.com/vi/\(video.id)/hqdefault.jpg")) }
                .clipped()
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Palette.tomato.opacity(0.92), in: Circle())
                        .shadow(radius: 8)
                }
                .overlay(alignment: .bottomTrailing) {
                    if let d = video.duration {
                        Text(d)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 6))
                            .padding(8)
                    }
                }
                .clipped()
            VStack(alignment: .leading, spacing: 2) {
                Text(video.title)
                    .fifiFont(.subheadline, weight: .medium)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                if let ch = video.channel {
                    Text(ch)
                        .fifiFont(.footnote)
                        .foregroundStyle(Palette.inkDim)
                        .lineLimit(1)
                }
            }
            .frame(minHeight: titleBlock + metaLine + 2, alignment: .topLeading)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 240)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(video.title)
        .accessibilityAddTraits(.isButton)
    }
}
