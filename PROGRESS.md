# PROGRESS.md — onsarj iOS

Projenin adım adım günlüğü. **Bir adım, bu dosya güncellenmeden tamamlanmış sayılmaz**
(CLAUDE.md bölüm 2.5).

Yeni katılan biri yalnızca `CLAUDE.md` ve bu dosyayı okuyarak projenin durumunu anlayabilmelidir.

---

## Şu an neredeyiz

**Durum:** Altyapı tamamlandı. Proje iskeleti, 30 modüllük paket mimarisi, kod kalitesi
araçları ve CI (GitHub Actions + Xcode Cloud) çalışıyor. Tasarım sisteminin temel
katmanı yazıldı: renk paleti, tipografi, boşluk ve yarıçap token'ları.

**Sırada:** Uluslararası telefon girişinin cihaz testi (Adım 18), ardından SMS kodu ekranı.
`WelcomeModel` ve `PhoneEntryModel` birim testleri ayrı görev olarak bekliyor.

**Yazılan ekranlar:** Karşılama (`WelcomeView`) ve telefon girişi (`PhoneEntryView`),
`AppRouter` ile bağlı (Adım 11–16). `DesignSystem`, `Localization`, `AuthFeature` ve
`App/Navigation` dışındaki modüller boş.

---

## Adım 18 — Uluslararası telefon numarası girişi (K-21)
**Tarih:** 2026-10-13

**Ne yapıldı**
- `PhoneNumbers` hedefi (Core): PhoneNumberKit'in tek import noktası (5.3 kural 11).
  `PhoneNumberFormatter` (`@MainActor`; kütüphane tipleri `Sendable` değil), `PhoneCountry`
  (ISO kodu, arama kodu, bayrak, cihaz dilinden ad), `ParsedPhoneNumber` (ülke, ulusal
  rakamlar, biçimlenmiş metin, E.164, `isValid`).
- `PhoneNumberTextField`: `UITextField` sarmalayıcı. Rakam dışı karakter, ulusal ön ek (`0`)
  ve fazla basamak alana hiç girmez; yazılırken ülke biçimine göre gruplanır; imleç
  biçimlendirmeden sonra aynı rakamın arkasında kalır; ayraç silinince önceki rakam silinir.
  `+` ile başlayan yapıştırma/otomatik doldurmada ülke numaradan belirlenir.
- `CountryPicker`: aranabilir liste (ad, ISO kodu, arama kodu), sheet olarak açılır. Boş
  sonuçta `ContentUnavailableView.search`. Varsayılan ülke `Locale.current.region`, yoksa TR.
  Ülke değişince numara yeni biçime göre yeniden biçimlenir. Yer tutucu ülkenin örnek numarası.
- `onContinue` artık E.164 veriyor: `+905537359394`. Geçerlilik gevşek (uzunluk), kütüphaneden.
- `verify-ios.sh --package <Paket>`: tek paketi iOS için derler, uygulamayı atlar.
- `AppDependencies`: `PhoneNumberFormatter` tek örnek, ilk ihtiyaçta oluşturuluyor.

**Dosyalar**
- Eklendi: `Packages/Core/Sources/PhoneNumbers/{PhoneNumberFormatter,PhoneCountry,ParsedPhoneNumber}.swift`,
  `Packages/Core/Tests/PhoneNumbersTests/PhoneNumberFormatterTests.swift`, `Packages/Core/Package.resolved`,
  `Packages/Features/Sources/AuthFeature/Components/{PhoneNumberTextField,CountryPicker}.swift`,
  `App/Composition/AppDependencies.swift`
- Değişti: `Packages/Core/Package.swift`, `Packages/Features/Package.swift`,
  `Packages/Features/Sources/AuthFeature/{PhoneEntryView,PhoneEntryModel}.swift`,
  `Packages/Features/Sources/AuthFeature/Components/PhoneNumberField.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings` (3 anahtar),
  `App/RootView.swift`, `App/OnsarjApp.swift`, `Tooling/Scripts/verify-ios.sh`
- Silindi: `Packages/Features/Sources/AuthFeature/PhoneCountry.swift` (yerine `PhoneNumbers`)

