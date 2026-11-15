import Foundation
import OnsarjDomain
import Testing

@testable import GarageFeature

/// Sonucu ayarlanabilen araç kataloğu; çağrıları sayar.
actor FakeVehicleCatalog: VehicleCatalog {
    struct Failure: Error {}

    static let brands = [
        VehicleBrand(id: VehicleBrand.ID("byd"), name: "BYD", logoURL: nil, modelCount: 1),
        VehicleBrand(id: VehicleBrand.ID("ist"), name: "İstanbul Motor", logoURL: nil, modelCount: 1),
        VehicleBrand(id: VehicleBrand.ID("skoda"), name: "Škoda", logoURL: nil, modelCount: 1),
        VehicleBrand(id: VehicleBrand.ID("togg"), name: "Togg", logoURL: nil, modelCount: 1),
    ]
    static let dolphin = VehicleModel(
        id: VehicleModel.ID("dolphin"), brandID: VehicleBrand.ID("byd"), name: "Dolphin", bodyType: .hatchback)
    static let variants = ["a", "b"]
        .map {
            VehicleVariant(
                id: VehicleVariant.ID($0), modelID: dolphin.id, name: $0, modelYear: 2023, batteryCapacityKwh: 60.5,
                connectors: [.type2], maxAcPowerKw: nil, maxDcPowerKw: nil, referenceConsumptionKwhPer100Km: 17.8,
                imageURL: nil)
        }

    private(set) var brandCalls = 0
    private(set) var modelCalls = 0

    func brands() async throws -> [VehicleBrand] {
        brandCalls += 1
        return Self.brands
    }

    func models(of brandID: VehicleBrand.ID) async throws -> [VehicleModel] {
        modelCalls += 1
        return [Self.dolphin]
    }

    func variants(of modelID: VehicleModel.ID) async throws -> [VehicleVariant] {
        Self.variants
    }
}

/// Eklemeyi bir sinyal gelene kadar bekleten depo: ekleme sürerken durumu gözlemek için.
actor SlowAddRepository: VehicleRepository {
    private var continuation: CheckedContinuation<Void, Never>?
    private var shouldFail = false

    func release(failing: Bool) {
        shouldFail = failing
        continuation?.resume()
        continuation = nil
    }

    func addVehicle(variantID: VehicleVariant.ID) async throws -> Vehicle {
        await withCheckedContinuation { continuation = $0 }
        if shouldFail { throw VehicleRepositoryError.variantNotFound }
        return TestVehicles.dolphin()
    }

    func vehicles() async throws -> [Vehicle] { [] }
    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle { TestVehicles.dolphin() }
    func deleteVehicle(_ id: Vehicle.ID) async throws {}
    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        TestVehicles.dolphin()
    }
    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        TestVehicles.dolphin()
    }
    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        TestVehicles.dolphin()
    }
    func setDefaultVehicle(_ id: Vehicle.ID) async throws -> Vehicle { TestVehicles.dolphin() }
}

@MainActor
@Suite("GarageModel")
struct GarageModelTests {
    @Test("Karta dokunmak varsayılanı değiştirir ve kapanmayı ister")
    func selectChangesDefault() async throws {
        let repository = FakeVehicleRepository(
            result: .success([
                TestVehicles.dolphin(id: "a", isDefault: true), TestVehicles.dolphin(id: "b", isDefault: false),
            ])
        )
        let model = GarageModel(repository: repository)
        await model.load()
        #expect(model.activeVehicleID == Vehicle.ID("a"))

        #expect(await model.select(Vehicle.ID("b")))
        let vehicles = try await repository.vehicles()
        #expect(Vehicle.activeVehicle(in: vehicles)?.id == Vehicle.ID("b"))
    }

    @Test("Etkin araca dokunmak yazmadan kapatır; hata olursa kapanmaz ve bildirir")
    func activeAndFailure() async {
        let repository = FakeVehicleRepository(
            result: .success([
                TestVehicles.dolphin(id: "a", isDefault: true), TestVehicles.dolphin(id: "b", isDefault: false),
            ])
        )
        let model = GarageModel(repository: repository)
        await model.load()
        await repository.setFailsWrites(true)

        #expect(await model.select(Vehicle.ID("a")))
        #expect(!(await model.select(Vehicle.ID("b"))))
        #expect(model.notice?.kind == .saveFailed)
    }
}

@MainActor
@Suite("AddVehicleModel")
struct AddVehicleModelTests {
    private func model(
        repository: any VehicleRepository = FakeVehicleRepository(result: .success([])),
        catalog: FakeVehicleCatalog = FakeVehicleCatalog()
    ) -> AddVehicleModel {
        AddVehicleModel(repository: repository, catalog: catalog)
    }

    @Test(
        "Marka araması Türkçe I/ı, İ/i ve aksan duyarsız",
        arguments: [
            ("istanbul", "İstanbul Motor"), ("ISTANBUL", "İstanbul Motor"), ("skoda", "Škoda"), ("TOĞG", "Togg"),
        ]
    )
    func brandSearch(query: String, expected: String) async {
        let model = model()
        await model.loadBrands()
        model.brandQuery = query
        #expect(model.filteredBrands.map(\.name) == [expected])
    }

    @Test("Boş sorgu tüm markaları verir; eşleşme yoksa liste boş")
    func emptyAndNoResults() async {
        let model = model()
        await model.loadBrands()
        #expect(model.filteredBrands.count == 4)
        model.brandQuery = "zzz"
        #expect(model.filteredBrands.isEmpty)
    }

    @Test("Katalog yanıtları bellekte tutulur; geri gelince yeniden istenmez")
    func cachesResponses() async {
        let catalog = FakeVehicleCatalog()
        let model = model(catalog: catalog)
        await model.loadBrands()
        await model.loadBrands()
        await model.loadModels(of: VehicleBrand.ID("byd"))
        await model.loadModels(of: VehicleBrand.ID("byd"))
        #expect(await catalog.brandCalls == 1)
        #expect(await catalog.modelCalls == 1)
    }

    @Test("Eklerken diğer satırlar pasif; hata olursa sayfada kalınır ve bildirilir")
    func addingDisablesOthersAndFailureStays() async {
        let repository = SlowAddRepository()
        let model = model(repository: repository)
        let variant = FakeVehicleCatalog.variants[0]

        let task = Task { await model.add(variant) }
        while model.addingVariantID == nil { await Task.yield() }
        #expect(model.addingVariantID == variant.id)
        #expect(!(await model.add(FakeVehicleCatalog.variants[1])), "İkinci ekleme başlamaz")

        await repository.release(failing: true)
        #expect(!(await task.value))
        #expect(model.addingVariantID == nil)
        #expect(model.notice?.kind == .addFailed)
    }

    @Test("Başarılı ekleme kapanmayı ister")
    func addSucceeds() async {
        let repository = SlowAddRepository()
        let model = model(repository: repository)
        let task = Task { await model.add(FakeVehicleCatalog.variants[0]) }
        while model.addingVariantID == nil { await Task.yield() }
        await repository.release(failing: false)
        #expect(await task.value)
    }

    @Test("Model sayısı çoğul kuralıyla biçimlenir")
    func modelCountPlural() {
        let one = GarageText.modelCount(1)
        let three = GarageText.modelCount(3)
        #expect(one.hasPrefix("1 "))
        #expect(three.hasPrefix("3 "))
        #expect(one != three || Locale.current.language.languageCode == .turkish)
    }
}
