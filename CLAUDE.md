# CLAUDE.md — onsarj iOS

Bu dosya, onsarj iOS projesinde çalışan herkes (insan geliştirici veya yapay zekâ asistanı) için
bağlayıcı çalışma sözleşmesidir. Kod yazmadan önce okunur, her oturumda geçerlidir.

**Öncelik sırası (çelişki olursa):**
1. Bu dosyadaki "Çalışma İlkeleri" ve "Sabit Kararlar"
2. `PROGRESS.md` içindeki güncel proje durumu
3. Modül ve mimari kuralları
4. Kod standartları
5. Kişisel tercih

Bu dosyadaki bir kuralı ihlal etmek gerekiyorsa **kod yazılmaz, önce proje sahibine sorulur.**

---

## 1. Proje Tanıtımı

**onsarj**, elektrikli araç sürücüleri için şarj istasyonu bulma, şarj duraklı rota planlama ve
uygulama içi adım adım navigasyon sunan bir iOS uygulamasıdır. Referans alınan ürün
ABRP (A Better Routeplanner).

**Ürünün iki temel ilkesi:**
- **Kullanım kolaylığı** — Kullanıcı sürüş halindedir; her ekran tek bakışta anlaşılmalıdır.
- **Hız** — Harita akıcı, açılış hızlı, etkileşim gecikmesiz olmalıdır.

**Kullanım ortamı:** Uygulama araç içinde, çoğu zaman hareket halinde ve **internet bağlantısının
kesilebildiği** koşullarda kullanılır. Bu, mimarinin her katmanını etkileyen bir gerçektir,
sonradan eklenecek bir özellik değildir.

**Ekip:** 3-4 kişilik iOS ekibi paralel çalışır. Uygulama uzun ömürlü ve sürekli güncel tutulacaktır.

**Kapsam:** iPhone. iPad desteği yoktur. Android ayrı bir native uygulamadır, ortak kod yoktur.

---

## 2. Çalışma İlkeleri (Bağlayıcı)

Bu bölüm dosyanın en önemli kısmıdır.

### 2.1 Adım adım ilerle
- Büyük bir iş tek seferde yapılmaz. Önce plan sunulur, onay alınır, sonra bölüm bölüm uygulanır.
- Her bölüm bittiğinde durulur, sonuç özetlenir ve devam onayı beklenir.
- "Bu arada şunu da ekledim" yaklaşımı kabul edilmez. İstenmeyen değişiklik yapılmaz.

### 2.2 Emin değilsen sor
Aşağıdaki durumlarda **kod yazılmaz, soru sorulur:**
- Mimariyi, modül sınırlarını veya bağımlılık yönünü etkileyen bir karar gerekiyorsa
- Yeni bir üçüncü parti bağımlılık eklenecekse
- Bir veri modeli veya API sözleşmesi değişecekse
- Ürün davranışı belirsizse (kullanıcı ne görmeli, hata durumunda ne olmalı)
- Bu dosyadaki bir kuralla çelişen bir şey yapmak gerekiyorsa
- İki makul çözüm varsa ve seçim geri dönüşü zor sonuçlar doğuruyorsa

Varsayımda bulunulmaz. Varsayım gerekiyorsa açıkça yazılır: "Şunu varsaydım, yanlışsa söyleyin."

### 2.3 Geçici kod yasaktır
- `TODO`, `FIXME`, "şimdilik böyle olsun", sabit kodlanmış (hardcoded) değer, yorum satırına
  alınmış kod bırakılmaz.
- Bir şey eksikse ya tam yapılır ya hiç yapılmaz ve karar defterine yazılır.
- Sahte (mock) veri yalnızca test hedeflerinde ve SwiftUI önizlemelerinde bulunur, üretim
  kodunda asla.
- "Sonra düzeltiriz" diye yazılan kod yazılmaz. Sonra hiç gelmez.