**Kararlar**
- **K-21 sürüm düzeltmesi (proje sahibi onayı):** `4.3.0` yalnızca terk edilmiş
  `marmelroy` deposunda var; yeni depo `5.0.0` ile başlıyor. Kural
  `.upToNextMinor(from: "5.0.0")`, çözülen sürüm `5.0.12`. K-21 metni proje sahibince güncellenecek.
- `PhoneNumberKitUI` (hazır alan ve seçici) çekilmedi; kendi alanımız yazıldı.
- Testler ayrı `PhoneNumbersTests` hedefinde; `CoreTests` dokunulmadı (proje sahibi kararı).
- Features için platform koruması yazılmadı; `swift build` (Features) artık macOS'ta derlenmez,
  doğrulaması `verify-ios.sh --package Features` ile (proje sahibi kararı).
- UIKit yazı tipi: proje sahibinin eklediği `UITypography.numeric` kullanılıyor. Ajanın
  `Typography.swift`'e eklediği eşdeğer `numericUIFont` geri alındı (dosya HEAD ile aynı).
- Kütüphanenin `PartialFormatter`'ı iç durum taşıyor; her çağrıda yenisi oluşturuluyor.
  `PhoneNumberUtility` ilk oluşturmada ~25 ms (macOS ölçümü), bu yüzden tek örnek.
- Ülke seçici sheet; ekran içi sunum, `Route` değişmedi. Ek metin anahtarları:
  `signup.country.title`, `signup.country.search`, `signup.phone.accessibility.country`.
- Gevşek doğrulamanın sonucu: TR'de `4XX` ile başlayan 10 haneli numara da geçerli sayılır.

**Doğrulama**
- `swift build` + `swift test` (Core): geçti; `PhoneNumbersTests` 10 test / 12 durum geçti.
- `swift build` (Features): bilerek geçmez (UIKit). `verify-ios.sh` (tam): tüm şemalar geçti.
- `swiftlint --strict`, `swift format lint --strict`: ajanın dosyalarında ihlal yok.
  `UITypography.swift` ve `SemanticColors.swift` sonunda satır sonu eksik (proje sahibinin dosyaları).

**Bilinen eksikler**
- `PhoneNumbers` ürünü uygulama hedefine açıkça bağlı değil (`App/Composition` import ediyor,
  şu an `AuthFeature` üzerinden geçişli çözülüyor). Xcode'dan bağlanmalı.
- `PhoneNumberTextField` imleç/silme davranışı için otomatik test yok; cihazda elle denenmeli.
- Ülke seçici kapandıktan sonra klavye yeniden açılmıyor; kullanıcı alana dokunmalı.
- `PhoneEntryModel`, `WelcomeModel` birim testleri hâlâ ayrı görev.

**Sıradaki adım:** Cihaz testi; ardından SMS kodu ekranı.

---

## Adım 17 — Telefon ekranında özel simge
**Tarih:** 2026-10-13

**Ne yapıldı**
- Rozetteki SF Symbol (`phone.fill`) yerine proje sahibinin SVG simgesi
  (`phone-entry-icon`, 24×24, iki renkli) kullanılıyor. Gri daire korundu.
- Proje sahibinin eklediği iki ayrı görsel seti (`phone-entry-icon`,
  `phone-entry-icon-dark`) tek sette birleştirildi: koyu sürüm `Dark` görünümünde,
  `Original` çizim, vektör verisi korunuyor, tek ölçek.
- `IconBadge` artık `Image` alıyor: özel görsel kendi renk ve doğal boyutuyla, SF Symbol
  verilirse `Typography.titleSmall` + `Theme.textSecondary` ile çiziliyor.

**Dosyalar**
- Değişti: `Packages/Features/Sources/AuthFeature/Components/IconBadge.swift`,
  `Packages/Features/Sources/AuthFeature/PhoneEntryView.swift`,
  `Packages/Features/Sources/AuthFeature/Resources/Media.xcassets/phone-entry-icon.imageset/`
- Silindi: `.../Media.xcassets/phone-entry-icon-dark.imageset/`

**Kararlar**
- Simge yalnızca bu ekrana ait; `DesignSystem`'e değil `AuthFeature` kaynaklarına konuldu.
- Simge 24pt sabit (doğal boyut), yazı boyutuyla ölçeklenmiyor; daire ölçekleniyor.

