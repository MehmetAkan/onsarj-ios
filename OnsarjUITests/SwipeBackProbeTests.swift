import XCTest

final class SwipeBackProbeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
        app.launch()
    }

    @MainActor private func swipeFromEdge() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.35))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.35))
        start.press(forDuration: 0.05, thenDragTo: end)
        sleep(1)
    }

    @MainActor private func goToPhone() {
        XCTAssertTrue(app.buttons["Telefon ile Devam Et"].waitForExistence(timeout: 10))
        app.buttons["Telefon ile Devam Et"].tap()
        XCTAssertTrue(app.staticTexts["Telefon numaran nedir?"].waitForExistence(timeout: 5))
    }

    @MainActor private func goToCode() {
        goToPhone()
        let phone = app.textFields["Telefon numaranı gir"]
        phone.tap()
        phone.typeText("5321234567")
        app.buttons["Devam"].tap()
        XCTAssertTrue(app.staticTexts["Kodunu gir"].waitForExistence(timeout: 5))
    }

    @MainActor private func goToName() {
        goToCode()
        app.typeText("123456")
        if !app.staticTexts["Adın nedir?"].waitForExistence(timeout: 3) {
            app.buttons["Devam"].tap()
        }
        XCTAssertTrue(app.staticTexts["Adın nedir?"].waitForExistence(timeout: 5))
    }

    @MainActor func testWelcomeSwipeDoesNothingAndAppStaysResponsive() {
        XCTAssertTrue(app.buttons["Telefon ile Devam Et"].waitForExistence(timeout: 10))
        swipeFromEdge()
        goToPhone()
    }

    @MainActor func testPhoneSwipeReturnsToWelcome() {
        goToPhone()
        swipeFromEdge()
        XCTAssertTrue(app.buttons["Telefon ile Devam Et"].waitForExistence(timeout: 5))
    }

    @MainActor func testCodeSwipeReturnsToPhone() {
        goToCode()
        swipeFromEdge()
        XCTAssertTrue(app.staticTexts["Telefon numaran nedir?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Kodunu gir"].exists)
    }

    @MainActor func testNameSwipeReturnsToPhoneNotCode() {
        goToName()
        swipeFromEdge()
        XCTAssertTrue(app.staticTexts["Telefon numaran nedir?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Kodunu gir"].exists)
        // Telefondan bir daha geri: karşılama. SMS ekranı arada yok.
        swipeFromEdge()
        XCTAssertTrue(app.buttons["Telefon ile Devam Et"].waitForExistence(timeout: 5))
    }

    @MainActor func testNameBackArrowReturnsToPhoneNotCode() {
        goToName()
        app.buttons["Geri dön"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Telefon numaran nedir?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Kodunu gir"].exists)
    }
}
