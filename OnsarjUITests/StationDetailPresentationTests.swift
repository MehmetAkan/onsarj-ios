import CoreLocation
import XCTest

/// İstasyon detay sayfasının sunumu (2.9): pine dokununca sistem sayfası orta kademede açılır; sayfa açıkken
/// başka bir pine dokununca sayfa kapanmadan o istasyonla yenilenir; büyük kademeye çekilir; kapatılınca
/// pin seçimi kalkar. Her adımda ekran görüntüsü eklenir.
///
/// `dense` senaryosunda 85 m arayla duran iki ZES istasyonu (`st_dense_0745`, `st_dense_0313`) kullanılır;
/// konum ikisinin ~480 m güneyine ayarlanır, harita sokak düzeyinde ikisini de sayfanın üstünde gösterir.
/// Dokunma noktaları 440×956 pt ekran içindir (iPhone 16/17 Pro Max).
///
/// **Ön koşul:** konum izni verilmiş olmalı (`xcrun simctl privacy <cihaz> grant location com.onsarj.Onsarj`);
/// test `-parallel-testing-enabled NO` ile koşulur.
final class StationDetailPresentationTests: XCTestCase {
    private var app: XCUIApplication!

    private let location = CLLocation(latitude: 37.0345, longitude: 30.6104)

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "-onsarjStationScenario", "dense",
        ]
    }

    @MainActor
    func testOpensUpdatesExpandsAndCloses() {
        XCUIDevice.shared.location = XCUILocation(location: location)
        app.launch()
        XCTAssertTrue(app.buttons["Nereye gitmek istiyorsun?"].waitForExistence(timeout: 15))
        pause(5)

        tap(x: 234, y: 171)
        XCTAssertTrue(app.staticTexts["ZES 0745"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Yol tarifi al"].waitForExistence(timeout: 10))
        pause(2)
        attachScreenshot("1-orta")

        // Sayfa orta kademedeyken harita etkileşime açık: diğer pine dokunulur.
        tap(x: 265, y: 150)
        XCTAssertTrue(app.staticTexts["ZES 0313"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["ZES 0745"].exists)
        pause(2)
        attachScreenshot("2-baska-pin")

        // Sürükleme göstergesinden ekranın üstüne çekilir: büyük kademe.
        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: 220, dy: 454))
            .press(forDuration: 0.2, thenDragTo: origin.withOffset(CGVector(dx: 220, dy: 40)), withVelocity: .slow,
                thenHoldForDuration: 0.3)
        pause(2)
        attachScreenshot("3-buyuk")

        app.buttons["Kapat"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Yol tarifi al"].waitForNonExistence(timeout: 5))
        pause(2)
        attachScreenshot("4-kapandi")
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
