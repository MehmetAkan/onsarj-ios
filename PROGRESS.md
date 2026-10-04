# PROGRESS.md — onsarj iOS

Projenin adım adım günlüğü. **Bir adım, bu dosya güncellenmeden tamamlanmış sayılmaz**
(CLAUDE.md bölüm 2.5).

Yeni katılan biri yalnızca `CLAUDE.md` ve bu dosyayı okuyarak projenin durumunu anlayabilmelidir.

---

## Şu an neredeyiz

**Durum:** Altyapı tamamlandı. Proje iskeleti, 30 modüllük paket mimarisi, kod kalitesi
araçları ve CI (GitHub Actions + Xcode Cloud) çalışıyor. Tasarım sisteminin temel
katmanı yazıldı: renk paleti, tipografi, boşluk ve yarıçap token'ları.

**Sırada:** İlk ekran. Bu akışta anlamsal renk token'ları ve koyu tema da tanımlanacak.

**Yazılmış ekran veya iş mantığı yok.** `DesignSystem` dışındaki 29 modül hâlâ boş.

---

## Kayıt biçimi

Her adım şu başlıklarla yazılır: ne yapıldı, hangi dosyalar, alınan kararlar, bilinen eksikler,
sıradaki adım. En yeni kayıt en üstte olacak şekilde eklenir.

---

## Adım 9 — Tasarım sisteminin temel katmanı
**Tarih:** 2026-10-04

**Ne yapıldı**
- `ColorPalette.swift`: 7 aile, 77 renk basamağı (gray, green, red, blue, indigo,
  violet, purple), hepsi 50–950 arası.
- `Typography.swift`: Dynamic Type üzerine kurulu metin token'ları + yazı boyutu
  aralığını sınırlayan `onsarjDynamicTypeRange()`.
- `Spacing.swift`: 4pt ızgaraya oturan boşluk ölçeği, ekran kenar boşluğu,
  minimum dokunma alanı.
- `Radius.swift`: kullanım yerine göre adlandırılmış köşe yarıçapları.
- `DesignSystem.swift` yer tutucusu silindi.

**Dosyalar**
- Eklendi: `Packages/Core/Sources/DesignSystem/{ColorPalette,Typography,Spacing,Radius}.swift`
- Silindi: `Packages/Core/Sources/DesignSystem/DesignSystem.swift`
- Değişti: `CLAUDE.md` (bölüm 6.5, 6.6, 6.7)

**Renklerin kaynağı**
- Marka tarafından verilenler: `#4BBC17` (logo yeşili → green500), `#050715`
  (koyu marka rengi → gray950), `#F5F5F6` (gray100), `#E6E6EA` (gray200),
  `#C3C3CD` (gray300).
- Gray ve green ölçekleri bu çapalardan OKLCH uzayında türetildi; basamaklar
  algısal olarak eşit aralıklı.
- Red, blue, indigo, violet, purple **Tailwind v4'ün resmi OKLCH tanımlarından**
  çevrildi. Dikkat: v4'te değerler v3'ten farklı (örn. `red500` artık `#FB2C36`).

**Kararlar**
- **İki katmanlı renk sistemi (CLAUDE.md 6.5).** Ham palet + anlamsal token'lar.
  Ham palet `public` bırakıldı; başlangıçta `internal` yapılıp erişimin derleyiciyle
  engellenmesi önerildi ancak tasarımı tek kişi yönettiği için gereksiz sürtünme
  yaratacağı gerekçesiyle reddedildi.
- **Tipografi Dynamic Type üzerine kuruldu.** `Font.system(size:)` kullanılmıyor.
  Desteklenen aralık `xSmall`–`xxxLarge`; erişilebilirlik kademeleri kapsam dışı.
- **Test matrisi (CLAUDE.md 6.7):** her ekran Large ve xxxLarge yazı boyutlarında,
  iPhone SE ve Pro Max'te kontrol edilir.
- Değişen sayılar için sabit genişlikli rakam token'ları (`numeric`). Navigasyonda
  sayı güncellenirken metnin yatayda zıplamasını önlüyor.
- Özel yazı tipi yok, sistem yazı tipi kullanılıyor.

**Doğrulama**
- `swift build` (Core paketi) hatasız.
- `swiftlint lint --strict` ve `swift format lint --strict` temiz.

