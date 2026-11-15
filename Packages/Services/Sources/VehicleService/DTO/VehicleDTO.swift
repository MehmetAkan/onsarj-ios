import Foundation

/// Araç listesi yanıtı: `{"vehicles": [ ... ]}`.
struct VehicleListDTO: Decodable {
    var vehicles: [VehicleDTO]
}

/// Backend'in araç kaydı, JSON'daki haliyle (`Docs/Backend/vehicles.md`).
///
/// Zorunlu alanlar da isteğe bağlı çözülür: eksik alan çözümleme sırasında değil, eşlemede
/// (`VehicleMapper`) yakalanır. Böylece hata hangi aracın hangi alanında olduğunu söyler.
/// Değişebilen alanlar `var`'dır: fixture yazma isteklerini bir backend gibi bu kayda uygular.
struct VehicleDTO: Decodable {
    let id: String?
    let make: String?
    let model: String?
    let variant: String?
    let modelYear: Int?
    var nickname: String?
    let batteryCapacityKwh: Double?
    var connectors: [String]?
    let maxAcPowerKw: Double?
    let maxDcPowerKw: Double?
    var colorHex: String?
    let bodyType: String?
    /// Fixture, görsel adını eşlemeden önce yerel dosya adresine çevirir.
    var imageUrl: String?
    var batteryHealthPercent: Int?
    var isDefault: Bool?
    var drivingProfiles: [DrivingProfileDTO]?
    var activeProfileId: String?

    /// JSON alan adları; eşleme hatası hangi alanın hatalı olduğunu bunlarla bildirir.
    enum CodingKeys: String, CodingKey {
        case id
        case make
        case model
        case variant
        case modelYear
        case nickname
        case batteryCapacityKwh
        case connectors
        case maxAcPowerKw
        case maxDcPowerKw
        case colorHex
        case bodyType
        case imageUrl
        case batteryHealthPercent
        case isDefault
        case drivingProfiles
        case activeProfileId
    }
}

/// Aracın bir sürüş profili, JSON'daki haliyle.
struct DrivingProfileDTO: Decodable {
    var id: String?
    var name: String?
    var consumptionKwhPer100Km: Double?
    var maxSpeedKmh: Int?
    var isStandard: Bool?
}
