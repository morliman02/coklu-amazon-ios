import SwiftUI
import WebKit

/// Bir hesabın tarayıcı ekranı: üstte yükleme çubuğu, ortada site,
/// altta Amazon uygulamasındaki gibi menü.
struct BrowserView: View {
    let account: Account
    @ObservedObject var controller: BrowserController
    var onShowAccounts: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            WebViewHost(webView: controller.webView)
            Divider()
            HStack(spacing: 0) {
                navButton("house", "Ana sayfa") { controller.goHome() }
                navButton("person", "Hesabım") { controller.openAccountPage() }
                navButton("cart", "Sepet") { controller.openCart() }
                navButton("square.grid.2x2", account.name, action: onShowAccounts)
            }
            .frame(height: 56)
            .background(Color.white)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.amazonOrange)
                .frame(width: geo.size.width * controller.progress)
                .opacity(controller.isLoading ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: controller.progress)
        }
        .frame(height: 3)
        .background(Color.amazonDark.ignoresSafeArea(edges: .top))
    }

    private func navButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: 11)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(white: 0.07))
    }
}

/// Havuzdaki aynı WKWebView'i her açılışta yeni bir kaba taşır, böylece
/// sayfa yeniden yüklenmez.
struct WebViewHost: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        attach(to: container)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        if webView.superview !== container { attach(to: container) }
    }

    private func attach(to container: UIView) {
        webView.removeFromSuperview()
        webView.frame = container.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(webView)
    }
}