**Doğrulama**
- `swift build` (Features) ve `verify-ios.sh --app`: geçti. Lint: ajanın dosyalarında ihlal yok.

**Bilinen eksikler**
- **Açık ve koyu SVG dosyaları birebir aynı.** Koyu tema sürümü proje sahibi tarafından
  `Dark` kutusuna yeniden eklenmeli.

**Sıradaki adım:** Telefon numarası biçiminin düzenlenmesi.

---

## Adım 16 — İlk yönlendirme: AppRouter ve Route
**Tarih:** 2026-10-13

**Ne yapıldı**
- `AppRouter` (`@Observable`): gezinme yığını (`path`), `push` ve `pop`. Özellikler arası
  tek geçiş noktası (CLAUDE.md 5.3 kural 1).
- `Route`: ilk hedef `phoneEntry`. Karşılama ekranı yığının tabanı, `Route`'ta yer almaz.
- `RootView`: `NavigationStack(path:)`; karşılamadaki "Telefon ile Devam Et" →
  `PhoneEntryView`, geri oku → `pop`.
- Karşılama ekranında gezinme çubuğu gizlendi; boş çubuk logoyu aşağı itiyordu.

**Dosyalar**
- Eklendi: `App/Navigation/{AppRouter,Route}.swift`
- Değişti: `App/RootView.swift` (dosya sonundaki eksik satır sonu da giderildi)

**Kararlar**
- Proje sahibi ekranı cihazda test edebilmek için bağlantıyı istedi. CLAUDE.md'deki yapıya
  uygun olarak `App/Navigation/` altında kuruldu. `App/` senkronize klasör olduğu için
  `project.pbxproj` değişmedi.
- Bağlanmamış istekler boş kapanış: "Giriş yap" ve telefon ekranındaki "Devam"
  (SMS kodu ekranı henüz yok). İlgili ekranlar yazıldığında bağlanacak.
- `DeepLinkHandler` ve ekran görüntüleme telemetrisi (K-19) kapsam dışı.

**Doğrulama**
- `verify-ios.sh --app`: geçti. `swiftlint` ve `swift format lint`: `App/` temiz.

**Bilinen eksikler**
- `PhoneEntryView` sistem geri düğmesini gizlediği için kenardan kaydırarak geri dönme
  hareketi çalışmayabilir (aşağıda, Adım 15).

**Sıradaki adım:** Proje sahibinin cihaz testi; ardından SMS kodu ekranı.

---

## Adım 15 — Telefon numarası giriş ekranı ve ortak birincil buton
**Tarih:** 2026-10-13

**Ne yapıldı**
- `PrimaryButton` (`DesignSystem/Components`): `WelcomeView`'daki gizli stil ortak bileşene
  taşındı, ölçüler birebir korundu (en az 58pt yükseklik, `Typography.button`, `Radius.button`).
  Devre dışı durumu standart `.disabled(_:)` ile; arka plan `Theme.actionPrimaryDisabled`.
- `PhoneEntryView`: gezinme çubuğu (geri oku + başlık), simge rozeti, başlık, açıklama,
  ülke kodu + numara alanı, klavyenin üstünde kalan "Devam" butonu (`safeAreaInset`).
  Açılışta numara alanı odaklanır. İçerik `ScrollView` içinde (SE + xxxLarge).
- `PhoneEntryModel`: numara yalnızca rakam olarak tutulur, `(5XX) XXX XX XX` biçiminde
  gösterilir. Geçerlilik: 10 hane, ilk hane 5. Yapıştırma/otomatik doldurmada baştaki
  `+90` ve `0` atılır. `onContinue` ülke kodu dahil yalnızca rakam verir (`905537359394`).
- `PhoneCountry`: ülke kodu, bayrak, basamak sayısı, gruplama kalıbı, ilk hane kuralı.
  Bileşene dışarıdan verilir; ülke seçimi eklendiğinde liste bu tipten oluşur.
- `PhoneNumberField`, `IconBadge` bileşenleri; 7 `signup.phone.*` metni (en + tr).

