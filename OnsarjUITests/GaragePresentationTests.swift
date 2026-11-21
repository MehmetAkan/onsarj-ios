import XCTest

/// "Araçlarınız" ve "Araç ekle": karttaki ad ve okla açılır, içerik yüksekliğinde; "Yeni araç ekle"
/// markalara geçer ve modal tam yüksekliğe çıkar. Togg eklenince kart Togg'a, BYD seçilince BYD'ye
/// döner. Araç yokken kartın "Araç ekle"si doğrudan markaları açar. Her adımda ekran görüntüsü:
/// sunumun iOS sürümleri arasındaki görünümü bunlarla karşılaştırılır (CLAUDE.md 2.9).
final class GaragePresentationTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
    }

    @MainActor
    func testAddToggThenSwitchBackToBYD() {
        app.launch()
        openYourVehicles()
        attachScreenshot("1-araclariniz")

        app.buttons["Yeni araç ekle"].tap()
        XCTAssertTrue(app.staticTexts["Araç ekle"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(containing: "Togg", type: .button).waitForExistence(timeout: 5))
        attachScreenshot("2-markalar-tam-yukseklik")

        element(containing: "Togg", type: .button).tap()
        XCTAssertTrue(element(containing: "T10X", type: .button).waitForExistence(timeout: 5))
        element(containing: "T10X", type: .button).tap()
        XCTAssertTrue(element(containing: "V1 RWD", type: .button).waitForExistence(timeout: 5))
        attachScreenshot("3-varyantlar")
        element(containing: "V1 RWD", type: .button).tap()

        XCTAssertTrue(app.staticTexts["Togg T10X"].waitForExistence(timeout: 5), "Kart Togg'a geçmeli")
        attachScreenshot("4-kart-togg")

        openYourVehicles(cardTitle: "Togg T10X")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "2023")).count, 1)
        attachScreenshot("5-araclariniz-iki-arac")
        element(containing: "BYD Dolphin 2023", type: .button).tap()
        XCTAssertTrue(app.staticTexts["BYD Dolphin"].waitForExistence(timeout: 5), "Kart BYD'ye dönmeli")
        attachScreenshot("6-kart-byd")
    }

    @MainActor
    func testEmptyGarageOpensBrandsDirectly() {
        app.launchArguments += ["-onsarjFixtureScenario", "noVehicles"]
        app.launch()
        let addVehicle = app.buttons["Araç ekle"]
        XCTAssertTrue(addVehicle.waitForExistence(timeout: 15))
        addVehicle.tap()

        XCTAssertTrue(element(containing: "Togg", type: .button).waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Geri"].exists, "Akışın kökünde geri düğmesi olmamalı")
        attachScreenshot("1-bos-garaj-markalar")

        app.textFields["Ara"].tap()
        app.typeText("BYD")
        XCTAssertTrue(element(containing: "BYD", type: .button).waitForExistence(timeout: 3))
        XCTAssertFalse(element(containing: "Togg", type: .button).exists)
        attachScreenshot("2-arama")
    }

    @MainActor
    private func openYourVehicles(cardTitle: String = "BYD Dolphin") {
        let card = element(containing: cardTitle, type: .button)
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        card.tap()
        XCTAssertTrue(app.staticTexts["Araçlarınız"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Yeni araç ekle"].waitForExistence(timeout: 5))
    }

    private func element(containing text: String, type: XCUIElement.ElementType) -> XCUIElement {
        app.descendants(matching: type).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
