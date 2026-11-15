import Testing

@testable import OnsarjDomain

@Suite("Sürüş profili ve araç güncellemesi doğrulaması")
struct DrivingProfileTests {
    private let profiles = [VehicleTests.standard, VehicleTests.highway]

    private func draft(
        id: DrivingProfile.ID? = nil,
        name: String = "Şehir",
        consumption: Double = 15,
        speed: Int = 90
    ) -> DrivingProfileDraft {
        DrivingProfileDraft(id: id, name: name, consumptionKwhPer100Km: consumption, maxSpeedKmh: speed)
    }

    @Test(
        "Tüketim sınırları 5,0…50,0", arguments: [(4.9, false), (5.0, true), (50.0, true), (50.1, false), (4.96, true)])
    func consumptionBounds(value: Double, isValid: Bool) {
        #expect(DrivingProfile.isValidConsumption(value) == isValid)
    }

    @Test("Hız sınırları 50…250", arguments: [(49, false), (50, true), (250, true), (251, false)])
    func speedBounds(value: Int, isValid: Bool) {
        #expect(DrivingProfile.isValidMaxSpeed(value) == isValid)
    }

    @Test("Tüketim bir ondalığa yuvarlanır")
    func consumptionRounded() {
        #expect(draft(consumption: 17.84).consumptionKwhPer100Km == 17.8)
    }

    @Test("Ad: boş, uzun ve tekrar eden ad")
    func nameIssues() {
        #expect(DrivingProfile.nameIssue("   ", among: profiles, editing: nil) == .empty)
        #expect(DrivingProfile.nameIssue(String(repeating: "a", count: 40), among: profiles, editing: nil) == nil)
        #expect(DrivingProfile.nameIssue(String(repeating: "a", count: 41), among: profiles, editing: nil) == .tooLong)
        #expect(DrivingProfile.nameIssue("OTOYOL", among: profiles, editing: nil) == .duplicate)
        #expect(DrivingProfile.nameIssue(" otoyol ", among: profiles, editing: nil) == .duplicate)
        #expect(DrivingProfile.nameIssue("Otoyol", among: profiles, editing: VehicleTests.highway.id) == nil)
    }

    @Test("Ad benzersizliği Türkçe I/ı ve İ/i'yi aynı sayar")
    func turkishCaseInsensitive() {
        let city = DrivingProfile(
            id: DrivingProfile.ID("c"), name: "İzmir", consumptionKwhPer100Km: 15, maxSpeedKmh: 90, isStandard: false)
        #expect(DrivingProfile.nameIssue("izmir", among: [city], editing: nil) == .duplicate)
        #expect(DrivingProfile.nameIssue("IZMIR", among: [city], editing: nil) == .duplicate)
    }

    @Test("Taslak doğrulaması hatayı alanıyla verir")
    func draftValidation() {
        #expect(draft().validationError(among: profiles) == nil)
        #expect(draft(name: "").validationError(among: profiles) == .invalidValue(.profileName))
        #expect(draft(name: "otoyol").validationError(among: profiles) == .duplicateProfileName)
        #expect(draft(consumption: 60).validationError(among: profiles) == .invalidValue(.consumption))
        #expect(draft(speed: 300).validationError(among: profiles) == .invalidValue(.maxSpeed))
        #expect(draft(id: DrivingProfile.ID("yok")).validationError(among: profiles) == .profileNotFound)
    }

    @Test("Standart profilin adı değişmez, değerleri değişir")
    func standardNameIsFixed() {
        let rename = draft(id: VehicleTests.standard.id, name: "Ekonomi")
        #expect(rename.validationError(among: profiles) == .invalidValue(.profileName))
        let values = draft(id: VehicleTests.standard.id, name: "Standart", consumption: 16, speed: 110)
        #expect(values.validationError(among: profiles) == nil)
    }

    @Test("Araç güncellemesi doğrulaması")
    func updateValidation() {
        #expect(VehicleUpdate(nickname: "").validationError() == nil)
        #expect(VehicleUpdate(connectors: []).validationError() == .atLeastOneConnectorRequired)
        #expect(VehicleUpdate(batteryHealthPercent: 49).validationError() == .invalidValue(.batteryHealth))
        #expect(VehicleUpdate(batteryHealthPercent: 50).validationError() == nil)
        #expect(VehicleUpdate(colorHex: "kırmızı").validationError() == .invalidValue(.colorHex))
    }

    @Test("Boya: hex eşleşmesi büyük/küçük harf duyarsız, bilinmeyen renk nil")
    func paint() {
        #expect(VehiclePaint(hex: "#f2f2f2") == .white)
        #expect(VehiclePaint(hex: "#123456") == nil)
        #expect(VehiclePaint.allCases.count == 8)
        #expect(VehiclePaint.allCases.allSatisfy { VehiclePaint.isValidHex($0.hex) })
    }
}