**Bilinen eksikler**
- **Anlamsal renk token'ları ve koyu tema yok.** İlk ekran yazılırken tanımlanacak.
- `onsarjDynamicTypeRange()` tanımlandı ama hiçbir yere bağlanmadı. `DesignSystem`
  henüz uygulama hedefine bağlı değil; ilk ekranda `App/OnsarjApp.swift` içinde
  kök görünüme uygulanacak.
- Buton köşe yarıçapı belirsiz: paylaşılan iki tasarımda farklı görünüyor
  (`Radius.pill` mi `Radius.field` mi). İlk butonda netleşecek.
- Yeşilin 700–950 tonları sRGB sınırına dayandı; koyu zeminde fazla parlak
  görünürse yumuşatılacak.

**Sıradaki adım:** İlk ekran + anlamsal renk token'ları + koyu tema.

---

## Adım 8 — CI kurulumu
**Tarih:** 2026-10-04

**Ne yapıldı**
- **GitHub Actions** (`.github/workflows/lint.yml`): SwiftLint ve swift-format,
  Linux makinelerinde. İki iş de yeşil.
- **Xcode Cloud** "Build and Test" akışı: Branch Changes (main), Pull Request Changes
  (herhangi bir daldan main'e), Manual Start. Eylemler: Build - iOS, Test - iOS.
  Post-Actions boş.
- Paylaşılan Xcode şeması ve Xcode Cloud manifest dosyası depoya eklendi.

**Dosyalar**
- Eklendi: `.github/workflows/lint.yml`,
  `Onsarj.xcodeproj/xcshareddata/xcschemes/Onsarj.xcscheme`,
  `Onsarj.xcodeproj/xcshareddata/xcodecloud/manifest.json`

**Yaşanan sorunlar ve çözümleri**
- GitHub hesabında faturalandırma kilidi vardı, işler hiç başlamadı. Ödeme çözülünce
  düzeldi. Free plan ayda 2.000 Linux dakikası veriyor; lint işlerimiz ~1 dakika sürüyor.
- `swift format --strict` ilk çalıştırmada `Packages/Domain/Package.swift` içindeki
  gereksiz virgülü yakaladı. `swift format --in-place` ile düzeltildi.
- **Şema `xcuserdata` içindeydi**, yani depoyu klonlayan kimse göremezdi. Sebep:
  "Autocreate schemes" açık olduğu için Xcode şemayı diske yazmıyordu. Edit Scheme
  açılıp kapatılınca dosya oluştu ve `xcshareddata`'ya alındı.
- `actions/checkout@v4` Node.js 20 uyarısı verdi → `v5`'e yükseltildi.
  `ubuntu-latest` 19 Ekim 2026'da Ubuntu 26'ya taşınacağı için `ubuntu-24.04`'e sabitlendi.

**Bilinen eksikler**
- TestFlight dağıtımı yok. Archive eylemi ve Post-Action, kod imzalama ve CarPlay
  yetkisiyle (K-01) birlikte kurulacak.
- Belge değişikliklerinde (`.md`) derleme atlanmıyor. Xcode Cloud saatlerinden
  tasarruf için "Custom Conditions" ile `.md` hariç tutulabilir.
- Xcode Cloud, Xcode 27 kullanıyor. Yerel sürümle ayrışırsa sabitlemek gerekebilir.

---

## Adım 7 — Kod kalitesi araçları
**Tarih:** 2026-10-04

**Ne yapıldı**
- `.swiftlint.yml`: kural denetimi. Uzunluk sınırları CLAUDE.md'den alındı
  (tip 400, fonksiyon 40 satır). `force_unwrapping`, `force_cast`, `force_try`
  ve `todo` hata seviyesinde.
- Üç özel SwiftLint kuralı CLAUDE.md kurallarını denetliyor: `no_print`,
  `no_mapbox_outside_mapboxkit`, `no_hardcoded_hex_color`.
- `.swift-format`: biçimlendirme. 120 karakter satır, 4 boşluk girinti.
- `CODEOWNERS`: modül sahiplikleri. `Package.swift` dosyaları ayrıca işaretlendi —
  oradaki her değişiklik mimari karardır.
- `Tooling/Scripts/verify-ios.sh`: uygulama şemasını ve beş paketi iOS hedefi için
  `xcodebuild` ile derler. Paket şema adlarını çalışma anında keşfeder.

**Kararlar**
- **İş bölümü:** biçimlendirme swift-format'ın, kurallar SwiftLint'in işi.
  SwiftLint'in biçimlendirme kuralları kapatıldı; ikisi birden açık olsa birbirinin
  çıktısını bozar.
- **SwiftLint derleme aşamasına eklenmedi.** Her derlemeyi yavaşlatır ve açık olan
  User Script Sandboxing ayarıyla çakışır. Betikle ve CI'da çalışıyor.
- swift-format'ta `NeverForceUnwrap` ve benzerleri kapatıldı; SwiftLint zaten
  hata seviyesinde yakalıyor, ikisi birden açık olsa çift uyarı çıkar.

**Doğrulama**
- `swiftlint lint` ve `swift format lint` temiz.
- `verify-ios.sh` tüm paketleri derledi, hepsi geçti.

---

## Adım 6 — Paketlerin Xcode projesine bağlanması
**Tarih:** 2026-10-04

**Ne yapıldı**
- Beş yerel paket Xcode projesine eklendi (File → Add Package Dependencies → **Add Local**).
  Ekleme sırası bağımlılık yönünü izledi: Domain, Core, MapboxKit, Services, Features.
- Uygulama hedefine yalnızca `OnsarjCore` ve `OnsarjDomain` ürünleri bağlandı.
- Şablon artığı `ContentView.swift` silindi, yerine `App/RootView.swift` yazıldı.
  Gömülü "Hello, world!" metni ve `#Preview` bloğu kaldırıldı.
- `App/OnsarjApp.swift` içindeki çağrı `RootView()` olarak güncellendi.

**Dosyalar**
- Eklendi: `App/RootView.swift`
- Silindi: `App/ContentView.swift`
- Değişti: `App/OnsarjApp.swift`, `Onsarj.xcodeproj/project.pbxproj`

**Kurallar ve kararlar**
- **Bağlama kuralı:** Bir paket ürünü uygulama hedefine, ancak `App/` içindeki bir dosya onu
  gerçekten import ettiğinde bağlanır. 30 ürünü birden bağlamak kullanılmayan bağımlılıklar
  yaratır ve derleme grafiğini şişirir.
- **K-18 genişletildi:** Günlük akış VS Code + Xcode önizleme kanvası. Hot reload aracı
  (InjectionNext, HotSwiftUI) kullanılmayacak; her SwiftUI görünümüne geliştirme aracına özel
  satır eklemeyi gerektiriyor ve bu bölüm 2.3 ile çatışıyor.
- **CLAUDE.md bölüm 2.6 eklendi:** Ajanlara iş devretme kuralları. Ajanların ne okuyacağı,
  neye dokunmayacağı, hangi durumlarda durup soracağı ve `PROGRESS.md` kaydının zorunlu alanları.

**Doğrulama**
- Command+B hatasız derledi; Command+R ile simülatörde boş ekran açıldı.
- `git status --short` yalnızca beklenen dosyaları gösterdi; `Packages/` altında
  istenmeyen değişiklik yok.

**Bilinen eksikler**
- SwiftUI önizlemesi "Cannot use previews in this file" uyarısı verdi. İlk gerçek ekranda
  tekrar bakılacak; `SWIFT_COMPILATION_MODE = incremental` ayarıyla ilgili olabilir.
- `verify-ios.sh` henüz yazılmadı.

**Sıradaki adım:** Kod kalitesi araçları — `.swiftlint.yml`, `.swift-format`, `CODEOWNERS`,
`Tooling/Scripts/verify-ios.sh`.

---

## Adım 5 — Git deposu ve GitHub'a ilk yükleme
**Tarih:** 2026-10-03

**Ne yapıldı**
- `git init -b main` ile depo başlatıldı.
- `.gitignore`'un çalıştığı doğrulandı: `DerivedData`, `xcuserdata`, `.build/`,
  `Secrets.xcconfig` ve `.DS_Store` izlenmiyor.
- İlk commit atıldı ve `github.com/MehmetAkan/onsarj-ios` deposuna gönderildi.

**Bilinen eksikler**
- `.swiftlint.yml`, `.swift-format` ve `CODEOWNERS` henüz yok; ikinci commit'te gelecek.
- Kurallar yürürlükte olmadan yazılan kod olmaması için bu adım öne alınmalı.

---

## Adım 4 — Swift Package iskeleti
**Tarih:** 2026-10-03

**Ne yapıldı**
- 5 yerel Swift Package ve 30 modül oluşturuldu: `Core` (9), `Domain` (1),
  `MapboxKit` (4), `Services` (10), `Features` (13).
- Bağımlılık grafiği CLAUDE.md bölüm 5.3'teki kurallara göre kuruldu.
- Her pakette bir test hedefi oluşturuldu (modül başına değil).
- Beş paket de `swift build` ile hatasız derlendi.

**Doğrulanan mimari sınırlar**
- `Features` paketi `Services` paketine bağlı değil — özellikler servisleri yalnızca
  `OnsarjDomain` protokolleri üzerinden tanıyor.
- Hiçbir özellik hedefi başka bir özellik hedefine bağlı değil.
- `Core`, `Domain`'i bilmiyor.
- `LiveActivityModels` sıfır bağımlılıkta; widget eklentisi yalnızca onu çekecek.
- Hiçbir `Package.swift` dosyasında dış bağımlılık yok (Mapbox dahil).

**Alınan kararlar**
- **K-18 düzeltildi:** `swift build` ana makine için derliyor, `.iOS(.v17)` orada sınanmıyor.
  UIKit/CarPlay/ActivityKit/Mapbox kullanan modüllerin doğrulaması `xcodebuild` ile yapılacak,
  komut `Tooling/Scripts/verify-ios.sh` içine sarılacak.
- **K-19:** `Telemetry` yalnızca protokol barındıracak. SDK ayrı bir `TelemetryAdapters`
  hedefine girecek. Telemetry bağımlılığı tüm servislere ve `Networking`'e eklendi;
  özelliklere eklenmedi (ekran olayları `AppRouter`'dan tek noktadan kaydedilecek).
- Boş modül yer tutucuları yalnızca yorum satırı içeriyor. Modül adıyla aynı adda boş tip
  tanımlanmıyor (ad çakışması ve nitelikli ad karışıklığı yaratıyordu).
- `CarPlayFeature`, `NavigationEngine`'e **açıkça** bağlandı. Geçişli (transitive) import'a
  güvenilmiyor; `NavigationFeature` ile tutarlı olması için.

**Bilinen eksikler**
- Paketler Xcode projesine bağlı değil; uygulama hedefi hiçbirini görmüyor.
- `verify-ios.sh` henüz yazılmadı.
- Tüm modüller boş.

---

## Adım 3 — Derleme ayarlarının xcconfig'e taşınması
**Tarih:** 2026-10-03

**Ne yapıldı**
- `Config/` klasörü ve `Base`, `Debug`, `Release` xcconfig dosyaları oluşturuldu.
- Proje düzeyinde Debug ve Release yapılandırmalarına atandı (hedefler `None` kaldı,
  projeden miras alıyorlar).
- Hedef ve proje düzeyindeki ezen değerler temizlendi: `iOS Deployment Target`,
  `Targeted Device Families`, `Swift Language Version`, `Marketing Version`,
  `Current Project Version`.
- Üç hedefin de (`Onsarj`, `OnsarjTests`, `OnsarjUITests`) Resolved değerleri doğrulandı:
  Swift 6.0, iOS 17.0, yalnızca iPhone.
- `Assets.xcassets` `App/Resources/` altına taşındı.
- Şablon artığı `ContentView.swift` → `RootView.swift` oldu, gömülü "Hello, world!" metni kaldırıldı.

**Alınan kararlar**
- **K-20:** `Staging.xcconfig` ertelendi. Backend ortam adresleri belli olmadan (K-10)
  oluşturmak uydurma değer yazmak olurdu.
- `PRODUCT_BUNDLE_IDENTIFIER` bilerek hedef düzeyinde bırakıldı; uygulama, widget ve test
  hedefleri farklı kimlikler taşıyacak.

**Bilinen eksikler**
- Hedefe özel xcconfig dosyaları (`App.xcconfig`, `Tests.xcconfig`) yok. Hedef düzeyi
  ezmeleri tekrar ederse Widgets hedefiyle birlikte kurulacak.
- `RootView` boş ekran gösteriyor; `AppRouter` ve ilk özellikler gelince dolacak.

---

## Adım 2 — Kök dosyaları
**Tarih:** 2026-10-03

**Ne yapıldı**
- `.gitignore`, `.gitattributes`, `README.md` ve `CLAUDE.md` depo köküne eklendi.
- Xcode şeması paylaşıma açıldı (Manage Schemes → Shared). CI'ın şemayı görebilmesi için şart.

**Tasarım notları**
- `Package.resolved` bilerek yok sayılmadı; ekip ve CI aynı bağımlılık sürümlerini derlemeli.
- `project.pbxproj` için otomatik birleştirme (merge=union) kullanılmadı. Sessizce bozulmuş
  proje dosyası yerine görünür çakışma tercih edildi.

---

## Adım 1 — Xcode projesinin oluşturulması
**Tarih:** 2026-10-03

**Ne yapıldı**
- Xcode'da `Onsarj` adıyla iOS App projesi oluşturuldu.
- Bundle identifier: `com.onsarj.Onsarj` — **bir daha değişmeyecek** (CarPlay yetkisi,
  APNs anahtarı ve App Store Connect kaydı buna bağlanacak).
- Test sistemi: Swift Testing + XCTest UI Tests. Storage: None (K-06 açık olduğu için).
- Kaynak klasörü Xcode içinden `App` olarak yeniden adlandırıldı.
- Supported Destinations yalnızca iPhone bırakıldı (K-05).
- Depo kök klasörü `onsarj-ios` olarak adlandırıldı.

**Yaşanan sorun ve çözümü**
- İlk denemede klasörler Finder'dan yeniden adlandırıldı; sonuç: grup yanlış klasöre bağlandı,
  `Location` **Absolute Path** oldu ve "Recovered References" oluştu. Mutlak yol, ekip
  arkadaşlarının ve CI'ın projesini açamaması demekti.
- Proje silinip yeniden oluşturuldu. **Doğru yöntem:** klasör Finder'dan değil, Xcode'un
  Project Navigator'ı içinden yeniden adlandırılır; Xcode diskte de adını değiştirir ve
  referanslar bozulmaz.

---

## Adım 0 — Kararlar ve çalışma kuralları
**Tarih:** 2026-09

**Ne yapıldı**
- `CLAUDE.md` yazıldı: çalışma ilkeleri, sabit kararlar, mimari kurallar, dosya yapısı,
  kod standartları, güvenlik ve karar defteri.
- Modül haritası ve bağımlılık kuralları belirlendi.
- Kesinleşen kararlar: K-01 (CarPlay MVP'de), K-02 (yer verisi Mapbox), K-03 (çevrimdışı
  dayanıklılık), K-04 (ödeme kapsam dışı), K-05 (iOS 17, iPhone), K-07 (Xcode Cloud +
  GitHub Actions), K-08 (MVP ücretsiz), K-09 (doğrudan APNs), K-17 (`.xcodeproj` depoda),
  K-18 (VS Code + Xcode).

---

## Açık kalemler

**Bekleyen kararlar:** K-06 (SwiftData/GRDB), K-10 (OpenAPI sözleşmesi), K-11 (canlı veri
kanalı), K-12/K-13 (çökme takibi ve analitik), K-14 (özellik bayrakları), K-15 (tasarım
token'ları), K-16 (çeviri kaynağı). Ayrıntı: CLAUDE.md bölüm 9.2.

**Acil iş:** Apple CarPlay yetki (entitlement) başvurusu. Yanıt haftalar sürebiliyor ve
yetki olmadan CarPlay simülatörde bile test edilemiyor.

**Yol haritası**
1. Paketlerin Xcode projesine bağlanması
2. Kod kalitesi araçları: `.swiftlint.yml`, `.swift-format`, `CODEOWNERS`, `verify-ios.sh`
3. CI kurulumu: Xcode Cloud akışı + GitHub Actions lint
4. Mapbox entegrasyonu ve `Secrets.xcconfig`
5. İlk sprint doğrulamaları (CLAUDE.md bölüm 10)