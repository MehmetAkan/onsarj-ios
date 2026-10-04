# PROGRESS.md — onsarj iOS

Projenin adım adım günlüğü. **Bir adım, bu dosya güncellenmeden tamamlanmış sayılmaz**
(CLAUDE.md bölüm 2.5).

Yeni katılan biri yalnızca `CLAUDE.md` ve bu dosyayı okuyarak projenin durumunu anlayabilmelidir.

---

## Şu an neredeyiz

**Durum:** Proje iskeleti tamamlandı, paketler Xcode'a bağlandı, GitHub'a yüklendi.
Uygulama derleniyor ve boş bir ekran gösteriyor.

**Sırada:** Kod kalitesi araçları — `.swiftlint.yml`, `.swift-format`, `CODEOWNERS`,
`Tooling/Scripts/verify-ios.sh`.

**Yazılmış ekran veya iş mantığı yok.** 30 modül oluşturuldu ancak hepsi boş; her birinde
yalnızca tek yorum satırı içeren bir yer tutucu dosya var.

---

## Kayıt biçimi

Her adım şu başlıklarla yazılır: ne yapıldı, hangi dosyalar, alınan kararlar, bilinen eksikler,
sıradaki adım. En yeni kayıt en üstte olacak şekilde eklenir.

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