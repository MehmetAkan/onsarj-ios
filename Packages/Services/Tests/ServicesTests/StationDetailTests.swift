import Foundation
import OnsarjDomain
import Testing

@testable import StationService

@Suite("İstasyon detayı eşlemesi ve fixture")
struct StationDetailTests {
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func repository(_ scenario: FixtureStationScenario = .default) -> FixtureStationRepository {
        FixtureStationRepository(scenario: scenario, now: { Self.now })
    }

    @Test("Fiyat dizgesi Decimal'e kayıpsız çevrilir", arguments: ["14.98", "0.1", "16.75", "1234567.891"])
    func priceIsLossless(_ string: String) throws {
        let price = try StationDetailMapper.price(string)
        #expect(price.description == string)
        #expect(try StationDetailMapper.price("0.1") + StationDetailMapper.price("0.2") == Decimal(string: "0.3"))
    }

    @Test("Geçersiz fiyat dizgesi hatadır", arguments: ["14,98", "", "abc", "-1", "1e3"])
    func invalidPrice(_ string: String) {
        #expect(throws: StationDetailMappingError(field: "price")) { try StationDetailMapper.price(string) }
    }

    @Test("Zengin detay: saatler, kısıtlı erişim, iki soket türü, iki tarife, tanınmayan olanak atlanır")
    func richDetail() async throws {
        let detail = try await repository().stationDetail(Station.ID("st_002"))
        #expect(detail.station.network.id == ChargingNetwork.ID("net_zes"))
        #expect(detail.access == .restricted(note: "Yalnızca otopark müşterilerine"))
        #expect(detail.connectorGroups.map(\.type) == [.ccs2, .type2])
        #expect(detail.availability == .unknown)
        #expect(detail.tariffs.count == 2)
        #expect(detail.tariffs[1].pricePerMinute == Decimal(string: "0.50"))
        #expect(detail.tariffs[0].paymentMethods == [.app, .rfid])
        #expect(detail.amenities == [.cafe, .restroom, .wifi, .parking, .shopping])
        #expect(detail.rating == RatingSummary(average: 4.6, count: 23))
        #expect(detail.openingHours.timeZone.identifier == "Europe/Istanbul")
        guard case .weekly(let intervals) = detail.openingHours.schedule else {
            Issue.record("Haftalık saat bekleniyordu")
            return
        }
        #expect(intervals.count == 7)
    }

    @Test("Fixture tarihi şimdiye kaydırılır: Lara Yolu'nda son şarj 5 saat önce")
    func shiftedDates() async throws {
        let detail = try await repository().stationDetail(Station.ID("st_001"))
        #expect(detail.lastSuccessfulChargeAt == Self.now.addingTimeInterval(-5 * 3_600))
        #expect(detail.openingHours.schedule == .alwaysOpen)
        #expect(detail.speed == .ultraFast)
        #expect(detail.tariffs.first?.pricePerKwh == Decimal(string: "14.98"))
    }

    @Test("Detayın müsaitliği özettekiyle aynı")
    func availabilityMatchesSummary() async throws {
        let repository = repository()
        let world = GeoBoundingBox(
            southWest: GeoCoordinate(latitude: -90, longitude: -180),
            northEast: GeoCoordinate(latitude: 90, longitude: 180))
        for station in try await repository.stations(in: world) {
            let detail = try await repository.stationDetail(station.id)
            #expect(detail.availability == station.availability, "\(station.id.rawValue)")
        }
    }

    @Test("Üretilen detay deterministik")
    func generatedIsDeterministic() async throws {
        let id = Station.ID("st_dense_0042")
        let first = try await repository(.dense).stationDetail(id)
        let second = try await repository(.dense).stationDetail(id)
        #expect(first == second)
        #expect(!first.connectorGroups.isEmpty)
    }

    @Test("Bilinmeyen istasyon hatası")
    func notFound() async {
        await #expect(throws: StationRepositoryError.stationNotFound) {
            try await repository().stationDetail(Station.ID("st_yok"))
        }
    }
}
