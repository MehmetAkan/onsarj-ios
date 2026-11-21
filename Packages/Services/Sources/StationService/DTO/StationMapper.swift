import Foundation
import OnsarjDomain

/// İstasyon DTO'sunu Domain modeline eşler.
enum StationMapper {
    /// Tek bir kayıt eşlenemezse tüm yanıt geçersiz sayılır.
    static func stations(from list: StationListDTO, acceptsFileLogoURLs: Bool = false) throws -> [Station] {
        try list.stations.enumerated()
            .map { index, dto in
                try station(from: dto, at: index, acceptsFileLogoURLs: acceptsFileLogoURLs)
            }
    }

    static func station(from dto: StationDTO, at index: Int, acceptsFileLogoURLs: Bool) throws -> Station {
        let error = { (field: String, reason: StationMappingError.Reason) in
            StationMappingError(index: index, field: field, reason: reason)
        }
        guard let id = nonEmpty(dto.id) else { throw error("id", .missing) }
        guard let name = nonEmpty(dto.name) else { throw error("name", .missing) }
        guard let networkDTO = dto.network else { throw error("network", .missing) }
        guard let latitude = dto.coordinate?.latitude, let longitude = dto.coordinate?.longitude else {
            throw error("coordinate", .missing)
        }
        let coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        guard coordinate.isValid else { throw error("coordinate", .outOfRange) }
        let network: ChargingNetwork
        do {
            network = try ChargingNetworkMapper.network(
                from: networkDTO, at: index, acceptsFileLogoURLs: acceptsFileLogoURLs)
        } catch {
            throw StationMappingError(index: index, field: "network", reason: .missing)
        }
        return Station(
            id: Station.ID(id),
            name: name,
            network: network,
            coordinate: coordinate,
            availability: availability(from: dto.availability)
        )
    }

    /// Tanınmayan veya eksik değer `unknown` olur: backend yeni bir değer eklediğinde istemci hata vermez.
    static func availability(from value: String?) -> StationAvailability {
        value.flatMap(StationAvailability.init(rawValue:)) ?? .unknown
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

/// İstasyon eşleme hatası: hangi kaydın hangi alanında ne sorun olduğunu söyler.
struct StationMappingError: Error, Equatable {
    enum Reason: Equatable {
        case missing
        case outOfRange
    }

    let index: Int
    let field: String
    let reason: Reason
}
