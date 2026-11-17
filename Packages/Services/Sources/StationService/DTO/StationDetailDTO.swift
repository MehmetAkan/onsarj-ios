/// İstasyon detayı yanıtı (`GET /stations/{id}`): istasyon özetinin alanları ve detay alanları aynı nesnede.
/// Alanlar isteğe bağlı çözülür; eksik zorunlu alan eşlemede (`StationDetailMapper`) yakalanır.
struct StationDetailDTO: Decodable {
    let summary: StationDTO
    let address: String?
    /// IANA saat dilimi (ör. `Europe/Istanbul`).
    let timeZone: String?
    let openingHours: OpeningHoursDTO?
    let access: AccessDTO?
    /// ISO 8601, UTC.
    let lastSuccessfulChargeAt: String?
    let connectors: [ConnectorGroupDTO]?
    let tariffs: [TariffDTO]?
    let amenities: [String]?
    let rating: RatingDTO?

    private enum CodingKeys: String, CodingKey {
        case address, timeZone, openingHours, access, lastSuccessfulChargeAt, connectors, tariffs, amenities, rating
    }

    init(from decoder: any Decoder) throws {
        summary = try StationDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        timeZone = try container.decodeIfPresent(String.self, forKey: .timeZone)
        openingHours = try container.decodeIfPresent(OpeningHoursDTO.self, forKey: .openingHours)
        access = try container.decodeIfPresent(AccessDTO.self, forKey: .access)
        lastSuccessfulChargeAt = try container.decodeIfPresent(String.self, forKey: .lastSuccessfulChargeAt)
        connectors = try container.decodeIfPresent([ConnectorGroupDTO].self, forKey: .connectors)
        tariffs = try container.decodeIfPresent([TariffDTO].self, forKey: .tariffs)
        amenities = try container.decodeIfPresent([String].self, forKey: .amenities)
        rating = try container.decodeIfPresent(RatingDTO.self, forKey: .rating)
    }
}

/// `{"alwaysOpen": true}` ya da `{"alwaysOpen": false, "weekly": [...]}`.
struct OpeningHoursDTO: Decodable {
    let alwaysOpen: Bool?
    let weekly: [OpeningIntervalDTO]?
}

/// `{"day": "mon", "opens": "08:00", "closes": "22:00"}`.
struct OpeningIntervalDTO: Decodable {
    let day: String?
    let opens: String?
    let closes: String?
}

/// `{"type": "public"}` ya da `{"type": "restricted", "note": "..."}`.
struct AccessDTO: Decodable {
    let type: String?
    let note: String?
}

struct ConnectorGroupDTO: Decodable {
    let type: String?
    let maxPowerKw: Double?
    let total: Int?
    /// Canlı veri yoksa `null`.
    let available: Int?
}

/// Fiyatlar dizgedir (`"14.98"`): kayan noktaya çevrilmeden `Decimal` olarak çözülür.
struct TariffDTO: Decodable {
    let name: String?
    let paymentMethods: [String]?
    let pricePerKwh: String?
    let pricePerMinute: String?
    let currency: String?
}

struct RatingDTO: Decodable {
    let average: Double?
    let count: Int?
}