### 2.4 Modüler ve sağlam yaz
- Her yeni dosya, ait olduğu modülün içine konur. Modül dışına taşan kod yazılmaz.
- Kopyala-yapıştır ile çoğaltılan mantık kabul edilmez; ortak yere alınır.
- Bir tip 400 satırı, bir fonksiyon 40 satırı geçiyorsa bölünür.
- Büyük ve olgun iOS projelerindeki yerleşik yaklaşımlar örnek alınır; "kendimize özgü" çözüm
  ancak gerekçesi yazıldığında kabul edilir.

### 2.5 PROGRESS.md güncellenir
- Her tamamlanan adımdan sonra `PROGRESS.md` güncellenir.
- Ne yapıldı, hangi dosyalar eklendi/değişti, ne karar verildi, sırada ne var — hepsi yazılır.
- Bu dosya projenin hafızasıdır. Yeni katılan biri sadece bunu okuyarak durumu anlayabilmelidir.

### 2.6 Git işlemleri yapılmaz
- `git push`, `git pull`, `git merge`, dal (branch) oluşturma, birleştirme isteği (PR) açma
  işlemlerini **yalnızca proje sahibi yapar.**
- Asistan yerel dosya değişikliği yapar ve ne değiştiğini bildirir. Commit dahi önerilse de
  kendiliğinden atılmaz.
- Uzak depoya, CI'ya veya dağıtım ortamlarına hiçbir işlem gönderilmez.

### 2.7 Değişikliğin etkisini bildir
Bir değişiklik yapıldığında şu üç şey söylenir: ne değişti, neden değişti, neyi etkileyebilir.
Özellikle başka modülleri, ekip arkadaşlarının açık çalışmalarını veya API sözleşmesini
etkileyen değişikliklerde bu zorunludur.

---

## 3. Sabit Kararlar (Tartışmaya Kapalı)

| Konu | Karar |
|---|---|
| Platform yaklaşımı | Tamamen native iOS. React Native, Flutter, KMP kullanılmaz. Ortak kod yoktur. |
| Harita ve navigasyon | Mapbox resmi native SDK'ları. |
| Navigasyon | Uygulama içi adım adım navigasyon. Harici uygulamaya yönlendirme yoktur. |
| CarPlay | **MVP kapsamında.** Kategori: navigasyon. Kendi Mapbox stilimiz araç ekranında görünür. |
| Hesaplama yeri | Rota planlama ve batarya tahmini backend'de. iOS API tüketir, hesaplama yapmaz. |
| Dil | Türkçe ve İngilizce. |
| Cihaz | iPhone. iPad yok. |
| Minimum iOS | iOS 17. |
| Şarj başlatma / ödeme | **Kapsam dışı.** Uygulama içi şarj başlatma ve ödeme yoktur. |
| Premium | MVP'de tüm özellikler ücretsiz. Abonelik Faz 2. |

---

## 4. Teknoloji Kararları

| Alan | Karar | Not |
|---|---|---|
| Dil | Swift 6 araç zinciri | Strict concurrency hedef; Mapbox uyumu ilk sprintte doğrulanır |
| Arayüz | SwiftUI (ana), UIKit (gerektiğinde) | Navigasyon ve CarPlay UIKit tabanlı, SwiftUI'ye köprülenir |
| Durum yönetimi | Observation (`@Observable`) | TCA vb. üçüncü parti mimari çerçeve kullanılmaz |
| Bağımlılık yönetimi | Yalnızca Swift Package Manager | CocoaPods kullanılmaz |
| Modülerlik | Yerel Swift Package'lar | Bölüm 5'teki modül haritasına uyulur |
| Ağ | URLSession + async/await | Harici ağ kütüphanesi eklenmez |
| API istemcisi | swift-openapi-generator | Backend'in OpenAPI dosyasından üretilir; elle yazılmaz |
| Oturum | Keychain | Token'lar **yalnızca** Keychain'de |
| Ayarlar | UserDefaults / `@AppStorage` | Tema, birim, dil gibi basit tercihler |
| Yerel önbellek | *Karar bekliyor* (SwiftData / GRDB) | Karar defteri K-06 |
| Çoklu dil | String Catalogs (`.xcstrings`) | Metin kaynağı Android ile ortak |
| Kod kalitesi | SwiftLint + swift-format | İlk günden CI'da zorunlu |
| Test | Swift Testing (birim), XCTest UI, snapshot | Kritik akış: giriş, rota planlama, navigasyon |
| CI/CD | Xcode Cloud (derleme/test/TestFlight) + GitHub Actions (lint) | Karar defteri K-07 |
| Proje dosyası | `.xcodeproj` depoda; üretici araç yok | Karar defteri K-17 |
| Geliştirme ortamı | Kod yazımı VS Code, geri kalanı Xcode | Karar defteri K-18 |
| Performans | MetricKit + Instruments | Açılış süresi ve harita FPS düzenli ölçülür |

