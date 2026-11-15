import Foundation

/// Araç listesi yanıtı: `{"vehicles": [ ... ]}`.
struct VehicleListDTO: Decodable {
    var vehicles: [VehicleDTO]
}

/// Backend'in araç kaydı, JSON'daki haliyle.
///
/// Zorunlu alanlar da isteğe bağlı çözülür: eksik alan çözümleme sırasında değil, eşlemede
/// (`VehicleMapper`) yakalanır. Böylece hata hangi aracın hangi alanında olduğunu söyler.
struct VehicleDTO: Decodable {
    let id: String?
    let make: String?
    let model: String?
    let variant: String?
    let modelYear: Int?
    let nickname: String?
    let batteryCapacityKwh: Double?
    let rangeKm: Int?
    let consumptionWhPerKm: Int?
    let connectors: [String]?
    let maxAcPowerKw: Double?
    let maxDcPowerKw: Double?
    let colorHex: String?
    let bodyType: String?
    /// Değişkendir: fixture, görsel adını eşlemeden önce yerel dosya adresine çevirir.
    var imageUrl: String?
    let batteryHealthPercent: Int?
    let isDefault: Bool?

    /// JSON alan adları; eşleme hatası hangi alanın hatalı olduğunu bunlarla bildirir.
    enum CodingKeys: String, CodingKey {
        case id
        case make
        case model
        case variant
        case modelYear
        case nickname
        case batteryCapacityKwh
        case rangeKm
        case consumptionWhPerKm
        case connectors
        case maxAcPowerKw
        case maxDcPowerKw
        case colorHex
        case bodyType
        case imageUrl
        case batteryHealthPercent
        case isDefault
    }
}
