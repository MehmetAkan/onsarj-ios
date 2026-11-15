#if DEBUG
import Foundation
import OnsarjDomain
import Testing

@testable import VehicleService

@Suite("FixtureVehicleRepository yazma işlemleri")
struct FixtureVehicleWriteTests {
    private let repository = FixtureVehicleRepository()
    private let vehicleID = Vehicle.ID("veh_fixture_01")
    private let standardID = DrivingProfile.ID("prof_fixture_standard")
    private let highwayID = DrivingProfile.ID("prof_fixture_highway")

    private func draft(_ id: DrivingProfile.ID? = nil, name: String = "Şehir") -> DrivingProfileDraft {
        DrivingProfileDraft(id: id, name: name, consumptionKwhPer100Km: 15.2, maxSpeedKmh: 90)
    }

    @Test("Güncelleme yalnızca dolu alanları değiştirir ve sonraki okumada kalır")
    func update() async throws {
        let blue = VehiclePaint.blue.hex.lowercased()
        let update = VehicleUpdate(nickname: "  Beyaz  ", batteryHealthPercent: 90, colorHex: blue)
        let vehicle = try await repository.updateVehicle(vehicleID, update)
        #expect(vehicle.nickname == "Beyaz")
        #expect(vehicle.batteryHealthPercent == 90)
        #expect(vehicle.colorHex == VehiclePaint.blue.hex)
        #expect(vehicle.connectors == [.type2, .ccs2])
        #expect(try await repository.vehicles().first == vehicle)

        let cleared = try await repository.updateVehicle(vehicleID, VehicleUpdate(nickname: ""))
        #expect(cleared.nickname == nil)
    }

    @Test("Son konnektör kaldırılamaz; aralık dışı sağlık reddedilir")
    func invalidUpdates() async {
        await #expect(throws: VehicleRepositoryError.atLeastOneConnectorRequired) {
            try await repository.updateVehicle(vehicleID, VehicleUpdate(connectors: []))
        }
        await #expect(throws: VehicleRepositoryError.invalidValue(.batteryHealth)) {
            try await repository.updateVehicle(vehicleID, VehicleUpdate(batteryHealthPercent: 40))
        }
        await #expect(throws: VehicleRepositoryError.vehicleNotFound) {
            try await repository.updateVehicle(Vehicle.ID("yok"), VehicleUpdate(nickname: "a"))
        }
    }

    @Test("Profil ekleme yeni kimlik üretir; düzenleme değerleri değiştirir")
    func addAndEditProfile() async throws {
        let added = try await repository.saveProfile(draft(), for: vehicleID)
        let city = try #require(added.drivingProfiles.last)
        #expect(added.drivingProfiles.count == 3)
        #expect(city.name == "Şehir")
        #expect(![standardID, highwayID].contains(city.id))
        #expect(!city.isStandard)

        let edited = try await repository.saveProfile(
            DrivingProfileDraft(id: city.id, name: "Şehir içi", consumptionKwhPer100Km: 14, maxSpeedKmh: 80),
            for: vehicleID
        )
        #expect(edited.drivingProfiles.last?.name == "Şehir içi")
        #expect(edited.drivingProfiles.last?.maxSpeedKmh == 80)
    }

    @Test("Aynı ad (büyük/küçük harf duyarsız) reddedilir")
    func duplicateName() async {
        await #expect(throws: VehicleRepositoryError.duplicateProfileName) {
            try await repository.saveProfile(draft(name: "OTOYOL"), for: vehicleID)
        }
    }

    @Test("Standart profil silinemez; etkin profil silinince standart etkin olur")
    func deleteProfile() async throws {
        await #expect(throws: VehicleRepositoryError.cannotDeleteStandardProfile) {
            try await repository.deleteProfile(standardID, for: vehicleID)
        }
        let active = try await repository.setActiveProfile(highwayID, for: vehicleID)
        #expect(active.activeProfileID == highwayID)

        let afterDelete = try await repository.deleteProfile(highwayID, for: vehicleID)
        #expect(afterDelete.drivingProfiles.map(\.id) == [standardID])
        #expect(afterDelete.activeProfileID == standardID)
        await #expect(throws: VehicleRepositoryError.profileNotFound) {
            try await repository.setActiveProfile(highwayID, for: vehicleID)
        }
    }

    @Test("Aracı silmek sonrası liste boş")
    func deleteVehicle() async throws {
        try await repository.deleteVehicle(vehicleID)
        #expect(try await repository.vehicles().isEmpty)
    }

    @Test("Senaryolar yazmada da geçerli: noVehicles bulunamadı, failure hata")
    func scenarios() async {
        await #expect(throws: VehicleRepositoryError.vehicleNotFound) {
            try await FixtureVehicleRepository(scenario: .noVehicles).deleteVehicle(vehicleID)
        }
        await #expect(throws: FixtureScenarioFailure.self) {
            try await FixtureVehicleRepository(scenario: .failure).setActiveProfile(standardID, for: vehicleID)
        }
    }
}
#endif
