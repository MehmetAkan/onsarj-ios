// Geçici veri (K-23, K-26): backend hazır olana kadar yakındaki istasyonlar bu dosyadan gelir; backend
// bağlanınca dosya silinir.
#if DEBUG
import Foundation
import OnsarjDomain

extension FixtureStationRepository {
    /// Backend gibi: yarıçap içindeki istasyonların detayını alır, sorgunun süzgeçlerini uygular
    /// (`StationQuery.matches`), sıralar ve sınırlar (`StationQuery.arranged`). Liste öğesinin güç, sayı ve
    /// olanakları aynı detaydan gelir; detay sayfasıyla tutarlıdır. Fotoğraf fixture'da yoktur (`null`).
    ///
    /// Sonuç gerçek yanıt gibi JSON'a yazılıp `NearbyStationListDTO` → `NearbyStationMapper` yolundan geçer.
    public func nearbyStations(_ query: StationQuery) async throws -> [StationListItem] {
        var matches: [StationListItem] = []
        for station in try all() {
            let distance = GeoDistance.kilometers(from: query.origin, to: station.coordinate)
            guard distance <= query.radiusKm else { continue }
            let detail = try await stationDetail(station.id)
            guard query.matches(detail, distanceKm: distance),
                let item = StationListItem(detail: detail, photoURL: nil, distanceKm: distance)
            else { continue }
            matches.append(item)
        }
        let response = NearbyStationListDTO(stations: try query.arranged(matches).map(dto))
        let data = try JSONEncoder().encode(response)
        return try NearbyStationMapper.items(
            from: JSONDecoder().decode(NearbyStationListDTO.self, from: data), acceptsFileLogoURLs: true)
    }

    private func dto(for item: StationListItem) throws -> NearbyStationDTO {
        guard let summary = summary(for: item.station.id) else { throw StationRepositoryError.stationNotFound }
        return NearbyStationDTO(
            summary: summary,
            maxPowerKw: item.maxPowerKw,
            availableCount: item.availableCount,
            totalCount: item.totalCount,
            amenities: item.amenities.map(\.rawValue),
            photoUrl: nil,
            distanceKm: item.distanceKm.map(Self.roundedDistance)
        )
    }

    /// Backend uzaklığı metre hassasiyetinde döner.
    private static func roundedDistance(_ kilometers: Double) -> Double {
        (kilometers * 1000).rounded() / 1000
    }
}
#endif
