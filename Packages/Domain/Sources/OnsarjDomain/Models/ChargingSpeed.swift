/// Şarj hızı sınıfı: bir soketin veya istasyonun en yüksek gücüne göre. Ekranda 1–3 şimşekle gösterilir.
///
/// Eşikler yalnızca burada tanımlıdır; ekranlar sınıfı hesaplamaz, buradan alır.
public enum ChargingSpeed: Int, Sendable, Hashable, CaseIterable, Comparable {
    /// 50 kW'tan düşük (çoğunlukla AC).
    case normal = 1
    /// 50 kW ve üstü, 150 kW'tan düşük.
    case fast = 2
    /// 150 kW ve üstü.
    case ultraFast = 3

    /// Hızlı şarjın başladığı güç (kW).
    public static let fastThresholdKw: Double = 50
    /// Çok hızlı şarjın başladığı güç (kW).
    public static let ultraFastThresholdKw: Double = 150

    public init(powerKw: Double) {
        switch powerKw {
        case Self.ultraFastThresholdKw...: self = .ultraFast
        case Self.fastThresholdKw...: self = .fast
        default: self = .normal
        }
    }

    /// Gösterilen şimşek sayısı.
    public var boltCount: Int { rawValue }

    public static func < (lhs: ChargingSpeed, rhs: ChargingSpeed) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
