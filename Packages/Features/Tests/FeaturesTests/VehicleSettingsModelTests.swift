import Foundation
import OnsarjDomain
import Testing

@testable import GarageFeature

@MainActor
@Suite("VehicleSettingsModel")
struct VehicleSettingsModelTests {
    private let turkish = Locale(identifier: "tr_TR")

    private func loadedModel(_ repository: FakeVehicleRepository) async -> VehicleSettingsModel {
        let model = VehicleSettingsModel(repository: repository, vehicleID: Vehicle.ID("veh_1"))
        await model.load()
        return model
    }

    private func repository() -> FakeVehicleRepository {
        FakeVehicleRepository(result: .success([TestVehicles.dolphin()]))
    }

    @Test("Araç kimliğiyle yüklenir; bulunamazsa hata hali")
    func load() async {
        #expect(await loadedModel(repository()).phase == .loaded)
        let missing = FakeVehicleRepository(result: .success([TestVehicles.dolphin(id: "başka")]))
        #expect(await loadedModel(missing).phase == .failed)
    }

    @Test("Çipe dokunmak etkin profili değiştirir")
    func selectProfile() async {
        let model = await loadedModel(repository())
        await model.selectProfile(TestVehicles.highway.id)
        #expect(model.activeProfileID == TestVehicles.highway.id)
        #expect(model.vehicle?.activeProfile == TestVehicles.highway)
    }

    @Test("Yazma hatasında değer eski haline döner ve 'kaydedilemedi' bildirilir")
    func writeFailureReverts() async {
        let repository = repository()
        let model = await loadedModel(repository)
        await repository.setFailsWrites(true)

        await model.selectProfile(TestVehicles.highway.id)
        #expect(model.activeProfileID == TestVehicles.standard.id)
        #expect(model.notice?.kind == .saveFailed)

        await model.selectPaint(.red)
        #expect(model.colorHex == VehiclePaint.white.hex)
    }

    @Test("Boya rengi anında kaydolur")
    func paintSavesImmediately() async {
        let repository = repository()
        let model = await loadedModel(repository)
        await model.selectPaint(.blue)
        #expect(await repository.lastUpdate == VehicleUpdate(colorHex: VehiclePaint.blue.hex))
        #expect(model.colorHex == VehiclePaint.blue.hex)
    }

    @Test("Son konnektör kaldırılamaz; uyarı gösterilir, yazma yapılmaz")
    func lastConnectorStays() async {
        let repository = repository()
        let model = await loadedModel(repository)
        await model.toggleConnector(.ccs2)
        #expect(model.connectors == [.type2])
        await model.toggleConnector(.type2)
        #expect(model.connectors == [.type2])
        #expect(model.notice?.kind == .connectorRequired)
        #expect(await repository.lastUpdate == VehicleUpdate(connectors: [.type2]))
    }

    @Test("Değer modalı: tüketim etkin profile kaydedilir, bozulma sağlığa çevrilir")
    func saveValues() async {
        let repository = repository()
        let model = await loadedModel(repository)
        var editor = ValueEditTarget.consumption.editor(for: TestVehicles.dolphin(), locale: turkish)
        editor.text = "16,4"
        #expect(await model.save(.consumption, editor: editor))
        #expect(model.vehicle?.activeProfile.consumptionKwhPer100Km == 16.4)

        var degradation = ValueEditTarget.batteryDegradation.editor(for: TestVehicles.dolphin(), locale: turkish)
        degradation.text = "12"
        #expect(await model.save(.batteryDegradation, editor: degradation))
        #expect(model.vehicle?.batteryHealthPercent == 88)
    }

    @Test("Aracı silmek başarılıysa true döner")
    func deleteVehicle() async throws {
        let repository = repository()
        let model = await loadedModel(repository)
        #expect(await model.deleteVehicle())
        #expect(try await repository.vehicles().isEmpty)
    }
}

@Suite("ValueEditor")
struct ValueEditorTests {
    private let turkish = Locale(identifier: "tr_TR")
    private let english = Locale(identifier: "en_US")

    @Test("Mevcut değer yerel biçimde gelir; değişmemiş değerde Kaydet pasif")
    func initialValue() {
        let editor = ValueEditor.consumption(17.8, locale: turkish)
        #expect(editor.text == "17,8")
        #expect(editor.isValid)
        #expect(!editor.canSave)
    }

    @Test("Ondalık ayırıcı yerel ayara göre")
    func localeSeparator() {
        var turkishEditor = ValueEditor.consumption(17.8, locale: turkish)
        turkishEditor.text = "18,2"
        #expect(turkishEditor.decimalValue == 18.2)
        var englishEditor = ValueEditor.consumption(17.8, locale: english)
        englishEditor.text = "18.2"
        #expect(englishEditor.decimalValue == 18.2)
    }

    @Test("Geçersiz değerde Kaydet pasif ve hata satırı var", arguments: ["4,9", "50,1", "abc", "18,2,3"])
    func invalidDisablesSave(text: String) {
        var editor = ValueEditor.consumption(17.8, locale: turkish)
        editor.text = text
        #expect(!editor.canSave)
        #expect(editor.isOutOfRange)
        #expect(editor.rangeBounds?.lower == "5")
        #expect(editor.rangeBounds?.upper == "50")
    }

    @Test("Boş alan hata göstermez ama kaydedilemez")
    func emptyField() {
        var editor = ValueEditor.maxSpeed(120, locale: turkish)
        editor.text = " "
        #expect(!editor.isOutOfRange)
        #expect(!editor.canSave)
    }

    @Test("Tam sayı alanı kesirli değeri reddeder")
    func integerRejectsFraction() {
        var editor = ValueEditor.maxSpeed(120, locale: turkish)
        editor.text = "130,5"
        #expect(editor.integerValue == nil)
        editor.text = "130"
        #expect(editor.canSave)
    }
}

@Suite("DrivingProfileForm")
struct DrivingProfileFormTests {
    private let turkish = Locale(identifier: "tr_TR")

    @Test("Yeni profil standart profilin değerleriyle, boş adla başlar")
    func newProfileDefaults() {
        let form = DrivingProfileForm(profile: nil, vehicle: TestVehicles.dolphin(), locale: turkish)
        #expect(form.name.text.isEmpty)
        #expect(form.consumption.text == "17,8")
        #expect(form.maxSpeed.text == "120")
        #expect(!form.canSave)
        #expect(form.nameIssue == .empty)
    }

    @Test("Aynı ad reddedilir; geçerli adla taslak oluşur")
    func nameValidation() {
        var form = DrivingProfileForm(profile: nil, vehicle: TestVehicles.dolphin(), locale: turkish)
        form.name.text = "otoyol"
        #expect(form.nameIssue == .duplicate)
        #expect(form.draft == nil)
        form.name.text = "Şehir"
        #expect(
            form.draft == DrivingProfileDraft(id: nil, name: "Şehir", consumptionKwhPer100Km: 17.8, maxSpeedKmh: 120))
    }

    @Test("Standart profilin adı değişmez; değişiklik yoksa Kaydet pasif")
    func standardProfile() {
        var form = DrivingProfileForm(profile: TestVehicles.standard, vehicle: TestVehicles.dolphin(), locale: turkish)
        #expect(!form.isNameEditable)
        #expect(!form.canSave)
        form.maxSpeed.text = "110"
        #expect(form.draft?.name == "Standart")
        #expect(form.draft?.maxSpeedKmh == 110)
    }
}
