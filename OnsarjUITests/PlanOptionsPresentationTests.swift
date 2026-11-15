import XCTest

/// Plan seçenekleri modalı: ana sayfadaki "Seçenekler"den açılır; şarj ağları ve ağ seçici aynı
/// modal içinde yığınla açılır; geri, X ve aşağı çekme çalışır. Değişiklikler anında saklanır ve
/// uygulama yeniden açıldığında korunur. Test sonunda tercihleri varsayılana döndürür.
final class PlanOptionsPresentationTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
        app.launch()
    }

    @MainActor
    func testChangesPersistAcrossRelaunch() {
        openPlanOptions()
        attachScreenshot("1-plan-secenekleri")

        app.buttons["En az"].tap()
        app.buttons["Otoyollar"].tap()
        XCTAssertTrue(app.buttons["En az"].isSelected)
        XCTAssertTrue(app.buttons["Otoyollar"].isSelected)

        app.buttons["Düzenle"].tap()
        XCTAssertTrue(app.staticTexts["Ağların"].waitForExistence(timeout: 3))
        attachScreenshot("2-sarj-aglari-bos")

        app.buttons["Tercih edilen ağ ekle"].tap()
        XCTAssertTrue(app.buttons["Aksa Şarj, Ekle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "Klavye açılmadı")
        // Arama Türkçe kurallarla büyük/küçük harf duyarsız; satır klavyenin altında kalmasın diye aranır.
        app.typeText("zes")
        XCTAssertTrue(app.buttons["ZES, Ekle"].waitForExistence(timeout: 3))
        app.buttons["ZES, Ekle"].tap()
        XCTAssertTrue(app.buttons["ZES, Eklendi"].waitForExistence(timeout: 3))
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "TRU")
        XCTAssertTrue(app.buttons["Trugo, Ekle"].waitForExistence(timeout: 3))
        app.buttons["Trugo, Ekle"].tap()
        XCTAssertTrue(app.buttons["Trugo, Eklendi"].waitForExistence(timeout: 3))
        attachScreenshot("3-secici")

        app.buttons["Geri dön"].tap()
        XCTAssertTrue(app.buttons["ZES kaldır"].waitForExistence(timeout: 3))
        app.buttons["Kaçınılan ağ ekle"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "Klavye açılmadı")
        app.typeText("total")
        XCTAssertTrue(app.buttons["TotalEnergies, Kaçın"].waitForExistence(timeout: 3))
        app.buttons["TotalEnergies, Kaçın"].tap()
        XCTAssertTrue(app.buttons["TotalEnergies, Kaçınılıyor"].waitForExistence(timeout: 3))
        app.buttons["Geri dön"].tap()
        XCTAssertTrue(app.buttons["TotalEnergies kaldır"].waitForExistence(timeout: 3))
        attachScreenshot("4-sarj-aglari-dolu")

        app.buttons["Geri dön"].tap()
        XCTAssertTrue(app.staticTexts["ZES, Trugo"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["TotalEnergies"].exists)
        attachScreenshot("5-ozet")

        app.buttons["Kapat"].tap()
        XCTAssertTrue(title.waitForNonExistence(timeout: 3))

        app.terminate()
        app.launch()
        openPlanOptions()
        XCTAssertTrue(app.buttons["En az"].isSelected)
        XCTAssertTrue(app.buttons["Otoyollar"].isSelected)
        XCTAssertTrue(app.staticTexts["ZES, Trugo"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["TotalEnergies"].exists)
        attachScreenshot("6-yeniden-acilis")

        resetPreferences()
    }

    @MainActor
    func testCloseButtonAndSwipeDown() {
        openPlanOptions()
        app.buttons["Düzenle"].tap()
        app.buttons["Kaçınılan ağ ekle"].tap()
        XCTAssertTrue(app.buttons["ZES, Kaçın"].waitForExistence(timeout: 5))
        attachScreenshot("1-kacin-secici")
        app.buttons["Kapat"].tap()
        XCTAssertTrue(title.waitForNonExistence(timeout: 3))

        openPlanOptions()
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        top.press(forDuration: 0.1, thenDragTo: bottom, withVelocity: .fast, thenHoldForDuration: 0)
        XCTAssertTrue(title.waitForNonExistence(timeout: 3))
    }

    private var title: XCUIElement {
        app.staticTexts["Plan seçenekleri"]
    }

    @MainActor
    private func openPlanOptions() {
        let options = app.buttons["Seçenekler"]
        XCTAssertTrue(options.waitForExistence(timeout: 15))
        options.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Optimal"].waitForExistence(timeout: 5))
    }

    /// Sonraki koşular ve elle deneme temiz başlasın diye tercihleri varsayılana döndürür.
    @MainActor
    private func resetPreferences() {
        app.buttons["Optimal"].tap()
        app.buttons["Otoyollar"].tap()
        app.buttons["Düzenle"].tap()
        XCTAssertTrue(app.buttons["ZES kaldır"].waitForExistence(timeout: 3))
        app.buttons["ZES kaldır"].tap()
        app.buttons["Trugo kaldır"].tap()
        app.buttons["TotalEnergies kaldır"].tap()
        app.buttons["Geri dön"].tap()
        XCTAssertTrue(app.staticTexts["Tercih edilen ağ yok."].waitForExistence(timeout: 3))
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
