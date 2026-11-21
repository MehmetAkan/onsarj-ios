import Foundation
import OnsarjDomain
import Testing

@testable import VehicleService

@Suite("VehicleMapper")
struct VehicleMapperTests {
    /// Geçerli bir araç kaydının JSON'u; `overrides` alanları değiştirir, `removing` alanları siler.
    private static func json(_ overrides: [String: Any] = [:], removing removed: [String] = []) throws -> Data {
        // `colorHex` aracın boya verisidir, arayüz rengi değildir.
        // swiftlint:disable no_hardcoded_hex_color
        var vehicle: [String: Any] = [
            "id": "veh_1", "make": "BYD", "model": "Dolphin", "variant": "Standart",
            "modelYear": 2023, "batteryCapacityKwh": 60.5,
            "connectors": ["type2", "ccs2"], "maxAcPowerKw": 11,
            "maxDcPowerKw": 88, "colorHex": "#F2F2F2", "bodyType": "hatchback",
            "imageUrl": "https://example.com/dolphin.png", "batteryHealthPercent": 95, "isDefault": true,
            "drivingProfiles": [profile("std", standard: true), profile("hwy", standard: false)],
            "activeProfileId": "hwy",
        ]
        // swiftlint:enable no_hardcoded_hex_color
        vehicle.merge(overrides) { _, new in new }
        removed.forEach { vehicle.removeValue(forKey: $0) }
        return try JSONSerialization.data(withJSONObject: ["vehicles": [vehicle]])
    }

    private static func profile(_ id: String, standard: Bool) -> [String: Any] {
        ["id": id, "name": id, "consumptionKwhPer100Km": 17.8, "maxSpeedKmh": 120, "isStandard": standard]
    }

    #if DEBUG
    @Test("Fixture çözülür ve eşlenir")
    func fixtureDecodes() async throws {
        let vehicles = try await FixtureVehicleRepository().vehicles()
        let vehicle = try #require(vehicles.first)
        #expect(vehicles.count == 1)
        #expect(vehicle.displayName == "BYD Dolphin")
        #expect(vehicle.id == Vehicle.ID("veh_fixture_01"))
        #expect(vehicle.connectors == [.type2, .ccs2])
        #expect(vehicle.bodyType == .hatchback)
        #expect(vehicle.imageURL == nil)
        #expect(vehicle.nickname == nil)
        #expect(vehicle.isDefault)
        #expect(vehicle.drivingProfiles.map(\.name) == ["Standart", "Otoyol"])
        #expect(vehicle.activeProfile.name == "Standart")
        #expect(vehicle.activeProfile.consumptionKwhPer100Km == 17.8)
        #expect(vehicle.estimatedRangeKm(at: BatteryLevel(percent: 30)) == 97)
    }
    #endif

    @Test("Sürüş profilleri ve etkin profil eşlenir")
    func profilesMapped() throws {
        let vehicle = try #require(try VehicleMapper.vehicles(from: try Self.json()).first)
        #expect(vehicle.drivingProfiles.map(\.id.rawValue) == ["std", "hwy"])
        #expect(vehicle.standardProfile.id == DrivingProfile.ID("std"))
        #expect(vehicle.activeProfileID == DrivingProfile.ID("hwy"))
    }

    @Test("Etkin profil yoksa veya bilinmiyorsa standart profil etkindir", arguments: ["", "yok"])
    func unknownActiveProfileIsStandard(active: String) throws {
        let data =
            active.isEmpty ? try Self.json(removing: ["activeProfileId"]) : try Self.json(["activeProfileId": active])
        #expect(try VehicleMapper.vehicles(from: data).first?.activeProfileID == DrivingProfile.ID("std"))
    }

