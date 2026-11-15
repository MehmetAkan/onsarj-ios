import Foundation
import OnsarjDomain
import Testing

@testable import RoutePlanningService

/// Her test kendi suite'ini açar ve bitince siler; testler birbirini ve uygulamayı etkilemez.
@Suite("UserDefaultsRoutePreferencesStore")
struct RoutePreferencesStoreTests {
    private let suiteName = "onsarj.tests.routePreferences.\(UUID().uuidString)"

    private func withStore(_ body: (UserDefaultsRoutePreferencesStore) async throws -> Void) async rethrows {
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        try await body(UserDefaultsRoutePreferencesStore(suiteName: suiteName))
    }

    private func write(_ json: String) {
        UserDefaults(suiteName: suiteName)?.set(Data(json.utf8), forKey: UserDefaultsRoutePreferencesStore.key)
    }

    @Test("Kaydedilen tercihler aynen okunur")
    func roundTrip() async {
        await withStore { store in
            let preferences = RoutePreferences(
                chargeStops: .fewest,
                avoid: [.tolls, .borders],
                preferredNetworks: [ChargingNetwork.ID("b"), ChargingNetwork.ID("a")],
                avoidedNetworks: [ChargingNetwork.ID("z"), ChargingNetwork.ID("c")]
            )
            await store.save(preferences)
            #expect(await store.load() == preferences)
        }
    }

    @Test("Kayıt yoksa varsayılan")
    func emptyIsDefault() async {
        await withStore { store in
            #expect(await store.load() == .default)
        }
    }

    @Test("Bozuk kayıt varsayılan verir")
    func corruptIsDefault() async {
        await withStore { store in
            write("bozuk")
            #expect(await store.load() == .default)
        }
    }

    @Test("Bilinmeyen kaçınma değeri atlanır, diğerleri okunur")
    func unknownAvoidanceIsSkipped() async {
        await withStore { store in
            write(
                """
                {"chargeStops":"fewer","avoid":["tolls","unpaved","ferries"],
                 "preferredNetworks":["zes"],"avoidedNetworks":["trugo"]}
                """
            )
            let expected = RoutePreferences(
                chargeStops: .fewer,
                avoid: [.tolls, .ferries],
                preferredNetworks: [ChargingNetwork.ID("zes")],
                avoidedNetworks: [ChargingNetwork.ID("trugo")]
            )
            #expect(await store.load() == expected)
        }
    }

    @Test("Güçlü tercih kaldırılmadan önceki kayıt biçimi okunur; yalnızca kimlik alınır")
    func legacyPreferredFormat() async {
        await withStore { store in
            write(
                """
                {"chargeStops":"optimal","avoid":[],
                 "preferredNetworks":[{"id":"zes","isStrong":true},{"id":"trugo","isStrong":false}],
                 "avoidedNetworks":[]}
                """
            )
            let expected = RoutePreferences(preferredNetworks: [ChargingNetwork.ID("zes"), ChargingNetwork.ID("trugo")])
            #expect(await store.load() == expected)
        }
    }

    @Test("Bilinmeyen durak stratejisi optimal'e düşer")
    func unknownStrategyIsOptimal() async {
        await withStore { store in
            write(#"{"chargeStops":"never","avoid":[],"preferredNetworks":[],"avoidedNetworks":[]}"#)
            #expect(await store.load() == .default)
        }
    }
}
