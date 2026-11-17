# PROGRESS.md — onsarj iOS

Projenin adım adım günlüğü. **Bir adım, bu dosya güncellenmeden tamamlanmış sayılmaz**
(CLAUDE.md bölüm 2.5).

Yeni katılan biri yalnızca `CLAUDE.md` ve bu dosyayı okuyarak projenin durumunu anlayabilmelidir.

---

## Şu an neredeyiz

**Durum:** Altyapı tamamlandı. Proje iskeleti, 30 modüllük paket mimarisi, kod kalitesi
araçları ve CI (GitHub Actions + Xcode Cloud) çalışıyor. Tasarım sisteminin temel
katmanı yazıldı: renk paleti, tipografi, boşluk ve yarıçap token'ları. Mapbox Maps SDK
(11.33.1) eklendi; ana harita ekranı tam ekran harita ve "konumuma dön" butonuyla cihazda
çalışıyor.

**Uygulama akışı:** Kayıt akışı (karşılama → telefon → SMS kodu → ad-soyad) ana haritaya
bağlı (Adım 26). **Geçici:** ana sayfa tasarlanırken açılış doğrudan haritaya gidiyor
(`RootView.opensMapOnLaunch = true`, Adım 27). Oturum backend'le birlikte gelecek.

**Ana sayfa:** Alt sayfa kendi bileşenimiz `DetentSheet` (K-22); iOS'un `presentationDetents`
yapısı kullanılmıyor. **İki kademeli** (küçük, orta; K-25, Adım 33): arama alanı sayfayı
büyütmez, `onSearchTapped` ile dışarı bildirir; arama ayrı bir ekran olacak. Sayfada arama
satırı, kategori çipleri, araç kartı (Adım 33) ve alt butonlar var. Araç verisi Debug'da
fixture'dan, Release'de boş depodan geliyor (backend bekleniyor).

**Arama sayfası (Adım 36):** Ana sayfadaki arama alanından sistem `.sheet`'i olarak açılıyor; başlangıç ve
yazma halleri tamam, iOS 18.5 / 26.3 / 27.0'da UI testiyle doğrulandı. Veri Debug'da geçici tasarım
verisi (`SearchDesignFixtures`, silinecek). **Sırada:** sonuç listesi ekranı ve arama kaynağının kararı.
Proje sahibinin kararını bekleyenler: sayfa arka planının sürümler arası farkı (sistem sayfası mı,
`DetentSheet` mi), istasyon rozeti için ayrı token, `icon-category-mosque` görseli.

**Plan seçenekleri (Adım 37):** Ana sayfadaki "Seçenekler"den, arama sayfasıyla aynı sistem `.sheet`'iyle açılıyor;
şarj ağları ve ağ seçici aynı modal içinde yığınla açılıyor. Güçlü tercih (kalp) Adım 38'de kaldırıldı. Kaydet düğmesi yok, her değişiklik anında
`UserDefaults`'a yazılıyor (`RoutePreferencesStoring` arkasında; ileride backend). Şarj ağları Debug'da fixture'dan
(`FixtureChargingNetworkCatalog`, K-23), Release'de boş katalog.

**Backend sözleşme notları:** [Docs/Backend/README.md](Docs/Backend/README.md)

**İstasyon katmanı (Adım 41):** Haritada şarj istasyonları pin ve küme olarak görünüyor (GeoJSON kaynağı,
kaynak düzeyinde kümeleme, sembol katmanları; CLAUDE.md 5.4). Pine dokununca seçim ve ortalama var; detay sayfası
yok. Veri Debug'da fixture'dan (`-onsarjStationScenario dense` ile 1000 istasyon), Release'de boş depodan.

**Sırada:** İstasyon detayı (pine dokununca açılacak sayfa) ve şimşek listesi (haritanın erişilebilir karşılığı).
Kayıt akışının ekranları tamam ve ana haritaya bağlı. Kodun doğrulanması,
tekrar gönderilmesi, kayıtlı kullanıcının ayrılması ve ad-soyadın kaydı backend sözleşmesini
(K-10) bekliyor. `WelcomeModel` ve `PhoneEntryModel` birim testleri ayrı görev olarak bekliyor.

**Yazılan ekranlar:** Karşılama (`WelcomeView`), telefon girişi (`PhoneEntryView`), SMS kodu
(`VerificationCodeView`) ve ad-soyad (`NameEntryView`), `AppRouter` ile bağlı (Adım 11–22).
Ana harita (`HomeMapView`, Adım 25; yüzen butonlar ve alt sayfa Adım 27). Dolu modüller: `DesignSystem`, `Localization`,
`PhoneNumbers`, `LocationKit`, `MapEngine`, `AuthFeature`, `HomeMapFeature`, `App/Navigation`;
diğerleri boş.

**Tüm dosyası `#if canImport(UIKit)` ile korunan dosyalar (CLAUDE.md 6.8, eşik 5):** 3 —
`UITypography.swift`, `FormTextField.swift`, `HiddenNavigationBar.swift`.

---

## Adım 41 — Haritada şarj istasyonu pinleri ve kümeleri

**Tarih:** 2026-11-17

**Ne yapıldı**
- **Domain:** `GeoCoordinate`, `GeoBoundingBox` (içerme, ölçekleme; ters köşeli kutu çökmez), `StationAvailability`
  (`available | partial | unavailable | unknown`), `Station` (`network: ChargingNetwork`), `StationRepository`.
  Operatör ayrı tip değil: `ChargingNetwork`'e `logoURL` eklendi (proje sahibinin kararı).
- **Servis:** `StationDTO` ve `StationMapper` (tanınmayan müsaitlik `unknown`, aralık dışı koordinat hatası);
  `FixtureStationRepository` (tamamı `#if DEBUG`, JSON dizge → DTO → Domain, kutu süzmesi): elle yazılmış 49
  istasyon (Antalya 40, İstanbul 5, Ankara 4) ve `-onsarjStationScenario dense` ile sabit tohumlu 1000 istasyon.
  Ağ kimlikleri plan seçenekleri kataloğuyla aynı; katalog fixture'ına Shell Recharge (`net_shell`) eklendi.
  Görsel adresi doğrulaması `OnsarjCore.MediaURL`'e taşındı (araç ve istasyon eşleyicileri ortak kullanıyor).
- **Harita (`MapEngine`):** GeoJSON kaynağı + kaynak düzeyinde kümeleme + üç sembol katmanı (pinler, kümeler,
  seçili pin). Pin ve küme görselleri SwiftUI ile (`StationPinView`, `StationClusterView`) bir kez çizilip stile
  eklenir; ağ × müsaitlik × seçili ve küme yazısı başına önbellek, harita görseli ilk istediğinde üretilir. Logolar
  bir kez yüklenir; gelince o ağın görselleri yeniden çizilir. `MapView` dışa yalnızca Domain tipleriyle konuşur
  (`MapStations`: istasyonlar, seçili kimlik, kapanan alt şerit, `onStationTapped`, `onMapTapped`, `onCameraIdle`).
  Kümeye dokununca kümenin açıldığı yakınlaşmaya yumuşak geçiş. Kullanıcının konum noktası pinlerin üstünde.
- **Ana sayfa:** `StationFeed` (300 ms bekleme, önceki isteği iptal, görünen bölgenin 1,5 katını isteme, son 8 bölgeyi
  hatırlama, 3° boylam eşiği, kimliğe göre birleştirme). `HomeMapModel` depoyu `init` ile alır; pine dokununca seçim,
  harita pini alt sayfa ve butonların üstünde kalan alanın ortasına getirir, `onStationSelected` çağrılır (`App/`
  boş geçiyor); boş haritaya dokununca seçim kalkar.
- **Token:** `Palette.amber50…950`; `Theme.availabilityAvailable/Partial/Unavailable/Unknown`, `mapPinSurface`,
  `mapPinBorder`, `mapPinSelected` (iki temada green500), `mapClusterFill`, `onMapCluster`. Şimşek için mevcut
  `AppIcon.charger`.
- **Bulunan ve düzeltilen iki hata:** (1) Küre görünümünde Mapbox sınırlarında batı boylamı doğudan büyük gelebiliyor;
  `GeoBoundingBox.contains` aralık kurduğu için çöküyordu (karşılaştırmaya çevrildi, MapEngine kutuyu normalleştiriyor,
  test eklendi). (2) Kamera kullanıcıyı izlerken harita hiç boşta kalmıyor ve `onMapIdle` gelmiyordu; istasyonlar
  hiç yüklenmiyordu. İzleme sırasında görünen bölge kamera değiştikçe en sık saniyede bir bildiriliyor.

**Dosyalar**
- Eklenen: `Docs/Design/pin-taslak.png` (proje sahibi), `Docs/Backend/stations.md`,
  `Packages/Core/Sources/OnsarjCore/MediaURL.swift`, `Packages/Core/Tests/CoreTests/MediaURLTests.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Models/{GeoCoordinate,GeoBoundingBox,Station,StationAvailability}.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Protocols/StationRepository.swift`,
  `Packages/Domain/Tests/DomainTests/GeoBoundingBoxTests.swift`,
  `Packages/Services/Sources/StationService/DTO/{StationDTO,StationMapper}.swift`,
  `Packages/Services/Sources/StationService/Fixtures/{FixtureStationRepository,FixtureStationJSON,
  FixtureStationScenario,DenseStationGenerator}.swift`, `Packages/Services/Tests/ServicesTests/StationRepositoryTests.swift`,
  `Packages/MapboxKit/Sources/MapEngine/{MapStations,MapView+Stations}.swift`,
  `Packages/MapboxKit/Sources/MapEngine/Stations/{StationLayer,StationPinView,StationClusterView,StationImageFactory,
  StationImageKey}.swift`, `Packages/Features/Sources/HomeMapFeature/StationFeed.swift`,
  `Packages/Features/Tests/FeaturesTests/StationFeedTests.swift`, `OnsarjUITests/StationLayerPresentationTests.swift`
- Değişen: `CLAUDE.md` (5.6'ya `Docs/Design/` satırı, proje sahibinin izniyle), `Docs/Backend/{README,charging-networks}.md`,
  `Packages/Core/Sources/DesignSystem/{ColorPalette,SemanticColors}.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Models/ChargingNetwork.swift`,
  `Packages/Services/Sources/StationService/DTO/{ChargingNetworkDTO,ChargingNetworkMapper}.swift`,
  `Packages/Services/Sources/StationService/Fixtures/FixtureChargingNetworkCatalog.swift`,
  `Packages/Services/Sources/VehicleService/DTO/VehicleMapper.swift`,
  `Packages/Services/Tests/ServicesTests/ChargingNetworkCatalogTests.swift`,
  `Packages/MapboxKit/Sources/MapEngine/MapView.swift`,
  `Packages/Features/Sources/HomeMapFeature/{HomeMapModel,HomeMapView}.swift`,
  `Packages/Features/Tests/FeaturesTests/HomeMapModelTests.swift`,
  `App/Composition/{AppDependencies,FixtureImageExporter}.swift`, `App/RootView.swift`, `PROGRESS.md`

**Kararlar**
- **Kümeleme yaklaşımı (2.9):** GeoJSON kaynağı `cluster` + sembol katmanları, pin görselleri stile eklenmiş görsel.
  View annotation seçilmedi: Mapbox belgesi görünüm ek açıklamalarını "genellikle 100'ün altında" görünüm için
  öneriyor, üst üste binme açıkken 250'nin üstünde performansın düştüğünü yazıyor; yerleşik kümelemesi de yok. Kaynaklar:
  docs.mapbox.com/ios/maps/guides/annotations/view-annotations/, docs.mapbox.com/ios/maps/examples/point-clustering/,
  SDK 11.33.1 kaynağı (`PointClusteringExample.swift`, `GeoJSONSource.swift`, `MapboxMap.getGeoJsonClusterExpansionZoom`,
  `TapInteraction`). CLAUDE.md 5.4 ile aynı.
- **Kümeleme ayarı:** birleşme yarıçapı 50 pt, kümeleme en fazla 14. yakınlaşmaya kadar (15 = sokak düzeyi).
- **Katman sırası:** Standard'ın `top` yuvası şehir ve semt adlarının altında kaldığı için katmanlar stilin en üstüne,
  konum noktasının (`puck`) altına eklenir.
- **İstek eşiği:** `StationFeed.maximumRequestSpanDegrees = 3` (boylam; ≈7. yakınlaşma). Bekleme 300 ms, istek kutusu
  1,5 kat, hatırlanan bölge 8.
- **Küme halesi** taslaktaki kaynak değerle %22 opaklık (onaylanan varsayımda %28 yazıyordu; proje sahibinin verdiği
  ölçü esas alındı). Rengi `availabilityAvailable`.
- **Küme yazısı:** taslakta 15 ve 18 pt kalın. 6.6 `Font.system(size:)`'ı yasakladığı için `Typography.buttonSmall`
  (15) ve `Typography.headline` (17) kalın kullanıldı; büyük kümede 1 pt fark var. Görseller `large` yazı boyutunda ve
  açık temada çizilir (pin renkleri iki temada aynı).
- `MapView.accessibilityIdentifier` (`onsarj.map`): UI testleri harita hareketlerini bununla yapıyor.

**Doğrulama**
- `Packages/Domain`: `swift build`, `swift test` 36/36. `Packages/Core`: `swift build`, `swift test` 28 + 10.
- `Packages/Services`: `swift build`, `swift test` 69/69, `swift build -c release` geçti.
- `./Tooling/Scripts/verify-ios.sh --package MapboxKit` ve `--package Features`: geçti.
- `xcodebuild test` Features (iPhone SE, iOS 18.3): 78/78 (yeni: `StationFeedTests` 4, seçim testi 1).
- Tüm UI test paketi (iPhone 16 Pro Max, iOS 18.5, konum izni verili): 14/14. `StationLayerPresentationTests`
  iOS 18.5 açık ve koyu temada 4/4; iOS 26.3 açık ve koyu temada sokak düzeyi testi geçti, uzaklaşma gerektiren 3 test
  atlandı (bkz. açık noktalar). Ekran görüntüleri: dört müsaitlik rengi ve logolar, şimşekli pin, seçili pin ve
  ortalama, seçimin kalkması, kümeler (2–9), kümeye dokununca yakınlaşma, `dense` senaryosunda kümeler ve kaydırma.
- `dense` (1000 istasyon) kaydırma: simülatörde gözlemde takılma yok; ölçüm (`XCTHitchMetric`) yalnızca iOS 26'da var ve
  orada hareketler haritaya ulaşmadığı için ölçülemedi. Cihazda Instruments ile ölçülmeli.
- Release (simülatör): `FixtureStationRepository`, `DenseStationGenerator`, `handwrittenJSON`, `FixtureImageExporter`
  sembolleri 0, fixture istasyon adları 0, `NoStationsRepository` mevcut. Logo kataloğu ayarsız Release'de
  `Assets.car`'a giriyor (4 logo); `EXCLUDED_SOURCE_FILE_NAMES = */DebugFixtures/*` ile girmiyor (`Assets.car` hiç
  oluşmuyor; uygulamanın kendi kataloğunda derlenen görsel yok). Satırı proje sahibi `Release.xcconfig`'e ekleyecek.
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.
- Not: konum izni verili simülatörde harita kullanıcıyı izlerken sürekli hareket ettiği için XCUITest bazı adımlarda
  uygulamanın boşa çıkmasını ~15 dk bekliyor (test geçiyor, süre uzuyor).

**Bilinen eksikler ve açık noktalar**
- **Erişilebilirlik:** pinler ve kümeler stil katmanında çizildiği için VoiceOver'da erişilemez; Mapbox stil
  katmanlarına erişilebilirlik etiketi verilemiyor. Erişilebilir yol sonraki görevlerdeki **şimşek listesi** olacak.
- **Hata:** istasyon isteği hata verirse haritada o bölgenin pinleri gösterilmez, kullanıcıya hata çıkmaz; kayıt
  Telemetry bağlanınca eklenecek.
- **Logo alanı:** taslakta logonun arkasında açık gri bir iç daire görünüyor; bunun için token yok, logo beyaz
  dairenin içinde 34 pt'lik daireye kırpılıyor. İstenirse ayrı token eklenmeli.
- **Pin gölgesi** açık tema değeriyle çiziliyor (görseller tek kez, açık temada çizilir).
- **Konum noktası** izleme sırasında ekranın alt kısmında (y ≈ 700 pt / 956) duruyor; alt sayfa açıkken noktanın
  hemen üstü sayfayla kapanıyor. Bu davranış bu görevden önce de vardı; izleme kamerasına alt sayfa payı verilmesi
  ayrı iş.
- **iOS 26 UI testi:** XCUITest'in iki parmakla dokunuş, kıstırma ve sürükleme hareketleri iOS 26.3 simülatöründe
  Mapbox haritasına ulaşmıyor; uzaklaşma gerektiren üç test orada atlanıyor (sokak düzeyi testi iki sürümde koşuyor).
- `onStationSelected` `App/`'te boş; istasyon detayı sonraki görev.

**Sıradaki adım:** İstasyon detayı sayfası (pine dokununca) ve şimşek listesi.

---

## Adım 40 — Araçlarınız ve Araç ekle (GarageFeature)

**Tarih:** 2026-11-15

**Ne yapıldı**
- **Önceki görevden kalanlar:** `SwipeBackProbeTests` silindi. Varsayılan araç silinince kalanlardan en son
  eklenen varsayılan olur (fixture uyguluyor, `vehicles.md` açık noktası kapandı). `ValueEditorSheet.initialText`
  kaldırıldı: geçersiz hal önizlemesi tüketimi aralık dışında (60) olan bir önizleme aracıyla kuruluyor.