**Dosyalar**
- Eklendi: `Packages/Core/Sources/DesignSystem/Components/PrimaryButton.swift`,
  `Packages/Features/Sources/AuthFeature/{PhoneEntryView,PhoneEntryModel,PhoneCountry}.swift`,
  `Packages/Features/Sources/AuthFeature/Components/{PhoneNumberField,IconBadge}.swift`
- Değişti: `Packages/Features/Sources/AuthFeature/WelcomeView.swift` (gizli stil silindi,
  `PrimaryButton` kullanıyor), `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`

**Kararlar**
- `PhoneCountry` görevde listelenmeyen ayrı bir dosya: "dosya adı = tip adı" kuralı.
  `OnsarjDomain`'e konmadı; şimdilik yalnızca giriş akışının bilgisi.
- Gezinme çubuğu `toolbar` ile (sistem çubuğu); ekran bir `NavigationStack` içinde
  gösterilmeli. Sistem geri düğmesi gizlendi ki geri dönüş `onBack` ile App katmanından geçsin.
- `IconBadge` çapı 56pt, `@ScaledMetric` ile yazı boyutuyla ölçekleniyor (simge
  `Typography.titleSmall`); büyük yazıda simge daireden taşmasın diye.
- Klavye tipi ve `textContentType` macOS'ta yok; tek bir `#if os(iOS)` koruması
  (`phoneNumberInputTraits()`) ile `swift build` döngüsü korundu.
- Numara alanı ve ülke kodu `Typography.numeric` (sabit genişlikli rakam) kullanıyor.

**Doğrulama**
- `swift build` (Core, Features): geçti. `verify-ios.sh`: tüm şemalar geçti.
- `swiftlint --strict` ve `swift format lint --strict`: ajanın dosyalarında ihlal yok.
  `SemanticColors.swift` sonunda satır sonu eksik (proje sahibinin kaydedilmemiş değişikliği).
- Biçimlendirme mantığı geçici bir betikle sınandı (kalıcı test değil): kısmi girişler,
  11. hane reddi, `+90 …` ve `0 …` yapıştırma, harf ayıklama, ilk hane kuralı — beklendiği gibi.
- Önizleme matrisi (SE / Pro Max × Large / xxxLarge × boş / dolu) kanvasta gözle kontrol edilmedi.

**Bilinen eksikler**
- `PhoneEntryModel` ve `WelcomeModel` için birim testi yok (ayrı görev).
- Sistem geri düğmesi gizli olduğu için kenardan kaydırarak geri dönme hareketi devre dışı
  kalabilir. Cihazda kontrol edilmeli; gerekirse karar verilecek.
- Ülke kodu seçimi MVP'de yok (görev gereği).

---

## Adım 14 — Karşılama ekranı: başlık, açıklama hizası, buton köşesi
**Tarih:** 2026-10-12

**Ne yapıldı** (proje sahibinin cihaz kontrolüne göre)
- Slayt başlığı `Typography.display` (34pt) → `Typography.title` (28pt). İstek ~%10
  küçültmeydi (~31pt); Dynamic Type'ta 34 ile 28 arasında kademe yok, en yakın olan seçildi.
  Harf aralığı %2 daraltmaya çıkarıldı (28pt için -0,56, `relativeTo: .title`); %1 cihazda
  yetersiz göründü.
- Açıklama metni en az 2 satırlık yer kaplıyor (`lineLimit(2...)`). Tek satıra sığan
  açıklamada da görsel ve başlık diğer slaytlarla aynı hizada kalıyor. Metin 2 satırı
  aşarsa (dar ekran, büyük yazı) kırpılmadan uzuyor.
- `Radius.button` 16 → 20pt.
- Açıklama sütunu en fazla 300pt genişliğinde (`@ScaledMetric`, yazı boyutuyla ölçekleniyor).
  Geniş ekranlarda (Pro Max) 1. slaydın açıklaması tek satıra sığıyor ve altında boş satır
  kalıyordu; artık altı açıklama da (en + tr) iki satıra bölünüyor. Metinlerin tek satır
  genişliği 15pt'de ölçüldü: 370–434pt.