**Bağımlılık ekleme kuralı:** Yeni bir üçüncü parti paket, proje sahibinin onayı olmadan
eklenmez. Gerekçe, alternatifler ve bakım durumu yazılı olarak sunulur.

---

## 5. Mimari Kurallar

### 5.1 Katmanlar

```
APP        OnsarjApp (sahneler, bağımlılık kurulumu, yönlendirme) · OnsarjWidgets
   ↓
FEATURE    Ekranlar ve ekran mantığı. Birbirini import etmez.
   ↓
SERVICE / ENGINE    Veri erişimi ve SDK sarmalayıcıları.
   ↓
DOMAIN + CORE    Modeller/protokoller (saf Swift) · Altyapı
```

### 5.2 Modüller

Modüller 5 pakete dağılır. Paket = bir `Package.swift`, modül = o paketin içindeki bir hedef.

**Core paketi:** `OnsarjCore`, `DesignSystem`, `Localization`, `Networking`, `Storage`,
`LocationKit`, `Telemetry`, `PushNotifications`, `LiveActivityModels`

`LiveActivityModels` sıfır bağımlılıklıdır ve widget eklentisiyle paylaşılır.

**Domain paketi:** `OnsarjDomain` — modeller ve servis protokolleri. Saf Swift, hiçbir şeye
bağımlı değil.

**MapboxKit paketi:** `MapEngine`, `NavigationEngine`, `SearchEngine`, `CarPlayKit`

Mapbox SDK bağımlılıkları **yalnızca bu paketin `Package.swift` dosyasında** tanımlıdır.

**Services paketi:** `AuthService`, `VehicleService`, `StationService`, `PlaceService`,
`RoutePlanningService`, `SavedPlacesService`, `CommunityService`, `TripService`,
`LiveUpdateService`, `EntitlementService`

**Features paketi:** `AuthFeature`, `GarageFeature`, `HomeMapFeature`, `SearchFeature`,
`SavedPlacesFeature`, `RoutePlanningFeature`, `NavigationFeature`, `CarPlayFeature`,
`StationDetailFeature`, `PlaceDetailFeature`, `CommunityFeature`, `TripsFeature`, `ProfileFeature`

### 5.3 Bağımlılık kuralları (ihlal edilemez)

1. **Özellik modülleri birbirini import etmez.** Ekranlar arası geçişi App katmanı yönetir.
   Bir özellik "kullanıcı şunu istedi" sinyalini dışarı verir, hedef ekranı kendisi açmaz.
2. **Özellikler servis protokolünü bilir, gerçek uygulamasını bilmez.** Somut servisler yalnızca
   App katmanında bağlanır.
3. **Mapbox yalnızca `MapboxKit` paketi içinde import edilir.** Başka hiçbir modülde Mapbox tipi
   görünmez. `PlaceService` Mapbox Search'e değil `SearchEngine`'e, `CarPlayFeature` Mapbox
   `CarPlayManager`'a değil `CarPlayKit`'e bağlanır.
4. **Mapbox sürümleri tek noktada tanımlanır:** `Packages/MapboxKit/Package.swift`. Maps SDK
   ayrı bir sürümde eklenemez; Maps ve Navigation **her zaman birlikte** yükseltilir.
