#if DEBUG
import Foundation
import OnsarjDomain

/// Önizleme verisi: zengin detay, kısıtlı erişim, tarifesiz/olanaksız/puansız, yükleniyor ve hata halleri.
/// Değerler örnektir.
enum PreviewStationDetails {
    enum Content {
        case rich
        case restricted
        case bare
        case loading
        case failure
    }

    static let station = Station(
        id: Station.ID("preview"),
        name: "Kepez Moda Düğün Salonu",
        network: ChargingNetwork(id: ChargingNetwork.ID("net_trugo"), name: "Trugo"),
        coordinate: GeoCoordinate(latitude: 36.94, longitude: 30.71),
        availability: .available
    )

    static func detail(_ content: Content) -> StationDetail {
        switch content {
        case .restricted: restricted
        case .bare: bare
        case .rich, .loading, .failure: rich
        }
    }

    private static let istanbul = TimeZone(identifier: "Europe/Istanbul") ?? .current

    private static var rich: StationDetail {
        StationDetail(
            station: station, address: "2571. Sokak 4/2, Kepez",
            openingHours: OpeningHours(schedule: .alwaysOpen, timeZone: istanbul), access: .public,
            lastSuccessfulChargeAt: Date().addingTimeInterval(-5 * 3_600),
            connectorGroups: [ConnectorGroup(type: .ccs2, maxPowerKw: 160, total: 4, available: 4)],
            tariffs: [
                Tariff(
                    name: "Doğrudan ödeme", paymentMethods: [.contactless, .card],
                    pricePerKwh: Decimal(string: "14.98"), pricePerMinute: nil, currencyCode: "TRY")
            ],
            amenities: [.food], rating: nil)
    }

    private static var restricted: StationDetail {
        StationDetail(
            station: station, address: "Kaleiçi Katlı Otoparkı, Muratpaşa/Antalya",
            openingHours: OpeningHours(schedule: weekly, timeZone: istanbul),
            access: .restricted(note: "Yalnızca otopark müşterilerine"),
            lastSuccessfulChargeAt: Date().addingTimeInterval(-26 * 3_600),
            connectorGroups: [
                ConnectorGroup(type: .ccs2, maxPowerKw: 60, total: 2, available: 1),
                ConnectorGroup(type: .type2, maxPowerKw: 22, total: 4, available: nil),
            ],
            tariffs: [
                Tariff(
                    name: "ZES üyeliği", paymentMethods: [.app, .rfid], pricePerKwh: Decimal(string: "11.49"),
                    pricePerMinute: nil, currencyCode: "TRY"),
                Tariff(
                    name: "Doğrudan ödeme", paymentMethods: [.contactless], pricePerKwh: Decimal(string: "13.99"),
                    pricePerMinute: Decimal(string: "0.50"), currencyCode: "TRY"),
            ],
            amenities: [.cafe, .restroom, .wifi, .parking, .shopping],
            rating: RatingSummary(average: 4.6, count: 23))
    }

    private static var bare: StationDetail {
        StationDetail(
            station: station, address: "Işıklar Caddesi No: 41, Muratpaşa/Antalya",
            openingHours: OpeningHours(schedule: weekly, timeZone: istanbul), access: .public,
            lastSuccessfulChargeAt: nil,
            connectorGroups: [ConnectorGroup(type: .type2, maxPowerKw: 22, total: 2, available: 0)],
            tariffs: [], amenities: [], rating: nil)
    }

    private static var weekly: OpeningHours.Schedule {
        let days: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        guard let opens = TimeOfDay(hour: 8, minute: 0), let closes = TimeOfDay(hour: 22, minute: 0) else {
            return .alwaysOpen
        }
        return .weekly(days.map { OpeningInterval(day: $0, opens: opens, closes: closes) })
    }
}

/// Önizleme deposu: yükleniyor halinde hiç dönmez, hata halinde hata fırlatır.
struct PreviewStationRepository: StationRepository {
    let content: PreviewStationDetails.Content

    func stations(in box: GeoBoundingBox) async throws -> [Station] { [] }

    func stationDetail(_ id: Station.ID) async throws -> StationDetail {
        switch content {
        case .loading:
            try await Task.sleep(for: .seconds(3_600))
            throw CancellationError()
        case .failure:
            throw StationRepositoryError.stationNotFound
        case .rich, .restricted, .bare:
            return PreviewStationDetails.detail(content)
        }
    }
}
#endif
