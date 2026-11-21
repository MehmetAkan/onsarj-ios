import Foundation
import OnsarjDomain
import Testing

@testable import StationService

@Suite("Yakındaki istasyonlar: istek, eşleme ve fixture")
struct NearbyStationsTests {
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)
    /// Antalya, Muratpaşa; fixture istasyonlarının ortası.
    private static let origin = GeoCoordinate(latitude: 36.8849, longitude: 30.7046)

    private func repository() -> FixtureStationRepository {
        FixtureStationRepository(scenario: .default, now: { Self.now })
    }

    @Test("Varsayılan sorgu yalnızca merkez, yarıçap, limit ve sıralama üretir")
    func defaultQueryItems() {
        let items = NearbyStationsRequest.queryItems(for: StationQuery(origin: Self.origin))
        #expect(
            items.map { "\($0.name)=\($0.value ?? "")" }
                == ["lat=36.8849", "lon=30.7046", "radiusKm=25", "limit=50", "sort=distance"])
        #expect(NearbyStationsRequest.path == "/stations/nearby")
    }

    @Test("Tüm süzgeçler parametreye dönüşür; kümeler sıralı ve virgülle ayrılır")
    func fullQueryItems() {
        let query = StationQuery(
            origin: Self.origin, radiusKm: 12.5, limit: 20, sort: .availability, minimumSpeed: .ultraFast,
            minimumStalls: 4, networkIDs: [ChargingNetwork.ID("net_zes"), ChargingNetwork.ID("net_trugo")],
            onlyAvailable: true, connectorTypes: [.type2, .ccs2])
        let values = Dictionary(
            uniqueKeysWithValues: NearbyStationsRequest.queryItems(for: query).map { ($0.name, $0.value ?? "") })
        #expect(values["radiusKm"] == "12.5")
        #expect(values["sort"] == "availability")
        #expect(values["minSpeed"] == "ultrafast")
        #expect(values["minStalls"] == "4")
        #expect(values["networks"] == "net_trugo,net_zes")
        #expect(values["onlyAvailable"] == "true")
        #expect(values["connectors"] == "ccs2,type2")
    }

    @Test("Ondalık parametre yerelden bağımsız: nokta ayıraç, binlik ayıraç yok")
    func numberFormatting() {
        let query = StationQuery(origin: GeoCoordinate(latitude: -33.123456, longitude: 151.2), radiusKm: 1500)
        let values = Dictionary(
            uniqueKeysWithValues: NearbyStationsRequest.queryItems(for: query).map { ($0.name, $0.value ?? "") })
        #expect(values["lat"] == "-33.123456")
        #expect(values["radiusKm"] == "1500")
    }

    @Test("Fixture yakından uzağa sıralar, yarıçapı ve limiti uygular")
    func fixtureSortsAndLimits() async throws {
        let all = try await repository().nearbyStations(StationQuery(origin: Self.origin))
        #expect(!all.isEmpty)
        #expect(all.first?.station.id == Station.ID("st_002"), "Merkez st_002'nin konumu")
        let distances = all.compactMap(\.distanceKm)
        #expect(distances.count == all.count)
        #expect(distances == distances.sorted())
        #expect(distances.allSatisfy { $0 <= StationQuery.defaultRadiusKm })
        #expect(all.allSatisfy { $0.photoURL == nil })

        let limited = try await repository().nearbyStations(StationQuery(origin: Self.origin, limit: 3))
        #expect(limited.map(\.id) == Array(all.prefix(3)).map(\.id))
        let narrow = try await repository().nearbyStations(StationQuery(origin: Self.origin, radiusKm: 1))
        #expect(narrow.allSatisfy { ($0.distanceKm ?? .infinity) <= 1 })
        #expect(narrow.count < all.count)
    }

    @Test("Fixture backend gibi süzer: hız, soket, ağ, müsaitlik, konnektör")
    func fixtureFilters() async throws {
        let repository = repository()
        let ultra = try await repository.nearbyStations(StationQuery(origin: Self.origin, minimumSpeed: .ultraFast))
        #expect(!ultra.isEmpty)
        #expect(ultra.allSatisfy { $0.speed == .ultraFast })

        let stalls = try await repository.nearbyStations(StationQuery(origin: Self.origin, minimumStalls: 4))
        #expect(stalls.allSatisfy { $0.totalCount >= 4 })

        let zes = ChargingNetwork.ID("net_zes")
        let networks = try await repository.nearbyStations(StationQuery(origin: Self.origin, networkIDs: [zes]))
        #expect(!networks.isEmpty)
        #expect(networks.allSatisfy { $0.station.network.id == zes })

        let available = try await repository.nearbyStations(StationQuery(origin: Self.origin, onlyAvailable: true))
        #expect(!available.isEmpty)
        #expect(available.allSatisfy { ($0.availableCount ?? 0) > 0 })

        let chademo = try await repository.nearbyStations(StationQuery(origin: Self.origin, connectorTypes: [.chademo]))
        for item in chademo {
            let detail = try await repository.stationDetail(item.id)
            #expect(detail.connectorGroups.contains { $0.type == .chademo })
        }
        let all = try await repository.nearbyStations(StationQuery(origin: Self.origin))
        #expect(chademo.count < all.count)
    }

    @Test("Liste öğesi detayla tutarlı: güç, soket sayıları, olanaklar ve özet")
    func listMatchesDetail() async throws {
        let repository = repository()
        let items = try await repository.nearbyStations(StationQuery(origin: Self.origin))
        for item in items {
            let detail = try await repository.stationDetail(item.id)
            #expect(item.station == detail.station)
            #expect(item.maxPowerKw == detail.maxPowerKw)
            #expect(item.totalCount == detail.totalCount)
            #expect(item.availableCount == detail.availableCount)
            #expect(item.amenities == detail.amenities)
            #expect(item.availability == detail.availability)
        }
    }

    @Test("Eşleme: geçersiz sayılar hatadır; https olmayan fotoğraf ve tanınmayan olanak atlanır")
    func mapping() throws {
        func decode(_ fields: String) throws -> [StationListItem] {
            let json = """
                {"stations": [{"id": "st_x", "name": "X", "availability": "partial",
                  "network": {"id": "net_x", "name": "X", "logoUrl": null},
                  "coordinate": {"latitude": 36.9, "longitude": 30.7}, \(fields)}]}
                """
            return try NearbyStationMapper.items(
                from: JSONDecoder().decode(NearbyStationListDTO.self, from: Data(json.utf8)))
        }
        let valid = try decode(
            #""maxPowerKw": 160, "availableCount": 1, "totalCount": 2, "amenities": ["cafe", "spa"], "#
                + #""photoUrl": "https://cdn.example.com/st_x.jpg", "distanceKm": 1.25"#)
        #expect(valid.first?.amenities == [.cafe])
        #expect(valid.first?.photoURL?.absoluteString == "https://cdn.example.com/st_x.jpg")
        #expect(valid.first?.distanceKm == 1.25)

        let insecure = try decode(#""maxPowerKw": 22, "totalCount": 2, "photoUrl": "http://cdn.example.com/a.jpg""#)
        #expect(insecure.first?.photoURL == nil)
        #expect(insecure.first?.availableCount == nil)

        #expect(throws: StationMappingError(index: 0, field: "maxPowerKw", reason: .missing)) {
            try decode(#""totalCount": 2"#)
        }
        #expect(throws: StationMappingError(index: 0, field: "availableCount", reason: .outOfRange)) {
            try decode(#""maxPowerKw": 22, "availableCount": 3, "totalCount": 2"#)
        }
        #expect(throws: StationMappingError(index: 0, field: "distanceKm", reason: .outOfRange)) {
            try decode(#""maxPowerKw": 22, "totalCount": 2, "distanceKm": -1"#)
        }
    }
}
