/// Bir istasyonun anlık müsaitliği; haritada pinin altındaki noktanın rengi.
public enum StationAvailability: String, Sendable, Hashable, CaseIterable {
    /// Tüm soketler boş.
    case available
    /// En az bir soket dolu, en az biri boş.
    case partial
    /// Tüm soketler dolu veya arızalı.
    case unavailable
    /// Canlı veri yok.
    case unknown
}
