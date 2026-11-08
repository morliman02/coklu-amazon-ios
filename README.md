# Çoklu Amazon (iPhone)

Android'deki Çoklu Amazon'un iPhone sürümü. En fazla 100 hesap; her hesabın çerezleri ve oturumu
tamamen ayrı bir depoda durur, birbirine karışmaz. Varsayılan açılış adresi amazon.com.tr.

Gerekenler: Mac + Xcode 15 veya üstü, iPhone'da iOS 17 veya üstü, ücretsiz bir Apple kimliği.

## Telefona yükleme (bir kere, ~10 dk)
1. Bu `amazon-ios` klasörünü Mac'e kopyala, `CokluAmazon.xcodeproj` dosyasına çift tıkla.
2. Xcode > Settings > Accounts > **+** ile Apple kimliğinle giriş yap.
3. Soldan mavi **CokluAmazon** projesine, sonra **Signing & Capabilities** sekmesine tıkla.
   **Team** kısmından kendi adını ("Personal Team") seç.
   "Bundle identifier kullanılamıyor" hatası çıkarsa `com.fatih.amazonmulti` yazısının sonuna
   birkaç harf ekle (ör. `com.fatih.amazonmulti.f7`).
4. iPhone'u kabloyla Mac'e bağla, telefonda "Bu bilgisayara güven" de.
5. iPhone'da Ayarlar > Gizlilik ve Güvenlik > **Geliştirici Modu**'nu aç (telefon yeniden başlar).
6. Xcode'un üstündeki cihaz listesinden kendi iPhone'unu seç, ▶ (Run) düğmesine bas.
7. İlk açılışta "Güvenilmeyen geliştirici" derse: iPhone'da Ayarlar > Genel >
   VPN ve Cihaz Yönetimi > kendi Apple kimliğin > **Güven**.

**7 gün kuralı:** Ücretsiz Apple kimliğiyle yüklenen uygulama 7 gün sonra açılmaz. Telefonu Mac'e
bağlayıp Xcode'da tekrar ▶'ye basman yeter; hesapların ve oturumların silinmez.
Yıllık 99 $'lık Apple Developer hesabıyla bu süre 1 yıla çıkar.

## Kullanım
- **+ Hesap ekle**: ad ve açılış adresi gir (istersen başka bir site de olabilir).
- Hesaba dokun: o hesabın penceresi açılır, Amazon'a o hesapla giriş yap.
- Alt menü: **Ana sayfa**, **Hesabım**, **Sepet** ve hesap adının yazdığı **Hesaplar** düğmesi
  (hesap listesine döner). Geri gitmek için ekranın sol kenarından sağa kaydır.
- Hesaplar arasında gidip gelince sayfa kaldığı yerden devam eder.
- Basılı tut: Aç, Düzenle veya Sil. Silmek yalnızca bu telefondaki oturumu kaldırır.
- "Uygulamamızda alışveriş yapın" şeridi otomatik gizlenir.

## Dosyalar
- `CokluAmazon/AccountStore.swift` – hesap listesi, 100 hesap sınırı, silince veriyi temizleme
- `CokluAmazon/BrowserController.swift` – her hesap için ayrı `WKWebsiteDataStore(forIdentifier:)`,
  şerit gizleme betiği, açık pencereleri tutan havuz
- `CokluAmazon/BrowserView.swift` – tarayıcı ekranı ve alt menü
- `CokluAmazon/AccountsView.swift` – 4 sütunlu hesap ızgarası, ekleme/düzenleme
