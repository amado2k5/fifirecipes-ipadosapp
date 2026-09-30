import SwiftUI

/// Settings: language row (opens the picker), About, version info.
struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var showPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Button { showPicker = true } label: {
                    settingsRow(icon: "globe") {
                        HStack {
                            Text(app.s[.language])
                                .fifiFont(.headline, weight: .bold)
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Text(languageLabel)
                                .fifiFont(.subheadline, weight: .medium)
                                .foregroundStyle(Palette.leafDeep)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settingsLanguageRow")

                settingsRow(icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.s[.about])
                            .fifiFont(.headline, weight: .bold)
                            .foregroundStyle(Palette.ink)
                        Text(app.s[.aboutText])
                            .fifiFont(.body)
                            .foregroundStyle(Palette.inkDim)
                            .fixedSize(horizontal: false, vertical: true)
                        Link("fifi.cooking", destination: URL(string: "https://fifi.cooking")!)
                            .fifiFont(.subheadline, weight: .medium)
                            .foregroundStyle(Palette.leafDeep)
                    }
                }

                settingsRow(icon: "cube.box") {
                    HStack {
                        Text(app.s[.version])
                            .fifiFont(.headline, weight: .bold)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text("fifi.cooking · \(app.manifest?.version ?? "—")")
                            .fifiFont(.subheadline)
                            .foregroundStyle(Palette.inkDim)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showPicker) {
            LanguagePickerView()
                .environmentObject(app)
                .environment(\.fifiLanguage, app.lang)
                .background { PaperBackground() }
                .frame(minWidth: 560, minHeight: 560)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settingsScreen")
    }

    private var languageLabel: String {
        guard let info = app.langInfo else { return app.lang }
        return "\(info.nativeName) (\(info.englishName))"
    }

    private func settingsRow<Content: View>(
        icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Palette.leafDeep)
                .frame(width: 44, height: 44)
                .background(Palette.leafSoft, in: RoundedRectangle(cornerRadius: 12))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 1.5))
    }
}
