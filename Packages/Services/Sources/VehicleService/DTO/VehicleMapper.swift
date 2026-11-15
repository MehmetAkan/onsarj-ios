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
/// - Sürüş profilleri: liste yoksa, boşsa, bir profilin alanı eksikse veya standart profil sayısı
///   birden farklıysa hata. `activeProfileId` yoksa veya bilinmiyorsa standart profil etkindir.
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
        let colorHex = try validated(dto.colorHex, .colorHex, in: dto, where: VehiclePaint.isValidHex)
        let health = try validated(
            dto.batteryHealthPercent, .batteryHealthPercent, in: dto, where: healthRange.contains)
        let bodyType = try required(dto.bodyType, .bodyType, in: dto)
        let connectors = try required(dto.connectors, .connectors, in: dto)
        let profiles = try drivingProfiles(in: dto)

        return Vehicle(
            id: Vehicle.ID(id),
            make: try required(dto.make, .make, in: dto),
            model: try required(dto.model, .model, in: dto),
            variant: dto.variant,
            modelYear: try required(dto.modelYear, .modelYear, in: dto),
            nickname: dto.nickname,
            batteryCapacityKwh: try required(dto.batteryCapacityKwh, .batteryCapacityKwh, in: dto),
            connectors: connectors.compactMap(ConnectorType.init(rawValue:)),
            maxAcPowerKw: dto.maxAcPowerKw,
            maxDcPowerKw: dto.maxDcPowerKw,
            colorHex: colorHex,
            bodyType: BodyType(rawValue: bodyType) ?? .other,
            imageURL: imageURL(from: dto.imageUrl, acceptsFile: acceptsFileImageURLs),
            batteryHealthPercent: health,
            isDefault: try required(dto.isDefault, .isDefault, in: dto),
            drivingProfiles: profiles,
            // Eksik veya bilinmeyen kimlikte `Vehicle` standart profili etkin yapar.
            activeProfileID: DrivingProfile.ID(dto.activeProfileId ?? "")
        )
    }

    private static func drivingProfiles(in dto: VehicleDTO) throws -> [DrivingProfile] {
        let list = try required(dto.drivingProfiles, .drivingProfiles, in: dto)
        let invalid = VehicleMappingError(vehicleID: dto.id, field: .drivingProfiles, reason: .invalid)
        let profiles = try list.map { profile in
            guard let id = profile.id, let name = profile.name, let consumption = profile.consumptionKwhPer100Km,
                let speed = profile.maxSpeedKmh, let isStandard = profile.isStandard
            else { throw invalid }
            return DrivingProfile(
                id: DrivingProfile.ID(id),
                name: name,
                consumptionKwhPer100Km: consumption,
                maxSpeedKmh: speed,
                isStandard: isStandard
            )
        }
        guard profiles.filter(\.isStandard).count == 1 else { throw invalid }
        return profiles
    }

    /// Zorunlu ve koşulu sağlaması gereken alan; koşul sağlanmazsa `invalid` hatası.
    private static func validated<Value>(
        _ value: Value?,
        _ field: VehicleDTO.CodingKeys,
        in dto: VehicleDTO,
        where isValid: (Value) -> Bool
    ) throws -> Value {
        let value = try required(value, field, in: dto)
        guard isValid(value) else {
            throw VehicleMappingError(vehicleID: dto.id, field: field, reason: .invalid)
        }
        return value
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
