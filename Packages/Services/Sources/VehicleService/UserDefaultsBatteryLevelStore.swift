import Foundation
import OnsarjDomain

/// Batarya yüzdesini `UserDefaults`'ta, her araç için ayrı anahtarda saklar.
///
/// Anahtar `onsarj.batteryLevel.<araç kimliği>`, değer JSON olarak kodlanmış yüzde ve kayıt
/// anıdır. Kayıt yoksa veya çözülemiyorsa `nil` döner; varsayılan değer vermez.
///
/// **Eşzamanlılık:** `UserDefaults` SDK'da `Sendable` değildir; `Sendable` bir depo onu
/// saklayamaz. Depo yalnızca suite adını (`String?`) tutar ve her çağrıda `UserDefaults`'u
/// o adla açar. Apple'ın belgelerine göre `UserDefaults` iş parçacığı güvenlidir ve aynı ada
/// açılan örnekler aynı önbelleği paylaşır; bu yüzden ek maliyet küçüktür. `@unchecked Sendable`
/// ile derleyicinin denetimi kapatılmaz.
public struct UserDefaultsBatteryLevelStore: BatteryLevelStoring {
    private static let keyPrefix = "onsarj.batteryLevel."

    private let suiteName: String?

    /// - Parameter suiteName: `UserDefaults` suite'i; `nil` uygulamanın standart deposudur.
    ///   Testler kendi suite'ini verir.
    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    public func storedLevel(for vehicleID: Vehicle.ID) async -> StoredBatteryLevel? {
        guard let data = defaults()?.data(forKey: Self.key(for: vehicleID)),
            let record = try? JSONDecoder().decode(Record.self, from: data)
        else {
            return nil
        }
        return StoredBatteryLevel(level: BatteryLevel(percent: record.percent), recordedAt: record.recordedAt)
    }

    public func save(_ level: BatteryLevel, for vehicleID: Vehicle.ID, at date: Date) async {
        let record = Record(percent: level.percent, recordedAt: date)
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults()?.set(data, forKey: Self.key(for: vehicleID))
    }

    /// Suite adı geçersizse (uygulamanın paket kimliği gibi) `nil`; depo o zaman boş davranır.
    private func defaults() -> UserDefaults? {
        guard let suiteName else { return .standard }
        return UserDefaults(suiteName: suiteName)
    }

    static func key(for vehicleID: Vehicle.ID) -> String {
        keyPrefix + vehicleID.rawValue
    }

    /// Diskteki kayıt biçimi.
    private struct Record: Codable {
        let percent: Int
        let recordedAt: Date
    }
}
