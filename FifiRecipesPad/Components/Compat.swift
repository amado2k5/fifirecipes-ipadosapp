import SwiftUI

/// Compatibility shims so the app can deploy to iPadOS 16 (every iPad that
/// can run iPadOS 16–18, incl. iPad 5th gen, mini 5, Air 3 and all iPad Pros)
/// while still using newer APIs where available.

extension View {
    /// Marks rail content for aligned paging (iPadOS 17+); older releases
    /// scroll freely — same behaviour as the pre-paging iPhone app.
    @ViewBuilder
    func fifiRailTargetLayout() -> some View {
        if #available(iOS 17.0, *) {
            scrollTargetLayout()
        } else {
            self
        }
    }

    /// Aligned paging for horizontal rails (iPadOS 17+ only).
    @ViewBuilder
    func fifiRailPaging() -> some View {
        if #available(iOS 17.0, *) {
            scrollTargetBehavior(.viewAligned)
        } else {
            self
        }
    }

    /// Reports the view's actual rendered width into `binding`. Size class
    /// alone can't tell "regular width but only ~500pt" (portrait with the
    /// sidebar open, ⅔ Split View) from a truly wide canvas, so two-column
    /// layouts gate on this instead.
    func fifiMeasureWidth(_ binding: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self, of: { $0.size.width }) {
            binding.wrappedValue = $0
        }
    }
}
