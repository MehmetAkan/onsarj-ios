import XCTest

/// Araç ayarları: karttaki dişliyle açılır; profil değiştirince kartın alt başlığı ve menzili
/// değişir; değer modalı geçersiz değerde Kaydet'i pasif tutar; aracı silince kart "Araç ekle"ye
/// döner. Fixture değişiklikleri bellektedir; her açılışta fixture'a döner.
final class VehicleSettingsPresentationTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
        app.launch()
    }

    @MainActor
    func testProfileChangeUpdatesCard() {
        XCTAssertTrue(element(containing: "Standart").waitForExistence(timeout: 15))
        XCTAssertTrue(element(containing: "97 km").exists, "Menzil fixture ile 97 km olmalı")

        openSettings()
        attachScreenshot("1-ayarlar")
        app.buttons["Otoyol"].tap()
        XCTAssertTrue(app.buttons["Otoyol"].waitForSelection())
        XCTAssertTrue(element(containing: "20,5 kWh/100 km").waitForExistence(timeout: 3))

        app.buttons["Kapat"].tap()
        XCTAssertTrue(element(containing: "Otoyol").waitForExistence(timeout: 5))
        XCTAssertTrue(element(containing: "84 km").waitForExistence(timeout: 3), "Otoyol profiliyle menzil 84 km")
        attachScreenshot("2-kart-otoyol")
    }

    @MainActor
    func testValueSheetAndDeleteVehicle() {
        openSettings()
        element(containing: "Ref. tüketim", type: .button).tap()
        let save = app.buttons["Kaydet"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "Klavye açılmadı")
        XCTAssertFalse(save.isEnabled, "Değişmemiş değerde Kaydet pasif")
        attachScreenshot("1-deger-modali")

        app.typeText("60")
        XCTAssertTrue(element(containing: "5 ile 50 arasında").waitForExistence(timeout: 3))
        XCTAssertFalse(save.isEnabled, "Geçersiz değerde Kaydet pasif")
        attachScreenshot("2-deger-gecersiz")

        app.typeText(XCUIKeyboardKey.delete.rawValue + XCUIKeyboardKey.delete.rawValue + "18,5")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(element(containing: "18,5 kWh/100 km").waitForExistence(timeout: 3))

        let delete = app.buttons["Aracı sil"]
        app.swipeUp()
        delete.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        attachScreenshot("3-silme-onayi")
        app.alerts.firstMatch.buttons["Sil"].tap()
        XCTAssertTrue(app.buttons["Araç ekle"].waitForExistence(timeout: 5))
        attachScreenshot("4-arac-ekle")
    }

    @MainActor
    private func openSettings() {
        let gear = app.buttons["Araç ayarları"]
        XCTAssertTrue(gear.waitForExistence(timeout: 15))
        gear.tap()
        XCTAssertTrue(app.staticTexts["BYD Dolphin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Standart"].waitForExistence(timeout: 5))
    }

    private func element(containing text: String, type: XCUIElement.ElementType = .any) -> XCUIElement {
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

extension XCUIElement {
    /// Öğe kısa süre içinde seçili hale gelir mi.
    fileprivate func waitForSelection(timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "isSelected == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
