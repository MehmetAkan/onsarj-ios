import Foundation
import OnsarjDomain
import Testing

@testable import VehicleService

@Suite("Araç istek DTO'ları")
struct VehicleRequestDTOTests {
    private func json(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("Güncelleme isteği yalnızca dolu alanları ve backend alan adlarını taşır")
    func updateRequest() throws {
        let update = VehicleUpdate(connectors: [.type2, .ccs2], colorHex: VehiclePaint.black.hex)
        let body = try json(UpdateVehicleRequestDTO(update: update))
        #expect(Set(body.keys) == ["connectors", "colorHex"])
        #expect(body["connectors"] as? [String] == ["type2", "ccs2"])

        let full = try json(
            UpdateVehicleRequestDTO(update: VehicleUpdate(nickname: "", batteryHealthPercent: 95))
        )
        #expect(Set(full.keys) == ["nickname", "batteryHealthPercent"])
        #expect((full["nickname"] as? String)?.isEmpty == true)
    }

    @Test("Etkin profil isteği yalnızca activeProfileId taşır")
    func activeProfileRequest() throws {
        let body = try json(UpdateVehicleRequestDTO(activeProfileID: DrivingProfile.ID("prof_1")))
        #expect(body as? [String: String] == ["activeProfileId": "prof_1"])
    }

    @Test("Profil isteği ad, tüketim ve hız taşır; kimlik yolda gider")
    func profileRequest() throws {
        let draft = DrivingProfileDraft(
            id: DrivingProfile.ID("p"), name: " Şehir ", consumptionKwhPer100Km: 15.25, maxSpeedKmh: 90)
        let body = try json(DrivingProfileRequestDTO(draft: draft))
        #expect(Set(body.keys) == ["name", "consumptionKwhPer100Km", "maxSpeedKmh"])
        #expect(body["name"] as? String == "Şehir")
        #expect(body["consumptionKwhPer100Km"] as? Double == 15.3)
        #expect(body["maxSpeedKmh"] as? Int == 90)
    }
}