5. **Navigasyon oturumu tektir.** Yalnızca `NavigationEngine` oluşturur, uygulama boyunca tek
   örnek yaşar. Telefon ekranı ve CarPlay bu oturumu **dinler**, kendi oturumunu açmaz.
   Telefonda başlayan navigasyon araca bağlanınca kesintisiz devam eder ve tersi de geçerlidir.
6. **Domain ve Core hiçbir üst katmanı bilmez.** Döngüsel bağımlılık derleme düzeyinde imkânsızdır.
7. **Bağımlılık enjeksiyonu için kütüphane kullanılmaz.** `init` üzerinden enjeksiyon ve SwiftUI
   Environment yeterlidir.
8. **UIScene tabanlı yaşam döngüsü ilk günden kurulur** (telefon sahnesi + CarPlay sahnesi).
9. **Kod `App/` içinde değil, `Packages/` içinde yaşar.** `App/` hedefi incedir: yalnızca sahneler,
   bağımlılık bağlama (`Composition/`), özellikler arası yönlendirme (`Navigation/`) ve uygulama
   kaynakları bulunur. Hiçbir ekran, hiçbir iş mantığı `App/` içine yazılmaz.
10. **Paket ≠ modül.** 5 paket, ~30 hedef vardır: `Core`, `Domain`, `MapboxKit`, `Services`,
    `Features`. Her modül için ayrı `Package.swift` açılmaz.

### 5.4 Harita performans kuralı

- Şarj istasyonu pinleri **asla** SwiftUI/UIKit görünümü (view annotation) olarak çizilmez.
  Mapbox stil katmanı kullanılır: GeoJSON kaynağı + symbol layer.
- Kümeleme, Mapbox'ın **kaynak düzeyindeki** kümeleme özelliğiyle yapılır, elle hesaplanmaz.
- Binlerce istasyonda akıcılık tamamen bu kurala bağlıdır. İstisna yoktur.

### 5.5 Çevrimdışı dayanıklılık kuralı

Bağlantı kaybı istisna değil, **beklenen durumdur.**

- Rota planı ve o rotaya ait veriler (şarj durakları, durak istasyon bilgileri, adım listesi)
  navigasyon **başlarken** eksiksiz indirilir ve önbelleğe alınır.
- Bağlantı kesildiğinde navigasyon önbellekteki veriyle **kesintisiz devam eder.**
  Sesli yönlendirme cihazın kendi motoruna (AVSpeechSynthesizer) düşer.
- Canlı güncellemeler (istasyon durumu, batarya tahmini) bağlantı yokken sessizce durur;
  kullanıcıya verinin güncel olmadığı **net biçimde** gösterilir. Uygulama hata ekranına düşmez.
- Bağlantı geri geldiğinde otomatik olarak yeniden eşitlenir.
- Ağ hatası hiçbir zaman çökme veya boş ekranla sonuçlanmaz.
- *Not: Çevrimdışı harita indirme Faz 2'dir. Bu kural, indirilmiş harita olmadan da rota ve
  yönlendirmenin sürmesini kapsar.*

### 5.6 Dosya ve klasör yapısı

Bu yapı bağlayıcıdır. Yeni bir dosya, aşağıdaki ağaçta karşılığı olan klasöre konur.
Karşılığı yoksa kod yazılmaz, önce yapının nereye genişleyeceği kararlaştırılır.

