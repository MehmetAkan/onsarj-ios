import XCTest

/// Arama sayfasının sunumu (K-25): ana haritadaki arama alanından açılır, alan odaklanır, X ile ve
/// aşağı çekerek kapanır. Her adımda ekran görüntüsü eklenir; sunumun iOS sürümleri arasındaki
/// görünümü bu görüntülerle karşılaştırılır (CLAUDE.md 2.9).
final class SearchPresentationTests: XCTestCase {
    private var app: XCUIApplication!

    private let placeholder = "Nereye gitmek istiyorsun?"
    /// "Ara" kapsülü; klavyenin "Ara" tuşu da aynı etiketi taşıdığı için kimlikle bulunur.
    private var submitButton: XCUIElement { app.buttons["search.submitButton"] }

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
        app.launch()
    }

    @MainActor
    func testOpensFocusedAndClosesWithCloseButton() {
        openSearch()
        attachScreenshot("1-baslangic")

        app.typeText("Gazi")
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Gaziantep Şehir Merkezi"].waitForExistence(timeout: 3))
        attachScreenshot("2-yazma")

        app.buttons["Metni temizle"].tap()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 3))
        XCTAssertTrue(submitButton.waitForNonExistence(timeout: 3))

        app.buttons["Kapat"].tap()
        XCTAssertTrue(searchField.waitForNonExistence(timeout: 3))
        attachScreenshot("3-kapandi")
    }

    @MainActor
    func testClosesWithSwipeDown() {
        openSearch()
        // Klavye açıkken sayfayı üst kenarından aşağı çeker.
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        top.press(forDuration: 0.1, thenDragTo: bottom, withVelocity: .fast, thenHoldForDuration: 0)
        XCTAssertTrue(searchField.waitForNonExistence(timeout: 3))
    }

    private var searchField: XCUIElement {
        app.textFields[placeholder]
    }

    @MainActor
    private func openSearch() {
        let homeSearch = app.buttons[placeholder]
        XCTAssertTrue(homeSearch.waitForExistence(timeout: 15))
        homeSearch.tap()
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "Klavye açılmadı")
        XCTAssertTrue((searchField.value(forKey: "hasKeyboardFocus") as? Bool) ?? false, "Alan odaklı değil")
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
