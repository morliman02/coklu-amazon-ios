import UIKit
import WebKit

/// Açık hesap tarayıcılarını bellekte tutar; hesaplar arasında gidip
/// gelince sayfa kaldığı yerden devam eder. Çok sayıda hesap açılırsa en
/// uzun süredir kullanılmayan kapatılır (oturumu kaybolmaz, yalnızca
/// sayfa yeniden yüklenir).
@MainActor
final class WebViewPool {
    static let shared = WebViewPool()

    private let limit = 8
    private var controllers: [UUID: BrowserController] = [:]
    private var recent: [UUID] = []   // en son kullanılan en sonda

    func controller(for account: Account) -> BrowserController {
        recent.removeAll { $0 == account.id }
        recent.append(account.id)
        if let existing = controllers[account.id] { return existing }

        let created = BrowserController(account: account)
        controllers[account.id] = created
        while recent.count > limit {
            let oldest = recent.removeFirst()
            controllers[oldest]?.tearDown()
            controllers[oldest] = nil
        }
        return created
    }

    func accountChanged(_ account: Account) {
        controllers[account.id]?.setHome(account.url)
    }

    func discard(_ id: UUID) {
        controllers[id]?.tearDown()
        controllers[id] = nil
        recent.removeAll { $0 == id }
    }
}

/// Tek bir hesabın web görünümü. Her hesap kendi WKWebsiteDataStore'unu
/// kullanır, bu yüzden çerezler ve oturumlar hiçbir zaman karışmaz.
@MainActor
final class BrowserController: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView
    @Published var progress: Double = 0
    @Published var isLoading = false

    private(set) var homeURL: URL
    private var observers: [NSKeyValueObservation] = []

    init(account: Account) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore(forIdentifier: account.id)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // Site bizi mobil Safari sansın.
        config.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1"
        config.userContentController.addUserScript(WKUserScript(
            source: Scripts.hideAppBanner, injectionTime: .atDocumentEnd, forMainFrameOnly: true))

        webView = WKWebView(frame: .zero, configuration: config)
        homeURL = URL(string: account.url) ?? URL(string: AccountStore.defaultURL)!
        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .white

        observers = [
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                let value = view.estimatedProgress
                Task { @MainActor in self?.progress = value }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                let value = view.isLoading
                Task { @MainActor in self?.isLoading = value }
            },
        ]
        webView.load(URLRequest(url: homeURL))
    }

    // MARK: - Alt menü

    func goHome() { webView.load(URLRequest(url: homeURL)) }
    func openAccountPage() { open(path: "/gp/css/homepage.html") }
    func openCart() { open(path: "/gp/cart/view.html") }

    func setHome(_ url: String) {
        guard let new = URL(string: url), new != homeURL else { return }
        homeURL = new
        goHome()
    }

    func tearDown() {
        observers.removeAll()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.removeFromSuperview()
    }

    /// Açılış adresinin sitesinde bir sayfa (ör. sepet).
    private func open(path: String) {
        var c = URLComponents()
        c.scheme = homeURL.scheme ?? "https"
        c.host = homeURL.host
        c.path = path
        if let url = c.url { webView.load(URLRequest(url: url)) }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else { return .allow }
        switch scheme {
        case "http", "https", "about", "blob", "data":
            return .allow
        case "tel", "mailto", "sms":
            // Telefonun kendi uygulamalarıyla açılsın.
            _ = await UIApplication.shared.open(url)
            return .cancel
        default:
            // Amazon'un kendi uygulamasını açma denemeleri: yok say, bu
            // hesabın içinde kal.
            return .cancel
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: - WKUIDelegate

    /// Yeni sekmede açılmak istenen bağlantıları aynı pencerede aç.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

enum Scripts {
    /// Mobil sitenin üstündeki "Ücretsiz uygulamamızda alışveriş yapın"
    /// şeridini gizler. Şeridin sınıf adları değişebildiği için metninden
    /// bulunur ve sayfa sonradan değişirse diye birkaç saniye tekrar denenir.
    static let hideAppBanner = """
    (function(){
      var keys=['Uygulamamızda','uygulamamızda','Uygulamada aç','uygulamada aç','Get the app','in our app','Open in app'];
      function run(){
        var all=document.body?document.body.getElementsByTagName('*'):[];
        for(var i=0;i<all.length;i++){var e=all[i];
          if(e.children.length>3)continue;
          var t=e.textContent||'';var hit=false;
          for(var k=0;k<keys.length;k++)if(t.indexOf(keys[k])>=0)hit=true;
          if(!hit)continue;
          var box=e;
          while(box.parentElement&&box.parentElement!==document.body
            &&box.parentElement.getBoundingClientRect().height<140)box=box.parentElement;
          if(box.getBoundingClientRect().height<140)box.style.setProperty('display','none','important');
        }
      }
      run();var n=0;var timer=setInterval(function(){run();if(++n>10)clearInterval(timer);},500);
    })();
    """
}