    @Test("Standart profil yoksa, birden fazlaysa veya liste boşsa eşleme hatası verir")
    func invalidProfiles() {
        let expected = VehicleMappingError(vehicleID: "veh_1", field: .drivingProfiles, reason: .invalid)
        let cases: [[[String: Any]]] = [
            [Self.profile("a", standard: false)],
            [Self.profile("a", standard: true), Self.profile("b", standard: true)],
            [],
        ]
        for profiles in cases {
            #expect(throws: expected) {
                try VehicleMapper.vehicles(from: try Self.json(["drivingProfiles": profiles]))
            }
        }
    }

    @Test("Profil listesi yoksa eksik alan hatası")
    func missingProfiles() {
        #expect(throws: VehicleMappingError(vehicleID: "veh_1", field: .drivingProfiles, reason: .missing)) {
            try VehicleMapper.vehicles(from: try Self.json(removing: ["drivingProfiles"]))
        }
    }

    @Test("Geçerli görsel adresi korunur")
    func validImageURL() throws {
        let vehicle = try #require(try VehicleMapper.vehicles(from: try Self.json()).first)
        #expect(vehicle.imageURL == URL(string: "https://example.com/dolphin.png"))
    }

    @Test("Tanınmayan konektör atlanır")
    func unknownConnectorSkipped() throws {
        let data = try Self.json(["connectors": ["type2", "megawatt", "ccs2"]])
        #expect(try VehicleMapper.vehicles(from: data).first?.connectors == [.type2, .ccs2])
    }

    @Test("Tanınmayan kasa tipi other olur")
    func unknownBodyTypeIsOther() throws {
        let data = try Self.json(["bodyType": "roadster"])
        #expect(try VehicleMapper.vehicles(from: data).first?.bodyType == .other)
    }

    @Test("Boş ve geçersiz görsel adresi nil olur", arguments: ["", "görsel yok", "ftp://example.com/a.png"])
    func invalidImageURLIsNil(imageURL: String) throws {
        let data = try Self.json(["imageUrl": imageURL])
        #expect(try VehicleMapper.vehicles(from: data).first?.imageURL == nil)
    }

    @Test("file:// adresi varsayılan olarak reddedilir (backend yolu)")
    func fileURLRejectedByDefault() throws {
        let data = try Self.json(["imageUrl": "file:///tmp/dolphin.png"])
        #expect(try VehicleMapper.vehicles(from: data).first?.imageURL == nil)
    }

    @Test("file:// adresi yalnızca fixture izniyle kabul edilir")
    func fileURLAcceptedWhenAllowed() throws {
        let data = try Self.json(["imageUrl": "file:///tmp/dolphin.png"])
        let vehicle = try VehicleMapper.vehicles(from: data, acceptsFileImageURLs: true).first
        #expect(vehicle?.imageURL == URL(fileURLWithPath: "/tmp/dolphin.png"))
    }

    @Test(
        "file izni varken de boş, geçersiz ve başka şemalar nil olur",
        arguments: ["", "görsel yok", "ftp://example.com/a.png", "file://"]
    )
    func otherSchemesStillRejected(imageURL: String) throws {
        let data = try Self.json(["imageUrl": imageURL])
        #expect(try VehicleMapper.vehicles(from: data, acceptsFileImageURLs: true).first?.imageURL == nil)
    }

    @Test("Hatalı renk eşleme hatası verir", arguments: ["F2F2F2", "#F2F2F", "#GGGGGG", "#F2F2F2FF"])
    func invalidColorThrows(colorHex: String) {
        #expect(throws: VehicleMappingError(vehicleID: "veh_1", field: .colorHex, reason: .invalid)) {
            try VehicleMapper.vehicles(from: try Self.json(["colorHex": colorHex]))
        }
    }

    @Test("Aralık dışı batarya sağlığı eşleme hatası verir", arguments: [-1, 101])
    func invalidHealthThrows(health: Int) {
        let expected = VehicleMappingError(vehicleID: "veh_1", field: .batteryHealthPercent, reason: .invalid)
        #expect(throws: expected) {
            try VehicleMapper.vehicles(from: try Self.json(["batteryHealthPercent": health]))
        }
    }

    @Test("Eksik zorunlu alan eşleme hatası verir")
    func missingFieldThrows() {
        #expect(throws: VehicleMappingError(vehicleID: "veh_1", field: .batteryCapacityKwh, reason: .missing)) {
            try VehicleMapper.vehicles(from: try Self.json(removing: ["batteryCapacityKwh"]))
        }
    }

    @Test("Kimlik eksikse hata kimliksiz bildirilir")
    func missingIDThrows() {
        #expect(throws: VehicleMappingError(vehicleID: nil, field: .id, reason: .missing)) {
            try VehicleMapper.vehicles(from: try Self.json(removing: ["id"]))
        }
    }
}
