import Foundation
import OnsarjDomain

/// Yükleniyor halinde iskeleti çizen örnek detay. Gösterilmez: `.redacted(reason: .placeholder)` ile yalnızca
/// biçimi görünür; metinleri kullanıcıya ulaşmaz.
enum StationDetailPlaceholder {
    static func detail(for station: Station) -> StationDetail {
        StationDetail(
            station: station,
            address: String(repeating: "0", count: 32),
            openingHours: OpeningHours(schedule: .alwaysOpen, timeZone: .current),
            access: .public,
            lastSuccessfulChargeAt: nil,
            connectorGroups: [ConnectorGroup(type: .ccs2, maxPowerKw: 150, total: 4, available: nil)],
            tariffs: [],
            amenities: [],
            rating: nil
        )
    }
}
