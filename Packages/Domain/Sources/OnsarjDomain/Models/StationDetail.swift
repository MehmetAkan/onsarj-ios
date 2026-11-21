import Foundation

/// Bir istasyonun detayı: haritadaki özetin (`Station`) üstüne adres, saatler, erişim, soketler, tarifeler,
/// olanaklar ve puan. Ayrı bir istekle gelir (`StationRepository.stationDetail(_:)`).
public struct StationDetail: Sendable, Hashable {
    public let station: Station
    public let address: String
    public let openingHours: OpeningHours
    public let access: StationAccess
    /// İstasyonda son başarılı şarjın zamanı; bilinmiyorsa `nil`.
    public let lastSuccessfulChargeAt: Date?
    public let connectorGroups: [ConnectorGroup]
    public let tariffs: [Tariff]
    public let amenities: [Amenity]
    /// Kullanıcı puanı; henüz değerlendirme yoksa `nil`.
    public let rating: RatingSummary?

    public init(
        station: Station,
        address: String,
        openingHours: OpeningHours,
        access: StationAccess,
        lastSuccessfulChargeAt: Date?,
        connectorGroups: [ConnectorGroup],
        tariffs: [Tariff],
        amenities: [Amenity],
        rating: RatingSummary?
    ) {
        self.station = station
        self.address = address
        self.openingHours = openingHours
        self.access = access
        self.lastSuccessfulChargeAt = lastSuccessfulChargeAt
        self.connectorGroups = connectorGroups
        self.tariffs = tariffs
        self.amenities = amenities
        self.rating = rating
    }

    /// Gruplardaki en yüksek güç (kW); soket yoksa `nil`.
    public var maxPowerKw: Double? { connectorGroups.map(\.maxPowerKw).max() }

    /// En yüksek güce göre hız sınıfı.
    public var speed: ChargingSpeed? { maxPowerKw.map(ChargingSpeed.init(powerKw:)) }

    /// Toplam soket sayısı.
    public var totalCount: Int { connectorGroups.reduce(0) { $0 + $1.total } }

    /// Toplam boş soket sayısı; bir grubun bile canlı verisi yoksa `nil`.
    public var availableCount: Int? {
        connectorGroups.reduce(Optional(0)) { sum, group in
            guard let sum, let available = group.available else { return nil }
            return sum + available
        }
    }

    /// Soketlere göre müsaitlik; pinlerdeki kuralla aynı.
    public var availability: StationAvailability {
        StationAvailability(available: availableCount, total: totalCount)
    }
}

/// İstasyonu kimlerin kullanabildiği.
public enum StationAccess: Sendable, Hashable {
    /// Tüm elektrikli araçlara açık.
    case `public`
    /// Kısıtlı; açıklama backend'den gelir (ör. "Yalnızca otel müşterilerine").
    case restricted(note: String)
}

/// Kullanıcı puanlarının özeti.
public struct RatingSummary: Sendable, Hashable {
    /// 1–5 arası ortalama.
    public let average: Double
    public let count: Int

    public init(average: Double, count: Int) {
        self.average = average
        self.count = count
    }
}
