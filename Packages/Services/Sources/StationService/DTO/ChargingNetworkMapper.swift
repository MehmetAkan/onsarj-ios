import Foundation
import OnsarjCore
import OnsarjDomain

/// Şarj ağı DTO'sunu Domain modeline eşler.
enum ChargingNetworkMapper {
    static func networks(from list: ChargingNetworkListDTO) throws -> [ChargingNetwork] {
        try list.networks.enumerated().map { index, dto in try network(from: dto, at: index) }
    }

    /// Kimlik ve ad zorunludur; boş veya yalnızca boşluk olan değer eksik sayılır. Geçersiz logo adresi
    /// hata değildir, logo yok sayılır. `acceptsFileLogoURLs` yalnızca Debug fixture'ları içindir (K-23).
    static func network(
        from dto: ChargingNetworkDTO,
        at index: Int,
        acceptsFileLogoURLs: Bool = false
    ) throws -> ChargingNetwork {
        guard let id = dto.id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            throw ChargingNetworkMappingError.missingField(index: index, field: "id")
        }
        guard let name = dto.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            throw ChargingNetworkMappingError.missingField(index: index, field: "name")
        }
        return ChargingNetwork(
            id: ChargingNetwork.ID(id),
            name: name,
            logoURL: MediaURL.parse(dto.logoUrl, acceptsFile: acceptsFileLogoURLs)
        )
    }
}

/// Eşleme hatası: hangi kaydın hangi alanının eksik olduğunu söyler.
enum ChargingNetworkMappingError: Error, Equatable {
    case missingField(index: Int, field: String)
}
