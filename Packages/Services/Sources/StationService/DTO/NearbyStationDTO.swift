/// Yakındaki istasyonlar yanıtı: `{"stations": [ ... ]}`.
struct NearbyStationListDTO: Codable {
    var stations: [NearbyStationDTO]
}

/// Listedeki bir istasyon: özet alanları (`StationDTO`) ve liste alanları aynı JSON nesnesindedir.
struct NearbyStationDTO: Codable {
    var summary: StationDTO
    let maxPowerKw: Double?
    let availableCount: Int?
    let totalCount: Int?
    /// Olanak dizgeleri; tanınmayan değer atlanır.
    let amenities: [String]?
    let photoUrl: String?
    let distanceKm: Double?

    private enum CodingKeys: String, CodingKey {
        case maxPowerKw, availableCount, totalCount, amenities, photoUrl, distanceKm
    }

    init(
        summary: StationDTO,
        maxPowerKw: Double?,
        availableCount: Int?,
        totalCount: Int?,
        amenities: [String]?,
        photoUrl: String?,
        distanceKm: Double?
    ) {
        self.summary = summary
        self.maxPowerKw = maxPowerKw
        self.availableCount = availableCount
        self.totalCount = totalCount
        self.amenities = amenities
        self.photoUrl = photoUrl
        self.distanceKm = distanceKm
    }

    init(from decoder: any Decoder) throws {
        summary = try StationDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maxPowerKw = try container.decodeIfPresent(Double.self, forKey: .maxPowerKw)
        availableCount = try container.decodeIfPresent(Int.self, forKey: .availableCount)
        totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
        amenities = try container.decodeIfPresent([String].self, forKey: .amenities)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        distanceKm = try container.decodeIfPresent(Double.self, forKey: .distanceKm)
    }

    func encode(to encoder: any Encoder) throws {
        try summary.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(maxPowerKw, forKey: .maxPowerKw)
        try container.encodeIfPresent(availableCount, forKey: .availableCount)
        try container.encodeIfPresent(totalCount, forKey: .totalCount)
        try container.encodeIfPresent(amenities, forKey: .amenities)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(distanceKm, forKey: .distanceKm)
    }
}
