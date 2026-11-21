import Foundation
import LocationKit
import OnsarjDomain
import PhoneNumbers
import RoutePlanningService
import SearchFeature
import StationService
import VehicleService

/// Uygulama boyunca paylaşılan bağımlılıklar (CLAUDE.md 5.3 kural 2 ve 7).
///
/// Somut nesneler yalnızca burada oluşturulur ve ekranlara `init` ile verilir.
@MainActor
final class AppDependencies {
    /// Telefon numarası kuralları. Metadata yüklemesi pahalıdır; tek örnek paylaşılır ve
    /// ilk ihtiyaçta oluşturulur, böylece açılış süresine eklenmez.
    private(set) lazy var phoneNumberFormatter = PhoneNumberFormatter()

    /// Cihazın konumu ve konum izni. Tek örnek: harita ve ileride navigasyon aynı akışı dinler.
    private(set) lazy var locationSource: any LocationSource = DeviceLocationSource()

    /// Kullanıcının araçları. Backend hazır olana kadar Debug'da fixture (K-23); Release'de boş
    /// depo: uydurma veri dağıtıma girmez. İlk TestFlight dağıtımından önce gerçek depo gelir.
    /// Debug'da kartın hali başlatma argümanıyla seçilir: `-onsarjFixtureScenario <değer>`
    /// (`default`, `noImage`, `noVehicles`, `failure`).
    private(set) lazy var vehicleRepository: any VehicleRepository = makeVehicleRepository()

    /// Arama sayfasının geçmişi ve önerileri. Arama kaynağı henüz kararlaştırılmadı: Debug'da geçici
    /// tasarım verisi (`SearchDesignFixtures`), Release'de boş liste; uydurma veri dağıtıma girmez.
    #if DEBUG
    let searchHistory: @Sendable () async -> [SearchRow] = { SearchDesignFixtures.history() }
    let searchSuggestions: @Sendable (String) async -> [SearchRow] = { SearchDesignFixtures.suggestions(matching: $0) }
    #else
    let searchHistory: @Sendable () async -> [SearchRow] = { [] }
    let searchSuggestions: @Sendable (String) async -> [SearchRow] = { _ in [] }
    #endif

    /// Araç kartındaki batarya yüzdesi; cihazda saklanır.
    private(set) lazy var batteryLevelStore: any BatteryLevelStoring = UserDefaultsBatteryLevelStore()

    /// Kullanıcının rota planlama tercihleri; cihazda saklanır. İleride backend'e taşınır.
    private(set) lazy var routePreferencesStore: any RoutePreferencesStoring = UserDefaultsRoutePreferencesStore()

    /// Şarj ağı kataloğu. Backend hazır olana kadar Debug'da fixture (K-23); Release'de boş liste:
    /// uydurma veri dağıtıma girmez.
    private(set) lazy var chargingNetworkCatalog: any ChargingNetworkCatalog = Self.makeChargingNetworkCatalog()

    private static func makeChargingNetworkCatalog() -> any ChargingNetworkCatalog {
        #if DEBUG
        return FixtureChargingNetworkCatalog()
        #else
        return NoChargingNetworksCatalog()
        #endif
    }

    /// Eklenebilecek araçların kataloğu. Debug'da fixture (K-23, K-26), Release'de boş: uydurma veri
    /// dağıtıma girmez.
    private(set) lazy var vehicleCatalog: any VehicleCatalog = Self.makeVehicleCatalog()

    private static func makeVehicleCatalog() -> any VehicleCatalog {
        #if DEBUG
        return FixtureVehicleCatalog()
        #else
        return EmptyVehicleCatalog()
        #endif
    }

    /// Haritadaki şarj istasyonları. Debug'da fixture (K-23, K-26), Release'de boş liste: uydurma veri
    /// dağıtıma girmez. Debug'da yoğunluk başlatma argümanıyla seçilir: `-onsarjStationScenario dense`
    /// (1000 istasyon); varsayılan elle yazılmış liste.
    private(set) lazy var stationRepository: any StationRepository = makeStationRepository()

    #if DEBUG
    /// Fixture görselleri (araç görseli, ağ logoları); ilk ihtiyaçta bir kez yazılır.
    private lazy var fixtureImages = FixtureImageExporter.exportImages()
    #endif

    private func makeStationRepository() -> any StationRepository {
        #if DEBUG
        let value = UserDefaults.standard.string(forKey: FixtureStationScenario.userDefaultsKey)
        let images = fixtureImages
        return FixtureStationRepository(scenario: FixtureStationScenario(value: value)) { images[$0] }
        #else
        return NoStationsRepository()
        #endif
    }

    private func makeVehicleRepository() -> any VehicleRepository {
        #if DEBUG
        let scenario = FixtureScenario(value: UserDefaults.standard.string(forKey: FixtureScenario.userDefaultsKey))
        let images = fixtureImages
        return FixtureVehicleRepository(scenario: scenario) { images[$0] }
        #else
        return NoVehiclesRepository()
        #endif
    }
}

#if !DEBUG
/// Release'de, backend bağlanana kadar araç listesi boştur; kart "Araç ekle" halinde açılır. Liste boş
/// olduğu için yazma işlemlerinin hedefi de yoktur.
private struct NoVehiclesRepository: VehicleRepository {
    func vehicles() async throws -> [Vehicle] { [] }

    func updateVehicle(_ id: Vehicle.ID, _ update: VehicleUpdate) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func deleteVehicle(_ id: Vehicle.ID) async throws {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func saveProfile(_ draft: DrivingProfileDraft, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func deleteProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    func setActiveProfile(_ id: DrivingProfile.ID, for vehicleID: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }

    /// Katalog Release'de boş olduğu için eklenecek varyant da yoktur.
    func addVehicle(variantID: VehicleVariant.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.variantNotFound
    }

    func setDefaultVehicle(_ id: Vehicle.ID) async throws -> Vehicle {
        throw VehicleRepositoryError.vehicleNotFound
    }
}

/// Release'de, backend bağlanana kadar haritada ve yakındakiler listesinde istasyon yoktur.
private struct NoStationsRepository: StationRepository {
    func stations(in box: GeoBoundingBox) async throws -> [Station] { [] }

    func stationDetail(_ id: Station.ID) async throws -> StationDetail {
        throw StationRepositoryError.stationNotFound
    }

    func nearbyStations(_ query: StationQuery) async throws -> [StationListItem] { [] }
}

/// Release'de, backend bağlanana kadar araç kataloğu boştur.
private struct EmptyVehicleCatalog: VehicleCatalog {
    func brands() async throws -> [VehicleBrand] { [] }
    func models(of brandID: VehicleBrand.ID) async throws -> [VehicleModel] { [] }
    func variants(of modelID: VehicleModel.ID) async throws -> [VehicleVariant] { [] }
}

/// Release'de, backend bağlanana kadar şarj ağı kataloğu boştur; seçici "Sonuç bulunamadı" gösterir.
private struct NoChargingNetworksCatalog: ChargingNetworkCatalog {
    func networks(matching query: String) async throws -> [ChargingNetwork] { [] }
    func networks(withIDs ids: [ChargingNetwork.ID]) async throws -> [ChargingNetwork] { [] }
}
#endif
