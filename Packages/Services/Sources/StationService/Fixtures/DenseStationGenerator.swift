// Geçici veri (K-23): kümeleme ve performans sınaması için. Yalnızca Debug derlemesinde var.
#if DEBUG
import Foundation

/// `dense` senaryosunun istasyonlarını üretir: Antalya çevresinde 1000 kayıt. Üretim sabit tohumludur;
/// her çağrı aynı listeyi verir. Adlar ve konumlar örnektir.
enum DenseStationGenerator {
    static let count = 1000
    /// Antalya ve çevresi (Konyaaltı'ndan Aksu'ya, sahilden Döşemealtı'na).
    private static let latitudes = 36.80...37.10
    private static let longitudes = 30.45...30.95
    private static let seed: UInt64 = 0x6F6E_7361_726A

    private static let networks = [
        ChargingNetworkDTO(id: "net_trugo", name: "Trugo", logoUrl: "operator-togg"),
        ChargingNetworkDTO(id: "net_zes", name: "ZES", logoUrl: "operator-zes"),
        ChargingNetworkDTO(id: "net_esarj", name: "Eşarj", logoUrl: "operator-esarj"),
        ChargingNetworkDTO(id: "net_shell", name: "Shell Recharge", logoUrl: "operator-shell"),
    ]
    private static let availabilities = ["available", "partial", "unavailable", "unknown"]

    static func response() -> StationListDTO {
        var random = SplitMix64(seed: seed)
        let stations = (1...count)
            .map { number in
                let network = networks[Int(random.next() % UInt64(networks.count))]
                let availability = availabilities[Int(random.next() % UInt64(availabilities.count))]
                let latitude = random.unit(in: latitudes)
                let longitude = random.unit(in: longitudes)
                let suffix = String(format: "%04d", number)
                return StationDTO(
                    id: "st_dense_\(suffix)",
                    name: "\(network.name ?? "") \(suffix)",
                    network: network,
                    coordinate: CoordinateDTO(latitude: latitude, longitude: longitude),
                    availability: availability
                )
            }
        return StationListDTO(stations: stations)
    }
}

/// Sabit tohumlu, platformdan bağımsız sözde rastgele üreteç (SplitMix64). `SystemRandomNumberGenerator`
/// tohum almadığı için kullanılmaz.
private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    /// Aralıkta düzgün dağılmış değer.
    mutating func unit(in range: ClosedRange<Double>) -> Double {
        let fraction = Double(next() >> 11) / Double(UInt64(1) << 53)
        return range.lowerBound + fraction * (range.upperBound - range.lowerBound)
    }
}
#endif
