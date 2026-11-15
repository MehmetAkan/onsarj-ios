import Foundation
import OnsarjDomain

/// Rota planlama tercihlerini `UserDefaults`'ta tek anahtarda JSON olarak saklar.
///
/// Kayıt yoksa veya çözülemiyorsa `RoutePreferences.default` döner. Kayıt biçimi enum'ları dizge
/// olarak tutar; okunurken tanınmayan kaçınma değerleri atlanır (ör. ileride eklenip sonra
/// kaldırılan bir tür), tanınmayan durak stratejisi varsayılana (`optimal`) düşer. Tercih edilen ağlar eski
/// biçimde (`{"id": …, "isStrong": …}`, güçlü tercih kaldırılmadan önce) kayıtlıysa yalnızca kimlik okunur.
///
/// **Eşzamanlılık:** `UserDefaultsBatteryLevelStore` ile aynı yaklaşım: depo yalnızca suite adını
/// tutar ve her çağrıda `UserDefaults`'u o adla açar; `@unchecked Sendable` kullanılmaz.
public struct UserDefaultsRoutePreferencesStore: RoutePreferencesStoring {
    static let key = "onsarj.routePreferences"

    private let suiteName: String?

    /// - Parameter suiteName: `UserDefaults` suite'i; `nil` uygulamanın standart deposudur.
    ///   Testler kendi suite'ini verir.
    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    public func load() async -> RoutePreferences {
        guard let data = defaults()?.data(forKey: Self.key),
            let record = try? JSONDecoder().decode(Record.self, from: data)
        else {
            return .default
        }
        return record.preferences
    }

    public func save(_ preferences: RoutePreferences) async {
        guard let data = try? JSONEncoder().encode(Record(preferences)) else { return }
        defaults()?.set(data, forKey: Self.key)
    }

    /// Suite adı geçersizse (uygulamanın paket kimliği gibi) `nil`; depo o zaman boş davranır.
    private func defaults() -> UserDefaults? {
        guard let suiteName else { return .standard }
        return UserDefaults(suiteName: suiteName)
    }
}

/// Diskteki kayıt biçimi.
private struct Record: Codable {
    /// Tercih edilen ağ kaydı. Yeni biçim düz dizgedir; eski biçimdeki nesnenin yalnızca `id`'si okunur.
    struct Preferred: Codable {
        let id: String

        init(id: String) {
            self.id = id
        }

        init(from decoder: Decoder) throws {
            if let id = try? decoder.singleValueContainer().decode(String.self) {
                self.id = id
            } else {
                id = try decoder.container(keyedBy: LegacyKeys.self).decode(String.self, forKey: .id)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(id)
        }

        private enum LegacyKeys: String, CodingKey {
            case id
        }
    }

    let chargeStops: String
    let avoid: [String]
    let preferredNetworks: [Preferred]
    let avoidedNetworks: [String]

    init(_ preferences: RoutePreferences) {
        chargeStops = Self.code(for: preferences.chargeStops)
        // Küme sırasızdır; kayıt kararlı olsun diye tanım sırasıyla yazılır.
        avoid = RouteAvoidance.allCases.filter(preferences.avoid.contains).map(Self.code(for:))
        preferredNetworks = preferences.preferredNetworks.map { Preferred(id: $0.rawValue) }
        avoidedNetworks = preferences.avoidedNetworks.map(\.rawValue)
    }

    var preferences: RoutePreferences {
        RoutePreferences(
            chargeStops: ChargeStopStrategy.allCases.first { Self.code(for: $0) == chargeStops } ?? .optimal,
            avoid: Set(avoid.compactMap { code in RouteAvoidance.allCases.first { Self.code(for: $0) == code } }),
            preferredNetworks: preferredNetworks.map { ChargingNetwork.ID($0.id) },
            avoidedNetworks: avoidedNetworks.map(ChargingNetwork.ID.init)
        )
    }

    static func code(for strategy: ChargeStopStrategy) -> String {
        switch strategy {
        case .optimal: "optimal"
        case .fewer: "fewer"
        case .fewest: "fewest"
        }
    }

    static func code(for avoidance: RouteAvoidance) -> String {
        switch avoidance {
        case .tolls: "tolls"
        case .highways: "highways"
        case .ferries: "ferries"
        case .borders: "borders"
        }
    }
}