```
onsarj-ios/
├── CLAUDE.md                          çalışma sözleşmesi (bu dosya)
├── PROGRESS.md                        adım adım proje günlüğü
├── README.md                          kurulum ve ilk çalıştırma
├── .gitignore
├── .gitattributes                     .xcodeproj / .xcstrings birleştirme davranışı
├── .swiftlint.yml
├── .swift-format
├── CODEOWNERS                         modül sahiplikleri
├── Onsarj.xcodeproj                   depoda tutulur (K-17)
│
├── App/                               ── UYGULAMA HEDEFİ (ince) ──
│   ├── OnsarjApp.swift
│   ├── AppDelegate.swift              APNs kaydı, cihaz token'ı
│   ├── Scenes/
│   │   ├── PhoneSceneDelegate.swift
│   │   └── CarPlaySceneDelegate.swift
│   ├── Composition/
│   │   ├── AppDependencies.swift      protokol → somut servis bağlama
│   │   └── PreviewDependencies.swift  önizleme ve test için sahteler
│   ├── Navigation/
│   │   ├── AppRouter.swift            özellikler arası TEK geçiş noktası
│   │   ├── Route.swift
│   │   └── DeepLinkHandler.swift      bildirim hedefi → ekran
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── PrivacyInfo.xcprivacy
│   └── Support/
│       ├── Info.plist
│       └── Onsarj.entitlements        CarPlay, arka plan modları (location, audio)
│
├── Widgets/                           ── LIVE ACTIVITY EKLENTİSİ ──
│   ├── OnsarjWidgetsBundle.swift
│   ├── NavigationLiveActivity/
│   └── Support/
│       ├── Info.plist
│       └── OnsarjWidgets.entitlements
│
├── Packages/                          ── TÜM KOD BURADA ──
│   ├── Core/
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   │   ├── OnsarjCore/            log, hata tipleri, birim dönüşümü, biçimlendirme
│   │   │   ├── DesignSystem/          token'lar + ortak bileşenler
│   │   │   ├── Localization/
│   │   │   │   └── Resources/Localizable.xcstrings
│   │   │   ├── Networking/
│   │   │   │   ├── openapi.yaml       backend sözleşmesi (K-10)
│   │   │   │   ├── openapi-generator-config.yaml
│   │   │   │   └── Middleware/        token ekleme, yenileme, tekrar deneme, log
│   │   │   ├── Storage/               Keychain · SwiftData · UserDefaults
│   │   │   ├── LocationKit/           izin akışı, konum akışı, arka plan yapılandırması
│   │   │   ├── Telemetry/             protokol; adaptör K-12/K-13 sonrası
│   │   │   ├── PushNotifications/     APNs kaydı, yük çözümleme, yönlendirme sinyali
│   │   │   └── LiveActivityModels/    sıfır bağımlılık; widget ile paylaşılır
│   │   └── Tests/
│   │
│   ├── Domain/
│   │   ├── Package.swift
│   │   ├── Sources/OnsarjDomain/
│   │   │   ├── Models/                Vehicle, Station, RoutePlan, Trip, Place...
│   │   │   └── Protocols/             VehicleRepository, RoutePlanner, PlaceProvider...
│   │   └── Tests/
│   │
│   ├── MapboxKit/                     ← Mapbox SDK SADECE burada tanımlı
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   │   ├── MapEngine/             stiller, istasyon katmanı, kümeleme, kamera
│   │   │   ├── NavigationEngine/      TEK navigasyon oturumu, ses, mola modu
│   │   │   ├── SearchEngine/          Mapbox Search sarmalayıcısı
│   │   │   └── CarPlayKit/            CarPlayManager, araç ekranı haritası
│   │   └── Tests/
│   │
│   ├── Services/
│   │   ├── Package.swift
│   │   ├── Sources/                   AuthService · VehicleService · StationService
│   │   │                              PlaceService · RoutePlanningService
│   │   │                              SavedPlacesService · CommunityService
│   │   │                              TripService · LiveUpdateService
│   │   │                              EntitlementService
│   │   └── Tests/
│   │
│   └── Features/
│       ├── Package.swift
│       ├── Sources/                   AuthFeature · GarageFeature · HomeMapFeature
│       │                              SearchFeature · SavedPlacesFeature
│       │                              RoutePlanningFeature · NavigationFeature
│       │                              CarPlayFeature · StationDetailFeature
│       │                              PlaceDetailFeature · CommunityFeature
│       │                              TripsFeature · ProfileFeature
│       └── Tests/
│
├── Config/                            tüm derleme ayarları (Xcode arayüzünde DEĞİL)
│   ├── Base.xcconfig
│   ├── Debug.xcconfig
│   ├── Staging.xcconfig
│   ├── Release.xcconfig
│   └── Secrets.xcconfig.template      gerçek dosya .gitignore'da
│
├── Tooling/Scripts/
│   ├── bootstrap.sh                   yeni geliştirici kurulumu
│   └── generate-api-client.sh
│
├── ci_scripts/                        Xcode Cloud (kökte olmak ZORUNDA)
│   ├── ci_post_clone.sh               Mapbox token → .netrc, SwiftLint kurulumu
│   └── ci_pre_xcodebuild.sh
│
├── .github/workflows/
│   └── lint.yml                       Linux; SwiftLint + swift-format
│
└── Docs/
    ├── Architecture.md
    └── Decisions/                     ADR-0001-....md (kararların gerekçeleri)
```