- **Domain:** `VehicleBrand`, `VehicleModel`, `VehicleVariant`, `VehicleCatalog` protokolü;
  `VehicleRepository.addVehicle(variantID:)` ve `setDefaultVehicle(_:)`; hata `variantNotFound`,
  `invalidValue(.isDefault)`; `DrivingProfile.defaultMaxSpeedKmh` (120).
- **Servis:** katalog DTO'ları ve `VehicleCatalogMapper`; `FixtureVehicleCatalog` (10 marka, 20 model, 22 varyant;
  değerler örnek). `CreateVehicleRequestDTO` (`POST /vehicles`), varsayılan için `PATCH` gövdesine `isDefault`.
  Fixture backend aracı varyanttan oluşturuyor, varsayılanı tek tutuyor.
- **Ekranlar:** `GarageView` (kök, iki başlangıç), Araçlarınız (`VehicleListPage`, etkin araçta çerçeve),
  markalar (arama, logo yoksa araç simgesi, "N model"), modeller, varyantlar (onaysız ekleme, eklerken
  diğer satırlar pasif). `GarageModel`, `AddVehicleModel` (katalog yanıtları bellekte).
- **Ortak:** `SearchText` (`OnsarjCore`; şarj ağı fixture'ındaki arama anahtarı buraya taşındı, iki yer
  kullanıyor; yer tutucu `OnsarjCore.swift` silindi). `SearchField` (`DesignSystem`; proje sahibinin onayıyla
  `NetworkSearchField`'dan taşındı). `AppIcon.vehicle` (`car.fill`, iOS 13).
- **App:** `AppRouter.garage` (`GaragePresentation`), `onSwitchVehicle` ve `onAddVehicle` bağlandı; garaj ve
  ayarlar kapanınca kart yenileniyor (`vehiclesDidChange`). Release'de `EmptyVehicleCatalog`.

**Dosyalar**
- Eklenen: `Packages/Core/Sources/OnsarjCore/SearchText.swift`, `Packages/Core/Tests/CoreTests/SearchTextTests.swift`,
  `Packages/Core/Sources/DesignSystem/Components/SearchField.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Models/VehicleCatalogModels.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Protocols/VehicleCatalog.swift`,
  `Packages/Services/Sources/VehicleService/DTO/{VehicleCatalogDTOs,VehicleCatalogMapper}.swift`,
  `Packages/Services/Sources/VehicleService/Fixtures/{FixtureVehicleCatalog,FixtureVehicleCatalogJSON}.swift`,
  `Packages/Services/Tests/ServicesTests/VehicleCatalogTests.swift`,
  `Packages/Features/Sources/GarageFeature/{GarageView,GarageModel,AddVehicleModel,VehicleListPage,BrandListPage,
  ModelListPage,VariantListPage}.swift`,
  `Packages/Features/Sources/GarageFeature/Components/{CatalogList,VehicleListCard}.swift`,
  `Packages/Features/Tests/FeaturesTests/GarageModelTests.swift`, `OnsarjUITests/GaragePresentationTests.swift`,
  `Docs/Backend/vehicle-catalog.md`
- Silinen: `OnsarjUITests/SwipeBackProbeTests.swift`, `Packages/Core/Sources/OnsarjCore/OnsarjCore.swift`,
  `Packages/Services/Sources/StationService/Fixtures/NetworkSearchKey.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/Components/NetworkSearchField.swift`
- Değişen: `Packages/Domain/Sources/OnsarjDomain/{Protocols/VehicleRepository,Models/VehicleRepositoryError,
  Models/DrivingProfile}.swift`, `Packages/Services/Sources/VehicleService/DTO/{VehicleDTO,VehicleRequestDTOs}.swift`,
  `Packages/Services/Sources/VehicleService/Fixtures/{FixtureVehicleRepository,FixtureVehicleBackend}.swift`,
  `Packages/Services/Sources/StationService/Fixtures/FixtureChargingNetworkCatalog.swift`,
  `Packages/Services/Tests/ServicesTests/{VehicleRequestDTOTests,ChargingNetworkCatalogTests}.swift`,
  `Packages/Features/Sources/GarageFeature/{VehicleSettingsModel,ValueEditorSheet,Vehicle+Presentation}.swift`,
  `Packages/Features/Sources/GarageFeature/Components/{NoticeBanner,PreviewGarageSources}.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/PreviewVehicleSources.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/NetworkPickerView.swift`,
  `Packages/Features/Tests/FeaturesTests/TestVehicles.swift`, `Packages/Core/Sources/DesignSystem/AppIcon.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`, `App/Navigation/AppRouter.swift`,
  `App/RootView.swift`, `App/Composition/AppDependencies.swift`, `Docs/Backend/{README,vehicles}.md`, `PROGRESS.md`

**Kararlar**
- **Sunum (2.9):** sistem `.sheet`; `GarageView` kademeleri kendisi yönetir (`presentationDetents(_:selection:)`).
  Araçlarınız, sayfanın ölçtüğü ideal yükseklikte (üst çubuk + kartlar + düğme + alt güvenli alan) açılır;
  yığına sayfa eklenince `.large`'a, geri dönünce yeniden içerik yüksekliğine geçer. Kartın "Araç ekle"sinden
  yalnızca `.large`. iOS 18.5 ve 26.3'te çalıştırılıp ekran görüntüleriyle karşılaştırıldı.
  Davranış iki sürümde tutarlı: içerik yüksekliği doğru ölçülüyor (bir ve iki araçla, kesilme yok), "Yeni araç ekle"
  tam yüksekliğe çıkıyor, geri dönüş yeniden iniyor. Tek fark sistem görünümü: iOS 26.3'te içerik yüksekliğindeki
  sayfa kenarlardan içeride ("yüzen") çiziliyor, 18.5'te tam genişlik; tam yükseklikte ikisi de tam genişlik
  (K-22'deki davranış; değer modalında kabul edilen farkla aynı).
- **Varsayılan araç `PATCH /vehicles/{id}` ile** (`{"isDefault": true}`), ayrı uç nokta yok; `false` reddedilir.
- **Silinen varsayılan araç:** kalanlardan en son eklenen varsayılan olur (proje sahibinin kararı; backend kuralı).
- **Ortak metin taşımaları:** `networks.noResults` → `common.noResults` (ağ seçici, markalar);
  `vehicleSettings.saveFailed` → `common.saveFailed` (araç ayarları, Araçlarınız).
- `garage.modelCount %lld` anahtarı String Catalog çoğul biçimindedir; çoğul için anahtar `%lld` taşır
  (Türkçede tek biçim "N model", İngilizcede "1 model" / "N models").
- Profil adı karşılaştırmasında Türkçe `I/ı`, `İ/i` kuralı onaylandı (Adım 39).

**Doğrulama**
- `Packages/Core`: `swift build`, `swift test` 26/26.
- `Packages/Domain`: `swift build`, `swift test` 31/31.
- `Packages/Services`: `swift build`, `swift test` 62/62, `swift build -c release` geçti.
- `./Tooling/Scripts/verify-ios.sh --package Features`: geçti. Uygulama Debug derlemesi geçti.
- `xcodebuild test` Features (iPhone SE, iOS 18.3): 73/73.
- `GaragePresentationTests` (2 test) iOS 18.5'te geçti: karttaki adla Araçlarınız → "Yeni araç ekle" → Togg → T10X
  → V1 RWD → kart "Togg T10X"; Araçlarınız'dan BYD → kart "BYD Dolphin"; `noVehicles` ile "Araç ekle" doğrudan
  markaları açıyor, geri düğmesi yok, "BYD" araması yalnızca BYD'yi bırakıyor.
- iOS 26.3, tüm UI test paketi (10 test): garaj (2), araç ayarları (2), plan seçenekleri (2), arama (2) ve
  başlangıç testleri geçti.
- Uygulama Release: `FixtureVehicleCatalog`, `fixtureVehicleCatalogJSON`, `FixtureVehicleBackend`,
  `FixtureVehicleRepository`, `PreviewGarageRepository` sembolleri 0; `variant_togg` dizgesi 0; `GarageView` ve
  `EmptyVehicleCatalog` mevcut.
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.

**Bilinen eksikler ve açık noktalar**
- **Açık nokta:** Kayıt akışı yeniden giriş noktası olduğunda kenardan kaydırarak geri dönme, o akışın kendi UI
  testi olarak yazılacak (`SwipeBackProbeTests` silindi; `RootView.opensMapOnLaunch` hâlâ `true`).
- **Geçici:** katalog ve araç değişiklikleri yalnızca bellekte; uygulama yeniden açılınca fixture'a döner.
- Katalog logoları ve görselleri `null`; eklenen Togg aracı görselsiz (BYD fixture aracının görseli bir Togg
  çizimi, Adım 35'ten bilinen tutarsızlık).
- Görselsiz araç kartı görselli karttan alçak (görsel alanı gizleniyor).
- Araçlarınız'da silme ve düzenleme yok (ayarlar sayfasında).

**Sıradaki adım**
- İstasyon katmanı (CLAUDE.md 5.4) veya kayıt akışının yeniden giriş noktası olması.

---

## Adım 39 — Araç ayarları ve sürüş profilleri (GarageFeature)

**Tarih:** 2026-11-15

**Ne yapıldı**
- **Ortak metinler (0):** `common.back`, `common.close`, `common.retry`, `common.search`, `common.save`,
  `common.cancel`, `common.delete` eklendi; ekranlar arası paylaşılan kullanımlar bunlara taşındı, eski
  anahtarlar silindi (taşıma tablosu aşağıda).
- **K-26 (1):** `CLAUDE.md` 9.1'e K-26 ve ek notu, 5.6'ya `Docs/Backend/` satırı eklendi (proje sahibinin izniyle).
- **Domain:** `DrivingProfile` (sınırlar: tüketim 5,0…50,0, hız 50…250, ad ≤ 40 ve araçta benzersiz),
  `DrivingProfileDraft`, `VehicleUpdate`, `VehiclePaint` (8 boya), `VehicleRepositoryError`; `Vehicle`'a
  `drivingProfiles`, `activeProfileID`, `activeProfile`, `batteryDegradationPercent` (aralık 0…50) eklendi,
  `consumptionWhPerKm` ve `rangeKm` kaldırıldı. Menzil: `kapasite × sağlık × yüzde ÷ etkin tüketim`
  (fixture %30 → 97 km). `VehicleRepository`'ye beş yazma işlemi.
- **Servis:** DTO'ya profiller ve `activeProfileId`; istek DTO'ları `UpdateVehicleRequestDTO`
  (etkin profil de bununla), `DrivingProfileRequestDTO`. `FixtureVehicleRepository` artık `actor`;
  `FixtureVehicleBackend` istekleri bir backend gibi doğrulayıp bellekteki DTO'ya uygular.
- **Ekranlar:** araç ayarları (görsel, profil çipleri, tüketim/hız, ayrıntılar, boya, "Aracı sil" + onay),
  değer modalı, konnektör türleri, sürüş profilleri listesi (kaydırarak sil), profil formu. Anlık seçimler
  hata olursa geri döner ve "Değişiklik kaydedilemedi" bildirilir.
- **Ana sayfa kartı:** alt başlık etkin profil adı; menzil yeni hesap; dişli aracın kimliğini verir; ayarlar
  kapanınca kart yenilenir (`vehicleRevision`), araç silindiyse "Araç ekle".
- **DesignSystem (proje sahibinin onayıyla):** `ModalHeader`, `WrappingHStack`, `SelectableChip`,
  `AddRowButton`/`InsetDivider` `RoutePlanningFeature`'dan taşındı; iki özellik de bunları kullanıyor.
  `AppIcon.disclosure` (`chevron.right`, iOS 13) eklendi.
- `Docs/Backend/` açıldı: `README.md`, `vehicles.md`, `route-preferences.md`, `charging-networks.md`.

**Metin anahtarı taşımaları**

| Eski | Yeni | Kullanan ekranlar |
|---|---|---|
| `signup.phone.accessibility.back` ("Geri dön") | `common.back` ("Geri") | Telefon, SMS kodu, ad ekranları; plan seçenekleri ve garaj üst çubuğu |
| `search.close` | `common.close` | Arama; plan seçenekleri ve garaj üst çubuğu |
| `vehicleCard.retry` | `common.retry` | Araç kartı, ağ seçici, araç ayarları |
| `search.submit` | `common.search` | Arama "Ara" düğmesi, ağ seçici yer tutucusu |
| `search.delete` | `common.delete` | Arama geçmişi, profil listesi, araç silme onayı |

`home.search.placeholder` ana sayfa ve arama sayfasında aynı soruyu sorduğu için ortak bırakıldı.

**Dosyalar**
- Eklenen: `Packages/Domain/Sources/OnsarjDomain/Models/{DrivingProfile,DrivingProfileDraft,VehicleUpdate,
  VehiclePaint,VehicleRepositoryError}.swift`, `Packages/Domain/Tests/DomainTests/DrivingProfileTests.swift`,
  `Packages/Services/Sources/VehicleService/DTO/VehicleRequestDTOs.swift`,
  `Packages/Services/Sources/VehicleService/Fixtures/FixtureVehicleBackend.swift`,
  `Packages/Services/Tests/ServicesTests/{FixtureVehicleWriteTests,VehicleRequestDTOTests}.swift`,
  `Packages/Features/Sources/GarageFeature/{VehicleSettingsView,VehicleSettingsPage,VehicleSettingsModel,
  ValueEditor,ValueEditTarget,ValueEditorSheet,ConnectorTypesView,DrivingProfilesView,DrivingProfileForm,
  DrivingProfileFormView,Vehicle+Presentation}.swift`,
  `Packages/Features/Sources/GarageFeature/Components/{SettingsRow,ValueInputField,PaintPicker,NoticeBanner,
  PreviewGarageSources}.swift`, `Packages/Features/Tests/FeaturesTests/{TestVehicles,
  VehicleSettingsModelTests}.swift`, `Packages/Core/Sources/DesignSystem/Components/{ModalHeader,
  SelectableChip,AddRowButton}.swift`, `OnsarjUITests/VehicleSettingsPresentationTests.swift`,
  `Docs/Backend/{README,vehicles,route-preferences,charging-networks}.md`
- Taşınan: `RoutePlanningFeature/Components/WrappingHStack.swift` → `DesignSystem/Components/WrappingHStack.swift`
- Silinen: `Packages/Features/Sources/GarageFeature/GarageFeature.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/Components/ModalHeader.swift`
- Değişen: `CLAUDE.md` (5.6, K-26), `Packages/Domain/Sources/OnsarjDomain/Models/Vehicle.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Protocols/VehicleRepository.swift`,
  `Packages/Domain/Tests/DomainTests/VehicleTests.swift`,
  `Packages/Services/Sources/VehicleService/DTO/{VehicleDTO,VehicleMapper}.swift`,
  `Packages/Services/Sources/VehicleService/Fixtures/FixtureVehicleRepository.swift`,
  `Packages/Services/Tests/ServicesTests/VehicleMapperTests.swift`,
  `Packages/Features/Sources/HomeMapFeature/{HomeMapView,VehicleCardModel}.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/{VehicleCard,HomeSheetActions,PreviewVehicleSources}.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/{PlanOptionsPage,ChargingNetworksView,NetworkPickerView}.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/Components/{AvoidanceChips,NetworkRow,NetworkSearchField}.swift`,
  `Packages/Features/Sources/{AuthFeature/PhoneEntryView,AuthFeature/VerificationCodeView,AuthFeature/NameEntryView,
  SearchFeature/SearchView,SearchFeature/Components/SearchTopBar}.swift`,
  `Packages/Features/Tests/FeaturesTests/VehicleCardModelTests.swift`,
  `Packages/Core/Sources/DesignSystem/{AppIcon,Components/ScreenHeader}.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`,
  `App/Navigation/AppRouter.swift`, `App/RootView.swift`, `App/Composition/AppDependencies.swift`,
  `OnsarjUITests/{PlanOptionsPresentationTests,SwipeBackProbeTests}.swift`, `PROGRESS.md`
- Proje sahibi uygulama hedefine `GarageFeature` ürününü bağladı.

**Kararlar**
- **K-26** (proje sahibi) ve ek notu: DTO/fixture değişikliği aynı görevde `Docs/Backend/`'i günceller.
- **Ortak bileşenler `DesignSystem`'e taşındı** (proje sahibinin cevabı): kopyalamak 2.4'e aykırıydı.
- **Değer modalı sunumu (2.9):** sistem `.sheet`, içeriğin ölçülen yüksekliğinde (`presentationDetents(.height)`),
  görünür tutamaç; plan seçenekleri ve aramayla aynı yaklaşım. İçerik sürümler arasında aynı; iOS 26'da
  kısa sayfalar sistem gereği kenarlardan içeride ("yüzen") çizilir (K-22'deki davranış), iOS 18'de tam
  genişlik. Değer modalı kısa ömürlü bir giriş olduğu ve aşağı çekip kapatma gerektiği için kabul edildi;
  birebir aynılık istenirse karar proje sahibinde.
- **Etkin profil `PATCH /vehicles/{id}` ile** (`activeProfileId`): ayrı uç nokta açılmadı.
- **Takma ad:** boş dizge takma adı kaldırır; JSON'da `nil` alanlar yazılmadığı için "değişmesin" ile
  "kaldır" böyle ayrılır.
- Profil adı benzersizliği Türkçe `I/ı`, `İ/i`'yi aynı sayar (İngilizce "HIGHWAY"/"highway" de aynı kalsın diye).
- Kayıt başarısızsa değer modalı kapanır, değer eski haliyle kalır ve bildirim gösterilir; profil formu açık kalır.

**Doğrulama**
- `Packages/Domain`: `swift build`, `swift test` 31/31.
- `Packages/Services`: `swift build`, `swift test` 52/52, `swift build -c release` geçti.
- `./Tooling/Scripts/verify-ios.sh --package Features`: geçti. Uygulama Debug derlemesi geçti.
- `xcodebuild test` Features (iPhone SE, iOS 18.3): 65/65.
- `VehicleSettingsPresentationTests` (2 test) iOS 18.5'te geçti: dişliyle açılış, "Otoyol" çipi → kartta
  "Otoyol" ve ≈84 km (önce "Standart", 97 km), değer modalında geçersiz değer "5 ile 50 arasında bir değer gir" ve
  pasif Kaydet, 18,5 kaydı, aracı sil + onay → kart "Araç ekle".
- iOS 26.3, tüm UI test paketi: garaj (2), plan seçenekleri (2), arama (2) ve başlangıç testleri geçti.
  `SwipeBackProbeTests` (5) başarısız: testler kayıt akışının ilk ekranından başlıyor, uygulama ise Adım 27'den
  beri doğrudan haritayla açılıyor (`opensMapOnLaunch = true`). Bu adımdan bağımsız, önceden var olan durum;
  dosyada yalnızca "Geri dön" → "Geri" etiketi güncellendi.
- Uygulama Release: `FixtureVehicleRepository`, `FixtureVehicleBackend`, `FixtureChargingNetworkCatalog`,
  `PreviewGarageRepository` sembolleri 0; `prof_fixture` dizgesi 0; `VehicleSettingsView` mevcut.
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.

**Bilinen eksikler**
- **Geçici:** Fixture değişiklikleri yalnızca bellektedir; uygulama yeniden açılınca araç fixture'a döner (K-26).
- Çevrimdışı davranış (son alınan aracın kullanılması) bu görevin dışında; K-26 açık noktası.
- "Araç" satırı ve profil adı gibi veriler arayüzde olduğu gibi gösterilir (marka/model çevrilmez).
- Görselli önizleme gerçek adres olmadığı için görselsiz çizilir; görsel simülatörde fixture'dan görünüyor.
- `ValueEditorSheet`'in `initialText` parametresini yalnızca önizleme kullanıyor.
- Silinen araç varsayılansa yeni varsayılanın seçimi backend'e ait (`vehicles.md` açık nokta).
- Araç değiştirme ("⌄") ve "Araçlarınız" ekranı yok.

**Sıradaki adım**
- "Araçlarınız" ekranı ve araç değiştirme; ya da istasyon katmanı.

---

## Adım 38 — Plan seçenekleri düzeltmeleri: X, özet düzeni, güçlü tercih kaldırıldı

**Tarih:** 2026-11-15

**Ne yapıldı**
- Plan seçenekleri başlığındaki "Tamamlandı" kaldırıldı; yerine alt sayfalardaki yuvarlak X (`ModalCloseButton`).
- Şarj ağları özeti yeniden düzenlendi: "Tercih edilen" ve "Kaçınılan" küçük başlık (`caption`, `textSecondary`),
  altında virgülle ayrılmış ağ adları (en çok 2 satır, "…"); iki grup ince bir çizgiyle ayrılıyor (ikisi de doluysa).
- **Güçlü tercih (kalp) tamamen kaldırıldı** (proje sahibinin kararı): `NetworkPreference` silindi,
  `RoutePreferences.preferredNetworks` artık `[ChargingNetwork.ID]`, `toggleStrong` yok. Şarj ağları sayfasındaki
  kalp düğmesi ve `StrongPreferenceToggleStyle` silindi. `AppIcon`'dan `preference`, `strongPreference` ve yalnızca
  özetteki kalp için eklenen `image` erişimcisi kaldırıldı.
- Tercih deposu eski kayıt biçimini (`{"id", "isStrong"}`) okuyabiliyor, yalnızca kimliği alıyor; yeni kayıt düz dizge.
- Metinler: `plan.done`, `plan.networks.preferredSummary`, `plan.networks.avoidedSummary`,
  `plan.networks.accessibility.strong`, `networks.accessibility.strong` silindi; `plan.networks.preferred`
  ("Tercih edilen"), `plan.networks.avoided` ("Kaçınılan") eklendi; `networks.preferred.note` kalp cümlesi çıkarılarak
  "Planlamada önceliklendirilir." oldu.

**Dosyalar**
- Silinen: `Packages/Domain/Sources/OnsarjDomain/Models/NetworkPreference.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/Components/StrongPreferenceToggleStyle.swift`
- Değişen: `Packages/Domain/Sources/OnsarjDomain/Models/RoutePreferences.swift`,
  `Packages/Domain/Tests/DomainTests/RoutePreferencesTests.swift`,
  `Packages/Services/Sources/RoutePlanningService/UserDefaultsRoutePreferencesStore.swift`,
  `Packages/Services/Tests/ServicesTests/RoutePreferencesStoreTests.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/{PlanOptionsView,PlanOptionsPage,ChargingNetworksView,
  RoutePreferencesModel,RoutePreferences+Presentation}.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/Components/{ModalHeader,NetworkRow,NetworkSummary,
  PreviewRoutePlanningSources}.swift`, `Packages/Features/Tests/FeaturesTests/RoutePreferencesModelTests.swift`,
  `Packages/Core/Sources/DesignSystem/AppIcon.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`,
  `OnsarjUITests/PlanOptionsPresentationTests.swift`, `PROGRESS.md`

**Kararlar**
- Güçlü tercihin tamamen kaldırılması (Domain modeli dahil) proje sahibinin kararı; Android tarafının da aynı
  modele uyması gerekir.
- Adım 37'deki karşılaştırma görüntüsünde görünen gri ikinci segment, 2.9 doğrulaması için geçici konan sistem
  `Picker`'ıydı; uygulamada yoktur.

**Doğrulama**
- `Packages/Domain`: `swift test` 18/18. `Packages/Services`: `swift test` 38/38 (eski biçim testi yeni),
  `swift build -c release` geçti. `Packages/Core`: `swift build` geçti.
- `xcodebuild test` Features (iPhone SE, iOS 18.3): 48/48.
- `PlanOptionsPresentationTests` (2 test): iOS 18.5 ve 26.3'te geçti. Akışa kaçınılan ağ ekleme eklendi; özet, X ile
  kapanma ve yeniden açılışta korunma doğrulandı.
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.

**Bilinen eksikler**
- Adım 37'deki diğer eksikler geçerli ("Kaçınılıyor" kapsülü dolgusuz, ad çözümü hatası ayrımı, fixture geçici).

**Sıradaki adım**
- İstasyon katmanı veya rota planlama isteğinin tercihleri taşıması (K-10).

---

## Adım 37 — Plan seçenekleri ve şarj ağları (RoutePlanningFeature)

**Tarih:** 2026-11-15

**Ne yapıldı**
- Domain: `ChargeStopStrategy`, `RouteAvoidance`, `ChargingNetwork` (`ID` sarmalayıcı), `NetworkPreference`,
  `RoutePreferences` (değişmez: bir ağ iki listede birden olamaz, tekrar eklenmez; `init` de düzeltir) ve
  `RoutePreferencesStoring`, `ChargingNetworkCatalog` protokolleri.
- Servisler: `UserDefaultsRoutePreferencesStore` (batarya deposuyla aynı yaklaşım; tek anahtar
  `onsarj.routePreferences`, enum'lar dizge olarak); `FixtureChargingNetworkCatalog` (tamamı `#if DEBUG`, JSON → DTO →
  `ChargingNetworkMapper`, 15 ağ). Arama Türkçe kurallarla büyük/küçük harf ve aksan duyarsız "içerir"
  (`NetworkSearchKey`), sonuç Türkçe alfabe sırasıyla.
- Özellik: `PlanOptionsView` (kök, kendi `NavigationStack`'i), `PlanOptionsPage`, `ChargingNetworksView`,
  `NetworkPickerView` (iki kip). `RoutePreferencesModel` üç sayfada paylaşılıyor; her değişiklik bir kez ve sırayla
  `save` ediliyor, sonucu değiştirmeyen işlem kaydedilmiyor. `NetworkPickerModel`: 300 ms bekleme, `task(id:)` ile eski
  istek iptali, yükleniyor / sonuç yok / hata + "Tekrar dene".
- DesignSystem: `SegmentedControl` bileşeni; `AppIcon`'a 9 simge ve `Text` içinde kullanmak için `image` erişimcisi.
- App: `AppRouter.isPlanOptionsPresented`, `RootView` sunumu (`onOptions` bağlandı), `AppDependencies`'e tercih deposu
  ve katalog (Release'de `NoChargingNetworksCatalog`).
- `OnsarjUITests/PlanOptionsPresentationTests`: aç → seç → ağ ekle → güçlü tercih → kapat → uygulamayı yeniden aç →
  seçimler korunuyor; X ve aşağı çekme ile kapanma. Test sonunda tercihleri varsayılana döndürüyor.

**Dosyalar**
- Eklenen: `Packages/Domain/Sources/OnsarjDomain/Models/{ChargeStopStrategy,RouteAvoidance,ChargingNetwork,
  NetworkPreference,RoutePreferences}.swift`, `Packages/Domain/Sources/OnsarjDomain/Protocols/{RoutePreferencesStoring,
  ChargingNetworkCatalog}.swift`, `Packages/Domain/Tests/DomainTests/RoutePreferencesTests.swift`,
  `Packages/Services/Sources/RoutePlanningService/UserDefaultsRoutePreferencesStore.swift`,
  `Packages/Services/Sources/StationService/DTO/{ChargingNetworkDTO,ChargingNetworkMapper}.swift`,
  `Packages/Services/Sources/StationService/Fixtures/{FixtureChargingNetworkCatalog,NetworkSearchKey}.swift`,
  `Packages/Services/Tests/ServicesTests/{RoutePreferencesStoreTests,ChargingNetworkCatalogTests}.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/{PlanOptionsView,PlanOptionsPage,ChargingNetworksView,
  NetworkPickerView,RoutePreferencesModel,NetworkPickerModel,RoutePreferences+Presentation}.swift`,
  `Packages/Features/Sources/RoutePlanningFeature/Components/{ModalHeader,WrappingHStack,AvoidanceChips,
  StrongPreferenceToggleStyle,NetworkRow,NetworkSummary,NetworkSearchField,PickerRow,
  PreviewRoutePlanningSources}.swift`, `Packages/Features/Tests/FeaturesTests/RoutePreferencesModelTests.swift`,
  `Packages/Core/Sources/DesignSystem/Components/SegmentedControl.swift`,
  `OnsarjUITests/PlanOptionsPresentationTests.swift`
- Değişen: `Packages/Core/Sources/DesignSystem/AppIcon.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`, `App/Navigation/AppRouter.swift`,
  `App/RootView.swift`, `App/Composition/AppDependencies.swift`, `PROGRESS.md`
- Silinen: `Packages/Features/Sources/RoutePlanningFeature/RoutePlanningFeature.swift`,
  `Packages/Services/Sources/RoutePlanningService/RoutePlanningService.swift`,
  `Packages/Services/Sources/StationService/StationService.swift`
- Proje sahibi uygulama hedefine `RoutePlanningFeature`, `RoutePlanningService`, `StationService` ürünlerini bağladı.

**Kararlar**
- **Segment denetimi: kendi `SegmentedControl`'ümüz (2.9).** Sistem `Picker(.segmented)` geçici olarak kendi
  denetimimizin altına konup iOS 18.5 ve 26.3'te ekran görüntüsüyle karşılaştırıldı, sonra kaldırıldı. Sistem denetimi
  iki sürümde farklı çiziliyor (18.5: ayırıcılı yuvarlak dikdörtgen; 26.3: ayırıcısız kapsül). İkisinde de seçili parça
  beyaz ve dolgusuz, yazı küçük ve sabit. Tasarımın istediği belirgin dolgu yalnızca uygulama geneli
  `UISegmentedControl.appearance()` ile verilebiliyor. Bizimki: `backgroundCard` yol, seçili parça `actionPrimary` /
  `onActionPrimary`, eşit genişlik, büyük yazıda sarar, VoiceOver'da her parça düğme + "seçili".
- **Sunum:** arama sayfasıyla aynı sistem `.sheet` (görünür tutamaç). Üst çubuk sistem gezinme çubuğu değil,
  özelliğe ait `ModalHeader` (sürümler arası aynı görünüm; `hidesNavigationBar()` ile kenardan kaydırarak geri açık).
- **Simgeler (SF Symbols, iOS 17'de var):** `back` `chevron.left` (13), `preference` `heart` (13),
  `strongPreference` `heart.fill` (13), `remove` `xmark` (13), `checkmark` `checkmark` (13), `avoidTolls`
  `creditcard` (13), `avoidHighways` `road.lanes` (16), `avoidFerries` `ferry` (16), `avoidBorders` `flag` (13).
- **Yeniden kullanılan metinler:** geri `signup.phone.accessibility.back`, kapat `search.close`, tekrar dene
  `vehicleCard.retry`, arama yer tutucusu `search.submit` ("Ara"). Bu yüzden `networks.retry` eklenmedi.
  VoiceOver için `networks.accessibility.strong`, `networks.accessibility.remove`,
  `plan.networks.accessibility.strong` eklendi.
- Saklama: tanınmayan kaçınma değeri atlanır; tanınmayan durak stratejisi `optimal`'e düşer; kayıtta iki listede
  geçen ağ yalnızca tercih edilenlerde kalır.
- Yeni renk token'ı eklenmedi.

**Doğrulama**
- `Packages/Domain`: `swift build`, `swift test` 19/19.
- `Packages/Services`: `swift build`, `swift test` 37/37, `swift build -c release` geçti.
- `./Tooling/Scripts/verify-ios.sh --package Features`: geçti.
- `xcodebuild test` Features (iPhone SE, iOS 18.3): 48/48 (7 yeni).
- `PlanOptionsPresentationTests` (2 test): iOS 18.5, 26.3, 27.0'da geçti; tercihler yeniden açılışta korunuyor.
- Uygulama Release: `FixtureChargingNetworkCatalog` sembolü 0, `NetworkSearchKey` 0, "CHARGING TOGETHER" dizgesi 0
  (Debug'da 54 sembol); `UserDefaultsRoutePreferencesStore` mevcut.
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.

**Bilinen eksikler**
- **Geçici, silinecek:** `StationService/Fixtures/` (katalog ve arama anahtarı), backend gelince (K-23).
- Katalog ad çözümünde hata alırsa kayıtlı ağlar "Bilinmeyen ağ" görünür (ağ hatası ile silinmiş ağ ayrılmıyor).
- "Kaçınılıyor" kapsülü dolu değil, onay simgeli kırmızı çerçeve: kırmızı dolgu için uygun token yok.
- Kaçınma çiplerinden feribot çipi simgesi nedeniyle birkaç nokta daha yüksek.
- `ModalHeader` `ScreenHeader`'a benziyor; başka modal da gerekirse `DesignSystem`'e taşınabilir.
- `xxxLarge` / iPhone SE matrisi önizlemede yazıldı; Xcode kanvasında gözle kontrol edilecek.

**Sıradaki adım**
- İstasyon katmanı veya rota planlama isteğinin tercihleri taşıması (backend sözleşmesi K-10 ile).

---

## Adım 36 — Arama sayfası, tasarım aşaması (SearchFeature)

**Tarih:** 2026-11-15

**Ne yapıldı**
- `SearchFeature` yazıldı: `SearchView` (kök), `SearchModel` (`@Observable`), `SearchRow` (`place`,
  `history`, `charger`); bileşenler `SearchTopBar`, `SearchRowView`, `SavedPlacesChips`. Yer tutucu
  `SearchFeature.swift` silindi.
- İki hal: **başlangıç** (kayıtlı yer çipleri + geçmiş; geçmiş satırı sola kaydırınca "Sil") ve **yazma**
  (çipler ve geçmiş gizli, öneri listesi). Yalnızca boşluktan oluşan sorgu başlangıç sayılır. Yazma halinde
  alanın içinde temizle düğmesi, kapat yerine "Ara" kapsülü; geçiş hareketli, "Hareketi Azalt" açıkken hareketsiz.
  Klavye arama tuşu "Ara" ile aynı; boş sorguda `onSubmit` çağrılmaz. Liste kaydırılınca klavye kapanır.
- Sayfa açılınca alan odaklanır, klavye açılır. Ekran geçiş yapmaz; tüm istekler kapanışlarla dışarı bildirilir.
- App: `AppRouter.isSearchPresented` (2.6 onayıyla), `RootView` ana haritanın üstünde sistem `.sheet`'i
  (büyük kademe, görünür tutamaç) sunuyor; `onSearchTapped` açıyor, `onClose` kapatıyor, diğer kapanışlar boş.
  `AppDependencies` geçmiş ve öneri kapanışlarını veriyor.
- `AppIcon`: `close` (`xmark`, iOS 13), `clearText` (`xmark.circle.fill`, 13), `home` (`house.fill`, 13),
  `work` (`briefcase.fill`, 13), `add` (`plus`, 13), `history` (`clock.arrow.circlepath`, 14),
  `place` (`mappin.and.ellipse`, 14), `charger` (`bolt.fill`, 13). `search.*` metinleri ve satır türü için
  VoiceOver anahtarları eklendi; yer tutucu için `home.search.placeholder` yeniden kullanıldı.
- `OnsarjUITests/SearchPresentationTests`: aç → odak ve klavye → yaz → temizle → X ile kapat; ve aşağı
  çekerek kapat. Her adımda ekran görüntüsü.

**Dosyalar**
- Eklenen: `Packages/Features/Sources/SearchFeature/{SearchView,SearchModel,SearchRow}.swift`,
  `Packages/Features/Sources/SearchFeature/Components/{SearchTopBar,SearchRowView,SavedPlacesChips}.swift`,
  `Packages/Features/Tests/FeaturesTests/SearchModelTests.swift`, `App/Composition/SearchDesignFixtures.swift`,
  `OnsarjUITests/SearchPresentationTests.swift`
- Değişen: `Packages/Core/Sources/DesignSystem/AppIcon.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`, `App/Navigation/AppRouter.swift`,
  `App/RootView.swift`, `App/Composition/AppDependencies.swift`, `PROGRESS.md`
- Silinen: `Packages/Features/Sources/SearchFeature/SearchFeature.swift`
- Proje sahibi Xcode'dan uygulama hedefine `SearchFeature` ürününü bağladı (`project.pbxproj`).

**Kararlar**
- **Sunum: sistem `.sheet` (büyük kademe).** Doğrulama (2.9): aynı UI testi iOS 18.5 (iPhone 16 Pro Max),
  26.3 (iPhone 17 Pro Max) ve 27.0 (iPhone 18 Pro Max) simülatörlerinde koşuldu, ekran görüntüleri
  karşılaştırıldı. Üçünde de üstte harita şeridi, yuvarlak köşe, tutamaç, alan odaklı ve klavye açık;
  X ve aşağı çekme ile kapanıyor. Sayfanın içi üçünde aynı. **Sürüme bağlı fark yalnızca sistemin arka
  planında:** iOS 18.5'te harita küçülüp geriye itiliyor (kart yığını, üstte siyah şerit); 26.3 ve 27.0'da
  harita yerinde kalıp karartılıyor, köşeler daha yuvarlak. Kendi `DetentSheet`'imiz bu farkı kaldırırdı,
  ama K-22 gereği hiçbir zaman kapanmaz; aşağı çekerek kapatma, klavye ve odak için yeni bir kapanabilir
  mod gerekirdi. İçerik birebir aynı kaldığı ve fark yalnızca arka plan olduğu için sistem sayfası seçildi.
  Arka planın da birebir aynı olması istenirse karar proje sahibinde (K-22'ye ek).
- **Token:** `actionInverse`/`onActionInverse` eklenmedi; istenen değerler mevcut `Theme.actionPrimary`
  (gray950 / beyaz) ve `Theme.onActionPrimary` (gray50 / ink0) ile aynı. "Ara" kapsülü bunları kullanıyor.
- **iOS 17 doğrudan denenmedi (açık nokta):** makinede iOS 17 simülatörü yok. Proje sahibinin kararıyla
  iOS 18.5, 26 öncesi davranışın temsilcisi sayıldı.
- "Ara" kapsülüne `accessibilityIdentifier` verildi: klavyenin arama tuşu da "Ara" etiketini taşıdığı için
  UI testi kapsülü kimlikle buluyor. Kimlik kullanıcıya görünmez.
- Liste ayırıcısı satır içeriğinin sağ kenarına hizalandı; iOS 18.5 varsayılan olarak ekran kenarına uzatıyordu.

**Doğrulama**
- `cd Packages/Core && swift build`: geçti.
- `./Tooling/Scripts/verify-ios.sh --package Features`: geçti.
- `xcodebuild test` Features (iPhone SE, iOS 18.3): 41/41 geçti (`SearchModel` 6 yeni test, `HomeMapModel` ve
  `VehicleCardModel` dahil).
- `SearchPresentationTests` (2 test): iOS 18.5, 26.3, 27.0'da geçti. Ayırıcı düzeltmesinden sonra iOS 18.5'te
  yeniden koşuldu, geçti.
- Uygulama Release: `SearchDesignFixtures` sembolü 0, "Raw Coffe" dizgesi 0 (Debug'da 2).
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.

**Bilinen eksikler**
- **Geçici, silinecek:** `App/Composition/SearchDesignFixtures.swift` (yalnızca Debug) tasarım verisidir; arama
  kaynağı kararlaştırılıp bağlanınca silinir (K-23 ile aynı ilke). Release'de geçmiş ve öneriler boş.
- Şarj istasyonu rozeti `Theme.actionPrimary` dairesi üzerinde `onActionPrimary` simge kullanıyor (koyu temada
  beyaz daire). Anlamsal olarak eylem token'ı; ayrı bir rozet token'ı istenirse eklenmeli.
- Sonuç listesi ekranı, kayıtlı yer (ev, iş) ekranları ve geçmiş silmenin kalıcılığı yok; kapanışlar boş.
- Önizleme matrisi yazıldı; `xxxLarge` görünümü Xcode kanvasında/cihazda kontrol edilecek.

**Sıradaki adım**
- Sonuç listesi ekranı (Ara'ya basınca) ve arama kaynağının kararı.

---

## Adım 35 — Debug senaryoları, fixture görseli ve tutamaç token'ı (C3)

**Tarih:** 2026-11-14

**Ne yapıldı**
- `FixtureScenario` (`#if DEBUG`): `default`, `noImage`, `noVehicles`, `failure`; tanınmayan veya eksik
  değer `default`. Başlatma argümanı `-onsarjFixtureScenario <değer>` ile seçilir; okuma yalnızca
  `App/Composition` içinde, `#if DEBUG` altında.
- `FixtureVehicleRepository` senaryoyu ve `resourceLookup: @Sendable (String) -> URL?` kapanışını init'te
  alıyor. `failure` için ayrı `FixtureScenarioFailure` hatası. JSON'daki `imageUrl` artık görsel adı
  (`"vehicle-empty-state"`); depo adı `file://` adresine çevirip **eşlemeden önce** DTO'ya yazıyor.
- `VehicleMapper`'a dahili `acceptsFileImageURLs` parametresi (varsayılan `false`) eklendi; yalnızca
  fixture `true` veriyor. `true` iken de boş, geçersiz, `ftp://` ve yolsuz `file://` `nil` kalıyor.
- `App/Composition/FixtureImageExporter` (`#if DEBUG`): `Illustration.vehicleEmptyState`'i `ImageRenderer`
  ile şeffaf PNG'ye çevirip (ölçek 3) `Caches/onsarj-fixture/vehicle-empty-state.png`'ye yazıyor; yazılamazsa
  sözlük boş, araç görselsiz yükleniyor.
- `Theme.batteryThumb` (iki temada beyaz) eklendi; çubuk tutamacı onu kullanıyor, gölge aynı.

**Dosyalar**
- Eklenen: `Packages/Services/Sources/VehicleService/Fixtures/FixtureScenario.swift`,
  `Packages/Services/Tests/ServicesTests/FixtureScenarioTests.swift`,
  `App/Composition/FixtureImageExporter.swift`
- Değişen: `Packages/Services/Sources/VehicleService/Fixtures/FixtureVehicleRepository.swift`,
  `Packages/Services/Sources/VehicleService/DTO/{VehicleDTO,VehicleMapper}.swift`,
  `Packages/Services/Tests/ServicesTests/VehicleMapperTests.swift`,
  `Packages/Core/Sources/DesignSystem/SemanticColors.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/BatteryLevelSlider.swift`,
  `App/Composition/AppDependencies.swift`, `PROGRESS.md`

**Kararlar**
- **`acceptsFileImageURLs` (proje sahibinin kararı, Seçenek 1):** `file://` görsel adresi yalnızca
  `#if DEBUG` fixture'ının çağrısında kabul edilir. Gerekçe: eşleme her zaman `file` şemasını kabul etseydi
  backend'den gelebilecek hatalı bir yerel adres sessizce geçerli sayılırdı (Seçenek 2); fixture görseli
  eşlemeden sonra yazsaydı eşleme yolu atlanırdı (Seçenek 3). Parametre `internal`; Domain ve genel API değişmedi.
- `VehicleDTO.imageUrl` ve `VehicleListDTO.vehicles` `var` oldu (fixture'ın eşlemeden önce yazabilmesi için).

**Doğrulama**
- `Packages/Domain`: `swift build`, `swift test` 10/10.
- `Packages/Services`: `swift build`, `swift test` 24/24 (C1'in 14 testi aynen geçiyor; 3 eşleme, 7 senaryo testi
  yeni), `swift build -c release` geçti.
- `./Tooling/Scripts/verify-ios.sh --package Features`: geçti.
- `swiftlint lint --strict`, `swift format lint --strict … App Packages/*/Sources Packages/*/Tests`: 0 ihlal.
- Uygulama Release (genel iOS simülatörü): `FixtureScenario` sembolü 0, `FixtureVehicleRepository` sembolü 0,
  `onsarjFixtureScenario` dizgesi 0. Karşılaştırma için Debug'da (`Onsarj.debug.dylib`) 128 sembol ve 1 dizge.
- Simülatör (iPhone SE 3. nesil), dört senaryo ekran görüntüsüyle: `default` görselli kart; `noImage` görselsiz
  kart, yazılar tam genişlikte; `noVehicles` bulanık görsel + "Araç ekle"; `failure` "Araç yüklenemedi" +
  "Tekrar dene". **`AsyncImage` `file://` adresini simülatörde yüklüyor.** Dört halde kart yüksekliği aynı.

**Bilinen eksikler**
- Fixture görseli bir Togg, fixture aracı BYD Dolphin: yalnızca test için bilinen tutarsızlık. Gerçek Dolphin
  görseli gelince fixture'daki `imageUrl` değişir.
- Yazılan PNG ~3,6 MB (görselin doğal boyutu × 3). Yalnızca Debug'da ve `Caches`'te; uygulama her açılışta
  üzerine yazar.
- "Camiler" çipinde simge yok (`icon-category-mosque` henüz eklenmedi).

**Sıradaki adım**
- Proje sahibi şemada senaryoyu seçip cihazda dener; ardından arama modalı (`SearchFeature`).

---

## Adım 34 — Araç kartı sıkılaştırıldı, orta kademe içeriğe göre uzuyor

**Tarih:** 2026-11-14

**Ne yapıldı**
- Donanım paketi ("Standart") araç adının hemen altına alındı. Ad, ok ve donanım paketi artık tek
  düğme (`onSwitchVehicle`); iki satır birlikte dokunma alanını sağlıyor. Önceden ad satırının
  44 pt'lik dokunma alanı paketi aşağı itiyordu.
- Kartın dikey iç boşluğu `Spacing.lg` → `Spacing.md`, satır aralıkları `Spacing.md` → `Spacing.sm`.
  Ölçü iskeleti de buna göre güncellendi.
- `DetentSheet` orta kademesi içeriğe göre uzuyor: en az kullanılabilir yüksekliğin %50'si, içerik
  sığmazsa en çok %80'i; ötesinde içerik kayar. Amaç: tüm aksiyonların ilk bakışta görünmesi.
- Alt sayfa içeriğinin altına `Spacing.md` boşluk eklendi (butonlar ekran kenarına yapışmasın).

**Dosyalar**
- Değişen: `Packages/Features/Sources/HomeMapFeature/Components/{VehicleCard,HomeBottomSheet}.swift`,
  `Packages/Core/Sources/DesignSystem/Components/{DetentSheet,SheetDetent}.swift`, `PROGRESS.md`

**Kararlar**
- Orta kademenin üst sınırı %80 (`DetentSheet.maxMediumHeightRatio`): haritanın ve üstündeki
  butonların görünür kalması için. Proje sahibi cihazda değerlendirecek.

**Doğrulama**
- `verify-ios.sh --package Features`: geçti. `swift test` (Core): geçti.
- `swiftlint lint --strict`, `swift format lint --strict`: 0 ihlal.
- Uygulama iPhone SE (3. nesil) ve iPhone 16 Pro Max simülatöründe çalıştırıldı (Large, açık tema):
  iki cihazda da arama, çipler, araç kartı ve iki alt buton orta kademede tamamen görünüyor.

**Bilinen eksikler**
- "Camiler" çipinde simge görünmüyor: `icon-category-mosque` asset kataloğunda hâlâ yok.
- `xxxLarge` yazı boyutunda içerik %80 sınırını aşarsa kayar; cihazda bakılacak.

**Sıradaki adım**
- Kartın cihazda onayı; ardından arama modalı (`SearchFeature`).

---

## Adım 33 — Ana sayfa modalı iki kademe + araç kartı (C2)

**Tarih:** 2026-11-14

**Ne yapıldı**
- `DetentSheet` iki kademeye indi: `SheetDetent.expanded`, `SheetDetentHeights.expanded`,
  `draggableDetents` parametresi ve ulaşılabilir kademe hesabı kaldırıldı; `HomeMapModel.beginSearch()`
  ve `home.sheet.accessibility.expanded` metni silindi. Arama alanı artık sayfayı büyütmez;
  `HomeMapView` `onSearch` → `onSearchTapped` (K-25). Arama alanı VoiceOver'da yer tutucu metniyle düğme.
- Araç kartı (`VehicleCard`) çip şeridinin altına, alt butonların üstüne eklendi. Haller:
  yükleniyor, dolu, görselsiz, araç yok ("Araç ekle"), hata ("Tekrar dene"). Tüm haller aynı
  yüksekliği, dolu halin satırlarıyla aynı yazı tiplerinden oluşan görünmez bir ölçü iskeletinden alır.
- `BatteryLevelSlider`: yalnızca yatay başlayan sürüklemeyi alır (`DetentSheet` ile aynı kural ve
  eşik), 1'er adım, renk `BatteryLevel.band`'den, bant değişince seçim titreşimi (yalnızca sürüklerken),
  depoya sürükleme bitince bir kez yazılır; VoiceOver ayarlanabilir öğe, adım 5.
- `VehicleCardModel` (`@Observable`): `load()` (bir kez), `reload()`, `updateLevel(_:)`, `commitLevel()`.
  Kayıtlı yüzde yoksa `BatteryLevel.initial`; başlangıç değeri yazılmaz.
- DesignSystem: `Palette.yellow50…950`; `Theme.batteryLow/Medium/High/Track`; `Illustration.vehicleEmptyState`;
  `Effects.Muted` (bulanıklık 8, opaklık 0,6); `AppIcon.settings` (`gearshape`, iOS 14) ve
  `AppIcon.dropdown` (`chevron.down`, iOS 13). `.swiftlint.yml`'de `type_name` için `ID` istisnası;
  `Vehicle.ID`'deki satır içi istisna kaldırıldı.
- App: `AppDependencies` araç deposunu (Debug: `FixtureVehicleRepository`, Release: boş depo) ve
  `UserDefaultsBatteryLevelStore`'u veriyor; `RootView` yeni parametreleri boş kapanışlarla geçiriyor.
- CLAUDE.md 9.1'e **K-25** ve **K-22 ek notu** eklendi (proje sahibinin metni ve izniyle).

**Dosyalar**
- Eklenen: `Packages/Features/Sources/HomeMapFeature/VehicleCardModel.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/{VehicleCard,BatteryLevelSlider,PreviewVehicleSources}.swift`,
  `Packages/Features/Tests/FeaturesTests/VehicleCardModelTests.swift`,
  `Packages/Core/Sources/DesignSystem/{Illustration,Effects}.swift`
- Değişen: `Packages/Core/Sources/DesignSystem/{ColorPalette,SemanticColors,AppIcon}.swift`,
  `Packages/Core/Sources/DesignSystem/Components/{DetentSheet,DetentSheetTracker,SheetDetent,SheetDetentHeights}.swift`,
  `Packages/Core/Tests/CoreTests/DetentSheetTrackerTests.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`,
  `Packages/Features/Sources/HomeMapFeature/{HomeMapView,HomeMapModel}.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/{HomeBottomSheet,HomeSheetActions,MapSearchBar}.swift`,
  `Packages/Features/Tests/FeaturesTests/HomeMapModelTests.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Models/Vehicle.swift`, `App/Composition/AppDependencies.swift`,
  `App/RootView.swift`, `.swiftlint.yml`, `CLAUDE.md`, `PROGRESS.md`
- Proje sahibi Xcode'dan uygulama hedefine `VehicleService` ürününü bağladı (`project.pbxproj`).

**Kararlar ve açık noktalar**
- K-25 ve K-22 ek notu kesinleşti. Kart **orta kademede** görünür; küçük kademede yalnızca arama
  satırı vardır. Tahmini hesapla SE'de orta kademe kartın tamamını göstermeyebilir, içerik kayar;
  proje sahibi cihazda onaylayacak.
- **Eksik token:** tutamaç için iki temada beyaz bir token yok. Şimdilik `Theme.backgroundCard`
  (açık temada beyaz, koyu temada ink2, gölgeli). İki temada beyaz istenirse `batteryThumb` eklenmeli.
- `Theme.backgroundSubtleElevated` depoda yok (Adım 31'de belirtildi) ve hiçbir yerde kullanılmıyor.
- Görsel `dynamicTypeSize >= .xxxLarge` iken gizlenir (uygulama kökü yazı boyutunu `xxxLarge`'da sınırlar).
- **Açık nokta:** Release'de araç deposu boştur (uydurma veri yok). K-23 gereği ilk TestFlight
  dağıtımından önce gerçek depo (backend) bağlanmalı; aksi halde TestFlight'ta kart "Araç ekle" halinde açılır.
- Yükleme hatası kullanıcıya gösterilir ama loglanmaz; `HomeMapFeature` henüz loglama arayüzüne bağlı değil.

**Doğrulama**
- `Packages/Core`: `swift build` geçti; `swift test` 23/23 + 10/10 geçti.
- `verify-ios.sh --package Core` ve `--package Features`: geçti.
- `xcodebuild test -scheme Features-Package -only-testing:FeaturesTests` (iPhone SE 3. nesil simülatörü):
  35/35 geçti (`VehicleCardModel` 9 test, bazıları parametreli).
- `xcodebuild build -scheme Onsarj` Debug ve Release (genel iOS simülatörü): geçti.
- `Packages/Domain` 10/10, `Packages/Services` 14/14 geçti.
- `swiftlint lint --strict`: 0 ihlal. `swift format lint --strict --configuration .swift-format
  --recursive App Packages/*/Sources Packages/*/Tests`: 0 ihlal.
- `cd Packages/Features && swift build` macOS'ta çalışmaz (Mapbox xcframework'lerinde macOS yok); 6.8/K-18
  gereği Features `verify-ios.sh` ile doğrulandı.
- Sürükleme hissi, titreşim ve görsel denge cihazda denenecek.

**Bilinen eksikler**
- Araç görselli önizleme yok: gerçek görsel adresi backend'den gelecek (K-24).
- `.github/workflows/lint.yml` swift-format adımı `--recursive App Packages` kullanıyor; CI temiz
  checkout'ta çalıştığı için `.build` yok, değiştirilmedi.
- Arama, araç değiştirme, araç ayarları, araç ekleme kapanışları `App/`'te boş; ekranları yazılınca bağlanacak.

**Sıradaki adım**
- Kartın cihazda onayı (kademe, SE yerleşimi, tutamaç rengi); ardından arama modalı (`SearchFeature`).

---

## Adım 32 — Araç veri katmanı (C1)

**Tarih:** 2026-11-14

**Ne yapıldı**
- `OnsarjDomain`'e araç modeli eklendi: `Vehicle` (tip güvenli `Vehicle.ID`, `displayName`,
  `estimatedRangeKm(at:)`, `activeVehicle(in:)`), `ConnectorType`, `BodyType`, `BatteryLevel`
  (0…100'e sıkıştırma, bant eşikleri 20/50 yalnızca burada, `initial` = %30), `BatteryLevelBand`,
  `StoredBatteryLevel`.
- Protokoller: `VehicleRepository` (`vehicles()`) ve `BatteryLevelStoring` (`storedLevel(for:)`,
  `save(_:for:at:)`).
- `VehicleService`: `VehicleDTO` + `VehicleListDTO` (camelCase, `{"vehicles": [...]}`),
  `VehicleMapper` (tanınmayan konektör atlanır, tanınmayan kasa `other`, geçersiz görsel adresi `nil`;
  hatalı renk, aralık dışı batarya sağlığı veya eksik zorunlu alan `VehicleMappingError` fırlatır;
  hata aracın kimliğini, alanın JSON adını ve sebebini taşır).
- `FixtureVehicleRepository` (tamamı `#if DEBUG`): gömülü JSON'u gerçek yoldan
  (`JSONDecoder` → DTO → `VehicleMapper`) geçirir. Tek araç: BYD Dolphin.
- `UserDefaultsBatteryLevelStore`: her araç için `onsarj.batteryLevel.<id>` anahtarında JSON
  kaydı (yüzde + tarih). Kayıt yoksa veya bozuksa `nil`; varsayılan değer vermez.
- CLAUDE.md 9.1'e proje sahibinin metniyle **K-24** ve **K-23 ek notu** eklendi (proje
  sahibinin bu görev için açık izniyle).

**Dosyalar**
- Eklenen: `Packages/Domain/Sources/OnsarjDomain/Models/{Vehicle,ConnectorType,BodyType,BatteryLevel}.swift`,
  `Packages/Domain/Sources/OnsarjDomain/Protocols/{VehicleRepository,BatteryLevelStoring}.swift`,
  `Packages/Services/Sources/VehicleService/DTO/{VehicleDTO,VehicleMapper}.swift`,
  `Packages/Services/Sources/VehicleService/Fixtures/FixtureVehicleRepository.swift`,
  `Packages/Services/Sources/VehicleService/UserDefaultsBatteryLevelStore.swift`,
  `Packages/Domain/Tests/DomainTests/{BatteryLevelTests,VehicleTests}.swift`,
  `Packages/Services/Tests/ServicesTests/{VehicleMapperTests,BatteryStoreTests}.swift`
- Silinen: `Packages/Services/Sources/VehicleService/VehicleService.swift`,
  `Packages/Domain/Sources/OnsarjDomain/{Models,Protocols}/.gitkeep`
- Değişen: `CLAUDE.md` (yalnızca 9.1'e iki satır), `PROGRESS.md`

**Kararlar (hepsi çözüldü)**
- **K-24 eksikti:** proje sahibi metni verdi, karar defterine eklendi.
- **K-23 ile fixture biçimi:** fixture JSON'u kaynak dosyası değil, `#if DEBUG` korumalı Swift
  dosyasında dizge sabiti (K-23 ek notu). Klasör adı K-23'le uyumlu olarak `Fixtures/`.
- **`OnsarjDomain.swift` yer tutucusu** zaten silinmişti; yalnızca `VehicleService.swift` ve iki
  `.gitkeep` silindi.
- **`UserDefaults` ve Swift 6:** `UserDefaults` bu SDK'da `Sendable` değil (derleyici hatası ile
  doğrulandı). Depo yalnızca suite adını (`String?`) tutar ve `UserDefaults`'u her çağrıda açar;
  `nil` standart depodur. `@unchecked Sendable` kullanılmadı.
- **SwiftLint istisnaları (satır içi, gerekçeli):** `Vehicle.ID` için `type_name` (görev adı
  şart koşuyor); fixture JSON'u ve mapper testindeki `#F2F2F2` için `no_hardcoded_hex_color` (araç
  boya verisi, arayüz rengi değil). İleride `Station.ID` gibi tipler gelirse `.swiftlint.yml`'de
  `type_name.excluded: [ID]` düşünülebilir.

**Doğrulama**
- `Packages/Domain`: `swift build` geçti, `swift test` 10/10 geçti.
- `Packages/Services`: `swift build` geçti, `swift test` 14/14 geçti, `swift build -c release` geçti.
- `FixtureVehicleRepository`'ye kaynak kodda başka başvuru yok; tek başvuru `VehicleMapperTests`
  içinde ve o da `#if DEBUG` altında.
- `swiftlint lint --strict`: 0 ihlal. `swift format lint --strict` (`App`, `Packages/*/Sources`,
  `Packages/*/Tests`): 0 ihlal. Görevdeki `--recursive App Packages` biçimi `.build`
  içindeki üçüncü parti kodu da taradığı için kaynak klasörleriyle sınırlandı.

**Bilinen eksikler**
- Gerçek (uzak) `VehicleRepository` yok: backend sözleşmesi (K-10) bekleniyor.
- Fixture/gerçek seçimi `App/Composition`'a bağlanmadı (görev kapsamı dışında, C2 ile).
- Görsel disk önbelleği ayrı görev (K-24).

**Sıradaki adım**
- C2: araç kartı arayüzü (`BatteryLevel.initial`, bant rengi, görselsiz kart durumu).

---

## Adım 31 — Mapbox bilgi butonu ve ölçek çubuğunun yeri, alt buton köşesi

**Tarih:** 2026-11-14

**Ne yapıldı**
- Mapbox bilgi (attribution) butonu sağ üste taşındı; sol üstteki menü butonuyla aynı hizada
  (üstten `Spacing.sm`, kenardan `Spacing.screenMargin`). Mapbox'ın kendi butonu kullanılıyor.
- Pusula bilgi butonunun altına alındı (varsayılan yeri sağ üstteydi, bilgi butonuyla çakışırdı).
  Ölçek çubuğu menü butonunun sağına alındı; artık menünün arkasında kalmıyor.
- Yerleşim `MapEngine`'in yeni tipi `MapControlsLayout` ile veriliyor; dışarıya Mapbox tipi
  açılmıyor. `HomeMapView` değerleri `Spacing` token'larından veriyor.
- `ActionTileButton` köşesi `Radius.button` (20) → `Radius.field` (12): aynı yükseklikteki arama
  alanıyla aynı. Bu bileşen yalnızca ana sayfada kullanılıyor.

**Dosyalar**
- Eklenen: `Packages/MapboxKit/Sources/MapEngine/MapControlsLayout.swift`
- Değişen: `Packages/MapboxKit/Sources/MapEngine/MapView.swift`,
  `Packages/Features/Sources/HomeMapFeature/HomeMapView.swift`,
  `Packages/Core/Sources/DesignSystem/Components/ActionTileButton.swift`, `PROGRESS.md`

**Kararlar ve açık noktalar**
- **Logo opaklığı değiştirilmedi.** Mapbox: *"You may not style the Mapbox logo."* Bilgi butonunun
  opaklığı için iOS'ta kural yok; belirsiz olduğu için tam opaklıkta.
- **Logo varsayılan yerinde (sol alt) kaldı; proje sahibinin kararı.** Orta ve büyük kademede sayfanın
  arkasında kalıyor. Mapbox'ın *"must stay visible on the map"* şartıyla çelişebilir; proje sahibi
  ABRP'nin de böyle yaptığını, sorun çıkarsa düzeltileceğini belirtti. Açık risk.
- **`Theme.backgroundSubtleElevated` — karar bekliyor.** Token depoda yok (`a0d8d7f`'de silinmiş);
  `MapSearchBar` zaten `Theme.backgroundCard` kullanıyor. Alternatif değer `45f0288`'de: açık
  `Palette.gray100`, koyu `Palette.ink2`. Seçilirse token geri eklenir ve `MapSearchBar`'da tek satır değişir.
- Sayfa öğelerinin hepsi `Theme.backgroundCard`: arama alanı, asistan butonu, çipler, alt butonlar.
- **Varsayım:** Yapay zekâ butonu daire kaldı (yükseklik/yarıçap oranı 2). Proje sahibi şekli
  değiştirmeyi istemedi; istenirse `Radius.field` olur.

**Doğrulama**
- `verify-ios.sh --package MapboxKit`, `--package Features`, `--package Core`: geçti.
- `swift test` (Core): 25/25 geçti.
- `swiftlint lint --strict` ve `swift format lint --strict`: 0 ihlal.
- Ornament yerleşimi cihazda denenecek; önizlemede harita (ve Mapbox öğeleri) çizilmeyebilir.

**Bilinen eksikler**
- `icon-assistant.imageset` `actool` ile derlenince hata veriyor: tek ölçekli ("Any") ve 1x girişleri
  bir arada. Xcode'da "Single Scale" + "Preserve Vector Data" seçilmeli. `icon-category-mosque` henüz yok.

**Sıradaki adım**
- SVG'ler düzeltilince önizlemede görünmelerinin doğrulanması; ardından ana sayfa B parçası.

---

## Adım 30 — Arama çubuğu koyu tema rengi, sürüklemede aramanın tetiklenmesi

**Tarih:** 2026-11-08

**Ne yapıldı**
- Arama çubuğundan başlayan sürükleme bırakılınca arama butonu da tetikleniyor ve sayfa büyük
  kademeye açılıyordu. Kullanıcı ortaya dönmekte zorlanıyordu. Sebep: başlığın sürükleme
  hareketi `simultaneousGesture` ile bağlıydı, parmak butonun üstünde kalkınca buton da
  çalışıyordu. `highPriorityGesture` yapıldı. Sürükleme eşiği geçilince butonun dokunuşu iptal
  oluyor, kısa dokunuş yine aramayı açıyor.
- Koyu temada arama çubuğunun zemini (`backgroundSubtle`, ink1) alt sayfa zeminiyle
  (`backgroundElevated`, ink1) aynıydı ve görünmüyordu. Yeni token eklendi:
  `Theme.backgroundSubtleElevated` (açık gray100, koyu ink2). Yalnızca `MapSearchBar` kullanıyor.
- `SemanticColors.swift` dosyasının sonundaki eksik satır sonu eklendi (lint hatası).

**Dosyalar**
- Değişen: `Packages/Core/Sources/DesignSystem/Components/DetentSheet.swift`,
  `Packages/Core/Sources/DesignSystem/SemanticColors.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/MapSearchBar.swift`

**Kararlar**
- Yeni token proje sahibinin onayıyla eklendi. `backgroundSubtle` değiştirilmedi, giriş
  ekranlarındaki alanlar etkilenmez.

**Doğrulama**
- `verify-ios.sh --package Core` ve `--package Features`: geçti.
- `swift test` (Core): 23/23 geçti.
- `swiftlint lint --strict` ve `swift format lint`: değişen dosyalarda ihlal yok.
- Sürükleme davranışı komut satırından sınanamıyor; cihazda denenecek.

**Bilinen eksikler**
- İçerik bölgesinin hareketi hâlâ `simultaneousGesture`. İçeriğe buton eklendiğinde aynı sorun
  orada da çıkabilir. Yatay listeleri bozmamak için şimdilik değiştirilmedi; B–D parçalarında
  içerik gelince ele alınacak.
- Mapbox kaynak gösteriminin alt sayfa altında kalması (Adım 29) açık.

**Sıradaki adım**
- Ana sayfa B parçası (kategori çipleri), proje sahibinin onayıyla.

---

## Adım 29 — Butonlar sayfayı izliyor, büyük kademe yalnızca aramayla
**Tarih:** 2026-11-08

**Ne yapıldı**
- Alt sıradaki üç buton (şimşek, konumuma dön, yer imi) artık `DetentSheet`'in **eşlikçisi**
  (`accessory`): sayfanın üst kenarının `Spacing.md` üstünde durur ve sürüklerken parmakla
  birlikte hareket eder. Orta kademenin üstüne çıkmaz; sayfa büyürken üzerlerinden geçer.
  Sayfayla aynı zaman çizelgesinden çizildikleri için oturma yayında da birlikte hareket ederler.
- Sol üstteki menü butonu ayrı ve hiç hareket etmiyor. Önceki düzende `.animation(value:)`
  tüm buton katmanına uygulanıyordu; o katman kaldırıldı.
- `DetentSheet`'e `draggableDetents` eklendi. Ana sayfada sürüklenebilir kademeler küçük ve
  orta; büyük kademeye yalnızca aramaya dokunarak gidiliyor. Ortadan yukarı çekişte lastik
  direnci var, bırakınca ortaya dönüyor. Büyük kademedeyken sayfa aşağı sürüklenebiliyor.
  VoiceOver artır/azalt da yalnızca ulaşılabilen kademeler arasında geçiyor.
- Kullanılmayan API'ler kaldırıldı: `onHeightsChange`, `SheetDetent.settleAnimation`,
  `larger`/`smaller`, `SheetDetentHeights.zero`/`ascending`. `SheetDetentHeights` modül içine
  kapandı.

**Dosyalar**
- Değişti: `Packages/Core/Sources/DesignSystem/Components/{DetentSheet,DetentSheetTracker,SheetDetent,SheetDetentHeights,SheetMotion}.swift`,
  `Packages/Core/Tests/CoreTests/DetentSheetTrackerTests.swift`,
  `Packages/Features/Sources/HomeMapFeature/HomeMapView.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/HomeBottomSheet.swift`, `PROGRESS.md`

**Kararlar ve açık noktalar**
- Proje sahibinin isteği: butonlar sayfayı sürüklerken izler (Adım 28'deki "izlemesin"
  kararı geri alındı; kendi bileşenimiz anlık konumu verdiği için artık mümkün).
- **Varsayım:** "Yukarıda hareket eden buton" orta kademenin üstündeki hareket olarak
  yorumlandı; butonlar ortanın üstünde artık sabit. Menü butonu hiç hareket etmiyor.
- İçerik, ulaşılabilen en büyük kademede kayıyor (ana sayfada orta kademe). İçerik şimdilik boş.

**Doğrulama**
- `swift test --filter "DetentResolver|DetentSheetTracker"`: 16/16 geçti (2 yeni: sürüklenemeyen
  kademeye çıkılamaması, büyük kademeden aşağı sürükleme).
- `./Tooling/Scripts/verify-ios.sh`: tüm paketler ve uygulama geçti.
- `swiftlint lint --strict` / `swift format lint`: yeni kodda 0 ihlal (tek ihlal yine
  `SemanticColors.swift:132`).
- Simülatör (iOS 26.3 Pro Max, orta kademe): butonlar sayfanın üstünde. Sürükleme sırasındaki
  takip simülatörde elle denenmedi; cihazda denenmeli.

**Bilinen eksikler**
- Mapbox kaynak gösterimi hâlâ sayfanın altında (Adım 27).
- Arama odağı arama görevine kaldı.

**Sıradaki adım**
- Cihazda sürükleme ve takip hissinin denenmesi; ardından B parçası (kategori çipleri).

---

## Adım 28 — Kendi alt sayfamız (`DetentSheet`, K-22) ve kademeye göre yüzen butonlar
**Tarih:** 2026-11-08

**Ne yapıldı**
- iOS 26+ sistem alt sayfasının küçük/orta kademede kenarlardan içeride ("yüzen") çizildiği
  simülatörde (iOS 26.3) ve SDK başlığında doğrulandı; kapatan API yok (iOS 27 SDK dahil).
  Proje sahibi kendi bileşenimizi seçti (K-22).
- `DesignSystem/Components/DetentSheet`: saf SwiftUI, tam genişlik, alt güvenli alanı dolduran
  arka plan, üst köşeler `Radius.sheet`, `Theme.backgroundElevated`, `Theme.shadowFloating`.
  Yalnızca kendi alanındaki dokunuşları alır; ekranı kaplayan görünmez katman yok.
- Sürükleme: başlık (gösterge + arama çubuğu) her zaman sayfayı sürükler. İçerikte yukarı
  çekiş önce sayfayı büyük kademeye kadar büyütür, artanı içeriği kaydırır; aşağı çekiş önce
  içeriği en üste döndürür, artanı sayfayı küçültür. Bölme her harekette yapıldığı için
  parmak kalkmadan modlar arası geçişte sıçrama yok (`DetentSheetTracker`). Sınır ötesinde
  lastik direnci; yatay başlayan sürükleme yok sayılıyor.
- Bırakma: yansıtılan bitiş konumuna göre kademe seçimi (`DetentResolver`, saf fonksiyon);
  yavaşta en yakın, hızlı fırlatmada (≥ 500 nk/sn) fırlatma yönündeki kademe. Oturma kritik
  sönümlü yayla, içerik ataleti üstel yavaşlamayla; ikisi de zamana bağlı kapalı formül
  (`SheetMotion`) ve `TimelineView` ile çiziliyor, hareket sürerken yakalanan sayfa sıçramıyor.
- Erişilebilirlik: sürükleme göstergesi ayarlanabilir öğe (artır/azalt = kademe, değer
  seslendiriliyor); içerik VoiceOver kaydırmasına açık; "Hareketi Azalt"ta yay yerine 0,2 sn
  sade geçiş. Klavye: sayfa küçülmüyor, içeriğin altına klavye kadar boşluk ekleniyor.
- Yüzen butonlar: küçük kademede alt sıradaki üç buton sayfanın hemen üstüne iniyor, orta ve
  büyükte orta kademenin üstünde; menü butonu sabit. Geçiş, sayfanın bırakıldığı anda seçilen
  kademeyle, sayfanın oturma yayıyla aynı eğride (`SheetDetent.settleAnimation`); sürüklerken
  parmağı izlemiyor. Önceki `presentationDetents` kodu kaldırıldı.

**Kademe yükseklikleri** (ekranın alt kenarından, alt güvenli alan dahil)
- Küçük = sürükleme göstergesi + başlığın (arama çubuğu) ölçülen yüksekliği + `Spacing.md` +
  alt güvenli alan. Yazı boyutu büyüdükçe ölçüm, dolayısıyla kademe büyüyor.
- Orta = güvenli alanlar dışındaki yüksekliğin yarısı + alt güvenli alan (küçük ile büyük
  arasına sıkıştırılır).
- Büyük = ekran yüksekliği − üst güvenli alan − `Spacing.sm`.
- Ölçüm görünmez, dokunuş almayan üç katmanla: ekran, klavye hariç güvenli alan, klavye
  dahil görünür alan.

**Dosyalar**
- Eklendi: `Packages/Core/Sources/DesignSystem/Components/{DetentSheet,DetentSheetTracker,DetentResolver,SheetMotion,SheetDetent,SheetDetentHeights}.swift`,
  `Packages/Core/Tests/CoreTests/{DetentResolverTests,DetentSheetTrackerTests}.swift`
- Değişti: `Packages/Features/Sources/HomeMapFeature/{HomeMapView,HomeMapModel}.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/HomeBottomSheet.swift` (artık
  `DetentSheet` üzerine ince sarmalayıcı), `Localizable.xcstrings` (4 metin:
  `home.sheet.accessibility.{label,collapsed,medium,expanded}`), `PROGRESS.md`

**Kararlar ve açık noktalar**
- K-22 (proje sahibi): alt sayfa kendi bileşenimiz.
- İçerik kaydırması yerel `ScrollView` ile değil, sayfanın kendi sürüklemesiyle yapılıyor:
  iOS 17'de SwiftUI `ScrollView`'un sürüklemesi dıştaki `DragGesture`'a pürüzsüz devredilemiyor.
  Bedeli: kaydırma göstergesi yok; içerikte yerel `ScrollView`/`List` kullanılmamalı (yatay
  listeler sorun değil, dikey sürüklemeyi sayfa alıyor).
- Butonların geçişi sayfa *bırakıldığında* (hedef kademe belli olunca) başlıyor ve sayfayla
  aynı eğride bitiyor; tam durduktan sonra başlatmak gecikmeli hissettiriyordu.
- `DesignSystem` `Localization`'a bağımlı değil; VoiceOver metinleri bileşene dışarıdan veriliyor.
- **Çatışma:** "Aramaya dokununca odağı ver" ile "arama çubuğuna dokunma" bir arada
  yapılamadı; çubukta metin alanı yok. Dokununca sayfa büyük kademeye geçiyor, odak arama
  çubuğu görevinde gelecek. Klavye desteği bileşende hazır.
- Gösterge rengi `Theme.indicatorInactive`, boyutu `Spacing.xxl` × `Spacing.xs`; ayrı token yok.
- Fizik sabitleri (`SheetMotion`, `DetentResolver`) adlandırılmış ve belgelenmiş; tasarım
  token'ı değil.

**Doğrulama**
- `swift test --filter "DetentResolver|DetentSheetTracker"` (macOS): 14/14 geçti (yavaş bırakma,
  hızlı fırlatma, kademe atlama, sınır dışı, tek kademe, boş liste, kademenin tam üstü; içerik ↔
  sayfa devri iki yönde, başlık sürüklemesi, lastik direnci, yatay sürükleme).
- `./Tooling/Scripts/verify-ios.sh` (tüm paketler + uygulama): geçti, Swift uyarısı yok.
  `cd Packages/Core && swift build`: geçti.
- `swiftlint lint --strict` ve `swift format lint`: yeni kodda 0 ihlal; tek ihlal yine
  `SemanticColors.swift:132` (proje sahibinin açık düzenlemesi, dokunulmadı).
- Simülatör: iOS 26.3 Pro Max orta kademe — sayfa tam genişlik, alt kenara kadar, butonlar orta
  kademenin üstünde. iOS 18.3 SE `xxxLarge` küçük kademe — arama çubuğu tam görünüyor, üç buton
  sayfanın hemen üstüne inmiş. Küçük kademe görüntüsü için açılış kademesi derleme süresince
  geçici değiştirildi, hemen geri alındı.
- **Doğrulanmadı:** sürükleme, fırlatma, içerik devri, VoiceOver ve "Hareketi Azalt"
  simülatörde elle denenmedi (komut satırından sürükleme yapılamıyor). Cihazda denenmesi gerekiyor.

**Bilinen eksikler**
- Mapbox kaynak gösterimi hâlâ sayfanın altında (Adım 27 açık noktası).
- Sayfa içeriği şimdilik boş; içerik kaydırması yalnızca önizlemedeki örnekle denenebilir.
- Arama odağı ve klavye akışı arama görevine kaldı.

**Sıradaki adım**
- Proje sahibinin cihazda sürükleme hissini denemesi; ardından B parçası (kategori çipleri).

---

## Adım 27 — Ana sayfa A parçası: yüzen butonlar ve alt sayfa iskeleti
**Tarih:** 2026-11-08

**Ne yapıldı**
- Açılış yeniden doğrudan ana haritaya sabitlendi (proje sahibinin isteği):
  `RootView.opensMapOnLaunch = true`, `AppRouter.init(flow:)`. Kayıt → harita bağlantısı
  (Adım 26) duruyor; anahtar `false` yapılınca geri gelir.
- `DesignSystem/Components/FloatingMapButton`: dairesel, `Theme.backgroundElevated` zemin,
  `Theme.shadowFloating` gölge, `Theme.textPrimary` simge, `Spacing.minTapTarget` boyut,
  zorunlu VoiceOver etiketi. `RecenterButton` bu bileşene taşındı; izin akışı ve dolu/boş
  simge değişimi aynı (eski ince kenarlık tasarıma uymadığı için kalktı).
- `HomeMapView` iki katmana ayrıldı. Arka plan: harita + dört sabit buton (sol üst menü,
  sol alt şimşek ve konumuma dön, sağ alt yer imi). Ön katman: `.sheet` ile sunulan
  `HomeBottomSheet`. Ekran dışarıya `onMenu`, `onSearch`, `onNearbyChargers`, `onSavedPlaces`
  kapanışlarını veriyor; `RootView` henüz boş kapanış veriyor (hedef ekranlar yok).
- `HomeBottomSheet`: `presentationDetents` ile üç kademe (küçük / orta / büyük), sürükleme
  göstergesi, `Theme.backgroundElevated` zemin, `Radius.sheet` köşe, kapatılamaz
  (`interactiveDismissDisabled`), orta kademeye kadar harita etkileşime açık
  (`presentationBackgroundInteraction(.enabled(upThrough:))`). Açılış orta kademede.
- `MapSearchBar`: görsel arama çubuğu (büyüteç + yer tutucu, `Theme.backgroundSubtle`,
  `Radius.field`). Dokununca model sayfayı büyük kademeye alıyor ve `onSearch` çağrılıyor.
- `HomeMapModel`: `SheetDetent` (`collapsed`, `medium`, `expanded`), `sheetDetent` (varsayılan
  `.medium`), `beginSearch()`. Konum izni reddedildi uyarısı sayfanın üzerine taşındı (sayfa
  açıkken arkadaki görünüm ikinci bir sunum açamaz).
- 4 metin eklendi: `home.search.placeholder`, `home.accessibility.{menu,nearbyChargers,savedPlaces}`.

**Kademe yükseklikleri**
- **Küçük:** `Spacing.xl` (üst; sürükleme göstergesine yer) + arama çubuğunun ölçülen
  yüksekliği (`onGeometryChange`) + `Spacing.lg` (alt). Yazı boyutu büyüyünce çubuk uzar,
  ölçüm değişir, kademe de büyür.
- **Orta:** haritanın güvenli alan içindeki yüksekliği × 0,5
  (`HomeBottomSheet.mediumHeight(forContainerHeight:)`, sistemin `.medium` mantığı). Sistem
  `.medium` kullanılmadı; yüksekliği dışarıdan okunamıyor, butonların ise tam üstünde durması
  gerekiyor. Aynı fonksiyon hem kademeyi hem butonların alt boşluğunu (`orta + Spacing.md`)
  veriyor; iki taraf tek kaynaktan besleniyor.
- **Büyük:** sistemin `.large` kademesi.
- Yükseklikler ölçümle değiştiği için seçim modelde kademe adıyla (`SheetDetent`) tutuluyor;
  sistemin `PresentationDetent` değeri her çizimde güncel yükseklikten üretiliyor.

**Dosyalar**
- Eklendi: `Packages/Core/Sources/DesignSystem/Components/FloatingMapButton.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/{HomeBottomSheet,MapSearchBar}.swift`
- Değişti: `Packages/Features/Sources/HomeMapFeature/{HomeMapView,HomeMapModel}.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/RecenterButton.swift`,
  `Packages/Features/Tests/FeaturesTests/HomeMapModelTests.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`,
  `App/RootView.swift`, `App/Navigation/AppRouter.swift`, `PROGRESS.md`

**Kararlar ve açık noktalar**
- **Mapbox kaynak gösterimi alt sayfanın altında kalıyor** (CLAUDE.md 7 ile çatışma). Logo ve
  bilgi butonu haritanın sol/sağ alt köşesinde; sayfa en küçük kademede bile onları örtüyor.
  Çözüm `MapEngine.MapView`'a süs öğelerinin alt boşluğunu alan bir parametre eklemek; görev
  dosya listesi dışında olduğu için yapılmadı, proje sahibinin onayı bekleniyor.
- Mapbox ölçek çubuğu sol üstte menü butonuyla üst üste biniyor (simülatörde görüldü). Aynı
  `MapEngine` değişikliğiyle ele alınabilir (gizlemek ya da taşımak).
- Gölgenin yayılımı ve kayması `Spacing.sm` / `Spacing.xs`'ten alındı; gölge geometrisi
  token'ı yok. Ayrı bir token istenirse eklenir (Theme dosyasına dokunulmadı).
- Tasarım dosyası bu oturumda erişilebilir değildi; arama çubuğu ve butonların görsel
  ayrıntıları (simge seçimi, çubuk zemini, köşe yarıçapı) token'larla makul varsayımla yazıldı.
- Orta kademe oranı (0,5) B–D parçalarının içeriğine göre yeniden ayarlanabilir; tek nokta
  `HomeBottomSheet.mediumHeightRatio`.
- `HomeMapFeature/HomeMapFeature.swift` yer tutucusu modülde gerçek tipler olduğu halde duruyor
  (5.6 kural 6); bu görevin kapsamında olmadığı için silinmedi.

**Doğrulama**
- `./Tooling/Scripts/verify-ios.sh --package Features`: geçti, uyarı yok.
- `./Tooling/Scripts/verify-ios.sh --app`: geçti.
- `cd Packages/Core && swift build`: geçti (`FloatingMapButton` macOS'ta da derleniyor).
- `swiftlint lint --strict`: yeni/değişen dosyalarda 0 ihlal. Tek ihlal
  `SemanticColors.swift:132` (dosya sonu satır sonu eksik); bu proje sahibinin açık
  düzenlemesi (`shadowFloating` eklenmesi), dokunulmadı. `swift format lint`: aynı tek uyarı.
- Simülatör (iPhone SE 3, `xxxLarge`, açık tema): orta kademede butonlar sayfanın üst kenarının
  bir boşluk üstünde; **küçük kademede arama çubuğu kırpılmadan tam görünüyor**, butonlar
  yerinde. Küçük kademe, açılış kademesi derleme süresince geçici olarak değiştirilip görüntü
  alınarak doğrulandı; değişiklik hemen geri alındı.
- Önizlemeler: SE / Pro Max × `Large` / `xxxLarge` × açık / koyu (orta kademe) + SE `xxxLarge`
  üzerinde üç kademe. Önizlemeler Xcode kanvasında açılmadı.
- `HomeMapModelTests`'e 2 test eklendi (açılış kademesi, aramanın sayfayı büyütmesi);
  çalıştırılmadı, proje sahibi koşuyor.

**Bilinen eksikler**
- Mapbox kaynak gösterimi sayfanın altında kalıyor (yukarıda).
- Butonlar ve arama hiçbir ekran açmıyor; hedef ekranlar yazılınca `AppRouter`'a bağlanır.
- Pro Max ve koyu tema simülatörde denenmedi, yalnızca önizlemeleri yazıldı.

**Sıradaki adım**
- Kaynak gösterimi için `MapEngine` kararı; ardından ana sayfa B parçası (kategori çipleri).

---

## Adım 26 — Uygulama akışı: kayıt → ana harita
**Tarih:** 2026-11-07

**Ne yapıldı**
- Geçici `RootView.opensMapOnLaunch` sabiti kaldırıldı; açılış yeniden kayıt akışıyla başlıyor.
- `AppRouter`'a akış durumu eklendi: `AppRouter.Flow` (`signUp`, `home`) ve salt okunur `flow`.
- `AppRouter.completeSignUp()`: gezinme yığınını boşaltır ve `flow`'u `.home` yapar; ana
  haritadan geri dönerek kayıt ekranlarına ulaşılamaz.
- Ad-soyad ekranının `onContinue`'su `completeSignUp()`'a bağlandı. `RootView` `flow`'a göre
  kayıt akışını ya da `HomeMapView`'ı gösteriyor.
- `AppRouterTests`'e iki test eklendi: açılışın kayıt akışıyla başlaması, kayıt bitince
  haritaya geçilip yığının boşalması.

**Dosyalar**
- Değişti: `App/Navigation/AppRouter.swift`, `App/RootView.swift`,
  `OnsarjTests/AppRouterTests.swift`, `PROGRESS.md`

**Kararlar ve açık noktalar**
- Akış değişikliği proje sahibinin açık isteğiyle yapıldı ("kayıttan sonra ana sayfaya
  yönlendir"). `Route`'a yeni durum eklenmedi; harita yığına itilen bir ekran değil, ayrı bir
  akışın kökü.
- Ad ve soyad henüz hiçbir yere gönderilmiyor (K-10 bekleniyor).
- **Açık nokta:** Oturum kalıcı değil. Kayıt tamamlandı bilgisi saklanmadığı için uygulama her
  açılışta kayıt akışıyla başlıyor. Saklanacak şey gerçek oturum token'ı olmalı (Keychain,
  CLAUDE.md 7) ve `AuthService` + backend sözleşmesine (K-10) bağlı. Sahte bir "kayıtlı"
  bayrağı yazılmadı (CLAUDE.md 2.3).
- Uygulama hedefine ürün bağlama veya `project.pbxproj` değişikliği gerekmedi.

**Doğrulama**
- `./Tooling/Scripts/verify-ios.sh --app`: geçti. Bağlayıcıdan (`ld`) iki
  "address ... points before section(33) start" uyarısı geldi; Swift kodundan değil,
  bağlama aşamasından.
- `swiftlint lint --strict`: 0 ihlal. `swift format lint` (değişen dosyalar): 0 ihlal.
- `AppRouterTests` çalıştırılmadı; proje sahibi testleri kendisi koşuyor.

**Bilinen eksikler**
- Oturum saklanmıyor (yukarıda). Giriş yap (`WelcomeView.onLogin`) hâlâ bağlı değil.
- Haritadan çıkış / oturumu kapatma yok; profil ekranı yazılınca ele alınır.

**Sıradaki adım**
- Proje sahibinin cihazda kayıt → harita akışını denemesi; ardından istasyon katmanı.

---

## Adım 25 — Mapbox Maps SDK, MapEngine, konum izni ve ana harita ekranı
**Tarih:** 2026-11-02

**Ne yapıldı**
- Token yönetimi: `Config/Secrets.xcconfig.template`, `Base.xcconfig`'te `#include?` ile
  isteğe bağlı `Secrets.xcconfig`. Token uygulamaya kısmi Info.plist (`App/Support/Info.plist`,
  `MBXAccessToken = $(MAPBOX_PUBLIC_TOKEN)`) ve yalnızca uygulama hedefine bağlı
  `Config/App.xcconfig` (`INFOPLIST_FILE`) üzerinden ulaşıyor; SDK token'ı kendisi okuyor.
- `ci_scripts/ci_post_clone.sh`: `MAPBOX_DOWNLOAD_TOKEN` → `~/.netrc`, `MAPBOX_PUBLIC_TOKEN` →
  `Config/Secrets.xcconfig` (ikisi de izin 600). Değişken eksikse, indirme token'ı `sk.` ya da
  genel token `pk.` ile başlamıyorsa açık mesajla duruyor.
- `MapboxKit`: Maps SDK `exact: "11.33.1"`, yalnızca `MapEngine` hedefinde. `MapEngine`:
  `MapView` (UIViewRepresentable; dışarıya sade `UIView` döner, Mapbox tipi sızmaz), `MapStyle`
  (açık: Standard + `day`, koyu: Standard + `night`; tema değişince kendiliğinden geçer),
  `MapCamera` (başlangıç bölgesi, `followUser()`, `isFollowingUser`).
- Başlangıç görünümü cihazın bölge ayarındaki ülke: `LocationKit/CountryBounds` paket içi
  tablodan (237 ülke, Natural Earth v5.1.2, kamu malı) ülkenin sınır kutusunu verir; harita
  açılınca kutu ekrana sığdırılır. Bölge belirlenemezse `CountryBounds.fallbackRegionCode`
  (`"TR"`). İnternet gerekmez (K-03).
- `LocationKit`: `LocationAuthorization` (3 durum), `LocationSource` protokolü, `CountryBounds`,
  `DeviceLocationSource` (`CLLocationManager`; izin ve konum `AsyncStream` olarak, konum
  güncellemeleri yalnızca abone varken ve izin verilmişken çalışır).
- `HomeMapFeature`: `HomeMapView` + `HomeMapModel` + `Components/RecenterButton`. Tam ekran
  harita, konum göstergesi, sağ altta "konumuma dön". İzin yalnızca butona ilk dokunuşta
  isteniyor; reddedilmişse Ayarlar'a yönlendiren uyarı açılıyor.
- `NSLocationWhenInUseUsageDescription` (en/tr) ve 5 `home.map.*` metni eklendi.

**Dosyalar**
- Eklendi: `Config/Secrets.xcconfig.template`, `Config/App.xcconfig`, `App/Support/Info.plist`,
  `ci_scripts/ci_post_clone.sh`,
  `Packages/MapboxKit/Sources/MapEngine/{MapView,MapStyle,MapCamera}.swift`,
  `Packages/MapboxKit/Tests/MapboxKitTests/MapStyleTests.swift`,
  `Packages/Core/Sources/LocationKit/{LocationAuthorization,LocationSource,DeviceLocationSource,CountryBounds}.swift`,
  `Packages/Core/Sources/LocationKit/Resources/CountryBounds.json`,
  `Packages/Core/Tests/CoreTests/CountryBoundsTests.swift`,
  `Packages/Features/Sources/HomeMapFeature/{HomeMapView,HomeMapModel}.swift`,
  `Packages/Features/Sources/HomeMapFeature/Components/RecenterButton.swift`,
  `Packages/Features/Tests/FeaturesTests/HomeMapModelTests.swift`
- Değişti: `Config/Base.xcconfig`, `Packages/MapboxKit/Package.swift`, `Packages/Core/Package.swift`
  (yalnızca `LocationKit`'e `resources: [.process("Resources")]`, proje sahibinin izniyle),
  `Packages/Features/Package.swift`, `App/Composition/AppDependencies.swift`, `App/RootView.swift`,
  `App/Resources/InfoPlist.xcstrings`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`
- Değişti (otomatik, paket çözümlemesi): `Packages/{MapboxKit,Features,Services}/Package.resolved`,
  `Onsarj.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Değişti (proje sahibi, Xcode arayüzünden): `Onsarj.xcodeproj/project.pbxproj` — Info.plist
  üyelik istisnası, `App.xcconfig` referansı ve uygulama hedefinin iki yapılandırmasına bağlanması;
  `HomeMapFeature` ve `LocationKit` ürünlerinin uygulama hedefine bağlanması
- Silindi: `Packages/MapboxKit/Sources/MapEngine/MapEngine.swift`,
  `Packages/Core/Sources/LocationKit/LocationKit.swift` (yer tutucular)

**Kararlar ve açık noktalar**
- Sürüm `exact: "11.33.1"` (proje sahibi). 11.34.1 bir günlüktü; fark yalnızca çevrimdışı
  yöneticideki bir düzeltme. Navigation SDK eklenince ikisi birlikte güncel sürüme çıkar.
- `INFOPLIST_KEY_MBXAccessToken` çalışmadı: Xcode yalnızca tanıdığı `INFOPLIST_KEY_*`
  anahtarlarını aktarıyor. Kısmi Info.plist + `App.xcconfig` seçildi (proje sahibi, seçenek a).
- `MAPBOX_DOWNLOAD_TOKEN` zorunlu (proje sahibi). Maps 11.33.1 ikilileri şu an token'sız iniyor;
  Navigation SDK için kesin gerekecek. `MAPBOX_PUBLIC_TOKEN` Xcode Cloud'da Secret değil
  (uygulamaya gömülüyor, gizli değil); yalnızca indirme token'ı Secret.
- Standard'ın ayrı bir `standardNight` adresi yok; koyu tema aynı stilin `night` ışık ön
  ayarıyla veriliyor. Adres iki temada aynı olduğu için tema değişimi stili yeniden yüklemiyor.
- Mapbox'a konum verisi `LocationKit`'ten veriliyor (`LocationDataModel`). Mapbox kendi
  `AppleLocationProvider`'ını oluşturmuyor; aksi halde gösterge ilk çizildiğinde izni kendisi
  isterdi. Uygulamada tek konum kaynağı var.
- **Platform koruması yazılmadı** (CLAUDE.md 6.8: MapboxKit'te koruma yazılmaz; Mapbox'ın
  macOS sürümü de yok). Proje sahibi onayladı; sayaç **3**.
- Kamera davranışları (proje sahibi onayladı): izin daha önce verilmişse açılışta kamera
  kullanıcıya gider; izlerken zoom 15, kuzey yukarı, eğim yok (yön ve eğim navigasyonun işi);
  izin reddedilmişse butona dokununca Ayarlar uyarısı açılır.
- Başlangıç görünümü (proje sahibi): sabit Türkiye görünümü yerine cihazın bölgesindeki ülke.
  Veri kaynağı olarak paket içi sınır kutuları seçildi; CLGeocoder ağ gerektirdiği için (K-03),
  elle yazılmış liste her yeni pazarda kod değişikliği gerektirdiği için elendi.
  Kutu yöntemi: ülkenin en büyük poligonu + ona en fazla 3° uzaklıkta, alanı ana karanın en az
  %0,5'i olan parçalar; uzak denizaşırı topraklar (Fransız Guyanası, Alaska, Hawaii) dışarıda.
  Kaynak, sürüm, lisans, alınma tarihi ve yöntem JSON dosyasının başında yazılı. Yalnızca dört
  sayılık kutular var, poligon yok (10 KB). Kutular 180. boylamı geçmiyor.
- `"TR"` yedeği iki yerde duruyor: `CountryBounds.fallbackRegionCode` ve
  `PhoneNumberFormatter.fallbackRegionCode`. İki modül birbirine bağımlı değil; ortak bir yere
  almak bağımlılık değişikliği gerektirir. Ana pazar değişirse ikisi birlikte değişir.
- `MapEngine` `LocationKit`'e bağımlı olmadığı için iki benzer tip var: `CountryBounds`
  (LocationKit) ve `MapCamera.Region` (MapEngine); `HomeMapModel` birini diğerine çevirir.
- **Geçici açılış** (proje sahibinin açık kararı, CLAUDE.md 2.3'e bilinçli istisna):
  `RootView.opensMapOnLaunch = true`. Kayıt akışı silinmedi, dokunulmadı.
- Kenardan kaydırarak geri dönme düzeltmesi (commit `37e212c`, `6aa85df`) proje sahibi
  tarafından cihazda denendi, çalışıyor; ayrı bir adım olarak kaydedilmedi.
  `OnsarjUITests/SwipeBackProbeTests.swift`'in kalıcı mı olacağı karar bekliyor.

**Doğrulama**
- Swift 6 katı eşzamanlılık: `MapEngine` ve `HomeMapFeature` `-swift-version 6` ile,
  Mapbox modülleri (`MapboxMaps`, `MapboxCommonWrapper`, `MapboxCoreMapsWrapper`) kendi
  paketlerinin bildirdiği `-swift-version 5` ile derlendi. Derleme günlüklerinde **sıfır uyarı,
  sıfır hata.** Mapbox protokolü `ViewportStatusObserver` için `@preconcurrency` uyumu kullanıldı.
- `cd Packages/Core && swift build`: geçti.
- `verify-ios.sh`: tüm paketler ve uygulama şeması geçti. Bölge sığdırmada önce kullanılan
  `camera(for:padding:bearing:pitch:maxZoom:offset:)` kullanımdan kaldırılmış çıktı; yerine
  `camera(for:camera:coordinatesPadding:maxZoom:offset:)` kullanıldı, uyarı yok.
- `xcodebuild test` (iPhone 16 Pro simülatörü): `HomeMapModelTests` 8/8, `MapStyleTests` 3/3,
  `CountryBoundsTests` 6/6 geçti (son ikisi kaynak dosyasının iOS paketine girdiğini de sınar).
  `swift test --filter CountryBoundsTests` (macOS): 6/6.
- `swiftlint lint --strict`: 0 ihlal. `swift format lint`: 0 ihlal.
- Açık/koyu stil seçimi birim testiyle doğrulandı (Mapbox'ın `standard(lightPreset:)` tanımına
  eşit). Harita proje sahibi tarafından cihazda çalıştırıldı.
- Token yolu: üretilen `Onsarj.app/Info.plist`'te `MBXAccessToken` dolu; test hedeflerinde yok.

**Bilinen eksikler**
- **Geçici:** Açılış doğrudan haritaya gidiyor, kayıt akışı atlanıyor
  (`App/RootView.swift`, `opensMapOnLaunch`). Geri almak tek satır: `false`.
- Ülke kutusuyla açılış cihazda henüz denenmedi (önceki sabit Türkiye görünümü denendi).
- Takımada ülkelerinde (ör. Endonezya) kutu yalnızca ana kümeyi kapsar; ilk görünüm ülkenin
  bir kısmını gösterir.
- `HomeMapView` önizlemesinde harita çizilmeyebilir (token ve ağ gerekir); beklenen durum.
- Konum göstergesi yönü `course`'tan (hareket yönü) geliyor; pusula yönü (heading) yok.
- CLAUDE.md bölüm 10 maddeleri kapanmadı, bkz. aşağı.

**CLAUDE.md bölüm 10**
- "Mapbox SDK'larının Swift 6 strict concurrency ile uyumu": **Maps SDK için sıfır uyarı, sıfır
  hata.** Madde işaretlenmedi (proje sahibi): Maps ve Navigation'ı birlikte kapsar,
  Navigation SDK eklendiğinde kapanır.
- Özel Mapbox stilinin telefonda görünmesi: hazır Standard stil kullanılıyor, özel stil yok;
  açık kalıyor.

**Sıradaki adım:** Ülke kutusuyla açılışın cihazda denenmesi; ardından istasyon katmanı.

---

## Adım 24 — Uygulamanın Türkçe açılması
**Tarih:** 2026-10-25

**Ne yapıldı**
- Neden bulundu: Telefon dili Türkçeyken uygulama İngilizce açılıyordu. iOS uygulamanın dilini,
  ana paketin (`Onsarj.app`) bildirdiği dillere göre seçer. Türkçe metinler yalnızca
  `Core_Localization.bundle/tr.lproj` içindeydi; ana pakette hiç `.lproj` klasörü ve
  `CFBundleLocalizations` yoktu. Bu yüzden iOS geliştirme diline (`en`) düşüyordu.
- Neden doğrulandı: Aynı derlemenin Info.plist'ine yalnızca `CFBundleLocalizations = [en, tr]`
  eklenince uygulama Türkçe açıldı. Deneme geçici bir derleme kopyasında yapıldı, depoya girmedi.
- Proje sahibi Xcode'dan Turkish yerelleştirmesini ekledi (`knownRegions` listesine `tr`).
- `App/Resources/InfoPlist.xcstrings` oluşturuldu. İlk anahtar `CFBundleDisplayName`:
  en ve tr karşılığı `onsarj`. Derleme artık ana pakette `en.lproj` ve `tr.lproj` üretiyor.
- Dört ekran (karşılama, telefon, SMS kodu, ad-soyad) simülatörde Türkçe açılıp gezildi.

**Dosyalar**
- Eklendi: `App/Resources/InfoPlist.xcstrings`
- Değişti (proje sahibi, Xcode arayüzünden): `Onsarj.xcodeproj/project.pbxproj`, yalnızca
  `knownRegions` listesine `tr` satırı.

**Kararlar ve açık noktalar**
- Uygulamanın desteklediği dilleri bildirme yolu olarak `InfoPlist.xcstrings` seçildi
  (Apple'ın standart yolu). Alternatifi `CFBundleLocalizations` anahtarıydı; bunun için ayrı
  bir Info.plist, `xcconfig` ayarı ve senkronize klasörde üyelik istisnası gerekiyordu.
- İzin metinleri (`NSLocation*`, `NSUserNotifications*`) şimdi eklenmedi; harita ekranına
  gelindiğinde aynı dosyaya girecek. Ana paketten çevrilmeleri gerektiği için yerleri burası.
- Dil bildirimi artık uygulama hedefinde duruyor. Yeni bir dil eklenirse hem paketteki
  `Localizable.xcstrings`'e hem `InfoPlist.xcstrings`'e o dilin karşılıkları girilmeli;
  aksi halde iOS o dili uygulamada görmez.

**Doğrulama**
- Geçici UI testi (iPhone 17 Pro simülatörü, `-AppleLanguages (tr)`): dört ekranın Türkçe
  başlığı ve butonları bulunup ekran görüntüleri alındı, test geçti. Test sonra silindi.
- Simülatörün sistem dili `tr-TR` iken uygulama argümansız başlatıldı: karşılama ekranı Türkçe.
- `verify-ios.sh --app`: geçti. `swiftlint lint --strict`: ihlal yok.

**Bilinen eksikler**
- Ad-soyad ekranında simülatörün kendi klavye tanıtım sayfası İngilizce çıktı. Bu sistem
  klavyesinin dili, uygulamayla ilgisi yok.

**Sıradaki adım:** Kenardan kaydırarak geri dönmenin düzeltilmesi.

---

## Adım 23 — Koyu tema denetimi
**Tarih:** 2026-10-17

**Ne yapıldı**
- Dört ekran (`WelcomeView`, `PhoneEntryView`, `VerificationCodeView`, `NameEntryView`), alt
  bileşenleri (`AuthFeature/Components`) ve `DesignSystem/Components` altındaki üç bileşen
  tarandı: `Palette`'e doğrudan başvuru, `.white`/`.black`, `Color(.system…)`, `UIColor`
  sabiti yok. Tek sabit `CodeInputField`'deki `.clear`; görünmez giriş alanı için bilerek
  kullanılıyor, renk değil.
- `PrimaryButton`: devre dışıyken metin `Theme.onActionPrimaryDisabled` (önce her durumda
  `onActionPrimary` idi; koyu temada devre dışı butonda siyah zemin üzerinde siyah metin olurdu).
- Önizlemeler: dört ekranın her durumuna ve `ScreenHeader`, `FormTextField` önizlemelerine
  koyu tema varyantı eklendi (iPhone 17 Pro Max · Large · koyu). Ekran önizlemelerindeki
  görünüm kurulumu yardımcı fonksiyona alındı, tekrar etmiyor.
- Logo: `brand-logo` koyu varyantı (`brand-logo-white.svg`) tanımlı ve doğru seçiliyor.
  Geçici bir testle simülatörde ölçüldü: opak piksellerin ortalama parlaklığı açık temada
  0,16, koyu temada 0,78. Test sonra silindi.
- UIKit tarafı: `PhoneNumberTextField`'deki `UIColor(Theme.textPrimary)` ve
  `UIColor(Theme.textPlaceholder)` dönüşümlerinin dinamik kaldığı (açık/koyu farklı çözülüyor)
  aynı geçici testle doğrulandı.

**Dosyalar**
- Değişti: `Packages/Core/Sources/DesignSystem/Components/{PrimaryButton,ScreenHeader,FormTextField}.swift`,
  `Packages/Features/Sources/AuthFeature/{WelcomeView,PhoneEntryView,VerificationCodeView,NameEntryView}.swift`,
  `Packages/Core/Sources/DesignSystem/{UITypography,SemanticColors,ColorPalette}.swift` (yalnızca son satır sonu)
- Değişmedi (denetlendi, sorun yok): `AuthFeature/Components/{IconBadge,PhoneNumberField,
  PhoneNumberTextField,CodeInputField,ResendCodeButton,OnboardingSlide,PageIndicator,CountryPicker}.swift`

**Kararlar ve açık noktalar**
- `CountryPicker` (alt sayfa) liste zemini, satır zemini, ayraçlar, arama çubuğu ve boş arama
  görünümü (`ContentUnavailableView`) sistem renklerini kullanıyor; açıkça yazılmış renk yok.
  Koyu temada alt sayfanın sistem zemini `#1C1C1E` = `Palette.ink1` = `Theme.backgroundElevated`,
  yani görünür fark yok. Token'a bağlanması istenirse ayrı iş: `scrollContentBackground` ve
  `listRowBackground` ile `Theme.backgroundElevated`; ayraç için `Theme.borderSubtle`.
- Koyu temada yer tutucu (`ink4` `#5A5A5F`) alan zemini (`ink1`) üzerinde düşük kontrastlı
  (yaklaşık 2,5:1). Yer tutucu için kabul edilebilir; token değeri proje sahibinin kararı.

**Doğrulama**
- `verify-ios.sh --package Features`, `--package Core`, `--app`: geçti. `swift build` (Core): geçti.
- `swiftlint lint --strict`, `swift format lint --strict`: ihlal yok. `UITypography.swift`,
  `SemanticColors.swift`, `ColorPalette.swift` sonunda eksik olan satır sonu, proje sahibinin
  bu seferlik izniyle eklendi (renk değerlerine dokunulmadı).
- Ekranlar simülatörde koyu temada gözle kontrol edilmedi; önizlemeler eklendi.

**Bilinen eksikler**
- Koyu temanın SE ve xxxLarge kombinasyonları ayrı önizlenmiyor (koyu varyant yalnızca
  Pro Max · Large).

**Sıradaki adım:** Önizlemelerin Xcode'da koyu temada gözden geçirilmesi. `CountryPicker`
ve yer tutucu kontrastı proje sahibince kontrol edildi, olduğu gibi kalıyor.

---

## Adım 22 — Ad ve soyad ekranı, ortak form metin alanı
**Tarih:** 2026-10-17

**Ne yapıldı**
- `FormTextField` (`DesignSystem/Components`): tek satırlık form alanı. Görünümü ve yüksekliği
  telefon ekranındaki numara alanıyla aynı (`Theme.backgroundSubtle`, `Radius.field`, en az
  `Spacing.minTapTarget` + üstte/altta `Spacing.xs`). Dışarıdan: metin, yer tutucu anahtarı +
  paket, `textContentType`, büyük harf davranışı, dönüş tuşu, hata durumu (kenarlık
  `Theme.borderError`). Bağlamanın sahibi değeri keserse alan bunu kendi metnine geri yazar.
- `NameEntryView` + `NameEntryModel`: diğer iki ekranla aynı düzen. Ekran açılınca ad alanı
  odaklanıyor. Ad alanında `.next` soyada geçiriyor, soyadda `.done` klavyeyi kapatıyor.
  `.givenName` / `.familyName`, `.words`, otomatik düzeltme kapalı.
- Doğrulama: kırpıldıktan sonra en az 2 karakter ve en az bir harf. Karakter süzülmüyor.
  Her alan en fazla 50 karakter, fazlası kesiliyor. İki alan geçerli olana kadar "Devam"
  devre dışı. `onContinue` kırpılmış değerleri veriyor.
- Yönlendirme: `Route.nameEntry` eklendi. SMS ekranının `onSubmit`'i her kodda ad ekranına
  geçiyor (kayıtlı kullanıcı ayrımı K-10'u bekliyor). Ad ekranından geri dönüş
  `AppRouter.pop(to: .phoneEntry)` ile telefon ekranına gidiyor; harcanmış kodun ekranına
  dönülmüyor. `onContinue` bağlı değil, sonraki ekran tasarlanmadı.
- `user-entry-icon` görsel setinin `Contents.json`'ı diğer iki simgeyle aynı yapıya getirildi
  (tek ölçek, vektör korunuyor, `Original` çizim). Önceki hali SVG'yi 1x'e rasterleyip
  bulanık gösterirdi.
- 6 `signup.name.*` metni eklendi (İngilizce ve Türkçe).

**Dosyalar**
- Eklendi: `Packages/Core/Sources/DesignSystem/Components/FormTextField.swift`,
  `Packages/Features/Sources/AuthFeature/{NameEntryView,NameEntryModel}.swift`,
  `Packages/Features/Tests/FeaturesTests/NameEntryModelTests.swift`
- Değişti: `App/Navigation/{Route,AppRouter}.swift`, `App/RootView.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`,
  `Packages/Features/Sources/AuthFeature/Resources/Media.xcassets/user-entry-icon.imageset/Contents.json`

**Kararlar**
- `FormTextField.swift` dosyasının tamamı `#if canImport(UIKit)` içinde (proje sahibinin
  kararı, CLAUDE.md 6.8 "üçüncü durum"). Core'da `swift build` ayakta kalıyor.
  **Ayırma eşiği sayımı:** tüm dosyası korunan dosyalar `UITypography.swift` ve
  `FormTextField.swift`, yani **2**. `SemanticColors.swift`'te yalnızca import ve bir başlatıcı
  korunuyor, sayılmadı. Proje sahibi "üçüncüsü" demişti; sayımın teyidi bekleniyor. Eşik: 5.
- `IconBadge` değiştirilmedi. Görevin 2. maddesi zaten karşılanmıştı: bileşen `Image` alıyor,
  hem asset hem SF Symbol kabul ediyor. Ayrıca bileşen `DesignSystem`'de değil,
  `AuthFeature/Components` içinde.
- 50 karakter sınırı geçersizlik değil, kesme olarak uygulandı: fazlası alana girmez.
- Soyad alanındaki "Bitti" yalnızca klavyeyi kapatıyor, formu göndermiyor (varsayım).
- `FormTextField`'in hata durumu bu ekranda kullanılmıyor; tasarımda hata gösterimi yok.
- Geri oku etiketi `signup.phone.accessibility.back` yeniden kullanıldı (SMS ekranındaki gibi).

**Doğrulama**
- `verify-ios.sh --package Features`, `--package Core`, `--app`: geçti. `swift build` (Core): geçti.
- `xcodebuild test -scheme Features-Package` (iPhone 16 Pro simülatörü): 2 suite, 17 test geçti.
  `NameEntryModel` testleri: kırpma, 2 karakter alt sınırı, harfsiz girdinin reddi, isim içi
  noktalama, 50 karakter üst sınırı, butonun etkinleşmesi.
- `swiftlint lint --strict` ve `swift format lint`: yeni ihlal yok. Var olan iki ihlal:
  `UITypography.swift` ve `SemanticColors.swift` sonunda satır sonu eksik. Görev bu dosyalara
  dokunmayı yasakladığı için düzeltilmedi.
- Ekran proje sahibi tarafından simülatörde kontrol edildi, sorun bildirilmedi.

**Bilinen eksikler**
- Akıllı tırnak: SwiftUI'da kapatan bir değiştirici yok. Otomatik düzeltme kapalıyken
  sistemin akıllı tırnak uygulamadığı varsayıldı, `O'Brien` girişiyle cihazda denenmedi.
  Tutmazsa ya `FormTextField` UIKit'e geçer ya da kesme işareti kayıt sırasında normalleştirilir.
- Kenardan kaydırarak geri dönme çalışmıyor (Adım 21'den beri).
- `UITypography.swift` ve `SemanticColors.swift` lint ihlalleri.

**Sıradaki adım:** Ad-soyad sonrası ekranın tasarımı; K-10 gelince kod doğrulama ve
kayıt servislerinin bağlanması.

---

## Adım 21 — Ortak üst çubuk (ScreenHeader), SMS ekranı metinleri
**Tarih:** 2026-10-14

**Ne yapıldı**
- `ScreenHeader` (`DesignSystem/Components`): ortada başlık, solda geri oku. Telefon ve SMS
  ekranlarındaki yerel `toolbar` kopyaları silindi; iki ekran da sistem gezinme çubuğunu
  gizleyip bu bileşeni kullanıyor. Önizleme: SE ve Pro Max × Large ve xxxLarge.
- Geri oku: iOS 26'nın çizdiği cam çerçeve ve arka plan yok, yalnızca ok. Ok küçüldü
  (`Typography.buttonSmall`). Dokunma alanı `Spacing.minTapTarget` karesi (`contentShape`).
- SMS ekranından "Değiştir" kaldırıldı: `onChangeNumber` kapanışı, `RootView` bağlantısı ve
  `verification.action.changeNumber` anahtarı silindi. Numarayı değiştirmek için geri oku kullanılıyor.
- Tekrar gönderme satırı: önce soluk "Kod gelmedi mi?", yanında geri sayım ya da altı çizili
  "Kodu tekrar gönder". Büyük yazıda alt alta geçiyor.
- Metinler: başlık "Enter your code" / "Kodunu gir". Açıklama "We sent a 6-digit code by SMS to" /
  "6 haneli kodu SMS ile şu numaraya gönderdik:". Yeni anahtar: `verification.resend.question`.

**Dosyalar**
- Eklendi: `Packages/Core/Sources/DesignSystem/Components/ScreenHeader.swift`
- Değişti: `Packages/Features/Sources/AuthFeature/{PhoneEntryView,VerificationCodeView}.swift`,
  `Packages/Features/Sources/AuthFeature/Components/ResendCodeButton.swift`, `App/RootView.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings`

**Kararlar**
- `ScreenHeader` bir `toolbar` öğesi değil, görünüm olarak yazıldı (`safeAreaInset(edge: .top)`).
  Böylece görünüm iOS 17'den 26'ya kadar aynı kalıyor; iOS 26'nın cam arka planını
  sürüm kontrolüyle kapatmak gerekmiyor.
- DesignSystem `Localization`'a bağlı olmadığı için metinler `PrimaryButton`'daki gibi anahtar +
  paket olarak veriliyor.
- Başlık, uygulamadaki diğer başlıklar gibi cümle düzeninde yazıldı: "Enter your code".

**Doğrulama**
- `swift build` (Core), `verify-ios.sh` (tam: uygulama ve tüm paketler): geçti.
- `swiftlint --strict`, `swift format lint`: yeni ihlal yok.
- Simülatörde (iPhone 16 Pro, İngilizce) iki ekranın görüntüsü alınıp kontrol edildi.
  Geçici UI testi silindi.

**Bilinen eksikler**
- Sistem gezinme çubuğu gizli olduğu için kenardan kaydırarak geri dönme çalışmıyor
  (önceden de geri düğmesi gizli olduğu için çalışmıyordu).
- Simülatörde `-AppleLanguages (tr)` ile başlatılan uygulama İngilizce açıldı. Uygulamanın
  Türkçe yerelleştirmeyi bildirip bildirmediği (Info.plist / proje bölgeleri) kontrol edilmeli.
  İncelenmedi, proje dosyasına dokunulmadı.
- SE ve xxxLarge matrisi cihazda gözle kontrol edilmedi.

**Sıradaki adım:** Türkçe dil sorununun kontrolü; ardından ad-soyad ekranı (tasarım bekleniyor).

---

## Adım 20 — SMS kodu ekranında görsel düzeltmeler
**Tarih:** 2026-10-14

**Ne yapıldı**
- Simge: SF Symbol yerine proje sahibinin `sms-entry-icon` SVG'si. Görsel seti
  `phone-entry-icon` ile aynı yapıya getirildi: tek ölçek, vektör korunuyor, `Original` çizim.
- Kod alanı 6 ayrı kareye bölündü (`Typography.numericLarge`, `Theme.backgroundSubtle`,
  `Radius.field`, kareler eşit genişlikte). Sıradaki hanenin karesi kenarlıkla vurgulanıyor,
  yazıldıkça bir sonrakine geçiyor. Hata varken bütün kareler `Theme.borderError`.
- Alanın üstünde görünen yer tutucu metin ("Verification code, 6 digits") kaldırıldı.
  Etiket artık yalnızca VoiceOver'a veriliyor.
- "Değiştir" ve "Kodu tekrar gönder": yeşil yerine altı çizili `Theme.textPrimary`,
  `Typography.secondary`. Geri sayım soluk düz metin.
- Kod alanı ile tekrar gönderme satırı arası daraltıldı: aralık `Spacing.xs`, satırın 44pt
  dokunma alanı metnin altına doğru uzuyor.

**Dosyalar**
- Değişti: `Packages/Features/Sources/AuthFeature/VerificationCodeView.swift`,
  `Packages/Features/Sources/AuthFeature/Components/{CodeInputField,ResendCodeButton}.swift`,
  `Packages/Features/Sources/AuthFeature/Resources/Media.xcassets/sms-entry-icon.imageset/Contents.json`

**Kararlar**
- **[Onay]** Etkin karenin kenarlığı `Theme.actionPrimary`. Odak kenarlığı için ayrı bir
  token yok ve yeni token eklenmedi. İstenirse `borderFocused` token'ı proje sahibince eklenir.
- Adım 19'daki "Devam açılmıyor" bildirimi kodda tekrar oluşturulamadı. Simülatörde akış
  çalışıyor; büyük olasılıkla eski derlemeden kaynaklandı.

**Doğrulama**
- `verify-ios.sh --package Features` ve `--app`: geçti. `swiftlint --strict`,
  `swift format lint`: yeni ihlal yok.
- Simülatörde (iPhone 16 Pro, Large) geçici bir UI testiyle ekran görüntüsü alınıp kontrol
  edildi. Test dosyası sonra silindi, depoda kalmadı.

**Bilinen eksikler**
- SE ve xxxLarge matrisi gözle kontrol edilmedi.
- Hata mesajı alanı boşken de bir satır yer kaplıyor (zıplamayı önlemek için).
- Önceki görevin 1. ve 2. maddeleri (`ScreenHeader` ortak bileşeni, geri butonunun
  sadeleşmesi) henüz yapılmadı.

**Sıradaki adım:** `ScreenHeader` ve geri butonu.

---

## Adım 19 — SMS doğrulama kodu ekranı
**Tarih:** 2026-10-14

**Ne yapıldı**
- `VerificationCodeView`: telefon ekranıyla aynı dikey düzen. Gezinme çubuğu, `IconBadge`
  (`message.fill`), başlık, açıklama + numara + "Değiştir" bağlantısı, kod alanı, hata
  mesajı, tekrar gönderme satırı, altta `PrimaryButton`. Numara E.164 olarak gelir,
  `PhoneNumberFormatter` ile `+90 553 735 93 94` biçiminde gösterilir.
- `CodeInputField`: tek kutuda 6 hane (`Typography.numeric`), boş haneler
  `Theme.textPlaceholder` renginde `minus` simgesi. Üzerine metni ve imleci saydam bir
  SwiftUI `TextField` bindirildi (`.numberPad`, `.oneTimeCode`), ekran açılınca odaklanıyor.
  Hata varken kenarlık `Theme.borderError`. VoiceOver'a tek alan olarak sunuluyor.
- `VerificationCodeModel`: rakam dışı karakter ve 6'dan fazla hane süzülüyor. 6 hane
  dolunca kod kendiliğinden gönderiliyor. Süren gönderim (`submission`) varken ikinci
  gönderim yapılmıyor. Yeni bir rakam yazılınca hata temizleniyor.
- `ResendCodeButton`: geri sayım, başlangıç anı + süreden hesaplanıyor (`TimelineView`,
  1 sn). Arka planda geçen süre de sayılıyor. Süre dışarıdan veriliyor (varsayılan 60 sn).
- Hata görünümü: `VerificationCodeError` (şimdilik `invalidCode`). Mesaj alanı hata yokken
  de saydam olarak yerini koruyor, içerik zıplamıyor. Hata çıkınca VoiceOver'a duyuruluyor.
  Geri sayım `updatesFrequently` ile her saniye seslendirilmiyor.
- `Route.verificationCode(phoneNumber:)` eklendi. Telefon ekranındaki "Devam" artık bu
  ekrana geçiyor. "Değiştir" ve geri oku telefon ekranına dönüyor, girilen numara dolu kalıyor.

**Dosyalar**
- Eklendi: `Packages/Features/Sources/AuthFeature/{VerificationCodeView,VerificationCodeModel,VerificationCodeError}.swift`,
  `Packages/Features/Sources/AuthFeature/Components/{CodeInputField,ResendCodeButton}.swift`,
  `Packages/Features/Tests/FeaturesTests/VerificationCodeModelTests.swift`
- Değişti: `App/Navigation/Route.swift`, `App/RootView.swift`,
  `Packages/Core/Sources/Localization/Resources/Localizable.xcstrings` (9 `verification.*` anahtarı)

**Kararlar** (proje sahibinin onayını bekleyenler işaretli)
- **[Onay]** `onSubmit` imzası `(code) async throws(VerificationCodeError)`. Hata
  "dışarıdan" bu kapanıştan fırlatılarak veriliyor. Kapanış sürdüğü sürece gönderim kilitli
  kalıyor; çift gönderim böyle engelleniyor. Ayrı bir hata parametresi, modelin durumuyla
  çift sahiplik yaratırdı.
- **[Onay]** Görevdeki dört dosyaya ek olarak `VerificationCodeError.swift` açıldı
  (CLAUDE.md 6.3, özelliğin kendi hata tipi).
- **[Onay]** Kod alanı `opacity(0)` yerine saydam metin + saydam `tint` kullanıyor. Saydam
  görünüm SwiftUI'da dokunuşu ve VoiceOver erişimini kaybediyor. Gizli alan, süzülen değeri
  kendi metnine geri yazıyor; kabul edilmeyen karakter alanda birikmiyor.
- Geri sayım metni `%lld` ile yazıldı (görevdeki `%d` yerine). `Int` argümanının doğru
  biçim belirteci bu.
- Görev tanımına uygun olarak `Route`'a yeni durum eklendi (CLAUDE.md 2.6, ekranlar arası yeni geçiş).
- "Değiştir" de `pop()` yapıyor. Telefon ekranı yığında durumunu koruduğu için numara dolu kalıyor.
  Geri okundan farkı şimdilik yalnızca kapanış düzeyinde.
- Geri düğmesi etiketi olarak mevcut `signup.phone.accessibility.back` anahtarı kullanıldı.
- Yazı tipleri: "Değiştir" ve tekrar gönderme `Typography.caption`. Geri sayım rakamları ve
  numara `.monospacedDigit()`. Rakam haneleri yayılmıyor, `Spacing.lg` aralıkla ortalanıyor.

**Doğrulama**
- `swift build` + `swift test` (Core): geçti, 11 test.
- `verify-ios.sh --package Features` ve `verify-ios.sh --app`: geçti.
- `xcodebuild test -scheme Features-Package` (iPhone 16 Pro simülatörü):
  `VerificationCodeModel` paketindeki 9 test geçti.
- `swiftlint --strict`, `swift format lint --strict`: ajanın dosyalarında ihlal yok.
  `UITypography.swift` ve `SemanticColors.swift` sonunda satır sonu eksik (proje sahibinin dosyaları).

**Bilinen eksikler**
- Önizleme matrisi derleniyor ama gözle kontrol edilmedi. Cihazda `.oneTimeCode` önerisi,
  otomatik odak ve VoiceOver davranışı elle denenmeli.
- `onSubmit` ve `onResend`, `RootView` içinde boş kapanış (backend yok, K-10).
  Kod doğrulanınca nereye gidileceği belirsiz.
- Tekrar gönderme başarısız olursa ne gösterileceği tanımlı değil.
- Hata mesajı alanı tek hata türünün yüksekliğini ayırıyor. Daha uzun mesajlı bir tür
  eklenirse bu alan yeniden ele alınmalı.

**Sıradaki adım:** Cihaz testi; ardından doğrulama sonrası ekran (K-10 ile).

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