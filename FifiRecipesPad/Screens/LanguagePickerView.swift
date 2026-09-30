import SwiftUI

/// First-run language picker — large touch tiles with the language's native
/// and English names; also reachable from Settings (presented as a sheet).
struct LanguagePickerView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image("Emblem")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)
                Text(app.s[.appName])
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(Palette.leafDeep)
                Text(app.s[.chooseLanguage])
                    .fifiFont(.title3)
                    .foregroundStyle(Palette.inkDim)
            }
            .padding(.top, 28)
            .padding(.bottom, 18)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 190), spacing: 14)],
                spacing: 14
            ) {
                ForEach(app.manifest?.languages ?? [], id: \.code) { lang in
                    languageTile(lang)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("languagePicker")
    }

    private func languageTile(_ lang: LanguageInfo) -> some View {
        let selected = lang.code == app.lang
        return Button {
            app.setLanguage(lang.code)
        } label: {
            VStack(spacing: 2) {
                Text(lang.nativeName)
                    .fifiFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.ink)
                if lang.englishName != lang.nativeName {
                    Text(lang.englishName)
                        .fifiFont(.footnote)
                        .foregroundStyle(Palette.inkDim)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .padding(.vertical, 8)
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.leaf)
                        .padding(8)
                }
            }
            .background(selected ? Palette.leafSoft : Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Palette.leaf : Palette.cardBorder, lineWidth: selected ? 3 : 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("lang-\(lang.code)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