**Bir özellik modülünün içi** (örnek: `Packages/Features/Sources/StationDetailFeature/`):

```
StationDetailFeature/
├── StationDetailView.swift            ekranın kökü
├── StationDetailModel.swift           @Observable durum nesnesi
├── Components/                        ekrana özel alt görünümler
└── Resources/                         varsa modüle özel kaynaklar
```

**Yapıya dair kurallar:**

1. `App/` ve `Widgets/` **senkronize klasör** olarak tanımlanır (Xcode 16 özelliği). Böylece
   dosya eklemek `project.pbxproj`'u değiştirmez ve K-17'nin dayandığı varsayım korunur.
2. Derleme ayarı **hiçbir zaman** Xcode arayüzünden değiştirilmez; yalnızca `Config/*.xcconfig`
   düzenlenir. Arayüzden yapılan ayar proje dosyasına gömülür ve denetlenemez hale gelir.
3. Gizli anahtarlar: Mapbox **genel** erişim token'ı `Secrets.xcconfig` üzerinden gelir
   (`.gitignore`'da); Mapbox **gizli indirme** token'ı geliştirici makinesindeki `~/.netrc`
   dosyasında durur, CI'da `ci_post_clone.sh` tarafından oluşturulur. İkisi de depoya girmez.
4. Yeni modül eklemek = ilgili `Package.swift` içine hedef ve ürün tanımı yazmak. Yeni paket
   açmak, proje sahibinin onayını gerektirir.
5. `Package.swift` dosyalarındaki bağımlılık listeleri mimari kuralların denetleyicisidir.
   Bağımlılık orada yazılı değilse import derleme hatası verir. Bu listeler gevşetilmez.

---

## 6. Kod Standartları

### 6.1 Genel
- Swift API Design Guidelines geçerlidir.
- Eşzamanlılık: `async/await` ve aktörler kullanılır. Tamamlama bloğu (completion handler)
  yeni kodda kullanılmaz. Arayüz güncellemeleri `@MainActor` üzerindedir.
- Zorla açma (`!`) kullanılmaz. Tek istisna: derleme zamanında garanti edilen kaynak erişimleri
  ve testler.
- `print` kullanılmaz; `OnsarjCore` içindeki loglama arayüzü kullanılır.
- Erişim seviyesi en dar olacak şekilde yazılır. Modül dışına açılan her tip bilinçli bir karardır.
- Kullanıcıya görünen hiçbir metin koda gömülmez; String Catalog üzerinden gelir.
- Renk, yazı tipi ve boşluk değerleri koda gömülmez; `DesignSystem` token'ları kullanılır.

### 6.2 İsimlendirme
- Protokol: `StationRepository` — uygulaması: `RemoteStationRepository`, `CachedStationRepository`
- Görünüm: `StationDetailView` — durum nesnesi: `StationDetailModel`
- Dosya adı, içindeki ana tipin adıyla birebir aynıdır.

### 6.3 Hata yönetimi
- Her özellik alanı kendi hata tipini tanımlar; ham ağ hatası ekrana taşınmaz.
- Kullanıcıya gösterilen hata mesajı ne olduğunu ve ne yapılabileceğini söyler.
- Yeniden denenebilir hatalar için kullanıcıya tekrar deneme imkânı verilir.

### 6.4 Test
- Servis ve motor katmanında iş mantığı birim testiyle korunur.
- Kritik akışlar arayüz testiyle kapsanır: giriş, rota planlama, navigasyon başlatma.
- Test yazılmayan bir hata düzeltmesi tamamlanmış sayılmaz.

---

## 7. Güvenlik ve Gizlilik

- Token'lar yalnızca Keychain'de saklanır. UserDefaults'a asla yazılmaz.
- Token yenileme ağ katmanında otomatik ve **tek noktadan** yapılır.
- Hiçbir gizli anahtar depoya işlenmez.
- Log kayıtlarında telefon numarası, token veya konum verisi yer almaz.
- `PrivacyInfo.xcprivacy` eklenir ve kullanılan SDK'ların manifestleri kontrol edilir.
- KVKK aydınlatma metni ve açık rıza onayları giriş akışında yer alır.
- Konum ve bildirim izinleri, kullanıcı ilgili özelliği **ilk kullandığında** ve gerekçesi
  açıklanarak istenir. Açılışta topluca izin istenmez.
- Navigasyon için "Her zaman" konum izni istenmez; "Uygulamayı kullanırken" izni ve arka plan
  konum güncellemesi yeterlidir.
- Mapbox kaynak gösterimi (attribution) harita üzerinde görünür kalır; kaldırılamaz.

---

## 8. PROGRESS.md Kullanımı

`PROGRESS.md` projenin adım adım günlüğüdür ve **her tamamlanan adımda güncellenir.**

Her kayıt şunları içerir:
- Tarih ve adım numarası
- Ne yapıldı (kısa ve somut)
- Eklenen / değiştirilen dosyalar
- Alınan kararlar (varsa karar defteri numarasıyla)
- Bilinen eksikler
- Sıradaki adım

Kural: Bir adım, `PROGRESS.md` güncellenmeden tamamlanmış sayılmaz.

---

## 9. Karar Defteri

### 9.1 Kesinleşen kararlar

| No | Karar | Tarih |
|---|---|---|
| K-01 | CarPlay **MVP kapsamındadır.** Apple CarPlay yetki (entitlement) başvurusu yapılacaktır. | 2026-09 |
| K-02 | Yer/işletme verisi MVP'de **Mapbox** ile karşılanır. `PlaceProvider` soyutlaması kurulur; sağlayıcı değişimi ekranları etkilemez. Google Places UI Kit kapsam dışıdır, ileride yeniden değerlendirilir. | 2026-09 |
| K-03 | Çevrimdışı dayanıklılık temel gereksinimdir. Bölüm 5.5 geçerlidir. | 2026-09 |
| K-04 | Uygulama içi şarj başlatma ve ödeme **kapsam dışıdır.** İleride gerekirse yeniden ele alınır. | 2026-09 |
| K-05 | Minimum iOS 17. iPad desteği yoktur. | 2026-09 |
| K-07 | CI/CD: Derleme, test ve TestFlight **Xcode Cloud**'da (25 saat/ay, Developer Program'a dahil). SwiftLint ve swift-format kontrolü **GitHub Actions Linux** makinelerinde (macOS çarpanı yok). Mapbox indirme token'ı `ci_scripts/ci_post_clone.sh` içinde ortam değişkeninden `.netrc`'ye yazılır. **Yedek plan:** saatler yetmezse önce 100 saatlik plan, sonra ofiste Mac mini + self-hosted runner. Linux VPS'e iOS CI kurulamaz (macOS yalnızca Apple donanımında çalışır). | 2026-09 |
| K-08 | MVP'de tüm özellikler ücretsizdir. Abonelik Faz 2'dedir. `EntitlementService` protokol olarak şimdiden kurulur. | 2026-09 |
| K-09 | Bildirim: iOS'ta **doğrudan APNs** (.p8, token tabanlı). Firebase SDK projeye girmez. Android FCM kullanır; hedefleme mantığı her iki platform için de backend'dedir. Bildirim yükü yapısal hedef taşır (`tip`, `hedef: {ekran, id}`, benzersiz id) ve ekran isimleri iki platformda aynıdır. Sessiz bildirime kritik iş yüklenmez. **Bağlı not:** K-12/K-13/K-14 için Firebase ailesi seçilirse bu karar yeniden açılır; geçiş `PushNotifications` modülüyle sınırlı kalacak şekilde yazılır. | 2026-09 |
| K-17 | `.xcodeproj` **depoda tutulur**, proje üretici araç (Tuist/XcodeGen) kullanılmaz. Gerekçe: Xcode projesinde yalnızca 4 hedef var (uygulama, widget, 2 test); kodun tamamı SPM paketlerinde olduğu için dosya ekleme proje dosyasına dokunmaz; tüm derleme ayarları xcconfig'te durur. **Geçiş eşiği:** şu üçünden biri olursa XcodeGen'e geçilir — proje dosyasında 3 kez git çakışması yaşanması, Xcode hedef sayısının 6'yı geçmesi, ekibin 4 kişiyi aşması. | 2026-09 |
| K-18 | Geliştirme ortamı: **kod yazımı VS Code**, geri kalan her şey **Xcode**. Xcode'da kalanlar: simülatör, gerçek cihaz ve CarPlay testi, kod imzalama ve yetkiler, proje/şema ayarları, Instruments ile performans ölçümü, String Catalog düzenleme. Kod çoğunluğu SPM paketlerinde olduğu için VS Code'da `swift build` ve `swift test` ile modül bazında çalışılabilir. | 2026-09 |

