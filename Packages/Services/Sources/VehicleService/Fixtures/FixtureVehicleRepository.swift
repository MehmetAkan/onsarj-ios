// Geçici veri (K-23, K-26): backend hazır olana kadar araçlar bu dosyadan gelir; backend
// bağlanınca dosya silinir. JSON, K-23 ek notu gereği kaynak dosyası değil dizge sabitidir.
#if DEBUG
import Foundation
import OnsarjDomain

/// Araçları gömülü JSON'dan veren ve yazma isteklerini bellekte bir backend gibi işleyen depo.
///
/// - **Okuma:** `JSONDecoder` → `VehicleDTO` → `VehicleMapper`; gerçek yanıtla aynı yol.
/// - **Yazma (K-26):** Domain isteği önce backend istek DTO'suna (`UpdateVehicleRequestDTO`,
///   `DrivingProfileRequestDTO`) çevrilir; `FixtureVehicleBackend` isteği doğrular, bellekteki DTO'ya
///   uygular ve yanıt DTO'sunu döner; yanıt yine eşlemeden geçer.
/// - Değişiklikler yalnızca bellektedir: uygulama yeniden açılınca fixture'a döner.
///
/// **Görsel.** JSON'daki `imageUrl` bir adres değil, görsel adıdır; ilk okumada `resourceLookup` ile
/// yerel dosya adresine (`file://`) çevrilir. Eşleme `file` şemasını yalnızca buradan kabul eder.
///
/// **Senaryo.** `FixtureScenario` kartın hallerini kodu değiştirmeden denemeyi sağlar.
public actor FixtureVehicleRepository: VehicleRepository {
    private let scenario: FixtureScenario
    private let resourceLookup: @Sendable (String) -> URL?
    private var backend: FixtureVehicleBackend?

    /// - Parameters:
    ///   - scenario: Denenecek hal.
    ///   - resourceLookup: Görsel adını yerel dosya adresine çevirir; çözemezse `nil`.
    public init(
        scenario: FixtureScenario = .default,
        resourceLookup: @escaping @Sendable (String) -> URL? = { _ in nil }
    ) {
        self.scenario = scenario
        self.resourceLookup = resourceLookup
    }

    public func vehicles() async throws -> [Vehicle] {
        let list = VehicleListDTO(vehicles: try loadedBackend().vehicles)
        return try VehicleMapper.vehicles(from: list, acceptsFileImageURLs: true)
    }

    public func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle {
        try respond(try loadedBackend().patchVehicle(id.rawValue, UpdateVehicleRequestDTO(update: update)))
    }

    public func deleteVehicle(_ id: Vehicle.ID) async throws {
        try loadedBackend().deleteVehicle(id.rawValue)
    }

    public func addVehicle(variantID: VehicleVariant.ID) async throws -> Vehicle {
        let request = CreateVehicleRequestDTO(variantID: variantID)
        return try respond(try loadedBackend().postVehicle(request, catalog: try FixtureVehicleCatalog.tables()))
    }

    public func setDefaultVehicle(_ id: Vehicle.ID) async throws -> Vehicle {
        try respond(try loadedBackend().patchVehicle(id.rawValue, .makeDefault))
    }

    public func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        let request = DrivingProfileRequestDTO(draft: draft)
        let backend = try loadedBackend()
        if let id = draft.id {
            return try respond(try backend.putProfile(vehicleID.rawValue, profileID: id.rawValue, request))
        }
        return try respond(try backend.postProfile(vehicleID.rawValue, request))
    }

    public func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        try respond(try loadedBackend().deleteProfile(vehicleID.rawValue, profileID: id.rawValue))
    }

    public func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        let request = UpdateVehicleRequestDTO(activeProfileID: id)
        return try respond(try loadedBackend().patchVehicle(vehicleID.rawValue, request))
    }

    private func respond(_ dto: VehicleDTO) throws -> Vehicle {
        try VehicleMapper.vehicle(from: dto, acceptsFileImageURLs: true)
    }

    /// Senaryoya göre bellekteki backend; ilk çağrıda JSON'dan kurulur.
    private func loadedBackend() throws -> FixtureVehicleBackend {
        if scenario == .failure { throw FixtureScenarioFailure() }
        if let backend { return backend }
        var list = try JSONDecoder().decode(VehicleListDTO.self, from: Data(Self.json.utf8))
        if scenario == .noVehicles { list.vehicles = [] }
        for index in list.vehicles.indices {
            list.vehicles[index].imageUrl = imageAddress(for: list.vehicles[index].imageUrl)
        }
        let created = FixtureVehicleBackend(vehicles: list.vehicles)
        backend = created
        return created
    }

    /// Görsel adını yerel dosya adresine çevirir; `noImage` senaryosunda görsel yoktur.
    private func imageAddress(for name: String?) -> String? {
        guard scenario != .noImage, let name else { return nil }
        return resourceLookup(name)?.absoluteString
    }

    // `colorHex` aracın boya verisidir, arayüz rengi değildir.
    // swiftlint:disable no_hardcoded_hex_color
    static let json = """
        {
          "vehicles": [
            {
              "id": "veh_fixture_01",
              "make": "BYD",
              "model": "Dolphin",
              "variant": "Standart",
              "modelYear": 2023,
              "nickname": null,
              "batteryCapacityKwh": 60.5,
              "connectors": ["type2", "ccs2"],
              "maxAcPowerKw": 11,
              "maxDcPowerKw": 88,
              "colorHex": "#F2F2F2",
              "bodyType": "hatchback",
              "imageUrl": "vehicle-empty-state",
              "batteryHealthPercent": 95,
              "isDefault": true,
              "drivingProfiles": [
                {
                  "id": "prof_fixture_standard",
                  "name": "Standart",
                  "consumptionKwhPer100Km": 17.8,
                  "maxSpeedKmh": 120,
                  "isStandard": true
                },
                {
                  "id": "prof_fixture_highway",
                  "name": "Otoyol",
                  "consumptionKwhPer100Km": 20.5,
                  "maxSpeedKmh": 130,
                  "isStandard": false
                }
              ],
              "activeProfileId": "prof_fixture_standard"
            }
          ]
        }
        """
    // swiftlint:enable no_hardcoded_hex_color
}

/// `failure` senaryosunun bilerek fırlattığı hata: kartın hata halini denemek için.
struct FixtureScenarioFailure: Error {}
#endif