**Dosyalar**
- Değişti: `Packages/Core/Sources/DesignSystem/Radius.swift`,
  `Packages/Features/Sources/AuthFeature/Components/OnboardingSlide.swift`

**Kararlar**
- Açıklamanın satırları elle bölünmedi (metne `\n` eklenmedi). Satırın nerede kırılacağı
  ekran genişliğine, dile ve yazı boyutuna bağlı; elle bölme SE ve xxxLarge'da bozulur.
  Bunun yerine her açıklamaya en az 2 satırlık yer ayrıldı.
- `Radius.button` yalnızca bu butonda kullanılıyor; token değeri güncellendi.

**Doğrulama**
- `swift build` (Core, Features): geçti. `verify-ios.sh --app`: geçti.
- `lineLimit(2...)` davranışı `ImageRenderer` ile ölçüldü: tek satırlık metin 2 satır
  yüksekliği aldı, uzun metin sınırsız uzadı.
- Lint: ajanın dosyalarında ihlal yok. `App/RootView.swift` sonunda satır sonu eksik
  (proje sahibinin dosyası).

**Bilinen eksikler**
- Cihazda gözle kontrol edilmedi. `WelcomeModel` birim testleri bekliyor.

**Sıradaki adım:** Proje sahibinin cihaz kontrolü.

---

## Adım 13 — Karşılama ekranı görsel düzeltmeleri (cihaz testi sonrası)
**Tarih:** 2026-10-12

**Ne yapıldı** (proje sahibinin iPhone 16 üzerindeki testine göre)
- Logo %10 büyütüldü: `BrandAsset.logoHeight` 32 → 35pt.
- Slayt illüstrasyonları ekranın iki kenarına dayanıyor (yatay kenar boşluğu yalnızca
  metne uygulanıyor). Dikey alan yetmezse görsel küçülmüyor, üstten/alttan kırpılıyor
  (CSS `object-fit: cover` karşılığı). Yeterli alanda doğal oranında, kırpılmadan görünüyor.
- Slayt başlığı `Typography.title` (28pt) → `Typography.display` (34pt); harf aralığı
  punto büyüklüğünün %1'i kadar daraltıldı (`@ScaledMetric`, yazı boyutuyla ölçekleniyor).
  İlk denemedeki %10 cihazda fazla sıkı göründü.
- Başlık–açıklama arası `Spacing.sm` → `Spacing.xs`.
- Birincil buton yüksekliği ~54 → 58pt. İlk denemede 64pt (%20) ve 20pt yazı denendi;
  cihazda fazla büyük göründü, yükseklik %10 azaltıldı ve yazı 17pt'ye geri alındı.
- Giriş satırı `Typography.caption` (13pt) → `Typography.secondary` (15pt).

**Dosyalar**
- Değişti: `Packages/Core/Sources/DesignSystem/BrandAsset.swift`,
  `Packages/Features/Sources/AuthFeature/WelcomeView.swift`,
  `Packages/Features/Sources/AuthFeature/Components/OnboardingSlide.swift`

**Kararlar**
- `Typography.button` önce 20pt'ye çıkarıldı, cihaz kontrolünden sonra 17pt'ye geri alındı.
  Sonuçta `Typography.swift` değişmedi.
- İllüstrasyon en-boy oranı `OnboardingSlide` içinde `private` sabit (1:1). Görseller kare
  değişirse güncellenmeli.
