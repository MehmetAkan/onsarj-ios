import CoreLocation
import XCTest

/// Haritadaki istasyon katmanı: pinler, pin seçimi, kümeler ve kümeye dokununca yakınlaşma. Pinler stil
/// katmanında çizildiği için erişilebilirlik ağacında yoktur; adımlar ekran görüntüsüyle kaydedilir ve iOS
/// sürümleri ile temalar arasında karşılaştırılır (CLAUDE.md 2.9).
///
/// Konum testin içinde Antalya'ya ayarlanır; harita açılışta konuma sokak düzeyinde (15) gider. Dokunma
/// noktaları 440×956 pt ekran içindir (iPhone 16/17 Pro Max) ve o ekranlardaki görüntülerden alınmıştır.
///
/// **Ön koşul:** konum izni verilmiş olmalı: `xcrun simctl privacy <cihaz> grant location com.onsarj.Onsarj`.
/// Test `-parallel-testing-enabled NO` ile koşulur; paralel testte simülatör kopyası izni taşımaz.
///
/// **iOS 26:** XCUITest'in iki parmakla dokunuş, kıstırma ve sürükleme hareketleri iOS 26 simülatöründe
/// Mapbox haritasına ulaşmıyor (dokunma ve çift dokunma ulaşıyor). Uzaklaşma gerektiren testler orada atlanır.
final class StationLayerPresentationTests: XCTestCase {
    private var app: XCUIApplication!

    /// Işıklar istasyonunun 545 m güneyi, 295 m batısı. Mapbox konumu izlerken noktayı ekranın alt kısmına
    /// (y ≈ 700 pt) koyar; sokak düzeyinde Işıklar (Eşarj) ve Kaleiçi (ZES) pinleri sayfanın üstünde görünür.
    private let isiklarSouth = CLLocation(latitude: 36.8840, longitude: 30.7080)
    /// Muratpaşa'nın kuzeydoğusu; uzaklaştıkça Antalya'nın tüm istasyonları görünür.
    private let muratpasa = CLLocation(latitude: 36.8870, longitude: 30.7150)

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Sokak düzeyinde pinler; pine dokununca seçim ve ortalama; boş haritaya dokununca seçimin kalkması.
    /// Her iOS sürümünde koşar.
    @MainActor
    func testStreetLevelPinSelection() {
        launch(scenario: "default", at: isiklarSouth)
        attachScreenshot("1-sokak")

        // Işıklar pininin logo dairesi.
        tap(x: 373, y: 139)
        pause(2)
        attachScreenshot("2-secili")

        tap(x: 60, y: 300)
        pause(2)
        attachScreenshot("3-secim-kalkti")
    }

    /// Uzaklaşınca logolu pinler ve dört müsaitlik rengi; pin seçimi.
    @MainActor
    func testPinsAndSelection() throws {
        try skipOnIOS26()
        launch(scenario: "default", at: muratpasa)
        zoomOut(levels: 3)
        attachScreenshot("4-pinler")

        tap(x: 295, y: 330)
        pause(2)
        attachScreenshot("5-secili")
    }

    /// Uzaklaşınca kümeler; kümeye dokununca harita kümenin açıldığı düzeye yakınlaşır.
    @MainActor
    func testClustersExpandOnTap() throws {
        try skipOnIOS26()
        launch(scenario: "default", at: muratpasa)
        zoomOut(levels: 5)
        attachScreenshot("6-kumeler")

        tap(x: 191, y: 225)
        pause(2)
        attachScreenshot("7-kume-acildi")
    }

    /// 1000 istasyonla kümeler ve kaydırma; akıcılık ekran görüntüsü ve gözlemle değerlendirilir.
    @MainActor
    func testDenseScenarioScrolling() throws {
        try skipOnIOS26()
        launch(scenario: "dense", at: muratpasa)
        zoomOut(levels: 3)
        attachScreenshot("dense-kumeler")
        for _ in 0..<2 {
            map.swipeLeft(velocity: .fast)
            map.swipeDown(velocity: .fast)
            map.swipeRight(velocity: .fast)
            map.swipeUp(velocity: .fast)
        }
        pause(2)
        attachScreenshot("dense-kaydirma-sonu")
    }

    /// Harita (`MapView.accessibilityIdentifier`). Pencereye yapılan iki parmakla dokunuşun koordinatı
    /// hesaplanamıyor; hareketler bu öğeye yapılır.
    private var map: XCUIElement { app.descendants(matching: .any)["onsarj.map"].firstMatch }

    private func skipOnIOS26() throws {
        if #available(iOS 26.0, *) {
            throw XCTSkip("iOS 26 simülatöründe XCUITest çok parmaklı hareketleri haritaya ulaşmıyor")
        }
    }

    /// Mapbox'ta iki parmakla dokunuş bir düzey uzaklaştırır.
    @MainActor
    private func zoomOut(levels: Int) {
        for _ in 0..<levels {
            map.twoFingerTap()
            pause(1)
        }
        pause(2)
    }

    @MainActor
    private func launch(scenario: String, at location: CLLocation) {
        app.launchArguments = [
            "-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "-onsarjStationScenario", scenario,
        ]
        XCUIDevice.shared.location = XCUILocation(location: location)
        app.launch()
        XCTAssertTrue(app.buttons["Nereye gitmek istiyorsun?"].waitForExistence(timeout: 15))
        // Harita konuma gider, karolar ve istasyonlar yüklenir (300 ms bekleme + istek).
        pause(5)
    }

    /// Ekranın sol üst köşesine göre bir noktaya (pt) dokunur.
    @MainActor
    private func tap(x: CGFloat, y: CGFloat) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }

    /// Haritanın animasyonu ve yüklemesi için bekler; beklenen bir öğe olmadığı için ters beklenti kullanılır.
    @MainActor
    private func pause(_ seconds: TimeInterval) {
        let idle = expectation(description: "harita")
        idle.isInverted = true
        wait(for: [idle], timeout: seconds)
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
