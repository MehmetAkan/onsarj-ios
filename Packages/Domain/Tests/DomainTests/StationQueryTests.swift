import Foundation
import Testing

@testable import OnsarjDomain

@Suite("Yakındaki istasyonlar sorgusu")
struct StationQueryTests {
    private static let origin = GeoCoordinate(latitude: 36.8969, longitude: 30.7133)

    @Test("Haversine: İstanbul–Ankara ~349 km (bağımsız hesap), ekvatorda 1° ≈ 111,195 km, aynı nokta 0")
    func haversine() {
        let istanbul = GeoCoordinate(latitude: 41.0082, longitude: 28.9784)
        let ankara = GeoCoordinate(latitude: 39.9334, longitude: 32.8597)
        #expect(abs(GeoDistance.kilometers(from: istanbul, to: ankara) - 349.36) < 0.01)
        #expect(GeoDistance.kilometers(from: istanbul, to: istanbul) == 0)
        let oneDegree = GeoDistance.kilometers(
            from: GeoCoordinate(latitude: 0, longitude: 0), to: GeoCoordinate(latitude: 0, longitude: 1))
        #expect(abs(oneDegree - 111.195) < 0.01)
    }

    @Test("Mesafe sıralaması; eşitlikte kimlik")
    func sortByDistance() {
        let items = [Self.item("c", distance: 3), Self.item("b", distance: 1), Self.item("a", distance: 1)]
        #expect(StationQuery(origin: Self.origin).arranged(items).map(\.id.rawValue) == ["a", "b", "c"])
    }

    @Test("Güç sıralaması yüksekten; eşitlikte mesafe")
    func sortByPower() {
        let items = [
            Self.item("a", power: 50, distance: 1), Self.item("b", power: 160, distance: 5),
            Self.item("c", power: 160, distance: 2),
        ]
        let query = StationQuery(origin: Self.origin, sort: .power)
        #expect(query.arranged(items).map(\.id.rawValue) == ["c", "b", "a"])
    }

    @Test("Müsaitlik sıralaması: boş soketi olanlar önce; eşitlikte mesafe")
    func sortByAvailability() {
        let items = [
            Self.item("full", available: 0, distance: 1), Self.item("unknown", available: nil, distance: 0.5),
            Self.item("far", available: 1, distance: 9), Self.item("near", available: 2, distance: 3),
        ]
        let query = StationQuery(origin: Self.origin, sort: .availability)
        #expect(query.arranged(items).map(\.id.rawValue) == ["near", "far", "unknown", "full"])
    }

    @Test("Limit sonuç sayısını sınırlar")
    func limit() {
        let items = (0..<10).map { Self.item("s\($0)", distance: Double($0)) }
        #expect(StationQuery(origin: Self.origin, limit: 3).arranged(items).map(\.id.rawValue) == ["s0", "s1", "s2"])
    }

    @Test("Her süzgeç tek başına")
    func eachFilter() {
        let fast = Self.detail(network: "net_a", groups: [.init(type: .ccs2, maxPowerKw: 60, total: 2, available: 0)])
        var query = StationQuery(origin: Self.origin)
        #expect(query.matches(fast, distanceKm: 1))
        #expect(!query.matches(fast, distanceKm: 26), "Yarıçap dışında")

        query.minimumSpeed = .fast
        #expect(query.matches(fast, distanceKm: 1))
        query.minimumSpeed = .ultraFast
        #expect(!query.matches(fast, distanceKm: 1))
        query.minimumSpeed = nil

        query.minimumStalls = 2
        #expect(query.matches(fast, distanceKm: 1))
        query.minimumStalls = 4
        #expect(!query.matches(fast, distanceKm: 1))
        query.minimumStalls = nil

        query.networkIDs = [ChargingNetwork.ID("net_b")]
        #expect(!query.matches(fast, distanceKm: 1))
        query.networkIDs = [ChargingNetwork.ID("net_a"), ChargingNetwork.ID("net_b")]
        #expect(query.matches(fast, distanceKm: 1))
        query.networkIDs = []

        query.onlyAvailable = true
        #expect(!query.matches(fast, distanceKm: 1))
        query.onlyAvailable = false

        query.connectorTypes = [.type2]
        #expect(!query.matches(fast, distanceKm: 1))
        query.connectorTypes = [.type2, .ccs2]
        #expect(query.matches(fast, distanceKm: 1))
    }

    @Test("Süzgeçlerin birleşimi; canlı verisi olmayan istasyon 'yalnızca müsait'ten geçmez")
    func combinedFilters() {
        let mixed = Self.detail(
            network: "net_a",
            groups: [
                .init(type: .ccs2, maxPowerKw: 180, total: 4, available: 1),
                .init(type: .type2, maxPowerKw: 22, total: 2, available: 0),
            ])
        let unknown = Self.detail(
            network: "net_a", groups: [.init(type: .ccs2, maxPowerKw: 180, total: 4, available: nil)])
        let query = StationQuery(
            origin: Self.origin, minimumSpeed: .ultraFast, minimumStalls: 6, networkIDs: [ChargingNetwork.ID("net_a")],
            onlyAvailable: true, connectorTypes: [.type2])
        #expect(query.matches(mixed, distanceKm: 10))
        #expect(!query.matches(unknown, distanceKm: 10))
    }

    @Test("Liste öğesi detayla aynı güç, sayılar ve olanaklar; soketsiz istasyon listelenmez")
    func itemFromDetail() throws {
        let detail = Self.detail(
            network: "net_a",
            groups: [
                .init(type: .ccs2, maxPowerKw: 120, total: 2, available: 1),
                .init(type: .type2, maxPowerKw: 22, total: 2, available: 2),
            ])
        let item = try #require(StationListItem(detail: detail, photoURL: nil, distanceKm: 1.2))
        #expect(item.maxPowerKw == 120)
        #expect(item.speed == .fast)
        #expect(item.availableCount == 3)
        #expect(item.totalCount == 4)
        #expect(item.availability == .partial)
        #expect(item.amenities == [.cafe])
        #expect(StationListItem(detail: Self.detail(network: "n", groups: []), photoURL: nil, distanceKm: 1) == nil)
    }

    private static func item(
        _ id: String, power: Double = 50, available: Int? = 1, distance: Double?
    ) -> StationListItem {
        StationListItem(
            station: Station(
                id: Station.ID(id), name: id, network: ChargingNetwork(id: ChargingNetwork.ID("n"), name: "N"),
                coordinate: origin, availability: .unknown),
            maxPowerKw: power, availableCount: available, totalCount: 2, amenities: [], photoURL: nil,
            distanceKm: distance)
    }

    private static func detail(network: String, groups: [ConnectorGroup]) -> StationDetail {
        StationDetail(
            station: Station(
                id: Station.ID("st"), name: "S", network: ChargingNetwork(id: ChargingNetwork.ID(network), name: "N"),
                coordinate: origin, availability: .unknown),
            address: "A", openingHours: OpeningHours(schedule: .alwaysOpen, timeZone: .gmt), access: .public,
            lastSuccessfulChargeAt: nil, connectorGroups: groups, tariffs: [], amenities: [.cafe], rating: nil)
    }
}