### 9.2 Bekleyen kararlar

| No | Konu | Ne zaman gerekli | Durum |
|---|---|---|---|
| K-06 | Yerel önbellek: SwiftData mı GRDB mi? | Storage modülü doldurulurken | Açık |
| K-10 | OpenAPI sözleşmesinin teslimi | Networking modülü kurulurken | Backend'den bekleniyor |
| K-11 | Navigasyon sırasında canlı veri kanalı (sorgulama / WebSocket / push) | LiveUpdateService yazılırken | Backend ile görüşülecek |
| K-12 | Çökme takibi aracı (Sentry / Crashlytics) | Telemetry adaptörü yazılırken | Android ekibiyle ortak |
| K-13 | Analitik aracı | Telemetry adaptörü yazılırken | Android ekibiyle ortak |
| K-14 | Uzaktan yapılandırma ve özellik bayrakları | EntitlementService doldurulurken | Android ekibiyle ortak |
| K-15 | Tasarım token'larının ortak kaynağı | DesignSystem doldurulurken | Android ekibiyle ortak |
| K-16 | Çeviri metinlerinin ortak kaynağı | Localization doldurulurken | Android ekibiyle ortak |

**Kural:** Bekleyen bir karar gerektiren noktaya gelindiğinde kod yazılmaz, proje sahibine
sorulur. Karar verildiğinde bu tabloya taşınır ve `PROGRESS.md`'ye işlenir.

---

## 10. İlk Sprintte Doğrulanacaklar

Proje iskeleti kurulduktan sonra küçük bir teknik prototiple şunlar doğrulanır:

- [ ] Özel Mapbox stilinin telefonda ve CarPlay'de görünmesi
- [ ] Telefonda başlatılan navigasyonun CarPlay'e kesintisiz geçmesi
- [ ] Türkçe sesli yönlendirmenin kalitesi (sokak adları, kısaltmalar)
- [ ] Ekran kilitliyken navigasyonun sürmesi
- [ ] Birkaç bin istasyon pininin akıcı gösterimi (stil katmanı + kümeleme)
- [ ] Mapbox SDK'larının Swift 6 strict concurrency ile uyumu
- [ ] Bağlantı kesildiğinde navigasyonun önbellekle devam etmesi
