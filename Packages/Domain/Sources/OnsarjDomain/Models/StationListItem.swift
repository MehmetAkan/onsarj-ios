import Foundation

/// Yakındaki istasyonlar listesinde bir satır: haritadaki özetin (`Station`) üstüne güç, soket sayıları,
/// olanaklar, fotoğraf ve sorgunun merkezine uzaklık. `StationRepository.nearbyStations(_:)` ile gelir.
public struct StationListItem: Sendable, Hashable, Identifiable {
    public let station: Station
    /// İstasyondaki en yüksek güç (kW).
    public let maxPowerKw: Double
    /// Boş soket sayısı; canlı veri yoksa `nil`.
    public let availableCount: Int?
    /// Toplam soket sayısı.
    public let totalCount: Int
    public let amenities: [Amenity]
    /// İstasyonun fotoğrafı; yoksa `nil`.
    public let photoURL: URL?
    /// Sorgunun merkezine kuş uçuşu uzaklık (km); bilinmiyorsa `nil`.
    public let distanceKm: Double?

    public init(
        station: Station,
        maxPowerKw: Double,
        availableCount: Int?,
        totalCount: Int,
        amenities: [Amenity],
        photoURL: URL?,
        distanceKm: Double?
    ) {
        self.station = station
        self.maxPowerKw = maxPowerKw
        self.availableCount = availableCount
        self.totalCount = totalCount
        self.amenities = amenities
        self.photoURL = photoURL
        self.distanceKm = distanceKm
    }

    /// Detaydan liste öğesi; güç, soket sayıları ve olanaklar detayla aynıdır. Soketi olmayan istasyon
    /// listelenmez (`nil`).
    public init?(detail: StationDetail, photoURL: URL?, distanceKm: Double?) {
        guard let maxPowerKw = detail.maxPowerKw else { return nil }
        self.init(
            station: detail.station, maxPowerKw: maxPowerKw, availableCount: detail.availableCount,
            totalCount: detail.totalCount, amenities: detail.amenities, photoURL: photoURL, distanceKm: distanceKm)
    }

    public var id: Station.ID { station.id }

    /// En yüksek güce göre hız sınıfı.
    public var speed: ChargingSpeed { ChargingSpeed(powerKw: maxPowerKw) }

    /// Soketlere göre müsaitlik; pinlerdeki ve detaydaki kuralla aynı.
    public var availability: StationAvailability {
        StationAvailability(available: availableCount, total: totalCount)
    }
}
