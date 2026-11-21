import Foundation
import OnsarjDomain

/// Yakındaki istasyonlar isteği: `GET /stations/nearby` ve sorgu parametreleri.
///
/// Varsayılan değerindeki süzgeç (boş küme, `nil`, `false`) parametre üretmez; backend yokluğu "hepsi" sayar.
/// Kümeler virgülle ayrılır ve sıralanır, böylece aynı sorgu her zaman aynı adresi üretir (önbellek anahtarı).
enum NearbyStationsRequest {
    static let path = "/stations/nearby"

    static func queryItems(for query: StationQuery) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "lat", value: number(query.origin.latitude)),
            URLQueryItem(name: "lon", value: number(query.origin.longitude)),
            URLQueryItem(name: "radiusKm", value: number(query.radiusKm)),
            URLQueryItem(name: "limit", value: String(query.limit)),
            URLQueryItem(name: "sort", value: query.sort.rawValue),
        ]
        if let speed = query.minimumSpeed {
            items.append(URLQueryItem(name: "minSpeed", value: speedValue(speed)))
        }
        if let stalls = query.minimumStalls {
            items.append(URLQueryItem(name: "minStalls", value: String(stalls)))
        }
        if !query.networkIDs.isEmpty {
            items.append(
                URLQueryItem(name: "networks", value: query.networkIDs.map(\.rawValue).sorted().joined(separator: ",")))
        }
        if query.onlyAvailable {
            items.append(URLQueryItem(name: "onlyAvailable", value: "true"))
        }
        if !query.connectorTypes.isEmpty {
            items.append(
                URLQueryItem(
                    name: "connectors", value: query.connectorTypes.map(\.rawValue).sorted().joined(separator: ",")))
        }
        return items
    }

    /// Hız sınıfının sözleşmedeki adı.
    static func speedValue(_ speed: ChargingSpeed) -> String {
        switch speed {
        case .normal: "normal"
        case .fast: "fast"
        case .ultraFast: "ultrafast"
        }
    }

    /// Yerelden bağımsız ondalık: nokta ayıraçlı, gereksiz sıfırsız (`36.8969`, `25`).
    private static func number(_ value: Double) -> String {
        value.formatted(
            .number.locale(Locale(identifier: "en_US_POSIX")).grouping(.never).precision(.fractionLength(0...6)))
    }
}
