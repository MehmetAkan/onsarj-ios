import Foundation
import OnsarjDomain
import Testing

@testable import HomeMapFeature

@MainActor
@Suite("VehicleCardModel")
struct VehicleCardModelTests {
    private nonisolated static let recordedAt = Date(timeIntervalSince1970: 1_800_000_000)

    private static func vehicle(id: String = "veh_1", isDefault: Bool = true) -> Vehicle {
        TestVehicles.dolphin(id: id, isDefault: isDefault)
    }

    private func makeModel(
        repository: FakeVehicleRepository,
        store: FakeBatteryStore = FakeBatteryStore()
    ) -> VehicleCardModel {
        VehicleCardModel(repository: repository, batteryStore: store, now: { Self.recordedAt })
    }

    @Test("Kayıtlı yüzde yoksa kart başlangıç değeriyle açılır ve depoya yazılmaz")
    func startsWithInitialLevel() async {
        let store = FakeBatteryStore()
        let model = makeModel(repository: FakeVehicleRepository(result: .success([Self.vehicle()])), store: store)

        await model.load()
        await model.commitLevel()

        #expect(model.state == .loaded(Self.vehicle(), .initial))
        #expect(await store.saveCount == 0)
    }

    @Test("Kayıtlı yüzde varsa o gösterilir")
    func showsStoredLevel() async {
        let store = FakeBatteryStore(stored: StoredBatteryLevel(level: BatteryLevel(percent: 72), recordedAt: .now))
        let model = makeModel(repository: FakeVehicleRepository(result: .success([Self.vehicle()])), store: store)

        await model.load()

        #expect(model.state == .loaded(Self.vehicle(), BatteryLevel(percent: 72)))
    }

    @Test("Etkin araç varsayılan olarak işaretlenendir")
    func picksDefaultVehicle() async {
        let vehicles = [Self.vehicle(id: "a", isDefault: false), Self.vehicle(id: "b", isDefault: true)]
        let model = makeModel(repository: FakeVehicleRepository(result: .success(vehicles)))

        await model.load()

        #expect(model.state == .loaded(vehicles[1], .initial))
    }

    @Test("Araç listesi boşsa durum 'araç yok'")
    func emptyList() async {
        let model = makeModel(repository: FakeVehicleRepository(result: .success([])))

        await model.load()

        #expect(model.state == .empty)
    }

    @Test("Depo hata fırlatırsa durum 'hata'; yeniden yükleyince düzelir")
    func failureThenReload() async {
        let repository = FakeVehicleRepository(result: .failure)
        let model = makeModel(repository: repository)

        await model.load()
        #expect(model.state == .failed)

        await repository.setResult(.success([Self.vehicle()]))
        await model.reload()
        #expect(model.state == .loaded(Self.vehicle(), .initial))
    }

    @Test("Yüklenmiş kart ikinci kez yüklenmez")
    func loadRunsOnce() async {
        let repository = FakeVehicleRepository(result: .success([Self.vehicle()]))
        let model = makeModel(repository: repository)

        await model.load()
        await model.load()

        #expect(await repository.callCount == 1)
    }

    @Test("Sürükleme ekrandaki değeri anında değiştirir ama kaydetmez")
    func updateDoesNotSave() async {
        let store = FakeBatteryStore()
        let model = makeModel(repository: FakeVehicleRepository(result: .success([Self.vehicle()])), store: store)
        await model.load()

        model.updateLevel(64)

        #expect(model.state == .loaded(Self.vehicle(), BatteryLevel(percent: 64)))
        #expect(await store.saveCount == 0)
    }

    @Test("Sürükleme bitince tam bir kez kaydedilir", arguments: [(64, 64), (130, 100), (-5, 0)])
    func commitSavesOnce(percent: Int, expected: Int) async {
        let store = FakeBatteryStore()
        let model = makeModel(repository: FakeVehicleRepository(result: .success([Self.vehicle()])), store: store)
        await model.load()

        model.updateLevel(percent)
        await model.commitLevel()
        await model.commitLevel()

        #expect(await store.saveCount == 1)
        let saved = StoredBatteryLevel(level: BatteryLevel(percent: expected), recordedAt: Self.recordedAt)
        #expect(await store.lastSaved == saved)
        #expect(await store.lastVehicleID == Vehicle.ID("veh_1"))
    }

    @Test("Menzil karta doğru yansır: %30 → 97 km (60,5 kWh × %95 ÷ 17,8 kWh/100 km)")
    func rangeReflectsLevel() async {
        let model = makeModel(repository: FakeVehicleRepository(result: .success([Self.vehicle()])))
        await model.load()

        guard case .loaded(let vehicle, let level) = model.state else {
            Issue.record("Kart yüklenmedi")
            return
        }
        #expect(vehicle.estimatedRangeKm(at: level) == 97)
    }

    @Test("Kartın alt başlığı etkin profilin adıdır")
    func subtitleIsActiveProfile() {
        let vehicle = Self.vehicle()
        #expect(VehicleCard.subtitle(for: vehicle) == "Standart")
        #expect(VehicleCard.subtitle(for: vehicle.with(activeProfileID: TestVehicles.highway.id)) == "Otoyol")
    }

    @Test("Yenileme değişen aracı gösterir; araç silindiyse 'araç yok'")
    func refreshAfterSettings() async {
        let repository = FakeVehicleRepository(result: .success([Self.vehicle()]))
        let model = makeModel(repository: repository)
        await model.load()

        let changed = Self.vehicle().with(activeProfileID: TestVehicles.highway.id)
        await repository.setResult(.success([changed]))
        await model.refresh()
        #expect(model.state == .loaded(changed, .initial))

        await repository.setResult(.success([]))
        await model.refresh()
        #expect(model.state == .empty)
    }
}

private actor FakeBatteryStore: BatteryLevelStoring {
    private let stored: StoredBatteryLevel?
    private(set) var saveCount = 0
    private(set) var lastSaved: StoredBatteryLevel?
    private(set) var lastVehicleID: Vehicle.ID?

    init(stored: StoredBatteryLevel? = nil) {
        self.stored = stored
    }

    func storedLevel(for vehicleID: Vehicle.ID) async -> StoredBatteryLevel? {
        stored
    }

    func save(_ level: BatteryLevel, for vehicleID: Vehicle.ID, at date: Date) async {
        saveCount += 1
        lastSaved = StoredBatteryLevel(level: level, recordedAt: date)
        lastVehicleID = vehicleID
    }
}
