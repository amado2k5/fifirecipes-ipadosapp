import SwiftUI

/// iPad affordances layered onto recipe/chapter cards:
///   * pointer hover lift (trackpad / Magic Mouse / Pencil hover on M-series)
///   * context menu (long-press or right-click) with the system Share action
///   * drag-to-other-apps with the recipe's Universal Link in Split View
private struct FifiCardActions: ViewModifier {
    let shareURL: URL?

    func body(content: Content) -> some View {
        content
            .hoverEffect(.lift)
            .contextMenu {
                if let shareURL {
                    ShareLink(item: shareURL)
                }
            }
            .modifier(OptionalDrag(url: shareURL))
    }
}

private struct OptionalDrag: ViewModifier {
    let url: URL?
    func body(content: Content) -> some View {
        if let url {
            content.draggable(url)
        } else {
            content
        }
    }
}

extension View {
    /// Recipe deep-link URL — the same paths the AASA file claims, so links
    /// open in the app where installed and on fifi.cooking otherwise.
    static func fifiShareURL(recipeID: String) -> URL? {
        URL(string: "\(APIClient.origin)/recipe/\(recipeID)")
    }

    func fifiCardActions(recipeID: String) -> some View {
        modifier(FifiCardActions(shareURL: Self.fifiShareURL(recipeID: recipeID)))
    }

    func fifiCardActions() -> some View {
        modifier(FifiCardActions(shareURL: nil))
    }
}
