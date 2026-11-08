import SwiftUI

/// Hesap listesi: ekle, aç, düzenle, sil.
struct AccountsView: View {
    @ObservedObject var store: AccountStore
    var onOpen: (Account) -> Void

    @State private var editing: EditTarget?
    @State private var deleting: Account?
    @State private var showLimit = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                if store.accounts.isEmpty {
                    Text("Henüz hesap yok. Aşağıdaki düğmeyle ilk hesabını ekle.")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 48)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(store.sorted) { account in
                            tile(account)
                        }
                    }
                    .padding(8)
                }
            }
            addButton
        }
        .background(Color.pageGray.ignoresSafeArea())
        .sheet(item: $editing) { target in
            EditAccountView(target: target) { name, url in
                if let account = target.account {
                    store.update(account, name: name, url: url)
                } else {
                    store.add(name: name, url: url)
                }
            }
        }
        .alert("Hesap silinsin mi?", isPresented: Binding(
            get: { deleting != nil }, set: { if !$0 { deleting = nil } })
        ) {
            Button("Sil", role: .destructive) {
                if let account = deleting { store.delete(account) }
                deleting = nil
            }
            Button("İptal", role: .cancel) { deleting = nil }
        } message: {
            Text("\(deleting?.name ?? "") hesabının bu telefondaki oturumu ve çerezleri silinir. Amazon hesabın silinmez.")
        }
        .alert("En fazla \(AccountStore.maxAccounts) hesap eklenebilir.", isPresented: $showLimit) {
            Button("Tamam", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Çoklu Amazon")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
            Text("Her hesap kendi çerezleriyle ayrı çalışır. Açmak için dokun, düzenlemek için basılı tut.")
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.87))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.amazonDark.ignoresSafeArea(edges: .top))
    }

    private func tile(_ account: Account) -> some View {
        Button {
            onOpen(account)
        } label: {
            VStack(spacing: 6) {
                Text("\(account.number)")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.amazonOrange))
                Text(account.name)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.amazonDark)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onOpen(account) } label: { Label("Aç", systemImage: "arrow.up.right.square") }
            Button { editing = EditTarget(account: account, number: account.number) } label: {
                Label("Düzenle", systemImage: "pencil")
            }
            Button(role: .destructive) { deleting = account } label: { Label("Sil", systemImage: "trash") }
        }
    }

    private var addButton: some View {
        Button {
            if let number = store.firstFreeNumber() {
                editing = EditTarget(account: nil, number: number)
            } else {
                showLimit = true
            }
        } label: {
            Text("+  Hesap ekle")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.amazonOrange))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

struct EditTarget: Identifiable {
    let id = UUID()
    var account: Account?   // nil ise yeni hesap
    var number: Int
}

struct EditAccountView: View {
    let target: EditTarget
    var onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var url: String

    init(target: EditTarget, onSave: @escaping (String, String) -> Void) {
        self.target = target
        self.onSave = onSave
        _name = State(initialValue: target.account?.name ?? "Hesap \(target.number)")
        _url = State(initialValue: target.account?.url ?? AccountStore.defaultURL)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hesap adı") {
                    TextField("ör. Ev, İş", text: $name)
                }
                Section {
                    TextField("Açılış adresi", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Açılış adresi")
                } footer: {
                    Text("İstersen başka bir site de olabilir.")
                }
            }
            .navigationTitle(target.account == nil ? "Yeni hesap" : "Hesabı düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        onSave(name, url)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
