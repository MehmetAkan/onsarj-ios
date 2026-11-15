import Foundation
import OnsarjDomain
import Testing

@testable import VehicleService

/// Her test kendi suite'ini açar ve bitince siler; testler birbirini ve uygulamayı etkilemez.
@Suite("UserDefaultsBatteryLevelStore")
struct BatteryStoreTests {
    private let suiteName = "onsarj.tests.battery.\(UUID().uuidString)"
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func withStore(_ body: (UserDefaultsBatteryLevelStore) async throws -> Void) async rethrows {
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        try await body(UserDefaultsBatteryLevelStore(suiteName: suiteName))
    }

    @Test("Kaydedilen yüzde ve tarih aynen okunur")
    func roundTrip() async {
        await withStore { store in
            let id = Vehicle.ID("veh_1")
            await store.save(BatteryLevel(percent: 64), for: id, at: date)
            let expected = StoredBatteryLevel(level: BatteryLevel(percent: 64), recordedAt: date)
            #expect(await store.storedLevel(for: id) == expected)
        }
    }

    @Test("Kayıt yoksa nil")
    func emptyIsNil() async {
        await withStore { store in
            #expect(await store.storedLevel(for: Vehicle.ID("veh_1")) == nil)
        }
    }

    @Test("Ayrı araçların kayıtları karışmaz")
    func vehiclesAreIsolated() async {
        await withStore { store in
            await store.save(BatteryLevel(percent: 10), for: Vehicle.ID("a"), at: date)
            await store.save(BatteryLevel(percent: 90), for: Vehicle.ID("b"), at: date)
            #expect(await store.storedLevel(for: Vehicle.ID("a"))?.level.percent == 10)
            #expect(await store.storedLevel(for: Vehicle.ID("b"))?.level.percent == 90)
        }
    }

    @Test("Bozuk kayıt nil verir")
    func corruptRecordIsNil() async {
        await withStore { store in
            let id = Vehicle.ID("veh_1")
            let key = UserDefaultsBatteryLevelStore.key(for: id)
            UserDefaults(suiteName: suiteName)?.set(Data("bozuk".utf8), forKey: key)
            #expect(await store.storedLevel(for: id) == nil)
        }
    }
}
