import Foundation
import OnsarjDomain

/// Yakındaki istasyonlar DTO'sunu Domain modeline eşler.
///
/// Zorunlu alanlar: özet alanları (`StationMapper`), `maxPowerKw` (> 0), `totalCount` (≥ 0). `availableCount`
/// `null` ise canlı veri yoktur; `0...totalCount` dışındaysa hatadır. Fotoğraf adresi yalnızca `https` kabul
/// edilir, değilse yok sayılır. Tanınmayan olanak atlanır. Bir kayıt eşlenemezse tüm yanıt geçersizdir.
enum NearbyStationMapper {
    static func items(from list: NearbyStationListDTO, acceptsFileLogoURLs: Bool = false) throws -> [StationListItem] {
        try list.stations.enumerated()
            .map { index, dto in
                try item(from: dto, at: index, acceptsFileLogoURLs: acceptsFileLogoURLs)
            }
    }

    private static func item(
        from dto: NearbyStationDTO, at index: Int, acceptsFileLogoURLs: Bool
    ) throws
        -> StationListItem
    {
        let error = { (field: String, reason: StationMappingError.Reason) in
            StationMappingError(index: index, field: field, reason: reason)
        }
        let station = try StationMapper.station(from: dto.summary, at: index, acceptsFileLogoURLs: acceptsFileLogoURLs)
        guard let maxPowerKw = dto.maxPowerKw else { throw error("maxPowerKw", .missing) }
        guard maxPowerKw > 0 else { throw error("maxPowerKw", .outOfRange) }
        guard let totalCount = dto.totalCount else { throw error("totalCount", .missing) }
        guard totalCount >= 0 else { throw error("totalCount", .outOfRange) }
        if let available = dto.availableCount, !(0...totalCount).contains(available) {
            throw error("availableCount", .outOfRange)
        }
        if let distance = dto.distanceKm, distance < 0 { throw error("distanceKm", .outOfRange) }
        return StationListItem(
            station: station,
            maxPowerKw: maxPowerKw,
            availableCount: dto.availableCount,
            totalCount: totalCount,
            amenities: (dto.amenities ?? []).compactMap(Amenity.init(rawValue:)),
            photoURL: dto.photoUrl.flatMap(URL.init(string:)).flatMap { $0.scheme == "https" ? $0 : nil },
            distanceKm: dto.distanceKm
        )
    }
}
