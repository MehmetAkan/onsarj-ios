import Foundation
import OnsarjDomain
import Testing

@testable import StationService

@Suite("İstasyon eşlemesi ve fixture deposu")
struct StationRepositoryTests {
    private let antalya = GeoBoundingBox(
        southWest: GeoCoordinate(latitude: 36.7, longitude: 30.3),
        northEast: GeoCoordinate(latitude: 37.2, longitude: 31.1)
    )
    private let world = GeoBoundingBox(
        southWest: GeoCoordinate(latitude: -90, longitude: -180),
        northEast: GeoCoordinate(latitude: 90, longitude: 180)
    )

    @Test(
        "Müsaitlik dizgesi; tanınmayan veya eksik değer bilinmiyor",
        arguments: [
            ("available", StationAvailability.available), ("partial", .partial), ("unavailable", .unavailable),
            ("unknown", .unknown), ("charging", .unknown), ("AVAILABLE", .unknown),
        ])
    func availabilityMapping(value: String, expected: StationAvailability) {
        #expect(StationMapper.availability(from: value) == expected)
        #expect(StationMapper.availability(from: nil) == .unknown)
    }

    @Test("Aralık dışındaki koordinat eşleme hatasıdır", arguments: [(91.0, 30.0), (36.0, -181.0)])
    func invalidCoordinate(latitude: Double, longitude: Double) {
        let dto = StationDTO(
            id: "st_x", name: "X",
            network: ChargingNetworkDTO(id: "net_zes", name: "ZES", logoUrl: nil),
            coordinate: CoordinateDTO(latitude: latitude, longitude: longitude),
            availability: "available"
        )
        #expect(throws: StationMappingError(index: 0, field: "coordinate", reason: .outOfRange)) {
            try StationMapper.stations(from: StationListDTO(stations: [dto]))
        }
    }

    @Test("Kutu dışındaki istasyonlar dönmez")
    func boxFiltering() async throws {
        let repository = FixtureStationRepository()
        let all = try await repository.stations(in: world)
        let inAntalya = try await repository.stations(in: antalya)
        #expect(all.count == 49)
        #expect(inAntalya.count == 40)
        #expect(inAntalya.allSatisfy { antalya.contains($0.coordinate) })
        #expect(Set(all.map(\.availability)) == Set(StationAvailability.allCases))
    }

    @Test("Ağ kimlikleri şarj ağı kataloğundakilerle aynı")
    func networkIDsMatchCatalog() async throws {
        let stations = try await FixtureStationRepository().stations(in: world)
        let ids = Set(stations.map(\.network.id))
        let catalog = try await FixtureChargingNetworkCatalog().networks(withIDs: Array(ids))
        #expect(Set(catalog.map(\.id)) == ids)
    }

    @Test("Yoğun senaryo 1000 kayıt ve deterministik")
    func denseIsDeterministic() async throws {
        let first = try await FixtureStationRepository(scenario: .dense).stations(in: world)
        let second = try await FixtureStationRepository(scenario: .dense).stations(in: world)
        #expect(first.count == 1000)
        #expect(first == second)
        #expect(Set(first.map(\.id)).count == 1000)
        #expect(first.allSatisfy { antalya.contains($0.coordinate) })
    }

    @Test("Logo adı çözülürse file:// adresi, çözülmezse nil")
    func logoResolution() async throws {
        let file = URL(fileURLWithPath: "/tmp/onsarj-fixture/operator-zes.png")
        let repository = FixtureStationRepository { $0 == "operator-zes" ? file : nil }
        let stations = try await repository.stations(in: world)
        let zes = try #require(stations.first { $0.network.id == ChargingNetwork.ID("net_zes") })
        let trugo = try #require(stations.first { $0.network.id == ChargingNetwork.ID("net_trugo") })
        #expect(zes.network.logoURL == file)
        #expect(trugo.network.logoURL == nil)
    }

    @Test("Gerçek yanıtta file:// logo kabul edilmez, https kabul edilir")
    func releaseRejectsFileLogos() throws {
        let file = ChargingNetworkDTO(id: "net_zes", name: "ZES", logoUrl: "file:///tmp/zes.png")
        let https = ChargingNetworkDTO(id: "net_zes", name: "ZES", logoUrl: "https://cdn.example.com/zes.png")
        #expect(try ChargingNetworkMapper.network(from: file, at: 0).logoURL == nil)
        #expect(try ChargingNetworkMapper.network(from: https, at: 0).logoURL?.host == "cdn.example.com")
    }
}
