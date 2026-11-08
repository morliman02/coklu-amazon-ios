import SwiftUI

@main
struct CokluAmazonApp: App {
    @StateObject private var store = AccountStore()
    @State private var openAccount: Account?

    var body: some Scene {
        WindowGroup {
            AccountsView(store: store) { account in
                openAccount = account
            }
            .fullScreenCover(item: $openAccount) { account in
                BrowserView(
                    account: account,
                    controller: WebViewPool.shared.controller(for: account),
                    onShowAccounts: { openAccount = nil }
                )
                .preferredColorScheme(.light)
            }
            .preferredColorScheme(.light)
        }
    }
}

extension Color {
    static let amazonDark = Color(red: 0x23 / 255, green: 0x2F / 255, blue: 0x3E / 255)
    static let amazonOrange = Color(red: 1, green: 0x99 / 255, blue: 0)
    static let pageGray = Color(white: 0.953)
}
