import Foundation
import LocationKit
import OnsarjDomain
import PhoneNumbers
import SearchFeature
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
    private(set) lazy var vehicleRepository: any VehicleRepository = Self.makeVehicleRepository()

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

    private static func makeVehicleRepository() -> any VehicleRepository {
        #if DEBUG
        let scenario = FixtureScenario(value: UserDefaults.standard.string(forKey: FixtureScenario.userDefaultsKey))
        let images = FixtureImageExporter.exportImages()
        return FixtureVehicleRepository(scenario: scenario) { images[$0] }
        #else
        return NoVehiclesRepository()
        #endif
    }
}

#if !DEBUG
/// Release'de, backend bağlanana kadar araç listesi boştur; kart "Araç ekle" halinde açılır.
private struct NoVehiclesRepository: VehicleRepository {
    func vehicles() async throws -> [Vehicle] { [] }
}
#endif
