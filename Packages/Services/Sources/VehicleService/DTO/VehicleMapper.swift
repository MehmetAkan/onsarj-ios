import Foundation
import OnsarjDomain

/// Bir araç kaydı Domain modeline eşlenemedi.
struct VehicleMappingError: Error, Equatable {
    enum Reason: Equatable {
        /// Zorunlu alan yok.
        case missing
        /// Alan var ama değeri geçersiz.
        case invalid
    }

    /// Hatalı aracın kimliği; kimliğin kendisi eksikse `nil`.
    let vehicleID: String?
    /// Hatalı alanın JSON adı.
    let field: VehicleDTO.CodingKeys
    let reason: Reason
}

/// Backend'in araç kayıtlarını (`VehicleDTO`) Domain modeline (`Vehicle`) çevirir.
///
/// - Tanınmayan konektör atlanır: backend ileride yeni tür ekleyebilir.
/// - Tanınmayan kasa tipi `other` olur.
/// - Boş veya geçersiz görsel adresi `nil` olur. Yalnızca sunucusu olan `http(s)` adresleri
///   geçerlidir; `file` şeması yalnızca `acceptsFileImageURLs` ile, `#if DEBUG` fixture'ı için
///   kabul edilir. Gerçek (backend) yol bu parametreyi vermez.
/// - Zorunlu alan eksikse, renk `#RRGGBB` değilse veya batarya sağlığı 0…100 dışındaysa
///   `VehicleMappingError` fırlatılır; tek hatalı kayıt tüm listeyi düşürür.
enum VehicleMapper {
    private static let healthRange = 0...100

    /// JSON yanıtını çözer ve eşler.
    static func vehicles(from data: Data, acceptsFileImageURLs: Bool = false) throws -> [Vehicle] {
        let list = try JSONDecoder().decode(VehicleListDTO.self, from: data)
        return try vehicles(from: list, acceptsFileImageURLs: acceptsFileImageURLs)
    }

    /// Çözülmüş yanıtı eşler.
    /// - Parameter acceptsFileImageURLs: `file://` görsel adreslerini de kabul et. Yalnızca
    ///   fixture verir; backend'den gelen hatalı bir yerel adres sessizce geçerli sayılmasın diye
    ///   varsayılan `false`.
    static func vehicles(from list: VehicleListDTO, acceptsFileImageURLs: Bool) throws -> [Vehicle] {
        try list.vehicles.map { try vehicle(from: $0, acceptsFileImageURLs: acceptsFileImageURLs) }
    }

    static func vehicle(from dto: VehicleDTO, acceptsFileImageURLs: Bool) throws -> Vehicle {
        let id = try required(dto.id, .id, in: dto)
        let colorHex = try required(dto.colorHex, .colorHex, in: dto)
        guard isHexColor(colorHex) else {
            throw VehicleMappingError(vehicleID: id, field: .colorHex, reason: .invalid)
        }
        let health = try required(dto.batteryHealthPercent, .batteryHealthPercent, in: dto)
        guard healthRange.contains(health) else {
            throw VehicleMappingError(vehicleID: id, field: .batteryHealthPercent, reason: .invalid)
        }
        let bodyType = try required(dto.bodyType, .bodyType, in: dto)
        let connectors = try required(dto.connectors, .connectors, in: dto)

        return Vehicle(
            id: Vehicle.ID(id),
            make: try required(dto.make, .make, in: dto),
            model: try required(dto.model, .model, in: dto),
            variant: dto.variant,
            modelYear: try required(dto.modelYear, .modelYear, in: dto),
            nickname: dto.nickname,
            batteryCapacityKwh: try required(dto.batteryCapacityKwh, .batteryCapacityKwh, in: dto),
            rangeKm: try required(dto.rangeKm, .rangeKm, in: dto),
            consumptionWhPerKm: try required(dto.consumptionWhPerKm, .consumptionWhPerKm, in: dto),
            connectors: connectors.compactMap(ConnectorType.init(rawValue:)),
            maxAcPowerKw: dto.maxAcPowerKw,
            maxDcPowerKw: dto.maxDcPowerKw,
            colorHex: colorHex,
            bodyType: BodyType(rawValue: bodyType) ?? .other,
            imageURL: imageURL(from: dto.imageUrl, acceptsFile: acceptsFileImageURLs),
            batteryHealthPercent: health,
            isDefault: try required(dto.isDefault, .isDefault, in: dto)
        )
    }

    private static func required<Value>(
        _ value: Value?,
        _ field: VehicleDTO.CodingKeys,
        in dto: VehicleDTO
    ) throws -> Value {
        guard let value else {
            throw VehicleMappingError(vehicleID: dto.id, field: field, reason: .missing)
        }
        return value
    }

    /// `#` ve ardından altı onaltılık rakam.
    private static func isHexColor(_ value: String) -> Bool {
        let digits = value.dropFirst()
        return value.first == "#" && digits.count == 6 && digits.allSatisfy(\.isHexDigit)
    }

    /// Sunucusu olan http(s) adresleri kabul edilir; `acceptsFile` ise yolu olan `file` adresleri de.
    /// `URL(string:)` geçersiz karakterleri kodlayıp yine de adres döndürebildiği için şema, sunucu
    /// ve yol ayrıca denetlenir.
    private static func imageURL(from string: String?, acceptsFile: Bool) -> URL? {
        guard let string, let url = URL(string: string), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        switch scheme {
        case "https", "http":
            guard let host = url.host, !host.isEmpty else { return nil }
            return url
        case "file" where acceptsFile:
            return url.path.isEmpty ? nil : url
        default:
            return nil
        }
    }
}
