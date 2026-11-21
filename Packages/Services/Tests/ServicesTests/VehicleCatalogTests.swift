#if DEBUG
import Foundation
import OnsarjDomain
import Testing

@testable import VehicleService

@Suite("FixtureVehicleCatalog")
struct VehicleCatalogTests {
    private let catalog = FixtureVehicleCatalog()

    @Test("Markalar eşlenir, ada göre sıralı ve logosuz")
    func brands() async throws {
        let brands = try await catalog.brands()
        #expect(brands.count == 10)
        #expect(
            brands.map(\.name)
                == brands.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
        #expect(brands.allSatisfy { $0.logoURL == nil })
    }

    @Test("Her markanın model sayısı gerçek model sayısıyla aynı; her modelde 1–3 varyant")
    func modelCountsAreConsistent() async throws {
        for brand in try await catalog.brands() {
            let models = try await catalog.models(of: brand.id)
            #expect(models.count == brand.modelCount, "\(brand.name)")
            #expect((1...3).contains(models.count))
            for model in models {
                #expect(model.brandID == brand.id)
                let variants = try await catalog.variants(of: model.id)
                #expect((1...3).contains(variants.count), "\(model.name)")
                #expect(variants.allSatisfy { $0.modelID == model.id && !$0.connectors.isEmpty })
            }
        }
    }

    @Test("BYD Dolphin varyantı fixture aracıyla tutarlı")
    func dolphinMatchesFixtureVehicle() async throws {
        let variant = try #require(try await catalog.variants(of: VehicleModel.ID("model_byd_dolphin")).first)
        let vehicle = try #require(try await FixtureVehicleRepository().vehicles().first)
        #expect(variant.name == vehicle.variant)
        #expect(variant.modelYear == vehicle.modelYear)
        #expect(variant.batteryCapacityKwh == vehicle.batteryCapacityKwh)
        #expect(variant.referenceConsumptionKwhPer100Km == vehicle.standardProfile.consumptionKwhPer100Km)
    }

    @Test("Eşleme: eksik alan hangi kaydın hangi alanı olduğunu söyler")
    func mappingError() {
        let list = VehicleBrandListDTO(brands: [VehicleBrandDTO(id: "b", name: nil, logoUrl: nil, modelCount: 1)])
        #expect(throws: VehicleCatalogMappingError(record: .brand, index: 0, field: "name")) {
            try VehicleCatalogMapper.brands(from: list)
        }
    }
}

@Suite("FixtureVehicleRepository araç ekleme ve varsayılan")
struct FixtureVehicleDefaultTests {
    private let repository = FixtureVehicleRepository()
    private let dolphinID = Vehicle.ID("veh_fixture_01")
    private let toggVariant = VehicleVariant.ID("variant_togg_t10x_v1_rwd")

    @Test("Eklenen araç varsayılan olur, diğerleri olmaz; standart profil varyanttan gelir")
    func addVehicle() async throws {
        let togg = try await repository.addVehicle(variantID: toggVariant)
        #expect(togg.displayName == "Togg T10X")
        #expect(togg.variant == "V1 RWD Standart Menzil")
        #expect(togg.isDefault)
        #expect(togg.colorHex == VehiclePaint.white.hex)
        #expect(togg.drivingProfiles.count == 1)
        #expect(togg.standardProfile.consumptionKwhPer100Km == 16.9)
        #expect(togg.standardProfile.maxSpeedKmh == 120)
        #expect(togg.bodyType == .suv)

        let vehicles = try await repository.vehicles()
        #expect(vehicles.filter(\.isDefault).map(\.id) == [togg.id])
        #expect(Vehicle.activeVehicle(in: vehicles)?.id == togg.id)
    }

    @Test("Aynı varyant iki kez eklenebilir; bilinmeyen varyant reddedilir")
    func duplicatesAndUnknown() async throws {
        let first = try await repository.addVehicle(variantID: toggVariant)
        let second = try await repository.addVehicle(variantID: toggVariant)
        #expect(first.id != second.id)
        #expect(try await repository.vehicles().count == 3)
        await #expect(throws: VehicleRepositoryError.variantNotFound) {
            try await repository.addVehicle(variantID: VehicleVariant.ID("yok"))
        }
    }

    @Test("setDefaultVehicle varsayılanı değiştirir")
    func setDefault() async throws {
        let togg = try await repository.addVehicle(variantID: toggVariant)
        let dolphin = try await repository.setDefaultVehicle(dolphinID)
        #expect(dolphin.isDefault)
        let vehicles = try await repository.vehicles()
        #expect(vehicles.first { $0.id == togg.id }?.isDefault == false)
    }

    @Test("Varsayılan araç silinince kalanlardan en son eklenen varsayılan olur")
    func deleteDefaultPicksMostRecent() async throws {
        let first = try await repository.addVehicle(variantID: toggVariant)
        let second = try await repository.addVehicle(variantID: VehicleVariant.ID("variant_mg_mg4_standard"))
        _ = try await repository.setDefaultVehicle(first.id)

        try await repository.deleteVehicle(first.id)
        let vehicles = try await repository.vehicles()
        #expect(vehicles.filter(\.isDefault).map(\.id) == [second.id])

        try await repository.deleteVehicle(second.id)
        #expect(try await repository.vehicles().filter(\.isDefault).map(\.id) == [dolphinID])
    }

    @Test("noVehicles senaryosunda da araç eklenebilir")
    func addInEmptyGarage() async throws {
        let repository = FixtureVehicleRepository(scenario: .noVehicles)
        let togg = try await repository.addVehicle(variantID: toggVariant)
        #expect(try await repository.vehicles() == [togg])
    }
}
#endif
