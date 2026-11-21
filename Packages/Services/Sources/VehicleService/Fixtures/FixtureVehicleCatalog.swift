// Geçici veri (K-23, K-26): backend hazır olana kadar araç kataloğu bu dosyadan gelir; backend
// bağlanınca dosya silinir. JSON, K-23 ek notu gereği kaynak dosyası değil dizge sabitidir.
//
// DEĞERLER ÖRNEKTİR: marka, model ve varyantların kapasite, güç ve tüketim değerleri arayüzü denemek
// içindir; teknik doğruluk iddiası yoktur. Logolar backend'den gelecek (`logoUrl: null`).
#if DEBUG
import Foundation
import OnsarjDomain

/// Araç kataloğunu gömülü JSON'dan veren fixture. Her çağrı, ilgili uç noktanın yanıtını
/// (`VehicleBrandListDTO`, `VehicleModelListDTO`, `VehicleVariantListDTO`) bellekteki tablodan kurar ve
/// gerçek yanıtla aynı eşlemeden (`VehicleCatalogMapper`) geçirir. Markalar ada göre sıralıdır.
public struct FixtureVehicleCatalog: VehicleCatalog {
    public init() {}

    public func brands() async throws -> [VehicleBrand] {
        let brands = try Self.tables().brands
            .sorted {
                ($0.name ?? "").compare($1.name ?? "", options: .caseInsensitive, locale: Locale(identifier: "tr_TR"))
                    == .orderedAscending
            }
        return try VehicleCatalogMapper.brands(from: VehicleBrandListDTO(brands: brands))
    }

    public func models(of brandID: VehicleBrand.ID) async throws -> [VehicleModel] {
        let models = try Self.tables().models.filter { $0.brandId == brandID.rawValue }
        return try VehicleCatalogMapper.models(from: VehicleModelListDTO(models: models))
    }

    public func variants(of modelID: VehicleModel.ID) async throws -> [VehicleVariant] {
        let variants = try Self.tables().variants.filter { $0.modelId == modelID.rawValue }
        return try VehicleCatalogMapper.variants(from: VehicleVariantListDTO(variants: variants))
    }

    /// Katalog tabloları; araç deposu fixture'ı da yeni aracı bunlardan oluşturur.
    static func tables() throws -> Tables {
        try JSONDecoder().decode(Tables.self, from: Data(fixtureVehicleCatalogJSON.utf8))
    }

    /// Üç uç noktanın kayıtları; her dizi ilgili yanıttaki biçimdedir.
    struct Tables: Decodable {
        let brands: [VehicleBrandDTO]
        let models: [VehicleModelDTO]
        let variants: [VehicleVariantDTO]
    }
}
#endif
