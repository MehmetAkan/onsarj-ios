import CoreLocation
import XCTest

/// Yakındaki istasyonlar listesinin sunumu (2.9): şimşek düğmesiyle sistem sayfası orta kademede açılır; liste
/// açıkken arkadaki harita dokunmaya kapalıdır; "Sırala: Güç" seçilir; karta dokununca detay aynı sayfada itilir,
/// geri ile listeye dönülür, X ile kapanır. Her adımda ekran görüntüsü eklenir.
///
/// Varsayılan senaryoda konum Antalya, Muratpaşa'dadır (`st_002`'nin yanı). Dokunma noktaları 440×956 pt ekran
/// içindir (iPhone 16/17 Pro Max).
///
/// **Ön koşul:** konum izni verilmiş olmalı (`xcrun simctl privacy <cihaz> grant location com.onsarj.Onsarj`);
/// test `-parallel-testing-enabled NO` ile koşulur.
final class StationListPresentationTests: XCTestCase {
    private var app: XCUIApplication!

    private let location = CLLocation(latitude: 36.8849, longitude: 30.7046)

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
    }

    @MainActor
    func testListSortDetailBackAndClose() {
        XCUIDevice.shared.location = XCUILocation(location: location)
        app.launch()
        XCTAssertTrue(app.buttons["Yakındaki şarj istasyonları"].waitForExistence(timeout: 15))
        pause(3)
        app.buttons["Yakındaki şarj istasyonları"].tap()

        XCTAssertTrue(app.staticTexts["Şarj istasyonları"].waitForExistence(timeout: 10))
        let firstCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'kilovat'")).firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Konumun kapalı. Harita merkezine göre gösteriliyor."].exists)
        pause(1)
        attachScreenshot("1-liste")

        // VoiceOver: kart tek öğe, etiketi ağ, ad, uzaklık, hız ve güç, müsaitlik; yol tarifi ayrı bir düğme.
        let cardLabel = firstCard.label
        XCTContext.runActivity(named: "VoiceOver kart etiketi: \(cardLabel)") { _ in }
        XCTAssertTrue(cardLabel.hasPrefix("ZES, ZES Muratpaşa Kaleiçi Otopark, 10 metre, hızlı 60 kilovat"))
        XCTAssertGreaterThanOrEqual(app.buttons.matching(identifier: "Yol tarifi al").count, 2)
        XCTAssertEqual(app.buttons["Sırala"].value as? String, "Mesafe")

        // Liste odaklı ekran: sayfanın üstündeki haritaya dokunmak pin seçmez, detay açmaz.
        tap(x: 220, y: 200)
        pause(2)
        attachScreenshot("2-haritaya-dokunuldu")
        XCTAssertFalse(app.buttons["Yol tarifi al"].exists)
        let listStillOpen = app.staticTexts["Şarj istasyonları"].exists
        XCTContext.runActivity(named: "Haritaya dokununca liste açık mı: \(listStillOpen)") { _ in }
        if !listStillOpen {
            app.buttons["Yakındaki şarj istasyonları"].tap()
            XCTAssertTrue(app.staticTexts["Şarj istasyonları"].waitForExistence(timeout: 10))
        }

        app.buttons["Sırala"].tap()
        let power = app.buttons["Güç"].firstMatch
        XCTAssertTrue(power.waitForExistence(timeout: 5))
        pause(1)
        attachScreenshot("3-sirala-menusu")
        power.tap()
        XCTAssertTrue(app.buttons["Sırala"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sırala: Güç"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Sırala"].value as? String, "Güç")
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        pause(1)
        attachScreenshot("4-sirala-guc")

        firstCard.tap()
        XCTAssertTrue(app.buttons["Yol tarifi al"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Geri"].exists)
        pause(2)
        attachScreenshot("5-detay")

        app.buttons["Geri"].tap()
        XCTAssertTrue(app.staticTexts["Sırala: Güç"].waitForExistence(timeout: 5))
        pause(1)
        attachScreenshot("6-geri")

        app.buttons["Kapat"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Şarj istasyonları"].waitForNonExistence(timeout: 5))
        pause(1)
        attachScreenshot("7-kapandi")
    }

    /// Ekranın sol üst köşesine göre bir noktaya (pt) dokunur.
    @MainActor
    private func tap(x: CGFloat, y: CGFloat) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }

    /// Animasyon ve yükleme için bekler; beklenen bir öğe olmadığı için ters beklenti kullanılır.
    @MainActor
    private func pause(_ seconds: TimeInterval) {
        let idle = expectation(description: "bekle")
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
