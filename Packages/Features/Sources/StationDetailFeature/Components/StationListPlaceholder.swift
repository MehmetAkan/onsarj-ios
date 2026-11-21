import Foundation
import OnsarjDomain

/// Yükleniyor halinde kart iskeletini çizen örnek öğeler. Gösterilmez: `.redacted(reason: .placeholder)` ile
/// yalnızca biçimi görünür; metinleri kullanıcıya ulaşmaz.
enum StationListPlaceholder {
    /// İskelette gösterilen kart sayısı.
    static let count = 4

    static let items: [StationListItem] = (0..<count)
        .map { index in
            StationListItem(
                station: Station(
                    id: Station.ID("placeholder_\(index)"),
                    name: String(repeating: "0", count: 24),
                    network: ChargingNetwork(
                        id: ChargingNetwork.ID("placeholder"), name: String(repeating: "0", count: 8)),
                    coordinate: GeoCoordinate(latitude: 0, longitude: 0),
                    availability: .unknown),
                maxPowerKw: 150, availableCount: nil, totalCount: 4, amenities: [], photoURL: nil, distanceKm: 1)
        }
}