- Buton en küçük yüksekliği (`58`) ve başlık harf aralığı (`-0.34`, 34pt'nin %1'i) bileşene
  özel `private` sabitler (Adım 12'deki "boyut ≠ boşluk" kararı).

**Doğrulama**
- `swift build` (Core, Features): geçti.
- `verify-ios.sh --app`: geçti.
- `swiftlint --strict` ve `swift format lint --strict`: ajanın dosyalarında ihlal yok. Tek ihlal
  hâlâ `App/RootView.swift` sonunda satır sonu eksik (proje sahibinin dosyası).

**Bilinen eksikler**
- Değişiklikler cihazda ve iPhone SE + xxxLarge'da henüz gözle kontrol edilmedi.
- `WelcomeModel` birim testleri (Adım 12'den devam).

**Sıradaki adım:** Proje sahibinin cihaz kontrolü ve sonraki görsel düzeltmeler.

---

## Adım 12 — Karşılama ekranı düzeltmeleri ve macOS platform bildirimi
**Tarih:** 2026-10-12

**Ne yapıldı**
- Beş paketin `platforms` bildirimine `.macOS(.v14)` eklendi. `swift build` artık beş pakette
  de macOS'ta geçiyor; günlük geri bildirim döngüsü hızlı kalıyor.
- Otomatik ilerleme **son slaytta duruyor**, başa dönülmüyor. Son slayda bir kez
  ulaşıldıktan sonra zamanlayıcı bir daha başlamıyor; parmakla kaydırma çalışmaya devam ediyor.
- `BrandAsset.logoHeight` (32pt) eklendi; logo bu yükseklikte, genişliği en-boy oranından
  hesaplanarak gösteriliyor (önceden doğal boyutu 291×82 pt idi).
- `PageIndicator` nokta boyutları `Spacing` yerine dosyaya özel `private` sabitlerden
  geliyor (çap 8pt, aktif kapsül genişliği 24pt). Noktalar arası aralık `Spacing.sm` kaldı.
- `WelcomeModel` zamanlayıcı mantığı üç bağımsız koşulu birleştiriyor: ortam izni
  (ön plan + VoiceOver kapalı), kullanıcının kaydırması (sıfırlama), son slayda ulaşılması.

**Dosyalar**
- Değişti: `Packages/{Core,Domain,MapboxKit,Services,Features}/Package.swift` (yalnızca
  `platforms` satırı), `Packages/Core/Sources/DesignSystem/BrandAsset.swift`,
  `Packages/Features/Sources/AuthFeature/{WelcomeModel,WelcomeView}.swift`,
  `Packages/Features/Sources/AuthFeature/Components/PageIndicator.swift`

**Kararlar** (proje sahibi)
- **macOS 14 platform bildirimi:** ucuz çözüm kabul edildi. iOS'a özel API'ler
  (`UIApplication` vb.) girdikçe `swift build` yine kırılacak; o noktada `verify-ios.sh`'a
  tek paket doğrulayan bir seçenek eklenecek. `.tabViewStyle(.page)` için `#if os(iOS)`
  koruması bu yüzden yerinde kaldı (macOS'ta bu stil yok).
- **Son slaytta durma:** kullanıcı üç slaydı da görmüştür; döngü bilgi eklemeden hareket
  ekler ve `TabView` başa dönerken geriye kayarak bozuk görünür.
- **Varsayım (yanlışsa söyleyin):** son slayda ulaşıldıktan sonra kullanıcı geri kaydırsa
  da otomatik ilerleme yeniden başlamaz. Uygulama arka plandan dönünce de başlamaz.
- **Buton stili** `WelcomeView` içinde `private` kalıyor; telefon girişi ekranında ikinci
  kullanımla `DesignSystem`'e taşınacak.
- **Boyut ≠ boşluk:** bileşene özel boyutlar o bileşenin `private` sabitidir; paylaşılan
  marka öğesinin boyutu (`logoHeight`) `DesignSystem`'dedir.

**Doğrulama**
- `swift build`: Domain, Core, Services, MapboxKit, Features — hepsi geçti.
- `verify-ios.sh`: tüm şemalar geçti (uygulama dahil; `RootView` artık `WelcomeView` gösteriyor).
- `swiftlint lint --strict` ve `swift format lint --strict`: ajanın dosyalarında ihlal yok.
  Tek ihlal `App/RootView.swift` sonunda satır sonu eksik (proje sahibinin bağlama
  çalışması; ajan dokunmadı).

**Bilinen eksikler**
- `WelcomeModel` birim testi yok; ayrı görev olarak verilecek (projenin ilk testi, deseni
  kuracak): kaydırınca sıfırlama, arka planda durma, VoiceOver'da durma, son slaytta durma.
- Önizleme matrisi (CLAUDE.md 6.7) Xcode kanvasında gözle kontrol edilmedi.

**Sıradaki adım:** `WelcomeModel` birim testleri.

---

## Adım 11 — Karşılama (onboarding) ekranı
**Tarih:** 2026-10-12

**Ne yapıldı**
- `WelcomeView`: logo, üç slaytlı kaydırmalı alan (`TabView` + `.page`), sayfa göstergesi,
  tam genişlik birincil buton ve "Giriş yap" satırı. Ekran geçiş yapmaz; `onContinue` ve
  `onLogin` kapanışlarını dışarı açar (CLAUDE.md 5.3 kural 1).
- `WelcomeModel` (`@Observable`): aktif slayt ve 3 saniyelik otomatik ilerleme. Son slayttan
  sonra başa döner. Kullanıcı kaydırınca zamanlayıcı sıfırdan başlar. Uygulama ön planda
  değilken veya VoiceOver açıkken otomatik ilerleme durur.
- `PageIndicator`: aktif nokta kapsül, pasifler yuvarlak, geçiş animasyonlu. Ekran
  okuyucudan gizli (gezinme kaydırmalı alandan yapılır).
- String Catalog kuruldu: `Localizable.xcstrings`, 9 `welcome.*` anahtarı, en + tr.
  `Bundle.onsarj` erişim noktası eklendi.
- `BrandAsset.logo`: `DesignSystem` içindeki logoya erişim noktası.
- Önizleme: iPhone SE (3rd generation) ve iPhone 17 Pro Max × `Large` ve `xxxLarge`.

**Dosyalar**
- Eklendi: `Packages/Features/Sources/AuthFeature/{WelcomeView,WelcomeModel}.swift`,
  `Packages/Features/Sources/AuthFeature/Components/{OnboardingSlide,PageIndicator}.swift`,
  `Packages/Core/Sources/Localization/LocalizationBundle.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`,
  `Packages/Core/Sources/DesignSystem/BrandAsset.swift`
- Değişti: `Packages/Core/Package.swift` (`defaultLocalization: "en"`; `Localization` ve
  `DesignSystem` hedeflerine `resources`), `Packages/Features/Package.swift` (`AuthFeature`
  hedefine `resources`). Görevde izin verilen satırlar dışında değişiklik yok.
- Silindi: `Packages/Features/Sources/AuthFeature/AuthFeature.swift`,
  `Packages/Core/Sources/Localization/Localization.swift` (yer tutucular, CLAUDE.md 5.6 kural 6)

**Kararlar**
- **Buton köşesi `Radius.button`** (Adım 10 kararı). Görev metni `Radius.pill` diyordu;
  proje sahibine soruldu, `Radius.button` onaylandı.
- **`.tabViewStyle(.page)` `#if os(iOS)` ile korundu** (proje sahibi onayı, `SemanticColors`
  emsali). macOS'ta bu stil yok.
- Görev metnindeki `Assets.xcassets` yerine mevcut `Media.xcassets` kullanıldı (Adım 10
  kararı; SPM katalog adına bakmaz).
- Birincil buton stili `WelcomeView.swift` içinde `private` tanımlandı. İkinci ekranda
  birincil buton gerektiğinde `DesignSystem`'e ortak bileşen olarak taşınmalı.
- Giriş satırı `ViewThatFits` ile sığmazsa alt alta diziliyor (SE + xxxLarge).
- Sayfa göstergesi nokta boyutları `Spacing.sm` (çap) ve `Spacing.xl` (aktif genişlik)
  token'larından alındı; ayrı bir boyut token'ı yok.

**Doğrulama**
- `swift build` (Core): başarılı.
- `swift build` (Features): **başarısız.** Paket yalnızca `.iOS(.v17)` bildiriyor; macOS'ta
  varsayılan dağıtım hedefi düşük olduğu için `@Observable` (macOS 14) ve `Duration`
  (macOS 13) kullanılamıyor. Kod hatası değil, platform bildirimi meselesi (açık nokta).
- `Tooling/Scripts/verify-ios.sh`: tüm şemalar geçti (uygulama + 5 paket, AuthFeature dahil).
- `swiftlint lint --strict`: yeni dosyalarda ihlal yok. Önceden var olan 2 hata:
  `Radius.swift` ve `SemanticColors.swift` sonunda satır sonu eksik.
- `swift format lint --strict`: yeni dosyalarda ihlal yok. Önceden var olan hatalar:
  aynı iki dosyada satır sonu, `Typography.swift:70` `public extension`.
- Önizleme matrisi Xcode kanvasında **gözle kontrol edilmedi** (ajan ortamında kanvas yok).

**Bilinen eksikler**
- Ekran uygulamaya bağlı değil; `RootView` hâlâ boş. `DesignSystem`, `Localization`,
  `AuthFeature` ürünlerinin uygulama hedefine Xcode arayüzünden eklenmesi gerekiyor.
- `onsarjDynamicTypeRange()` hâlâ uygulanmadı (uygulama köküne bağlanınca).
- Son slayttan ilk slayda dönüşte `TabView` aradaki slaytların üzerinden geriye kayar.
  Kesintisiz sonsuz döngü görünümü istenirse ayrı iş.
- `WelcomeModel` için birim testi yazılmadı (görev kapsamında değildi).
- Logo SVG'nin doğal boyutunda (291×82 pt) gösteriliyor; logo boyutu için token yok.

**Sıradaki adım:** Karşılama ekranını `RootView`'a bağlamak ve 6.7 matrisinde gözle kontrol.

---

## Adım 10 — Anlamsal renk token'ları ve görseller
**Tarih:** 2026-10-12

**Ne yapıldı**
- `SemanticColors.swift`: `Theme` enum'u. Yüzey, metin, eylem, marka ve sayfa göstergesi
  token'ları; her biri açık ve koyu tema değeriyle birlikte.
- `Color(light:dark:)` yardımcısı: temayı çalışma zamanında çözer, tema değişiminde
  ekranın yeniden çizilmesi gerekmez.
- `Radius.button` eklendi (16pt).
- Görseller: `DesignSystem/Resources/Media.xcassets` → `brand-logo` (açık + koyu);
  `AuthFeature/Resources/Media.xcassets` → `onboarding-charger`, `onboarding-route`,
  `onboarding-navigation`.

**Kararlar**
- **Koyu tema değerleri mekanik olarak türetildi**, gri merdiveninin tersi alınarak
  (açıkta 950 → koyuda 50). Bunlar yer tutucu değildir: kontrast oranları korunur ve
  her ekran koyu temada doğru görünür. Tasarım ekibi koyu tema paletini ayrıca
  kurguladığında yalnızca `SemanticColors.swift` güncellenir, hiçbir ekran değişmez.
  Bu, bölüm 2.3'teki "geçici kod yasağı" ile çelişmez — eksik bir şey bırakılmıyor.
- **`Color(light:dark:)` platform korumasıyla yazıldı** (`#if canImport(UIKit)`).
  Gerekçe: UIKit macOS'ta yok, koruma olmasa `swift build` tüm `Core` paketinde
  kırılırdı ve her değişiklikte dakikalar süren `verify-ios.sh` beklenirdi. macOS dalı
  dağıtılmaz, yalnızca geliştirme döngüsünü hızlı tutar.
- **Buton yarıçapı: `Radius.button` (16pt)**, kapsül değil. Adım 9'dan beri açık olan
  soru kapandı. `card` ile aynı değerde ama ayrı token — ileride bağımsız değişebilsin.
- Katalog adı `Media.xcassets` olarak bırakıldı. SPM `.xcassets` uzantılı her klasörü
  işler, ad önemli değil.

**Bilinen eksikler**
- `DesignSystem` uygulama hedefine bağlı değil; `onsarjDynamicTypeRange()` hâlâ
  kullanılmıyor. Xcode arayüzünden proje sahibi bağlayacak.
- `Package.swift` dosyalarında `resources:` bildirimi yok. Karşılama ekranı görevinde
  eklenecek (o görev için özel izin verildi).
- **Onboarding PNG'leri büyük:** @3x dosyalar ~1,4–1,6 MB. Üç görsel × iki çözünürlük
  ≈ 9 MB. İlk açılış ekranı olduğu için uygulama boyutunu ve açılış süresini etkiler.
  Çözüm: Figma'dan PDF olarak yeniden dışa aktarmak veya ImageOptim'den geçirmek.
- Durum renkleri (başarı/uyarı/hata) henüz token olarak tanımlanmadı; ihtiyaç doğunca
  eklenecek.

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