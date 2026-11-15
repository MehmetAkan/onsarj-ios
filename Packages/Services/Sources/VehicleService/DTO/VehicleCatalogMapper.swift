import Foundation
import OnsarjDomain

/// Katalog kaydı Domain modeline eşlenemedi: kaydın türü, sırası ve eksik alanı.
struct VehicleCatalogMappingError: Error, Equatable {
    enum Record: Equatable {
        case brand
        case model
        case variant
    }

    let record: Record
    let index: Int
    let field: String
}

/// Katalog DTO'larını Domain modellerine çevirir.
///
/// Kimlik, ad ve sayısal alanlar zorunludur; eksikse `VehicleCatalogMappingError`. Tanınmayan kasa tipi
/// `other`, tanınmayan konnektör atlanır. Logo ve görsel adresi yalnızca `https` ise kullanılır.
enum VehicleCatalogMapper {
    static func brands(from list: VehicleBrandListDTO) throws -> [VehicleBrand] {
        try list.brands.enumerated()
            .map { index, dto in
                let field = { (name: String) in VehicleCatalogMappingError(record: .brand, index: index, field: name) }
                guard let id = dto.id else { throw field("id") }
                guard let name = dto.name else { throw field("name") }
                guard let count = dto.modelCount else { throw field("modelCount") }
                return VehicleBrand(
                    id: VehicleBrand.ID(id), name: name, logoURL: httpsURL(dto.logoUrl), modelCount: count)
            }
    }

    static func models(from list: VehicleModelListDTO) throws -> [VehicleModel] {
        try list.models.enumerated()
            .map { index, dto in
                let field = { (name: String) in VehicleCatalogMappingError(record: .model, index: index, field: name) }
                guard let id = dto.id else { throw field("id") }
                guard let brandID = dto.brandId else { throw field("brandId") }
                guard let name = dto.name else { throw field("name") }
                return VehicleModel(
                    id: VehicleModel.ID(id),
                    brandID: VehicleBrand.ID(brandID),
                    name: name,
                    bodyType: dto.bodyType.flatMap(BodyType.init(rawValue:)) ?? .other
                )
            }
    }

    static func variants(from list: VehicleVariantListDTO) throws -> [VehicleVariant] {
        try list.variants.enumerated()
            .map { index, dto in
                let field = { (name: String) in VehicleCatalogMappingError(record: .variant, index: index, field: name)
                }
                guard let id = dto.id else { throw field("id") }
                guard let modelID = dto.modelId else { throw field("modelId") }
                guard let name = dto.name else { throw field("name") }
                guard let year = dto.modelYear else { throw field("modelYear") }
                guard let capacity = dto.batteryCapacityKwh else { throw field("batteryCapacityKwh") }
                guard let connectors = dto.connectors else { throw field("connectors") }
                guard let consumption = dto.referenceConsumptionKwhPer100Km else {
                    throw field("referenceConsumptionKwhPer100Km")
                }
                return VehicleVariant(
                    id: VehicleVariant.ID(id),
                    modelID: VehicleModel.ID(modelID),
                    name: name,
                    modelYear: year,
                    batteryCapacityKwh: capacity,
                    connectors: connectors.compactMap(ConnectorType.init(rawValue:)),
                    maxAcPowerKw: dto.maxAcPowerKw,
                    maxDcPowerKw: dto.maxDcPowerKw,
                    referenceConsumptionKwhPer100Km: consumption,
                    imageURL: httpsURL(dto.imageUrl)
                )
            }
    }

    private static func httpsURL(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string), url.scheme?.lowercased() == "https",
            let host = url.host, !host.isEmpty
        else { return nil }
        return url
    }
}
