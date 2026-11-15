import Foundation

/// Aracın batarya doluluk yüzdesi.
///
/// Değer her zaman 0…100 aralığındadır: aralık dışı bir değer hata sayılmaz, en yakın sınıra
/// çekilir.
public struct BatteryLevel: Sendable, Equatable, Hashable {
    /// Kullanıcı henüz yüzde girmemişken arayüzün gösterdiği başlangıç değeri.
    ///
    /// Depoya yazılmaz; kayıt yalnızca kullanıcı yüzdeyi değiştirdiğinde oluşur.
    public static let initial = BatteryLevel(percent: 30)

    private static let range = 0...100

    /// `low` bandının en yüksek yüzdesi.
    private static let lowUpperBound = 20

    /// `medium` bandının en yüksek yüzdesi; üstü `high`.
    private static let mediumUpperBound = 50

    /// 0…100 aralığında yüzde.
    public let percent: Int

    /// - Parameter percent: Yüzde; 0…100 dışındaysa en yakın sınıra çekilir.
    public init(percent: Int) {
        self.percent = min(max(percent, Self.range.lowerBound), Self.range.upperBound)
    }

    /// Yüzdenin düştüğü bant. Arayüz renk kararını bu banttan verir; eşikler yalnızca burada
    /// tanımlıdır.
    public var band: BatteryLevelBand {
        switch percent {
        case ...Self.lowUpperBound: .low
        case ...Self.mediumUpperBound: .medium
        default: .high
        }
    }
}

/// Batarya yüzdesinin bandı: düşük (≤ %20), orta (%21–50), yüksek (> %50).
public enum BatteryLevelBand: Sendable, Equatable, Hashable {
    case low
    case medium
    case high
}

/// Cihazda saklanan batarya yüzdesi ve kaydedildiği an.
public struct StoredBatteryLevel: Sendable, Equatable {
    public let level: BatteryLevel
    public let recordedAt: Date

    public init(level: BatteryLevel, recordedAt: Date) {
        self.level = level
        self.recordedAt = recordedAt
    }
}
