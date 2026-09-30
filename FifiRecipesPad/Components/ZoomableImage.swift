import SwiftUI
import UIKit

/// Full-screen photo viewer: pinch-to-zoom, pan and double-tap zoom via a
/// UIScrollView — the reliable approach on iPadOS 16+ (SwiftUI's
/// MagnificationGesture predates MagnifyGesture and UIScrollView handles the
/// trackpad pinch gesture for free).
struct ZoomableImageView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let url: URL?

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            ZoomScrollView(image: image)
                .ignoresSafeArea()
            if image == nil {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(app.s[.loading])
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.55), in: Circle())
            }
            .keyboardShortcut(.cancelAction)
            .padding(20)
            .accessibilityLabel(app.s[.close])
        }
        .task { await load() }
        .accessibilityIdentifier("zoomView")
    }

    private func load() async {
        guard let url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let img = UIImage(data: data)
        else { return }
        image = img
    }
}

/// UIScrollView hosting a fitted UIImageView with zoom + double-tap.
private struct ZoomScrollView: UIViewRepresentable {
    let image: UIImage?

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 5
        scroll.bouncesZoom = true
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.addSubview(imageView)
        context.coordinator.imageView = imageView

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
        context.coordinator.layout(scroll)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func layout(_ scroll: UIScrollView) {
            imageView?.frame = CGRect(origin: .zero, size: scroll.bounds.size)
            scroll.contentSize = scroll.bounds.size
        }

        /// Recenters the image under the viewport while zoomed out — without
        /// this the fitted image sticks to the top-leading corner.
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let iv = imageView else { return }
            let x = max((scrollView.bounds.width - iv.frame.width) / 2, 0)
            let y = max((scrollView.bounds.height - iv.frame.height) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Rotation/multitasking resize: refit once back at min zoom.
            if let iv = imageView, scrollView.zoomScale == scrollView.minimumZoomScale,
               !iv.frame.size.equalTo(scrollView.bounds.size) {
                layout(scrollView)
            }
        }

        @objc func doubleTapped(_ gesture: UITapGestureRecognizer) {
            guard let scroll = gesture.view as? UIScrollView, let iv = imageView else { return }
            if scroll.zoomScale > scroll.minimumZoomScale {
                scroll.setZoomScale(scroll.minimumZoomScale, animated: true)
            } else {
                let point = gesture.location(in: iv)
                let size = scroll.bounds.width / max(scroll.maximumZoomScale / 2, 1)
                scroll.zoom(to: CGRect(x: point.x - size / 2, y: point.y - size / 2,
                                       width: size, height: size), animated: true)
            }
        }
    }
}
