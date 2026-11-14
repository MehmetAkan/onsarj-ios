import Foundation

/// Kullanıcının girdiği batarya yüzdesinin cihazdaki deposu; her araç için ayrı.
public protocol BatteryLevelStoring: Sendable {
    /// Araç için kayıtlı yüzde; kayıt yoksa veya okunamıyorsa `nil`. Varsayılan değer vermez.
    func storedLevel(for vehicleID: Vehicle.ID) async -> StoredBatteryLevel?

    /// Araç için yüzdeyi ve kayıt anını saklar; önceki kaydın yerine geçer.
    func save(_ level: BatteryLevel, for vehicleID: Vehicle.ID, at date: Date) async
}
