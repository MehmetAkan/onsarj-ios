import Foundation
import OnsarjDomain

/// İstasyon detayı DTO'sunu Domain modeline eşler.
///
/// Zorunlu alanlar: özet alanları (`StationMapper`), `address`, `timeZone`, `openingHours`, `access`,
/// `connectors`. Tanınmayan olanak ve ödeme yöntemi atlanır; tanınmayan konnektör türündeki grup atlanır.
/// Fiyat dizgesi geçersizse eşleme hatasıdır (yanlış fiyat göstermektense hiç göstermemek).
enum StationDetailMapper {
    static func detail(from dto: StationDetailDTO, acceptsFileLogoURLs: Bool = false) throws -> StationDetail {
        let station = try StationMapper.station(from: dto.summary, at: 0, acceptsFileLogoURLs: acceptsFileLogoURLs)
        guard let address = nonEmpty(dto.address) else { throw error("address") }
        guard let zone = dto.timeZone.flatMap(TimeZone.init(identifier:)) else { throw error("timeZone") }
        guard let hours = dto.openingHours else { throw error("openingHours") }
        guard let connectors = dto.connectors else { throw error("connectors") }
        return StationDetail(
            station: station,
            address: address,
            openingHours: OpeningHours(schedule: try schedule(from: hours), timeZone: zone),
            access: try access(from: dto.access),
            lastSuccessfulChargeAt: try dto.lastSuccessfulChargeAt.map(date),
            connectorGroups: try connectors.map(connectorGroup).compactMap { $0 },
            tariffs: try (dto.tariffs ?? []).map(tariff),
            amenities: (dto.amenities ?? []).compactMap(Amenity.init(rawValue:)),
            rating: dto.rating.flatMap(rating)
        )
    }

    /// `"14.98"` → `Decimal(1498, exponent: -2)`, kayıpsız. Yalnızca nokta ondalık ayıracı kabul edilir.
    static func price(_ string: String) throws -> Decimal {
        let pattern = /^\d+(\.\d+)?$/
        guard string.wholeMatch(of: pattern) != nil,
            let value = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))
        else { throw error("price") }
        return value
    }

    private static func schedule(from dto: OpeningHoursDTO) throws -> OpeningHours.Schedule {
        if dto.alwaysOpen == true { return .alwaysOpen }
        guard let weekly = dto.weekly else { throw error("openingHours") }
        return .weekly(try weekly.map(interval))
    }

    private static func interval(from dto: OpeningIntervalDTO) throws -> OpeningInterval {
        guard let day = dto.day.flatMap(Weekday.init(rawValue:)),
            let opens = dto.opens.flatMap(time), let closes = dto.closes.flatMap(time)
        else { throw error("openingHours") }
        return OpeningInterval(day: day, opens: opens, closes: closes)
    }

    /// `"HH:mm"`; `"24:00"` günün sonudur.
    private static func time(_ string: String) -> TimeOfDay? {
        let parts = string.split(separator: ":")
        guard parts.count == 2, parts.allSatisfy({ $0.count == 2 }), let hour = Int(parts[0]),
            let minute = Int(parts[1])
        else { return nil }
        return TimeOfDay(hour: hour, minute: minute)
    }

    private static func access(from dto: AccessDTO?) throws -> StationAccess {
        switch dto?.type {
        case "public": return .public
        case "restricted":
            guard let note = nonEmpty(dto?.note) else { throw error("access") }
            return .restricted(note: note)
        default: throw error("access")
        }
    }

    private static func date(_ string: String) throws -> Date {
        guard let date = try? Date(string, strategy: .iso8601) else { throw error("lastSuccessfulChargeAt") }
        return date
    }

    private static func connectorGroup(from dto: ConnectorGroupDTO) throws -> ConnectorGroup? {
        guard let power = dto.maxPowerKw, power > 0, let total = dto.total, total > 0 else {
            throw error("connectors")
        }
        if let available = dto.available, !(0...total).contains(available) { throw error("connectors") }
        guard let type = dto.type.flatMap(ConnectorType.init(rawValue:)) else { return nil }
        return ConnectorGroup(type: type, maxPowerKw: power, total: total, available: dto.available)
    }

    private static func tariff(from dto: TariffDTO) throws -> Tariff {
        guard let name = nonEmpty(dto.name), let currency = nonEmpty(dto.currency), currency.count == 3 else {
            throw error("tariffs")
        }
        return Tariff(
            name: name,
            paymentMethods: (dto.paymentMethods ?? []).compactMap(PaymentMethod.init(rawValue:)),
            pricePerKwh: try dto.pricePerKwh.map(price),
            pricePerMinute: try dto.pricePerMinute.map(price),
            currencyCode: currency
        )
    }

    private static func rating(from dto: RatingDTO) -> RatingSummary? {
        guard let average = dto.average, (1...5).contains(average), let count = dto.count, count > 0 else {
            return nil
        }
        return RatingSummary(average: average, count: count)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func error(_ field: String) -> StationDetailMappingError {
        StationDetailMappingError(field: field)
    }
}

/// Detay eşleme hatası: hangi alanın eksik veya geçersiz olduğunu söyler.
struct StationDetailMappingError: Error, Equatable {
    let field: String
}
