/// Bir istasyondaki aynı türden ve aynı güçteki soketler.
public struct ConnectorGroup: Sendable, Hashable {
    public let type: ConnectorType
    /// Soket başına en yüksek güç (kW).
    public let maxPowerKw: Double
    /// Soket sayısı.
    public let total: Int
    /// Boş soket sayısı; canlı veri yoksa `nil`.
    public let available: Int?

    public init(type: ConnectorType, maxPowerKw: Double, total: Int, available: Int?) {
        self.type = type
        self.maxPowerKw = maxPowerKw
        self.total = total
        self.available = available
    }

    /// Haritadaki pinle aynı kural: hepsi boş → müsait, en az biri boş → kısmen, hiçbiri → müsait değil,
    /// canlı veri yok → bilinmiyor.
    public var availability: StationAvailability {
        StationAvailability(available: available, total: total)
    }

    public var speed: ChargingSpeed { ChargingSpeed(powerKw: maxPowerKw) }
}

extension StationAvailability {
    /// Boş ve toplam soket sayısından müsaitlik. `available` `nil` ise canlı veri yoktur.
    public init(available: Int?, total: Int) {
        guard let available, total > 0 else {
            self = .unknown
            return
        }
        switch available {
        case total...: self = .available
        case 1...: self = .partial
        default: self = .unavailable
        }
    }
}
