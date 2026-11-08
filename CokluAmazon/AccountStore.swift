import Foundation
import WebKit

/// Bir hesap yuvası. `id`, o hesabın çerez ve site verisinin durduğu
/// WKWebsiteDataStore kimliğidir; her hesabın deposu tamamen ayrıdır.
struct Account: Identifiable, Codable, Equatable {
    var id: UUID
    var number: Int      // 1...100, kutuda görünen numara
    var name: String
    var url: String
}

/// Hesap listesini (ad, numara, açılış adresi) telefonda saklar.
@MainActor
final class AccountStore: ObservableObject {
    static let maxAccounts = 100
    static let defaultURL = "https://www.amazon.com.tr/"

    @Published private(set) var accounts: [Account] = []
    private let key = "accounts.v1"

    init() {
        load()
        purgeOrphanedStores()
    }

    var sorted: [Account] { accounts.sorted { $0.number < $1.number } }

    func firstFreeNumber() -> Int? {
        let used = Set(accounts.map(\.number))
        return (1...Self.maxAccounts).first { !used.contains($0) }
    }

    func add(name: String, url: String) {
        guard let number = firstFreeNumber() else { return }
        let account = Account(id: UUID(), number: number,
                              name: Self.cleanName(name, number: number),
                              url: Self.normalize(url))
        accounts.append(account)
        save()
    }

    func update(_ account: Account, name: String, url: String) {
        guard let i = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[i].name = Self.cleanName(name, number: account.number)
        accounts[i].url = Self.normalize(url)
        save()
        WebViewPool.shared.accountChanged(accounts[i])
    }

    /// Hesabı listeden kaldırır ve bu telefondaki çerez/oturum verisini siler.
    /// Amazon'daki hesabın kendisine dokunmaz.
    func delete(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        save()
        WebViewPool.shared.discard(account.id)
        // Web görünümü bellekten çıktıktan sonra depo silinebilir. Silinemezse
        // bir sonraki açılışta purgeOrphanedStores temizler.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            WKWebsiteDataStore.remove(forIdentifier: account.id) { _ in }
        }
    }

    // MARK: - Kayıt

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Account].self, from: data) else { return }
        accounts = list
    }

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Listede olmayan hesaplardan kalmış veri depolarını siler.
    private func purgeOrphanedStores() {
        let known = Set(accounts.map(\.id))
        WKWebsiteDataStore.fetchAllDataStoreIdentifiers { ids in
            for id in ids where !known.contains(id) {
                WKWebsiteDataStore.remove(forIdentifier: id) { _ in }
            }
        }
    }

    // MARK: - Yardımcılar

    static func cleanName(_ name: String, number: Int) -> String {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Hesap \(number)" : n
    }

    static func normalize(_ url: String) -> String {
        var u = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if u.isEmpty { return defaultURL }
        let lower = u.lowercased()
        if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") { u = "https://" + u }
        return URL(string: u) == nil ? defaultURL : u
    }
}
